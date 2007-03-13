###########################################
package Process::MaxSize;
###########################################

use strict;
use warnings;
use Log::Log4perl qw(:easy);

our $VERSION = "0.01";

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my @argv = @ARGV;

    my $self = {
        max_size => "10m",
        restart  => sub { 
            INFO "Restarting $0 @ARGV";
            exec $0, @argv 
        },
        sleep    => 10,
        %options,
    };

    if($self->{max_size} =~ /m$/) {
        $self->{max_size} =~ s/\D//g;
        $self->{max_size} *= 1024;
    }

    bless $self, $class;
}

###########################################
sub check {
###########################################
    my($self) = @_;

    my $mysize = $self->mysize();

    DEBUG "Checking size: ${mysize}kB (max $self->{max_size}kB)";

    if($mysize > $self->{max_size}) {
        WARN "Max size reached ",
             "(${mysize}kB/$self->{max_size}kB, restarting";

        $self->{restart}->();
          # Doesn't return
    }

    return $mysize;
}

###########################################
sub mysize {
###########################################
    my($self) = @_;

      # Doesn't work on freebsd
    #use Proc::ProcessTable;
    #my $t = Proc::ProcessTable->new();
    #my($p) = grep { $_->pid == $$ } @{$t->table};
    #return $p->size();
    
    my $size;

    open PIPE, "/bin/ps -ww -axo 'pid,rss' |";
    while(<PIPE>) {
        next unless /^$$\s/;
        chomp;
        $size = (split(' ', $_))[1];
    }
    close PIPE;

    return $size;
}

1;

__END__

=head1 NAME

Process::MaxSize - Restart processes when they exceed a size limit

=head1 SYNOPSIS

    use Process::MaxSize;

      # Limit the process to 100 MB
    my $watchdog = Process::MaxSize->new(
                       max_size => "100m"
    );

    while(1) {
        ... your code here ...
        $watchdog->check();
    }
   
=head1 DESCRIPTION

C<Process::MaxSize> helps to contain perl programs that leak memory.
It defines a watchdog that, at well defined locations within a program,
checks the current process size and triggers a restart routine in case
a predefined size limit is exceeded.

To define a new watchdog, use the C<Process::MaxSize> constructor:

    my $watchdog = Process::MaxSize->new();

By default, the memory watchdog will be set to 10M of memory and
a restart function that C<exec>s the same process again with a copy
of all command line arguments. To use different settings, let the
constructor know:

    my @argv = @ARGV;

      # Limit the process to 100 MB
    my $watchdog = Process::MaxSize->new(
        max_size => "100m",
        restart  => sub { exec $0, @argv };
    );

C<max_size> specifies the maximum real memory consumption in KBytes, 
unless the letter C<"m"> indicates that you mean MBytes.

C<restart> is a code ref that performs an arbitrary action. By default,
the current program gets restarted via C<exec> and a copy of its
command line arguments @ARGV.

The check method checks the current memory consumption and triggers
the C<restart> routine if the limit is exceeded:

        $watchdog->check();

=head2 What's process size?

To measure the process size, C<Process::MaxSize> defines a method
C<mysize()> which returns the current the real memory (resident set) 
size of the process in 1024 byte units. If you like to measure the virtual
memory size or use a different method than the somewhat crude call
of "ps" (like Proc::ProcessTable), just create a subclass and override
C<mysize()>.

=head1 LEGALESE

Copyright 2007 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2007, Mike Schilli <m@perlmeister.com>

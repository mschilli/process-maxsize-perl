###########################################
package Process::MaxSize;
###########################################

use strict;
use warnings;
use Log::Log4perl qw(:easy);
use Cwd;

our $VERSION = "0.03";

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my @argv = @ARGV;

    my $self = {
        max_size => "10m",
        restart  => sub { 
            INFO "Restarting $0 @ARGV";
            exec $0, @argv or
	        LOGDIE "exec failed: $!";
        },
        sleep    => 2,
	cwd      => cwd(),
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

    my $process_size = $self->process_size();

    DEBUG "Checking size: ${process_size}kB (max $self->{max_size}kB)";

    if($process_size > $self->{max_size}) {
        WARN "Max size reached ",
             "(${process_size}kB/$self->{max_size}kB, restarting";

          # Sleep the specified number of seconds
	if($self->{sleep}) {
            INFO "Sleeping $self->{sleep} seconds.";
            sleep($self->{sleep});
        }

          # Try to go back to the start directory
        INFO "Changing directory to $self->{cwd}";
        chdir $self->{cwd};

        $self->{restart}->();
          # Doesn't return
    }

    return $process_size;
}

###########################################
sub process_size {
###########################################
    my($self) = @_;

      # Doesn't work on freebsd
    #use Proc::ProcessTable;
    #my $t = Proc::ProcessTable->new();
    #my($p) = grep { $_->pid == $$ } @{$t->table};
    #return $p->size();
    
    my $size;

    my $ps         = "ps";
    my $solaris_ps = "/usr/ucb/ps";

    if( -f $solaris_ps ) {
        $ps = $solaris_ps;
    }

    open PIPE, "$ps wwaxo 'pid,rss' |";
    while(<PIPE>) {
        next unless /^\s*$$\s/;
	s/^\s+//g;
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

	  # restarts the process if memory limit is exceeded
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
        restart  => sub { exec($0, @argv) or 
                            die "Can't restart!" },
    );

C<max_size> specifies the maximum real memory consumption allowed in KBytes, 
unless the letter C<"m"> indicates that you mean MBytes.

C<restart> is a code ref that performs an arbitrary action. By default,
the current program gets restarted via C<exec> and a copy of its
command line arguments @ARGV. C<Process::MaxSize> is going to
change to the original start directory (of the time the constructor
was called) before calling the restart routine.

The check method checks the current memory consumption and triggers
the C<restart> routine if the limit is exceeded:

        $watchdog->check();

You want to plant the call to the C<check()> method at a location

=over 4

=item *

where the program whizzes by periodically to make sure you check as soon
as the process exceeds the memory limit and

=item *

where the program can be safely terminated and restarted.

=back

By default, C<Process::MaxSize> will sleep 2 seconds before restarting
the process. This is to prevent that it will hog the CPU if something
goes wrong with the exec and the process ends up in an infinite loop.
To eliminate this precautious setting, set the C<sleep> parameter
to the required number of seconds in the constructor call:

    my $watchdog = Process::MaxSize->new(
        sleep    => 0,
    );

The C<restart> method doesn't need to restart the program. It can
be used to simply set a flag which indicates another part of the program
that the preset size limit has been exceeded:

    my $watchdog = Process::MaxSize->new(
        restart  => sub { $out_of_memory = 1 },
    );

This can come in handy when the program flow requires that the program
needs to terminate/restart at a different point in the flow than the 
location where it detects that the process exceeds the memory limits.

=head2 Which process size?

To measure the process size, C<Process::MaxSize> defines a method
C<process_size()> which returns the current real memory (resident set) 
size of the process in 1024 byte units. If you like to measure the virtual
memory size instead or want to employ a different method than 
the somewhat crude call
to "ps" (Proc::ProcessTable comes to mind), just create a subclass of
C<Process::MaxSize> and override the C<process_size()> method to 
return the number of used KBytes.

=head2 Debugging/Logging

C<Process::MaxSize> is Log::Log4perl-enabled and will start logging
as soon as C<Log::Log4perl> gets initialized:

    use Log::Log4perl qw(:easy);
    Log::Log4perl->easy_init($DEBUG);

As usual with C<Log::Log4perl>, this is completely optional.

=head1 LEGALESE

Copyright 2007 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2007, Mike Schilli <m@perlmeister.com>

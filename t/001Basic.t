######################################################################
# Test suite for Process::MaxSize
# by Mike Schilli <mschilli@yahoo-inc.com>
######################################################################

use warnings;
use strict;
use Log::Log4perl qw(:easy);

use Test::More qw(no_plan);
BEGIN { use_ok('Process::MaxSize') };

# Log::Log4perl->easy_init($DEBUG);

use Process::MaxSize;

my $mysize = Process::MaxSize::mysize();

  # Sanity check
if($mysize < 1000 or
   $mysize > 20000) {
    die "Measured process size $mysize -- please contact the author";
}

my $max_size = $mysize + 1024*5;
my $mega = ("X" x (1024*1024));

my $restarted = 0;
my $p = Process::MaxSize->new(
    restart  => sub { $restarted = 1; },
    max_size => $max_size,
);

my @arr = ();

$p->check();
is($restarted, 0, "Not yet restarted");

push @arr, $mega;
$p->check();
is($restarted, 0, "Not yet restarted");

for(1..5) {
    push @arr, $mega;
    $p->check();
}

is($restarted, 1, "Restarted");

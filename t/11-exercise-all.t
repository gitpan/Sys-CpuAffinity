use Sys::CpuAffinity;
use Test::More tests => 1;
use strict qw(vars subs);
use warnings;

#
# Exercise all of the methods in the toolbox to
# count processors on the system, get cpu affinity,
# and set cpu affinity. 
#
# Generally each tool is targeted to work on a
# single system. Since most of the tools are
# targeted at a different system than yours,
# most of these tools will fail on your system.
#
# Among the tools that are targeted to your
# system, some of them will depend on certain
# Perl modules or certain external programs
# being available, so those tools might also
# fail on your system.
#
# Hopefully, we'll find at least one tool for
# each task (count cpus, get affinity, set
# affinity) that will work for you. And that's
# all we need.
#

my ($pid,$wpid);

$wpid = $pid = $$;
if ($^O eq "cygwin") {
  $wpid = Cygwin::pid_to_winpid($pid);
}

require "t/inventory.pl";

select STDERR;

EXERCISE_COUNT_NCPUS();
my $n = Sys::CpuAffinity::getNumCpus();
if ($n <= 1) {
 SKIP: {
    if ($n == 1) {
      skip "affinity exercise. Only one processor on this system", 1;
    } else {
      skip "affinity exercise. Can't detect number of processors", 1;
    }
  }
  exit 0;
}
EXERCISE_GET_AFFINITY();
EXERCISE_SET_AFFINITY();
ok(1);


sub EXERCISE_GET_AFFINITY {

    print "\n\n===============================================\n";

    print "Current affinity = \n";

    for my $s (inventory::getAffinity()) {
	my $sub = 'Sys::CpuAffinity::_getAffinity_with_' . $s;
	my $z = $s =~ /Win32/ ? $sub->($wpid) : $sub->($pid);
	printf "    %-25s ==> %d\n", $s, $z;
    }
}

sub EXERCISE_COUNT_NCPUS {

    print "\n\n=================================================\n";

    print "Num processors =\n";

    for my $technique (inventory::getNumCpus()) {
	my $s = 'Sys::CpuAffinity::_getNumCpus_from_' . $technique;
	printf "    %-25s - %d -\n", $technique, $s->();
    }

}

sub EXERCISE_SET_AFFINITY {

    print "\n\n==================================================\n";


    my $np = Sys::CpuAffinity::getNumCpus();
    return 0 if $np <= 1;

    my ($TARGET,$LAST_TARGET) = (0,0);
    my @mask = ();
    while (@mask < 500) {
	$TARGET = int(rand() * (2**$np - 1)) + 1
	    while $TARGET == $LAST_TARGET;
	$LAST_TARGET = $TARGET;
	push @mask, $TARGET;
    }

    # print "@mask\n";

    print "Set affinity =\n";

    for my $technique (inventory::setAffinity()) {
	my $rr = Sys::CpuAffinity::getAffinity($pid);
	my $mask;
	do {
	    $mask = shift @mask;
	} while $mask == $rr;

	my $s = "Sys::CpuAffinity::_setAffinity_with_$technique";
	if ($technique =~ /Win32/) {
	    $s->($wpid,$mask);
	} else {
	    $s->($pid,$mask);
	}
	my $r = Sys::CpuAffinity::getAffinity($pid);
	my $result = $r==$rr ? "FAIL" : " ok ";
	printf "    %-25s => %3u ==> %3u   [%s]\n", $technique, 
	  $mask, $r, $result;
    }
}


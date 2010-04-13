use Sys::CpuAffinity;
use Test::More tests => 8;
use strict;
use warnings;

my $ntests = 8;

my $n = Sys::CpuAffinity::getNumCpus();
ok($n > 0, "discovered $n processors");

if ($n <= 1) {
 SKIP: {
    skip "can't test affinity on single cpu system", $ntests - 1;
  }
  exit 0;
}

# On Windows (but not Cygwin), get/set affinity for a child process
# is different than for the parent process.
my $f = "ipc.$$";
unlink $f;
my $pid = CORE::fork();
if (defined $pid && $pid == 0) {

  open F, '>', $f;
  my $y3 = Sys::CpuAffinity::getAffinity($$);
  print F "getAffinity:$y3\n";

  my $r3 = 1 + int(rand() * ((1 << $n) - 1));
  while ($r3 == $y3) {
    $r3 = 1 + int(rand() * ((1 << $n) - 1));
  }

  print F "targetAffinity:$r3\n";
  my $z3 = Sys::CpuAffinity::setAffinity($$, $r3);
  print F "setAffinity:$z3\n";

  my $y4 = Sys::CpuAffinity::getAffinity($$);
  print F "getAffinity2:$y4\n";
  close F;

  exit 0;
}

my $y = Sys::CpuAffinity::getAffinity($$);
ok($y > 0 && $y < (1 << $n), "got current process affinity $y");

my $r = 1 + int(rand() * ((1 << $n) - 1));
while ($r == $y) {
  $r = 1 + int(rand() * ((1 << $n) - 1));
}

my $z = Sys::CpuAffinity::setAffinity($$, $r);
ok($z != 0, "setCpuAffinity returned non-zero");

my $y2 = Sys::CpuAffinity::getAffinity($$);
ok($y2 == $r, "setCpuAffinity set affinity to $r == $y2 != $y");

# unbind -- on solaris and with BSD's cpuset this is a different
# operation than binding to all processors.

my $y5 = Sys::CpuAffinity::setAffinity($$, -1);
my $z5 = Sys::CpuAffinity::getAffinity($$);
ok($y5 && $z5 && $z5+1 == 1 << $n,
   "setCpuAffinity(-1) does unbind");

CORE::wait;

open F, '<', $f;
print <F>;
close F;


open F, '<', $f;
my $g = <F>;
my ($y3) = $g =~ /getAffinity:(\d+)/;
ok(defined $y3 && $y3 > 0 && $y3 < (1<<$n), "got pseudo-proc affinity $y3");

$g = <F>;
my ($r3) = $g =~ /targetAffinity:(\d+)/;
$g = <F>;
my ($z3) = $g =~ /setAffinity:(\d+)/;
ok(defined $r3 && defined $z3 && $z3 != 0,
   "set pseudo-proc affinity non-zero result $z3");

$g = <F>;
close F;
unlink $f;

my ($y4) = $g =~ /getAffinity2:(\d+)/;
ok(defined $y4 && $y4 == $r3,
   "set pseudo-proc affinity to $r3 == $y4 != $y3");

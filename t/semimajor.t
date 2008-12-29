package main;	# To make Perl::Critic happy.

use strict;
use warnings;

# The following is a quick ad-hoc way to get an object with a specified
# period.
package Astro::Coord::ECI::TLE::Period;	## no critic ProhibitMultiplePackages

use base qw{Astro::Coord::ECI::TLE};

{
    my $pkg = __PACKAGE__;
    sub period {
	my ($self, @args) = @_;
	if (@args) {
	    $self->{$pkg}{period} = shift @args;
	    return;
	} else {
	    return $self->{$pkg}{period};
	}
    }
}

# And now, back to our regularly-scheduled test.
package main;	## no critic ProhibitMultiplePackages

use Astro::Coord::ECI::TLE;
use Test;

{
    my $tests = 0;
    my $loc = tell(DATA);
    while (<DATA>) {
	chomp;
	s/^\s+//;
	$_ or next;
	substr($_, 0, 1) eq '#' and next;
	$tests++;
    }
    plan (tests => $tests);
    seek (DATA, $loc, 0);
}

my $test = 0;

while (<DATA>) {
    chomp;
    s/^\s+//;
    $_ or next;
    substr($_, 0, 1) eq '#' and next;
    $test++;
    my ($period, $want, $tolerance) = split ('\s+', $_, 4);
    defined $tolerance or $tolerance = 1;
    my $tle = Astro::Coord::ECI::TLE::Period->new();
    $tle->period($period);
    my $got = $tle->semimajor();
    print <<eod;
#
# Test $test - Semimajor axis from period.
#          Want: $want
#           Got: $got
#     Tolerance: $tolerance
eod
    ok(abs ($want - $got) <= $tolerance);
}

1;
__DATA__

# Worked examples are hard to find. This one is pretty approximate.
86400	42273	40

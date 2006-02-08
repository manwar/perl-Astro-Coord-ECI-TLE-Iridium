=head1 NAME

Astro::Coord::ECI::Utils - Utility routines for astronomical calculations

=head1 SYNOPSIS

 my $loc = Astro::Coord::ECI->geodetic ($lat, $lon, $elev);
 my $sun = Astro::Coord::ECI::Sun->new ()->universal (time ());
 my ($azimuth, $elevation, $range) = $loc->azel ($sun);

=head1 DESCRIPTION

This module was written to provide a home for all the constants and
utility subroutines used by B<Astro::Coord::ECI> and its descendents.
What ended up here was anything that was essentially a subroutine, not
a method.

This package exports nothing by default. But all the constants and
subroutines documented below are exportable, and the :all tag gets you
all of them.

The following constants are exportable:

 LIGHTYEAR = number of kilometers in a light year
 PARSEC = number of kilometers in a parsec
 PERL2000 = January 1 2000, 12 noon universal, in Perl time
 PI = the circle ratio, computed as atan2 (0, -1)
 PIOVER2 = half the circle ratio
 SECSPERDAY = the number of seconds in a day
 TWOPI = twice the circle ratio

In addition, the following subroutines are exportable:

=over 4

=cut

use strict;
use warnings;

package Astro::Coord::ECI::Utils;

our $VERSION = 0.001;

use Carp;
use Data::Dumper;
use Exporter qw{import};
use POSIX qw{floor};
use Time::Local;
use UNIVERSAL qw{can isa};

our @EXPORT;
our @EXPORT_OK = qw{
	LIGHTYEAR PARSEC PERL2000 PI PIOVER2 SECSPERDAY TWOPI
	acos asin deg2rad distsq equation_of_time jcent2000 jday2000
	julianday mod2pi nutation_in_longitude nutation_in_obliquity
	obliquity omega rad2deg tan theta0 thetag};

# Notes for the conversion: The all caps names are constants. The
# following names were once public methods of Astro::Coord::ECI:
#	equation_of_time jcent2000 jday2000 julianday
#	nutation_in_longitude nutation_in_obliquity obliquity omega
#	theta0 thetag
# All others were "private" methods whose names began with an
# underscore.

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
    );

use constant LIGHTYEAR => 9.4607e12;	# 1 light-year, per Meeus, Appendix I pg 407.
use constant PARSEC => 30.8568e12;	# 1 parsec, per Meeus, Appendix I pg 407.
use constant PERL2000 => timegm (0, 0, 12, 1, 0, 100);
use constant PI => atan2 (0, -1);
use constant PIOVER2 => PI / 2;
use constant SECSPERDAY => 86400;
### use constant SOLAR_RADIUS => 1392000 / 2;	# Meeus, Appendix I, page 407.
use constant TWOPI => PI * 2;


=item $angle = acos ($value)

This subroutine calculates the arc in radians whose cosine is the given
value.

=cut

sub acos {atan2 (sqrt (1 - $_[0] * $_[0]), $_[0])}


=item $angle = asin ($value)

This subroutine calculates the arc in radians whose sine is the given
value.

=cut

sub asin {atan2 ($_[0], sqrt (1 - $_[0] * $_[0]))}


=item $rad = deg2rad ($degr)

This subroutine converts degrees to radians.

=cut

sub deg2rad {$_[0] * PI / 180}


=item $value = distsq (\@coord1, \@coord2)

This subroutine calculates the square of the distance between the two
sets of Cartesian coordinates. We don't take the square root here
because of cases (e.g. the law of cosines) where we would just have
to square the result again.

=cut

sub distsq {
ref $_[0] eq 'ARRAY' && ref $_[1] eq 'ARRAY' && @{$_[0]} == @{$_[1]} or
    die "Programming error - Both arguments to distsq must be ",
    "references to lists of the same length.";

my $sum = 0;
my $size = @{$_[0]};
for (my $inx = 0; $inx < $size; $inx++) {
    my $delta = $_[0][$inx] - $_[1][$inx];
    $sum += $delta * $delta;
    }
$sum
}


=item $seconds = equation_of_time ($time);

This method returns the equation of time at the given B<dynamical>
time.

The algorithm is from W. S. Smart's "Text-Book on Spherical Astronomy",
as reported in Jean Meeus' "Astronomical Algorithms", 2nd Edition,
Chapter 28, page 185.

=cut

sub equation_of_time {

my $time = shift;

my $epsilon = obliquity ($time);
my $y = tan ($epsilon / 2);
$y *= $y;


#	The following algorithm is from Meeus, chapter 25, page, 163 ff.

my $T = jcent2000 ($time);				# Meeus (25.1)
my $L0 = mod2pi (deg2rad ((.0003032 * $T + 36000.76983) * $T	# Meeus (25.2)
	+ 280.46646));
my $M = mod2pi (deg2rad (((-.0001537) * $T + 35999.05029)	# Meeus (25.3)
	* $T + 357.52911));
my $e = (-0.0000001267 * $T - 0.000042037) * $T + 0.016708634;	# Meeus (25.4)

my $E = $y * sin (2 * $L0) - 2 * $e * sin ($M) +
    4 * $e * $y * sin ($M) * cos (2 * $L0) -
    $y * $y * .5 * sin (4 * $L0) -
    1.25 * $e * $e * sin (2 * $M);				# Meeus (28.3)

$E * SECSPERDAY / TWOPI;	# The formula gives radians.
}


=item $century = jcent2000 ($time);

Several of the algorithms in Jean Meeus' "Astronomical Algorithms"
are expressed in terms of the number of Julian centuries from epoch
J2000.0 (e.g equations 12.1, 22.1). This subroutine encapsulates
that calculation.

=cut

sub jcent2000 {
jday2000 ($_[0]) / 36525;
}


=item $jd = jday2000 ($time);

This subroutine converts a Perl date to the number of Julian days
(and fractions thereof) since Julian 2000.0. This quantity is used
in a number of the algorithms in Jean Meeus' "Astronomical
Algorithms".

The computation makes use of information from Jean Meeus' "Astronomical
Algorithms", 2nd Edition, Chapter 7, page 62.

=cut

sub jday2000 {
($_[0] - PERL2000) / SECSPERDAY			#   Meeus p. 62
}


=item $jd = julianday ($time);

This subroutine converts a Perl date to a Julian day number.

The computation makes use of information from Jean Meeus' "Astronomical
Algorithms", 2nd Edition, Chapter 7, page 62.

=cut

sub julianday {
jday2000($_[0]) + 2_451_545.0	#   Meeus p. 62
}


=item $delta_psi = nutation_in_longitude ($time)

This subroutine calculates the nutation in longitude (delta psi) for
the given B<dynamical> time.

The algorithm comes from Jean Meeus' "Astronomical Algorithms", 2nd
Edition, Chapter 22, pages 143ff. Meeus states that it is good to
0.5 seconds of arc.

=cut

sub nutation_in_longitude {

my $time = shift;
my $T = jcent2000 ($time);	# Meeus (22.1)

my $omega = mod2pi (deg2rad ((($T / 450000 + .0020708) * $T -
	1934.136261) * $T + 125.04452));

my $L = mod2pi (deg2rad (36000.7698 * $T + 280.4665));
my $Lprime = mod2pi (deg2rad (481267.8813 * $T + 218.3165));
my $delta_psi = deg2rad ((-17.20 * sin ($omega) - 1.32 * sin (2 * $L)
	- 0.23 * sin (2 * $Lprime) + 0.21 * sin (2 * $omega))/3600);

$delta_psi;
}


=item $delta_epsilon = nutation_in_obliquity ($time)

This subroutine calculates the nutation in obliquity (delta epsilon)
for the given B<dynamical> time.

The algorithm comes from Jean Meeus' "Astronomical Algorithms", 2nd
Edition, Chapter 22, pages 143ff. Meeus states that it is good to
0.1 seconds of arc.

=cut

sub nutation_in_obliquity {

my $time = shift;
my $T = jcent2000 ($time);	# Meeus (22.1)

my $omega = mod2pi (deg2rad ((($T / 450000 + .0020708) * $T -
	1934.136261) * $T + 125.04452));

my $L = mod2pi (deg2rad (36000.7698 * $T + 280.4665));
my $Lprime = mod2pi (deg2rad (481267.8813 * $T + 218.3165));
my $delta_epsilon = deg2rad ((9.20 * cos ($omega) + 0.57 * cos (2 * $L) +
	0.10 * cos (2 * $Lprime) - 0.09 * cos (2 * $omega))/3600);

$delta_epsilon;
}


=item $epsilon = obliquity ($time)

This subroutine calculates the obliquity of the ecliptic in radians at
the given B<dynamical> time.

The algorithm comes from Jean Meeus' "Astronomical Algorithms", 2nd
Edition, Chapter 22, pages 143ff. The conversion from universal to
dynamical time comes from chapter 10, equation 10.2  on page 78.

=cut

use constant E0BASE => (21.446 / 60 + 26) / 60 + 23;

sub obliquity {

my $time = shift;

my $T = jcent2000 ($time);	# Meeus (22.1)

my $delta_epsilon = nutation_in_obliquity ($time);

my $epsilon0 = deg2rad (((0.001813 * $T - 0.00059) * $T - 46.8150)
	* $T / 3600 + E0BASE);
$epsilon0 + $delta_epsilon;
}


=item $radians = omega ($time);

This subroutine calculates the ecliptic longitude of the ascending node
of the Moon's mean orbit at the given B<dynamical> time.

The algorithm comes from Jean Meeus' "Astronomical Algorithms", 2nd
Edition, Chapter 22, pages 143ff.

=cut

sub omega {
my $T = jcent2000 (shift);	# Meeus (22.1)

my $omega = mod2pi (deg2rad ((($T / 450000 + .0020708) * $T -
	1934.136261) * $T + 125.04452));
}


=item $degrees = rad2deg ($radians)

This subroutine converts the given angle in radians to its equivalent
in degrees.

=cut

sub rad2deg {$_[0] / PI * 180}


=begin comment

#	($xprime, $yprime) = _rotate ($theta, $x, $y)

#	Rotate coordinates in the Cartesian plane.
#	The arguments are the angle and the coordinates, and
#	the rotated coordinates 

sub _rotate {
my ($theta, $x, $y) = @_;
my $costh = cos ($theta);
my $sinth = sin ($theta);
($x * $costh - $y * $sinth, $x * $sinth + $y * $costh);
}

=end comment

=item $value = tan ($angle)

This subroutine computes the tangent of the given angle in radians.

=cut

sub tan {sin ($_[0]) / cos ($_[0])}


=item $value = theta0 ($time);

This subroutine returns the Greenwich hour angle of the mean equinox at
0 hours universal on the day whose time is given (i.e. the argument is
a standard Perl time).

=cut

sub theta0 {
thetag (timegm (0, 0, 0, (gmtime $_[0])[3 .. 5]));
}


=item $value = thetag ($time);

This subroutine returns the Greenwich hour angle of the mean equinox at
the given time.

The algorithm comes from Jean Meeus' "Astronomical Algorithms", 2nd
Edition, equation 12.4, page 88.

=cut


#	Meeus, pg 88, equation 12.4, converted to radians and Perl dates.

sub thetag {
my $T = jcent2000 ($_[0]);
mod2pi (4.89496121273579 + 6.30038809898496 *
	jday2000 ($_[0]))
	+ (6.77070812713916e-06 - 4.5087296615715e-10 * $T) * $T * $T;
}


=item $theta = mod2pi ($theta)

This subrouting reduces the given angle in radians to the range 0 <=
$theta < TWOPI.

=cut

sub mod2pi {
$_[0] - floor ($_[0] / TWOPI) * TWOPI;
}

=back

=head1 ACKNOWLEDGEMENTS

The author wishes to acknowledge Jean Meeus, whose book "Astronomical
Algorithms" (second edition) published by Willmann-Bell Inc
(L<http://www.willbell.com/>) provided several of the algorithms
implemented herein.

=head1 BUGS

Bugs can be reported to the author by mail, or through
L<http://rt.cpan.org/>.

=head1 AUTHOR

Thomas R. Wyant, III (F<wyant at cpan dot org>)

=head1 COPYRIGHT

Copyright 2005, 2006 by Thomas R. Wyant, III
(F<wyant at cpan dot org>). All rights reserved.

This module is free software; you can use it, redistribute it and/or
modify it under the same terms as Perl itself. Please see
L<http://perldoc.perl.org/index-licence.html> for the current licenses.

This software is provided without any warranty of any kind, express or
implied. The author will not be liable for any damages of any sort
relating in any way to this software.

=cut
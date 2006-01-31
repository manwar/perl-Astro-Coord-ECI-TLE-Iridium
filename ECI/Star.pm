=head1 NAME

Astro::Coord::ECI::Star - Compute the position of a star.

=head1 SYNOPSIS

 my $star = Astro::Coord::ECI::Star->star ();
 my $sta = Astro::Coord::ECI->new (name => 'Spica')->
     position (3.51331869544372, -0.194802985206623);
 my ($time, $rise) = $sta->next_elevation ($star);
 print "Spica's @{[$rise ? 'rise' : 'set']} is ",
     scalar localtime $time;

=head1 DESCRIPTION

This module implements the position of a star (or any other object
which can be regarded as fixed on the celestial sphere) as a function
of time, as described in Jean Meeus' "Astronomical Algorithms," second
edition. It is a subclass of Astro::Coord::ECI, with a position()
method to set the catalog position (and optionally proper motion as
well), and the time_set() method overridden to compute the position
of the star at the given time.

=head2 Methods

The following methods should be considered public:

=over

=cut

use strict;
use warnings;

package Astro::Coord::ECI::Star;

our $VERSION = 0.001;

use base qw{Astro::Coord::ECI};

use Astro::Coord::ECI::Sun;	# Need for abberation calc.
use Carp;
use Data::Dumper;
use POSIX qw{floor strftime};
##use Time::Local;
use UNIVERSAL qw{isa};


#	"Hand-import" non-oo utilities from the superclass.

BEGIN {
*_deg2rad = \&Astro::Coord::ECI::_deg2rad;
*_mod2pi = \&Astro::Coord::ECI::_mod2pi;
*_rad2deg = \&Astro::Coord::ECI::_rad2deg;
*PERL2000 = \&Astro::Coord::ECI::PERL2000;
*PIOVER2 = \&Astro::Coord::ECI::PIOVER2;
}


=item $star = Astro::Coord::ECI::Star->new ();

This method instantiates an object to represent the coordinates of a
star, or some other object which may be regarded as fixed on the
celestial sphere. This is a subclass of Astro::Coord::ECI, with the
angularvelocity attribute initialized to zero.

=cut

sub new {
my $class = shift;
my $self = $class->SUPER::new (angularvelocity => 0,
    @_);
}


=item @almanac = $star->almanac ($location, $start, $end);

This method produces almanac data for the star for the given location,
between the given start and end times. The location is assumed to be
Earth-Fixed - that is, you can't do this for something in orbit.

The start time defaults to the current time setting of the $star
object, and the end time defaults to a day after the start time.

The almanac data consists of a list of list references. Each list
reference points to a list containing the following elements:

 [0] => time
 [1] => event (string)
 [2] => detail (integer)
 [3] => description (string)

The @almanac list is returned sorted by time.

The following events, details, and descriptions are at least
potentially returned:

 horizon: 0 = star sets, 1 = star rises;
 transit: 1 = star transits meridian;

=cut

sub almanac {
my $self = shift;
my $location = shift;
ref $location && UNIVERSAL::isa ($location, 'Astro::Coord::ECI') or
    croak <<eod;
Error - The first argument of the almanac() method must be a member of
        the Astro::Coord::ECI class, or a subclass thereof.
eod

my $start = shift || $self->universal;
my $end = shift || $start + 86400;

my @almanac;

my $name = $self->get ('name') || $self->get ('id') || 'star';
foreach (
	[$location, next_elevation => [$self, 0, 1], 'horizon',
		["$name sets", "$name rises"]],
	[$location, next_meridian => [$self], 'transit',
		[undef, "$name transits meridian"]],
	) {
    my ($obj, $method, $arg, $event, $descr) = @$_;
    $obj->universal ($start);
    while (1) {
	my ($time, $which) = $obj->$method (@$arg);
	last unless $time && $time < $end;
	push @almanac, [$time, $event, $which, $descr->[$which]]
	    if $descr->[$which];
	}
    }
return sort {$a->[0] <=> $b->[0]} @almanac;
}


use constant NEVER_PASS_ELEV => 2 * __PACKAGE__->SECSPERDAY;

=item $star = $star->position ($ra, $dec, $range, $mra, $mdc, $mrg, $time);

This method sets the position and proper motion of the star in
equatorial coordinates. Right ascension and declination are
specified in radians, and range in kilometers. Proper motion in
range and declination is specified in radians B<per second> (an
B<extremely> small number!), and the proper motion in recession
in kilometers per second.

The range defaults to 1 parsec, which is too close but probably good
enough since we don't take paralax into account when computing
position, and since you can override it with a range (in km!) if you
so desire. The proper motions default to 0. The time defaults to
J2000.0. If you are not interested in proper motion but are interested
in time, omit the proper motion arguments completely and specify time
as the fourth argument.

If you call this as a class method, a new Astro::Coord::ECI::Star
object will be constructed. If you call it without arguments, the
position of the star is returned.

Note that this is B<not> simply a synonym for the equatorial() method.
The equatorial() method returns the position of the star corrected for
precession and nutation. This method is used to set the catalog
position of the star in question.

=cut

sub position {
my $self = shift;
return @{$self->{_star_position}} unless @_;
my @args = @_;
$args[2] ||= 30.8568e12;	# 1 parsec, per Meeus, Appendix I pg 407.
@args < 5 and splice @args, 3, 0, 0, 0, 0;
$args[3] ||= 0;
$args[4] ||= 0;
$args[5] ||= 0;
$args[6] ||= PERL2000;
$self = $self->new () unless ref $self;
$self->{_star_position} = [@args];
$self->dynamical ($args[6]);
$self;
}

=item $star->time_set ()

This method sets coordinates of the object to the coordinates of the
star at the object's currently-set universal time. Proper motion is
taken into account if this was specified.

Although there's no reason this method can't be called directly, it
exists to take advantage of the hook in the Astro::Coord::ECI
object, to allow the position of the Moon to be computed when the
object's time is set.

The computation comes from Jean Meeus' "Astronomical Algorithms", 2nd
Edition, Chapter 23, pages 149ff.

=cut

use constant CONSTANT_OF_ABERRATION => _deg2rad (20.49552 / 3600);

sub time_set {
my $self = shift;

$self->{_star_position} or croak <<eod;
Error - The position of the star has not been set.
eod

my ($ra, $dec, $range, $mra, $mdc, $mrg, $epoch) = @{$self->{_star_position}};

my $time = $self->universal;
my $end = $self->dynamical;

#	Account for the proper motion of the star, and set our
#	equatorial coordinates to the result.

my $deltat = $end - $epoch;
$ra += $mra * $deltat;
$dec += $mdc * $deltat;
$range += $mrg * $deltat;
$self->dynamical ($epoch)->equatorial ($ra, $dec, $range);

#	Precess ourselves to the correct time.

$self->precess ($time);


#	Get ecliptic coordinates, and correct for nutation.

my ($beta, $lamda) = $self->ecliptic ();
my $delta_psi = $self->nutation_in_longitude ();
$lamda += $delta_psi;


#	Calculate and add in the abberation terms (Meeus 23.2);

my $T = $self->jcent2000 ($time);			# Meeus (22.1)
my $e = (-0.0000001267 * $T - 0.000042037) * $T + 0.016708634;	# Meeus (25.4)
my $pi = _deg2rad ((0.00046 * $T + 1.71946) * $T + 102.93735);
my $sun = $self->{_star_sun} ||= Astro::Coord::ECI::Sun->new ();
$sun->universal ($time);

my $geoterm = $sun->geometric_longitude () - $lamda;
my $periterm = $pi - $lamda;
my $deltalamda = ($e * cos ($periterm) - cos ($geoterm)) *
	CONSTANT_OF_ABERRATION / cos ($beta);
my $deltabeta = - (sin ($geoterm) - $e * sin ($periterm)) * sin ($beta) *
	CONSTANT_OF_ABERRATION;
$lamda += $deltalamda;
$beta += $deltabeta;

$self->ecliptic ($beta, $lamda, $range);
}


1;

=back

=head1 ACKNOWLEDGEMENTS

The author wishes to acknowledge the following individuals and
organizations.

Jean Meeus, whose book "Astronomical Algorithms" (second edition)
formed the basis for this module.

Dr. Meeus' publisher, Willman-Bell Inc (F<http://www.willbell.com/>),
which kindly granted permission to use Dr. Meeus' work in this module.

=head1 SEE ALSO

The B<Astro-Catalog> package by Alasdair Allan, which accomodates a
much more fulsome description of a star. The star's coordinates are
represented by an B<Astro::Coords> object.

The B<Astro-Coords> package by Tim Jenness can also be used to find
the position of a star at a given time given a catalog entry for the
star. A wide variety of coordinate representations is accomodated.
This package requires B<Astro::SLA>, which in its turn requires the
SLALIB library.

=head1 AUTHOR

Thomas R. Wyant, III (F<wyant at cpan dot org>)

=head1 COPYRIGHT

Copyright 2005, 2006 by Thomas R. Wyant, III
(F<wyant at cpan dot org>). All rights reserved.

This module is free software; you can use it, redistribute it
and/or modify it under the same terms as Perl itself.

This software is provided without any warranty of any kind, express or
implied. The author will not be liable for any damages of any sort
relating in any way to this software.

=cut

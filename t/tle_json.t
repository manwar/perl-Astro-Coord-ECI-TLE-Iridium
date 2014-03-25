package main;

use 5.006002;

use strict;
use warnings;

use Astro::Coord::ECI::TLE qw{ BODY_TYPE_DEBRIS BODY_TYPE_PAYLOAD };
use Astro::Coord::ECI::TLE::Iridium;
use Test::More 0.88;	# Because of done_testing();

eval {
    require JSON;
    1;
} or plan skip_all => 'Optional module JSON required';

_json_config();

my $version = Astro::Coord::ECI::TLE->VERSION();

# The following TLE data are from sgp4-ver.tle, and ultimately from
# "Revisiting Spacetrack Report #3" by David A. Vallado, Paul Crawford,
# Richard Hujsak, and T. S. Kelso, presented at the 2006 AIAA/AAS
# Astrodynamics Specialist Conference.

# This report was obtained from the Celestrak web site, specifically
# http://celestrak.com/publications/AIAA/2006-6753/

# The common name, RCS and effective date were added by me for testing
# purposes. The RCS and effective date are fictional, and any
# resemblance to the actual values are purely coincidental.

my $vanguard = <<'EOD';
VANGUARD 1 --effective 2000/179/22:00:00 --rcs 0.254
1 00005U 58002B   00179.78495062  .00000023  00000-0  28098-4 0  4753
2 00005  34.2682 348.7242 1859667 331.7664  19.3264 10.82419157413667
EOD

my ( $tle ) = Astro::Coord::ECI::TLE->parse( $vanguard );

$tle->set(
    file	=> 42,
    ordinal	=> 666,
    originator	=> 'Arthur Dent',
    intrinsic_magnitude	=> 11.0,
);

my $hash = $tle->TO_JSON();

foreach my $key ( qw{
	ARG_OF_PERICENTER
	BSTAR
	CLASSIFICATION_TYPE
	COMMENT
	CREATION_DATE
	ECCENTRICITY
	ELEMENT_SET_NO
	EPHEMERIS_TYPE
	EPOCH
	EPOCH_MICROSECONDS
	FILE
	INCLINATION
	INTLDES
	LAUNCH_NUM
	LAUNCH_PIECE
	LAUNCH_YEAR
	MEAN_ANOMALY
	MEAN_MOTION
	MEAN_MOTION_DDOT
	MEAN_MOTION_DOT
	NORAD_CAT_ID
	OBJECT_NAME
	OBJECT_NUMBER
	OBJECT_TYPE
	ORDINAL
	ORIGINATOR
	RA_OF_ASC_NODE
	RCSVALUE
	REV_AT_EPOCH
	TLE_LINE0
	TLE_LINE1
	TLE_LINE2
	effective_date
	intrinsic_magnitude
    } ) {
    ok exists $hash->{$key}, "Hash key $key is present for Vanguard 1";
}

_fudge_json( $hash );

is_deeply $hash, {
    'ARG_OF_PERICENTER' => '331.7664',
    'BSTAR' => '2.8098e-05',
    'CLASSIFICATION_TYPE' => 'U',
    'COMMENT' => "Generated by Astro::Coord::ECI::TLE v$version",
#   'CREATION_DATE' => '2012-07-15 19:14:46',
    'ECCENTRICITY' => '0.1859667',
    'ELEMENT_SET_NO' => '475',
    'EPHEMERIS_TYPE' => '0',
    'EPOCH' => '2000-06-27 18:50:19',
    'EPOCH_MICROSECONDS'	=> '733568',
    FILE	=> '42',
    'INCLINATION' => '34.2682',
    'INTLDES' => '58002B',
    'LAUNCH_NUM' => '002',
    'LAUNCH_PIECE' => 'B',
    'LAUNCH_YEAR' => 1958,
    'MEAN_ANOMALY' => '19.3264',
    'MEAN_MOTION' => '10.82419157',
    'MEAN_MOTION_DOT' => '2.3e-07',
    'MEAN_MOTION_DDOT' => '0',
    'NORAD_CAT_ID' => '00005',
    'OBJECT_NAME' => 'VANGUARD 1',
    'OBJECT_NUMBER'	=> '00005',
    OBJECT_TYPE	=> uc BODY_TYPE_PAYLOAD,
    ORDINAL	=> 666,
    ORIGINATOR	=> 'Arthur Dent',
    'RA_OF_ASC_NODE' => '348.7242',
    'RCSVALUE' => '0.254',
    'REV_AT_EPOCH' => '41366',
    'TLE_LINE0' => '0 VANGUARD 1',
    'TLE_LINE1' => '1 00005U 58002B   00179.78495062  .00000023  00000-0  28098-4 0  4753',
    'TLE_LINE2' => '2 00005  34.2682 348.7242 1859667 331.7664  19.3264 10.82419157413667',
    'effective_date' => '2000-06-27 22:00:00',
    intrinsic_magnitude	=> 11.0,
}, 'Test the hash generated by TO_JSON() for Vanguard 1.';

my $json = JSON->new()->utf8()->convert_blessed();

{   # Local symbol block. Also single-iteration loop.
    my $name = 'Vanguard 1 round-trip via JSON';

    my $data;
    eval {
	$data = $json->encode( [ $tle ] );
	1;
    } or do {
	fail "$name failed to encode JSON: $@";
	last;
    };

    my $tle2;
    eval {
	( $tle2 ) = Astro::Coord::ECI::TLE->parse( $data );
	1;
    } or do {
	fail "$name failed to parse JSON: $@";
	diag $data;
	last;
    };

    is $tle2->get( 'tle' ), $vanguard, $name;
}

Astro::Coord::ECI::TLE->status( add => 5, iridium => 'S' );

# This TLE duplicates the above, and comes from the same source. The
# common name has been changed to reflect the use to which the data are
# being put.

( $tle ) = Astro::Coord::ECI::TLE->parse( <<'EOD' );
FAKE IRIDIUM
1 00005U 58002B   00179.78495062  .00000023  00000-0  28098-4 0  4753
2 00005  34.2682 348.7242 1859667 331.7664  19.3264 10.82419157413667
EOD

$tle->set(
    object_type	=> 'Debris',
);

$hash = $tle->TO_JSON();

foreach my $key ( qw{
	ARG_OF_PERICENTER
	BSTAR
	CLASSIFICATION_TYPE
	COMMENT
	CREATION_DATE
	ECCENTRICITY
	ELEMENT_SET_NO
	EPHEMERIS_TYPE
	EPOCH
	EPOCH_MICROSECONDS
	INCLINATION
	INTLDES
	LAUNCH_NUM
	LAUNCH_PIECE
	LAUNCH_YEAR
	MEAN_ANOMALY
	MEAN_MOTION
	MEAN_MOTION_DDOT
	MEAN_MOTION_DOT
	NORAD_CAT_ID
	OBJECT_NAME
	OBJECT_NUMBER
	OBJECT_TYPE
	RA_OF_ASC_NODE
	REV_AT_EPOCH
	TLE_LINE0
	TLE_LINE1
	TLE_LINE2
	operational_status
    } ) {
    ok exists $hash->{$key},
	"Hash key $key is present for a fictitious Iridium satellite";
}

_fudge_json( $hash );

is_deeply $hash, {
    'ARG_OF_PERICENTER' => '331.7664',
    'BSTAR' => '2.8098e-05',
    'CLASSIFICATION_TYPE' => 'U',
    'COMMENT' => "Generated by Astro::Coord::ECI::TLE v$version",
#   'CREATION_DATE' => '2012-07-15 19:14:46',
    'ECCENTRICITY' => '0.1859667',
    'ELEMENT_SET_NO' => '475',
    'EPHEMERIS_TYPE' => '0',
    'EPOCH' => '2000-06-27 18:50:19',
    'EPOCH_MICROSECONDS' => '733568',
    'INCLINATION' => '34.2682',
    'INTLDES' => '58002B',
    'LAUNCH_NUM' => '002',
    'LAUNCH_PIECE' => 'B',
    'LAUNCH_YEAR' => 1958,
    'MEAN_ANOMALY' => '19.3264',
    'MEAN_MOTION' => '10.82419157',
    'MEAN_MOTION_DOT' => '2.3e-07',
    'MEAN_MOTION_DDOT' => '0',
    'NORAD_CAT_ID' => '00005',
    'OBJECT_NAME' => 'FAKE IRIDIUM',
    'OBJECT_NUMBER'	=> '00005',
    'RA_OF_ASC_NODE' => '348.7242',
    OBJECT_TYPE	=> uc BODY_TYPE_DEBRIS,
    'REV_AT_EPOCH' => '41366',
    'TLE_LINE0' => '0 FAKE IRIDIUM',
    'TLE_LINE1' => '1 00005U 58002B   00179.78495062  .00000023  00000-0  28098-4 0  4753',
    'TLE_LINE2' => '2 00005  34.2682 348.7242 1859667 331.7664  19.3264 10.82419157413667',
    'operational_status' => 'S',
    intrinsic_magnitude	=> 7,	# Added by after_reblessing()
}, 'Test the hash generated by TO_JSON() for Vanguard 1.';

# This TLE duplicates the above, and comes from the same source. The
# common name has been changed to reflect the use to which the data are
# being put, and a Kelso-type status has been added, which should
# override the default.

( $tle ) = Astro::Coord::ECI::TLE->parse( <<'EOD' );
FAKE IRIDIUM [+]
1 00005U 58002B   00179.78495062  .00000023  00000-0  28098-4 0  4753
2 00005  34.2682 348.7242 1859667 331.7664  19.3264 10.82419157413667
EOD

$hash = $tle->TO_JSON();

_fudge_json( $hash );

# All we care about here is whether the canned status got overridden.
# This is not really a JSON test, but this was a convenient place to put
# it.

is $hash->{operational_status}, '+', 'Override operational status';

done_testing;

sub _fudge_json {
    my ( $hash ) = @_;

    # We have no idea what the creation date is going to be, so we just
    # ignore it.
    delete $hash->{CREATION_DATE};

    # MSWin32 (at least!) insists on a three-digit exponent, so we fudge
    # it back to two.
    foreach my $key ( qw{ BSTAR MEAN_MOTION_DOT MEAN_MOTION_DDOT } ) {
	$hash->{$key} =~ s{ (?<= e [+-] ) ( \d+ ) \z }
	    { sprintf '%02d', $1 }smxe;
    }

    return;
}

sub _json_config {
    diag '';
    foreach my $json ( qw{ JSON JSON::PP JSON::XS } ) {
	my $version;
	eval {
	    $version = $json->VERSION();
	    1;
	};
	defined $version
	    or $version = 'undef';
	diag sprintf '%-10s %s', $json, $version;
    }
    return;
}

1;

# ex: set textwidth=72 :

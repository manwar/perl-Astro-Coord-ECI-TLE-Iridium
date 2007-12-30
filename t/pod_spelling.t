use strict;
use warnings;

BEGIN {
    eval "use Test::Spelling";
    $@ and do {
	print "1..0 # skip Test::Spelling not available.\n";
	exit;
    };
}

our $VERSION = '0.010';

add_stopwords (<DATA>);

all_pod_files_spelling_ok ();
__DATA__
Above's
accreted
Alasdair
altazimuth
angulardiameter
angularvelocity
appulse
appulsed
appulsing
appulses
argumentofperigee
Astro
Astrodynamics
au
autoheight
azel
backdate
Barycentric
barycentre
BC
bissextile
body's
boosters
Borkowski
Borkowski's
Brett
Brodowski
bstardrag
CA
ca
Celestrak
Chalpront
cmd
coodinate
Coords
dans
darwin
DateTime
datetime
de
deg
degreesDminutesMsecondsS
des
distsq
DMOD
Dominik
ds
du
dualvar
dualvars
ECEF
ECI
eci
EDT
edt
edu
elementnumber
ELP
ephemeristype
Escobal
EST
exportable
ff
firstderivative
foo
fr
Francou
Fugina
Gasparovic
gb
geocode
Geocoder
geocoder
GMT
gmtime's
Goran
Green's
Gregorian
harvard
Haversine
haversine
haversines
Hujsak
IDs
illum
illuminator
IMACAT
Imacat
ini
internet
isa
jan
jcent
jd
jday
Jenness
jul
julianday
Kazimierz
Kelso
Kelso's
lib
LLC
ls
Lune
ly
magma
Mariana
max
McCants
meananomaly
meanmotion
Meeus
min
mma
mmas
Moon's
MoonPhase
MSWin
NORAD
NORAD's
nouvelles
Obliquity
obliquity
Observatoire
OID
op
oped
orbitaux
Palau
parametres
pbcopy
pbpaste
pc
PE
perigee
perltime
Persei
pg
pm
pp
pre
psiprime
rad
Ramon
readonly
rebless
reblessable
reblessed
reblesses
reblessing
ref
reportable
revolutionsatepoch
Rico
rightascension
Roehric
Saemundsson's
SATCAT
satpass
SATPASSINI
SDP
sdp
secondderivative
semimajor
SGP
sgp
SI
SIGINT
SIMBAD
Simbad
simbad
Sinnott
SKYSAT
skysat
SLALIB
Smart's
solstices
SPACETRACK
Spacetrack
Storable
strasbg
SunTime
Survey's
TAI
TDB
TDT
Terre
thetag
Thorfinn
timegm's
timekeeping
TIMEZONES
TLE
tle
TT
Touze
Turbo
TWOPI
tz
uk
USGS
UT
UTC
VA
valeurs
Vallado
ver
webcmd
WGS
Willmann
Wyant
xclip
xxxx
XYZ


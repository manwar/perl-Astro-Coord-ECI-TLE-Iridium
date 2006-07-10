#!/usr/local/bin/perl

use t::Satpass;

t::Satpass::satpass (*DATA);

__END__

-skip not_available ('SOAP::Lite') || not_reachable ('http://rpc.geocoder.us/')

set country us
set autoheight 0
geocode '1600 pennsylvania ave washington dc'
-data <<eod

1600 Pennsylvania Ave NW
Washington DC 20502

set location '1600 Pennsylvania Ave NW Washington DC 20502'
set latitude 38.898748
set longitude -77.037684
eod
-test geocode U.S. location via http://rpc.geocoder.us/

-skip not_available ('XML::Parser') || not_reachable ('http://rpc.geocoder.ca/')

set country ca
set autoheight 0
geocode '80 Wellington Street, Ottawa ON'
-data <<eod
set location '80 Wellington Street, Ottawa ON'
set latitude 45.423388
set longitude -75.697786
eod
-test geocode Canadian location via http://rpc.geocoder.ca/

-skip not_available ('SOAP::Lite', 'XML::Parser') || not_reachable ('http://gisdata.usgs.gov/')

set country us
set location '1600 Pennsylvania Ave NW Washington DC 20502'
set latitude 38.898748
set longitude -77.037684
set height 0
height
-fail <<eod
Test %d may fail due to a database problem on http://gisdata.usgs.gov/
or due to a change in the interface specification. If you want to
distinguish between the two, visit that site and look up the height
at latitude 38.898748 longitude -77.037684 by hand.
eod
-data set height 16.68
-test fetch height in continental U.S. from http://gisdata.usgs.gov/

set country ca
set location '80 Wellington Street Ottawa ON'
set latitude 45.423388
set longitude -75.697786
set height 0
height -retry 8
-data set height 82.00
-fail <<eod
Test %d may fail due to a database problem on http://gisdata.usgs.gov/
or due to a change in the interface specification. If you want to
distinguish between the two, visit that site and look up the height
at latitude 45.423388 longitude -75.697786 by hand.

This test may also occasionally fail because http://gisdata.usgs.gov/
returned zero for the height. I consider this to be a server bug,
not a bug in satpass.
eod
-test fetch height in Canada from http://gisdata.usgs.gov/

-skip ''
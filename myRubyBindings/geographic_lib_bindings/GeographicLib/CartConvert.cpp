/**
 * \file CartConvert.cpp
 * \brief Command line utility for geodetic to cartesian coordinate conversions
 *
 * Copyright (c) Charles Karney (2008) <charles@karney.com>
 * http://charles.karney.info/geographic
 * and licensed under the LGPL.
 *
 * Compile with
 *
 *   g++ -g -O3 -I.. -o CartConvert CartConvert.cpp Geocentric.cpp LocalCartesian.cpp Constants.cpp
 *
 * See \ref cartconvert for usage information.
 **********************************************************************/

#include <string>
#include <iostream>
#include <iomanip>
#include <sstream>
#include "GeographicLib/Geocentric.hpp"
#include "GeographicLib/LocalCartesian.hpp"

int usage(int retval) {
  ( retval ? std::cerr : std::cout ) <<
"Usage: CartConvert [-r] [-l lat0 lon0 h0] [-h]\n\
$Id: CartConvert.cpp 6553 2009-02-24 03:10:01Z ckarney $\n\
\n\
Convert geodetic coordinates to either geocentric or local cartesian\n\
coordinates.  Geocentric coordinates have the origin at the center of the\n\
earth, with the z axis going thru the north pole, and the x axis thru lat =\n\
0, lon = 0.  By default, the conversion is to geocentric coordinates.\n\
Specifying -l lat0 lon0 h0 causes a local coordinate system to be used with\n\
the origin at latitude = lat0, longitude = lon0, height = h0, z normal to\n\
the ellipsoid and y due north.  The WGS84 model of the earth is used.\n\
\n\
Geodetic coordinates are provided on standard input as a set of lines\n\
containing (blank separated) latitude, longitude (decimal degrees), and\n\
height (meters).  For each set of geodetic coordinates, the corresponding\n\
cartesian coordinates x, y, z (meters) are printed on standard output.\n\
\n\
If -r is given the reverse transformation is performed.\n\
\n\
-h prints this help\n";
  return retval;
}

int main(int argc, char* argv[]) {
  bool localcartesian = false, reverse = false;
  double latlonh0[3] = {0, 0, 0};
  for (int m = 1; m < argc; ++m) {
    std::string arg = std::string(argv[m]);
    if (arg == "-r")
      reverse = true;
    else if (arg == "-l") {
      localcartesian = true;
      for (unsigned i = 0; i < 3; ++i) {
	if (++m == argc) return usage(1);
	std::string a = std::string(argv[m]);
	std::istringstream str(a);
	if (!(str >> latlonh0[i])) return usage(1);
      }
    } else
      return usage(arg != "-h");
  }
  const GeographicLib::LocalCartesian lc(latlonh0[0], latlonh0[1], latlonh0[2]);
  const GeographicLib::Geocentric& ec = GeographicLib::Geocentric::WGS84;

  std::cout << std::setprecision(16);
  while (true) {
    double lat, lon, h, x, y, z;
    if (reverse)
      std::cin >> x >> y >> z;
    else
      std::cin >> lat >> lon >> h;
    if (!std::cin.good())
      break;
    if (reverse) {
      if (localcartesian)
	lc.Reverse(x, y, z, lat, lon, h);
      else
	ec.Reverse(x, y, z, lat, lon, h);
      std::cout << lat << " " << lon << " " << h << "\n";
    } else {
      if (localcartesian)
	lc.Forward(lat, lon, h, x, y, z);
      else
	ec.Forward(lat, lon, h, x, y, z);
      std::cout << x << " " << y << " " << z << "\n";
    }
  }
  return 0;
}

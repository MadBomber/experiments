/**
 * \file Geod.cpp
 * \brief Command line utility for geodesic calculations
 *
 * Copyright (c) Charles Karney (2008) <charles@karney.com>
 * http://charles.karney.info/geographic
 * and licensed under the LGPL.
 *
 * Compile with
 *
 *   g++ -g -O3 -I.. -o Geod Geod.cpp Geodesic.cpp DMS.cpp Constants.cpp
 *
 * See \ref geod for usage information.
 **********************************************************************/

#include <string>
#include <iostream>
#include <iomanip>
#include <sstream>
#include <stdexcept>
#include "GeographicLib/Geodesic.hpp"
#include "GeographicLib/DMS.hpp"

int usage(int retval) {
  ( retval ? std::cerr : std::cout ) <<
"Usage: Geod [-l lat1 lon1 azi1 | -i] [-n] [-d] [-f] [-p prec] [-h]\n\
$Id: Geod.cpp 6572 2009-03-01 22:41:48Z ckarney $\n\
\n\
Perform geodesic calculations.\n\
\n\
The shortest path between two points on the ellipsoid at (lat1, lon1)\n\
and (lat2, lon2) is called the geodesic.  Its length is s12 and the\n\
geodesic from point 1 to point 2 has azimuths azi1 and azi2 at the two\n\
end points.\n\
\n\
Geod operates in one of three modes:\n\
\n\
(1) It accepts lines on the standard input containing \"lat1 lon1 azi1\n\
    s12\" and prints \"lat2 lon2 azi2\" on standard output.  This is the\n\
    direct geodesic calculation.\n\
\n\
(2) Command line arguments \"-l lat1 lon1 azi1\" specify a geodesic line.\n\
    Geod then accepts a sequence of s12 values (one per line) on\n\
    standard input and prints \"lat2 lon2 azi2\" for each.  This generates\n\
    a sequence of points on a single geodesic.\n\
\n\
(3) With the -i command line argument, Geod performs the inverse\n\
    geodesic calculation.  It reads lines containing \"lat1 lon1 lat2\n\
    lon2\" and prints the corresponding values of \"azi1 azi2 s12\".\n\
\n\
By default, the WGS84 ellipsoid is used.  With the -n option, it uses\n\
the international ellipsoid (major radius 6378388 m, inverse flattening\n\
297).\n\
\n\
Output of angles is as decimal degrees.  If -d is specified the output\n\
is as degrees, minutes, seconds.  Input can be in either style.  d, ',\n\
and \" are used to denote degrees, minutes, and seconds, with the least\n\
significant designator optional.  By default, latitude precedes\n\
longitude for each point; however on input either may be given first by\n\
appending N or S to the latitude and E or W to the longitude.  s12 is\n\
always given in meters.\n\
\n\
The output lines consist of the three quantities needs to complete the\n\
specification of the geodesic.  With the -f option, each line of output\n\
is a complete geodesic specification consisting of seven quantities\n\
\n\
    lat1 lon1 azi1 lat2 lon2 azi2 s12\n\
\n\
-p prec (default 3) gives the precision of the output relative to 1m.\n\
The minimum value of prec is 0 (1 m accuracy) and the maximum value is\n\
10 (0.1 nm accuracy, but then the last digits are unreliable).\n\
\n\
-h prints this help.\n";
  return retval;
}


std::string LatLonString(double lat, double lon, int prec, bool dms) {
  using namespace GeographicLib;
  if (dms)
    return
      DMS::Encode(lat, prec + 5, DMS::LATITUDE) + " " +
      DMS::Encode(lon, prec + 5, DMS::LONGITUDE);
  else {
    std::ostringstream os;
    os << std::fixed << std::setprecision(prec + 5)
       << lat << " " << lon;
    return os.str();
  }
}

std::string AzimuthString(double azi, int prec, bool dms) {
  using namespace GeographicLib;
  if (dms)
    return DMS::Encode(azi, prec + 5, DMS::AZIMUTH);
  else {
    std::ostringstream os;
    os << std::fixed << std::setprecision(prec + 5)
       << azi;
    return os.str();
  }
}

double ReadAzimuth(const std::string& s) {
  using namespace GeographicLib;
  DMS::flag ind;
  double azi = DMS::Decode(s, ind);
  if (!(azi >= -180 && azi <= 360))
    throw std::out_of_range("Azimuth " + s + " not in range [-180,360]");
  if (azi >= 180) azi -= 360;
  if (ind == DMS::LATITUDE)
    throw std::out_of_range("Azimuth " + s +
			    " has a latitude hemisphere, N/S");
  return azi;
}

int main(int argc, char* argv[]) {
  bool linecalc = false, inverse = false, international = false,
    dms = false, full = false;
  double lat1, lon1, azi1, lat2, lon2, azi2, s12;
  int prec = 3;

  for (int m = 1; m < argc; ++m) {
    std::string arg = std::string(argv[m]);
    if (arg == "-i") {
      inverse = true;
      linecalc = false;
    } else if (arg == "-l") {
      inverse = false;
      linecalc = true;
      if (m + 3 >= argc) return usage(1);
      try {
	GeographicLib::DMS::DecodeLatLon(std::string(argv[m + 1]),
					 std::string(argv[m + 2]),
					 lat1, lon1);
	azi1 = ReadAzimuth(std::string(argv[m + 3]));
	m += 3;
      }
      catch (std::out_of_range& e) {
	std::cerr << "ERROR: " << e.what() << "\n";
	return usage(1);
      }
    } else if (arg == "-n")
      international = true;
    else if (arg == "-d")
      dms = true;
    else if (arg == "-f")
      full = true;
    else if (arg == "-p") {
      if (++m == argc) return usage(1);
      std::string a = std::string(argv[m]);
      std::istringstream str(a);
      if (!(str >> prec)) return usage(1);
    } else
      return usage(arg != "-h");
  }

  const GeographicLib::Geodesic internat(6378388.0, 297.0);
  const GeographicLib::Geodesic& geod = international ? internat :
    GeographicLib::Geodesic::WGS84;
  GeographicLib::GeodesicLine l;
  if (linecalc)
    l = geod.Line(lat1, lon1, azi1);

  // Max precision = 9: 1 nm in distance, 10^-14 deg (= 1.1 nm),
  // 10^-10 sec (= 3 nm).
  prec = std::min(10, std::max(0, prec));
  std::cout << std::fixed << std::setprecision(prec);
  std::string s;
  int retval = 0;
  while (std::getline(std::cin, s)) {
    try {
      std::istringstream str(s);
      if (linecalc) {
	if (!(str >> s12))
	  throw std::out_of_range("Incomplete input: " + s);
	l.Position(s12, lat2, lon2, azi2);
	if (full)
	  std::cout << LatLonString(lat1, lon1, prec, dms) << " " <<
	    AzimuthString(azi1, prec, dms) << " ";
	std::cout << LatLonString(lat2, lon2, prec, dms) << " " <<
	  AzimuthString(azi2, prec, dms);
	if (full)
	  std::cout << " " << s12;
	std::cout << "\n";
      } else if (inverse) {
	std::string slat1, slon1, slat2, slon2;
	if (!(str >> slat1 >> slon1 >> slat2 >> slon2))
	  throw std::out_of_range("Incomplete input: " + s);
	GeographicLib::DMS::DecodeLatLon(slat1, slon1, lat1, lon1);
	GeographicLib::DMS::DecodeLatLon(slat2, slon2, lat2, lon2);
	geod.Inverse(lat1, lon1, lat2, lon2, s12, azi1, azi2);
	if (full)
	  std::cout << LatLonString(lat1, lon1, prec, dms) << " ";
	std::cout << AzimuthString(azi1, prec, dms) << " ";
	if (full)
	  std::cout << LatLonString(lat2, lon2, prec, dms) << " ";
	std::cout << AzimuthString(azi2, prec, dms) << " " << s12 << "\n";
      } else {
	std::string slat1, slon1, sazi1;
	if (!(str >> slat1 >> slon1 >> sazi1 >> s12))
	  throw std::out_of_range("Incomplete input: " + s);
	GeographicLib::DMS::DecodeLatLon(slat1, slon1, lat1, lon1);
	azi1 = ReadAzimuth(sazi1);
	geod.Direct(lat1, lon1, azi1, s12, lat2, lon2, azi2);
	if (full)
	  std::cout << LatLonString(lat1, lon1, prec, dms) << " " <<
	    AzimuthString(azi1, prec, dms) << " ";
	std::cout << LatLonString(lat2, lon2, prec, dms) << " " <<
	  AzimuthString(azi2, prec, dms);
	if (full)
	  std::cout << " " << s12;
	std::cout << "\n";
      }
    }
    catch (std::out_of_range& e) {
      // Write error message cout so output lines match input lines
      std::cout << "ERROR: " << e.what() << "\n";
      retval = 1;
    }
  }
  return retval;
}

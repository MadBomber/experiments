/**
 * \file MGRS.hpp
 * \brief Header for GeographicLib::MGRS class
 *
 * Copyright (c) Charles Karney (2008) <charles@karney.com>
 * and licensed under the LGPL.
 **********************************************************************/

#if !defined(MGRS_HPP)
#define MGRS_HPP "$Id: MGRS.hpp 6559 2009-02-28 16:49:53Z ckarney $"

#include <cmath>
#include <algorithm>
#include <string>
#include <sstream>

namespace GeographicLib {

  /**
   * \brief Convert between UTM/UPS and %MGRS
   *
   * MGRS is defined in Chapter 3 of
   * - J. W. Hager, L. L. Fry, S. S. Jacks, D. R. Hill,
   *   <a href="http://earth-info.nga.mil/GandG/publications/tm8358.1/pdf/TM8358_1.pdf">

   *   Datums, Ellipsoids, Grids, and Grid Reference Systems</a>,
   *   Defense Mapping Agency, Technical Manual TM8358.1 (1990).
   *
   * This implementation has the following properties:
   * - The conversions are closed, i.e., output from Forward is legal input for
   *   Reverse and vice versa.  Conversion in both directions preserve the
   *   UTM/UPS selection and the UTM zone.
   * - Forward followed by Reverse and vice versa is approximately the
   *   identity.  (This is affected in predictable ways by errors in
   *   determining the latitude band and by loss of precision in the MGRS
   *   coordinates.)
   * - All MGRS coordinates truncate to legal 100km blocks.  All MGRS
   *   coordinates with a legal 100km block prefix are legal (even though the
   *   latitude band letter may now belong to a neighboring band).
   * - The range of UTM/UPS coordinates allowed for conversion to MGRS
   *   coordinates is the maximum consistent with staying within the letter
   *   ranges of the MGRS scheme.
   *
   * The <a href="http://www.nga.mil">NGA</a> software package
   * <a href="http://earth-info.nga.mil/GandG/geotrans/index.html">geotrans</a>
   * also provides conversions to and from MGRS.  Version 2.4.2 (and earlier)
   * suffers from some drawbacks:
   * - Conversions to MGRS coordinate return the closest grid corner.  This is
   *   contrary to the normal standard of grid systems (which is to return the
   *   coordinates of the enclosing square) and results in illegal MGRS
   *   coordinates being returned
   * - Inconsistent rules are used to determine the whether a particular MGRS
   *   coordinate is legal.  A more systematic approach is taken here.
   * - The underlying projections are not very accurately implemented.
   **********************************************************************/
  class MGRS {
  private:
    // The smallest length s.t., 1.0e7 - eps < 1.0e7 (approx 1.9 nm)
    static const double eps;
    // The smallest angle s.t., 90 - eps < 90 (approx 50e-12 arcsec)
    static const double angeps;
    static const std::string hemispheres;
    static const std::string utmcols[3];
    static const std::string utmrow;
    static const std::string upscols[4];
    static const std::string upsrows[2];
    static const std::string latband;
    static const std::string upsband;
    static const std::string digits;

    static const int mineasting[4];
    static const int maxeasting[4];
    static const int minnorthing[4];
    static const int maxnorthing[4];
    enum {
      base = 10,
      // Top-level tiles are 10^5 m = 100km on a side
      tilelevel = 5,
      // Period of UTM row letters
      utmrowperiod = 20,
      // Row letters are shifted by 5 for even zones
      utmevenrowshift = 5,
      // Maximum precision is um
      maxprec = 5 + 6
    };
    static void CheckCoords(bool utmp, bool& northp, double& x, double& y);
    static int lookup(const std::string& s, char c) throw() {
      std::string::size_type r = s.find(toupper(c));
      return r == std::string::npos ? -1 : int(r);
    }
    template<typename T> static std::string str(T x) {
      std::ostringstream s; s << x; return s.str();
    }
    static int UTMRow(int iband, int icol, int irow) throw();

    friend class UTMUPS;	// UTMUPS::StandardZone calls LatitudeBand
    // Return latitude band number [-10, 10) for the give latitude (degrees).
    // The bands are reckoned in include their southern edges.
    static int LatitudeBand(double lat) throw() {
      int ilat = int(std::floor(lat));
      return (std::max)(-10, (std::min)(9, (ilat + 80)/8 - 10));
    }
    // These are protected also so that UTMUPS can access them.
    friend class GeoCoords;	// GeoCoords accesses utmNshift
    enum {
      tile = 100000,		// Size MGRS blocks
      minutmcol = 1,
      maxutmcol = 9,
      minutmSrow = 10,
      maxutmSrow = 100,		// Also used for UTM S false northing
      minutmNrow = 0,		// Also used for UTM N false northing
      maxutmNrow = 95,
      minupsSind = 8,		// These 4 ind's apply to easting and northing
      maxupsSind = 32,
      minupsNind = 13,
      maxupsNind = 27,
      upseasting = 20,		// Also used for UPS false northing
      utmeasting = 5,		// UTM false easting
      // Difference between S hemisphere northing and N hemisphere northing
      utmNshift = (maxutmSrow - minutmNrow) * tile
    };
  public:

    /**
     * Convert UTM or UPS coordinate to an MGRS coordinate.  \e zone and \e
     * northp give input zone (with \e zone = 0 indicating UPS) and hemisphere,
     * \e x and \e y are the easting and northing (meters).  \e prec indicates
     * the desired precision with \e prec = 0 (the minimum) meaning 100 km, \e
     * prec = 5 meaning 1 m, and \e prec == 11 (the maximum) meaning 1 um.
     *
     * UTM eastings are allowed to be in the range [100 km, 900 km], northings
     * are allowed to be in in [0 km, 9500 km] for the northern hemisphere and
     * in [1000 km, 10000 km] for the southern hemisphere.  (However UTM
     * northings can be continued across the equator.  So the actual limits on
     * the northings are [-9000 km, 9500 km] for the "northern" hemisphere and
     * [1000 km, 19500 km] for the "southern" hemisphere.)
     *
     * UPS eastings/northings are allowed to be in the range [1300 km, 2700 km]
     * in the northern hemisphere and in [800 km, 3200 km] in the southern
     * hemisphere.
     *
     * The ranges are 100 km more restrictive that for the conversion between
     * geographic coordinates and UTM and UPS given by UTMUPS.  These
     * restrictions are dictated by the allowed letters in MGRS coordinates.
     * The choice of 9500 km for the maximum northing for northern hemisphere
     * and of 1000 km as the minimum northing for southern hemisphere provide
     * at least 0.5 degree extension into standard UPS zones.  The upper ends
     * of the ranges for the UPS coordinates is dictated by requiring symmetry
     * about the meridans 0E and 90E.
     *
     * All allowed UTM and UPS coordinates may now be converted to legal MGRS
     * coordinates with the proviso that eastings and northings on the upper
     * boundaries are silently reduced by about 4nm to place them \e within the
     * allowed range.  (This includes reducing a southern hemisphere northing
     * of 10000km by 4nm so that it is placed in latitude band M.)  The UTM or
     * UPS coordinates are truncated to requested precision to determine the
     * MGRS coordinate.  Thus in UTM zone 38N, the square area with easting in
     * [444 km, 445 km) and northing in [3688 km, 3689 km) maps to MGRS
     * coordinate 38SMB4488 (at \e prec = 2, 1km), Kulani Sq., Baghdad.
     *
     * The UTM/UPS selection and the UTM zone is preserved in the conversion to
     * MGRS coordinate.  Thus for \e zone > 0, the MGRS coordinate begins with
     * the zone number followed by one of [C&ndash;M] for the southern
     * hemisphere and [N&ndash;X] for the northern hemisphere.  For \e zone =
     * 0, the MGRS coordinates begins with one of [AB] for the southern
     * hemisphere and [XY] for the northern hemisphere.
     *
     * The conversion to the MGRS is exact for prec in [0, 5] except that a
     * neighboring latitude band letter may be given if the point is within 5nm
     * of a band boundary.  For prec in [6, 11], the conversion is accurate to
     * roundoff.
     *
     **********************************************************************/
    static void Forward(int zone, bool northp, double x, double y,
			int prec, std::string& mgrs);

    /**
     * Convert UTM or UPS coordinates to an MGRS coordinate in case that
     * latitude is already known.  The latitude is ignored for \e zone = 0
     * (UPS); otherwise the latitude is used to determine the latitude band and
     * this is checked for consistency using the same tests as Reverse.
     **********************************************************************/
    static void Forward(int zone, bool northp, double x, double y, double lat,
			int prec, std::string& mgrs);

    /**
     * Convert a MGRS coordinate to UTM or UPS coordinates returning zone \e
     * zone, hemisphere \e northp, easting \e x (meters), northing \e y
     * (meters) .  Also return the precision of the MGRS string (see Forward).
     * If \e centerp = true (default), return center of the MGRS square, else
     * return SW (lower left) corner.
     *
     * All conversions from MGRS to UTM/UPS are permitted provided the MGRS
     * coordinate is a possible result of a conversion in the other direction.
     * (The leading 0 may be dropped from an input MGRS coordinate for UTM
     * zones 1&ndash;9.)  In addition, MGRS coordinates with a neighboring
     * latitude band letter are permitted provided that some portion of the
     * 100km block is within the given latitude band.  Thus
     *   - 38VLS and 38WLS are allowed (latitude 64N intersects the square
     *     38[VW]LS); but 38VMS is not permitted (all of 38VMS is north of 64N)
     *   - 38MPE and 38NPF are permitted (they straddle the equator); but 38NPE
     *     and 38MPF are not permitted (the equator does not intersect either
     *     block).
     *   - Similarly ZAB and YZB are permitted (they straddle the prime
     *     meridian); but YAB and ZZB are not (the prime meridian does not
     *     intersect either block).
     *
     * The UTM/UPS selection and the UTM zone is preserved in the conversion
     * from MGRS coordinate.  The conversion is exact for prec in [0, 5].  With
     * centerp = true the conversion from MGRS to geographic and back is
     * stable.  This is not assured if \e centerp = false.
     **********************************************************************/
    static void Reverse(const std::string& mgrs,
			int& zone, bool& northp, double& x, double& y,
			int& prec, bool centerp = true);

  };

} // namespace GeographicLib
#endif

/**
 * \file Geocentric.hpp
 * \brief Header for GeographicLib::Geocentric class
 *
 * Copyright (c) Charles Karney (2008) <charles@karney.com>
 * and licensed under the LGPL.
 **********************************************************************/

#if !defined(GEOCENTRIC_HPP)
#define GEOCENTRIC_HPP "$Id: Geocentric.hpp 6559 2009-02-28 16:49:53Z ckarney $"

#include <cmath>

namespace GeographicLib {

  /**
   * \brief %Geocentric coordinates
   *
   * Convert between geodetic coordinates latitude = \e lat, longitude = \e
   * lon, height = \e h (measured vertically from the surface of the ellipsoid)
   * to geocentric coordinates (\e x, \e y, \e z).  The origin of geocentric
   * coordinates is at the center of the earth.  The \e z axis goes thru the
   * north pole, \e lat = 90<sup>o</sup>.  The \e x axis goes thru \e lat = 0,
   * \e lon = 0.  Geocentric coordinates are also known as earth centered,
   * earth fixed (ECEF) coordinates.
   *
   * The conversion from geographic to geocentric coordinates is
   * straightforward.  For the reverse transformation we use
   * - H. Vermeille,
   *   <a href="http://dx.doi.org/10.1007/s00190-002-0273-6"> Direct
   *   transformation from geocentric coordinates to geodetic coordinates</a>,
   *   J. Geodesy 76, 451&ndash;454 (2002).
   * .
   * Several changes have been made to ensure that the method returns accurate
   * results for all finite inputs (even if \e h is infinite).  See
   * \ref geocentric for details.
   * 
   * The errors in these routines are close to round-off.  Specifically, for
   * points within 5000 km of the surface of the ellipsoid (either inside or
   * outside the ellipsoid), the error is bounded by 7 nm for the WGS84
   * ellipsoid.  See \ref geocentric for further information on the errors.
   **********************************************************************/

  class Geocentric {
  private:
    const double _a, _f, _e2, _e4, _e2m, _maxrad;
    static inline double sq(double x) throw() { return x * x; }
#if defined(_MSC_VER)
    static inline double hypot(double x, double y) throw()
    { return _hypot(x, y); }
    static inline double cbrt(double x) throw() {
      double y = std::pow(std::abs(x), 1/3.0);
      return x < 0 ? -y : y;
    }
#else
    static inline double hypot(double x, double y) throw()
    { return ::hypot(x, y); }
    static inline double cbrt(double x) throw() { return ::cbrt(x); }
#endif
  public:

    /**
     * Constructor for a ellipsoid radius \e a (meters) and inverse flattening
     * \e invf.  Setting \e invf <= 0 implies \e invf = inf or flattening = 0
     * (i.e., a sphere).
     **********************************************************************/
    Geocentric(double a, double invf) throw();

    /**
     * Convert from geodetic coordinates \e lat, \e lon (degrees), \e h
     * (meters) to geocentric coordinates \e x, \e y, \e z (meters).  \e lat
     * should be in the range [-90, 90]; \e lon and \e lon0 should be in the
     * range [-180, 360].
     **********************************************************************/
    void Forward(double lat, double lon, double h,
		 double& x, double& y, double& z) const throw();

    /**
     * Convert from geocentric coordinates \e x, \e y, \e z (meters) to
     * geodetic \e lat, \e lon (degrees), \e h (meters).  In general there are
     * multiple solutions and the result which minimizes the absolute value of
     * \e h is returned.  If there are still multiple solutions with different
     * latitutes (applies only if \e z = 0), then the solution with \e lat > 0
     * is returned.  If there are still multiple solutions with different
     * longitudes (applies only if \e x = \e y = 0) then \e lon = 0 is
     * returned.  The value of \e h returned satisfies \e h >= - \e a (1 - \e
     * e<sup>2</sup>) / sqrt(1 - \e e<sup>2</sup> sin<sup>2</sup>\e lat).  The
     * value of \e lon returned is in the range [-180, 180).
     **********************************************************************/
    void Reverse(double x, double y, double z,
		 double& lat, double& lon, double& h) const throw();

    /**
     * A global instantiation of Geocentric with the parameters for the WGS84
     * ellipsoid.
     **********************************************************************/
    const static Geocentric WGS84;
  };

} //namespace GeographicLib
#endif

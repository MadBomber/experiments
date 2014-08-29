/**
 * \file PolarStereographic.hpp
 * \brief Header for GeographicLib::PolarStereographic class
 *
 * Copyright (c) Charles Karney (2008) <charles@karney.com>
 * and licensed under the LGPL.
 **********************************************************************/

#if !defined(POLARSTEREOGRAPHIC_HPP)
#define POLARSTEREOGRAPHIC_HPP "$Id: PolarStereographic.hpp 6537 2009-02-14 13:41:47Z ckarney $"

#include <cmath>

namespace GeographicLib {

  /**
   * \brief Polar Stereographic Projection
   *
   * Implementation taken from the report,
   * - J. P. Snyder,
   *   <a href="http://pubs.er.usgs.gov/usgspubs/pp/pp1395"> Map Projections: A
   *   Working Manual</a>, USGS Professional Paper 1395 (1987),
   *   pp. 160&ndash;163.
   *
   * This is a straightforward implementation of the equations in Snyder except
   * that Newton's method is used to invert the projection.
   **********************************************************************/
  class PolarStereographic {
  private:
    const double _a, _f, _k0, _e, _e2m, _c, _tol;
    const int _numit;
    static inline double sq(double x) throw() { return x * x; }
#if defined(_MSC_VER)
    static inline double hypot(double x, double y) throw()
    { return _hypot(x, y); }
#else
    static inline double hypot(double x, double y) throw()
    { return ::hypot(x, y); }
#endif
  public:

    /**
     * Constructor for a ellipsoid radius \e a (meters), inverse flattening \e
     * invf, and central scale factor \e k0.  Setting \e invf <= 0 implies \e
     * invf = inf or flattening = 0 (i.e., a sphere).
     **********************************************************************/
    PolarStereographic(double a, double invf, double k0) throw();

    /**
     * Convert from latitude \e lat (degrees) and longitude \e lon (degrees) to
     * polar stereographic easting \e x (meters) and northing \e y (meters).
     * The projection is about the pole given by \e northp (false means south,
     * true means north).  Also return the meridian convergence \e gamma
     * (degrees) and the scale \e k.  No false easting or northing is added.
     * \e lat should be in the range (-90, 90] for \e northp = true and in the
     * range [-90, 90) for \e northp = false; \e lon should be in the range
     * [-180, 360].
     **********************************************************************/
    void Forward(bool northp, double lat, double lon,
		 double& x, double& y,
		 double& gamma, double& k) const throw();

    /**
     * Convert from polar stereogrphic easting \e x (meters) and northing \e y
     * (meters) to latitude \e lat (degrees) and longitude \e lon (degrees) .
     * The hemisphere is given by \e northp (false means south, true means
     * north).  Also return the meridian convergence \e gamma (degrees) and the
     * scale \e k.  No false easting or northing is added.  The value of \e lon
     * returned is in the range [-180, 180).
     **********************************************************************/
    void Reverse(bool northp, double x, double y,
		 double& lat, double& lon,
		 double& gamma, double& k) const throw();

    /**
     * A global instantiation of PolarStereographic with the WGS84 ellipsoid
     * and the UPS scale factor.  However, unlike UPS, no false easting or
     * northing is added.
     **********************************************************************/
    const static PolarStereographic UPS;
  };

} // namespace GeographicLib

#endif

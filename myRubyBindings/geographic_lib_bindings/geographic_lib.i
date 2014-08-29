/* File : geographic_lib.i */

%module GeographicLib



/****************************************************************/

%include "attribute.i"
%include "carrays.i"
%include "cdata.i"
%include "cmalloc.i"
%include "constraints.i"
%include "cpointer.i"
%include "cstring.i"

%include "exception.i"
%include "inttypes.i"
%include "math.i"

%include "std_except.i"
%include "stdint.i"
%include "stl.i"
%include "swigarch.i"
%include "swigrun.i"
%include "wchar.i"
%include "windows.i"


/*************** ruby SubDirectory *****************/


%include "ruby/attribute.i"
%include "ruby/carrays.i"
%include "ruby/cdata.i"
%include "ruby/cmalloc.i"

%include "ruby/cpointer.i"
%include "ruby/cstring.i"

%include "ruby/exception.i"
%include "ruby/factory.i"
%include "ruby/file.i"


%include "ruby/std_common.i"
%include "ruby/std_deque.i"
%include "ruby/std_except.i"
%include "ruby/std_map.i"
%include "ruby/std_pair.i"
%include "ruby/std_string.i"
%include "ruby/std_vector.i"
%include "ruby/stl.i"
%include "ruby/timeval.i"
%include "ruby/typemaps.i"

/****************************************************/






%{
#include "GeographicLib/Constants.hpp"
#include "GeographicLib/DMS.cpp"
%}

%include "GeographicLib/Constants.hpp"
%include "GeographicLib/DMS.hpp"

/*
%include "GeographicLib/Constants.hpp"
%include "GeographicLib/DMS.hpp"
%include "GeographicLib/EllipticFunction.hpp"
%include "GeographicLib/GeoCoords.hpp"
%include "GeographicLib/Geocentric.hpp"
%include "GeographicLib/Geodesic.hpp"
%include "GeographicLib/LocalCartesian.hpp"
%include "GeographicLib/MGRS.hpp"
%include "GeographicLib/PolarStereographic.hpp"
%include "GeographicLib/TransverseMercator.hpp"
%include "GeographicLib/TransverseMercatorExact.hpp"
%include "GeographicLib/UTMUPS.hpp"
*/
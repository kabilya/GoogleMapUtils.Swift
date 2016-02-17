//
//  SphericalUtil.swift
//
//  Created by Christian Abella  on 10/10/2015.
//

import Foundation

public class SphericalUtil {
  
  private init()
  {
  }
  
  /**
  * Returns the heading from one to : LatLng another LatLng. Headings are
  * expressed in degrees clockwise from North within the range [-180,180).
  * @return The heading in degrees clockwise from north.
  */
  class func computeHeading(from : LatLng, to : LatLng) -> Double
  {
    // http://williams.best.vwh.net/avform.htm#Crs
    let fromLat = MapUtils.toRadians(from.latitude)
    let fromLng = MapUtils.toRadians(from.longitude)
    let toLat = MapUtils.toRadians(to.latitude)
    let toLng = MapUtils.toRadians(to.longitude)
    let dLng = toLng - fromLng
    
    let heading = atan2(
      sin(dLng) * cos(toLat),
      cos(fromLat) * sin(toLat) - sin(fromLat) * cos(toLat) * cos(dLng))
    return MathUtil.wrap(MapUtils.toDegrees(heading), min: -180, max: 180)
  }
  
  /**
  * Returns the LatLng resulting from moving a distance from an origin
  * in the specified heading (expressed in degrees clockwise from north).
  * @param from     The from : LatLng which to start.
  * @param distance The distance to travel.
  * @param heading  The heading in degrees clockwise from north.
  */
  class func computeOffset(from : LatLng, var distance : Double, var heading : Double) -> LatLng
  {
    distance /= MathUtil.EARTH_RADIUS
    heading = MapUtils.toRadians(heading)
    // http://williams.best.vwh.net/avform.htm#LL
    let fromLat = MapUtils.toRadians(from.latitude)
    let fromLng = MapUtils.toRadians(from.longitude)
    let cosDistance = cos(distance)
    let sinDistance = sin(distance)
    let sinFromLat = sin(fromLat)
    let cosFromLat = cos(fromLat)
    let sinLat = cosDistance * sinFromLat + sinDistance * cosFromLat * cos(heading)
    let dLng = atan2(
      sinDistance * cosFromLat * sin(heading),
      cosDistance - sinFromLat * sinLat)
    return LatLng(latitude: MapUtils.toDegrees(asin(sinLat)), longitude: MapUtils.toDegrees(fromLng + dLng))
  }
  
  /**
  * Returns the location of origin when provided with a LatLng destination,
  * meters travelled and original heading. Headings are expressed in degrees
  * clockwise from North. This function returns nil when no solution is
  * available.
  * @param to       The destination LatLng.
  * @param distance The distance travelled, in meters.
  * @param heading  The heading in degrees clockwise from north.
  */
  class func computeOffsetOrigin(to : LatLng, var distance : Double, var heading : Double) -> LatLng!
  {
    heading = MapUtils.toRadians(heading)
    distance /= MathUtil.EARTH_RADIUS
    // http://lists.maptools.org/M_PIpermail/proj/2008-October/003939.html
    let n1 = cos(distance)
    let n2 = sin(distance) * cos(heading)
    let n3 = sin(distance) * sin(heading)
    let n4 = sin(MapUtils.toRadians(to.latitude))
    // There are two solutions for b. b = n2 * n4 +/- sqrt(), one solution results
    // in the latitude outside the [-90, 90] range. We first try one solution and
    // back off to the other if we are outside that range.
    let n12 = n1 * n1
    let discriminant = n2 * n2 * n12 + n12 * n12 - n12 * n4 * n4
    
    if (discriminant < 0)
    {
      // No real solution which would make sense in LatLng-space.
      return nil
    }
    
    var b = n2 * n4 + sqrt(discriminant)
    b /= n1 * n1 + n2 * n2
    let a = (n4 - n2 * b) / n1
    var fromLatRadians = atan2(a, b)
    
    if (fromLatRadians < -M_PI / 2 || fromLatRadians > M_PI / 2)
    {
      b = n2 * n4 - sqrt(discriminant)
      b /= n1 * n1 + n2 * n2
      fromLatRadians = atan2(a, b)
    }
    
    if (fromLatRadians < -M_PI / 2 || fromLatRadians > M_PI / 2)
    {
      // No solution which would make sense in LatLng-space.
      return nil
    }
    
    let fromLngRadians = MapUtils.toRadians(to.longitude) -
      atan2(n3, n1 * cos(fromLatRadians) - n2 * sin(fromLatRadians))
    return LatLng(latitude: MapUtils.toDegrees(fromLatRadians), longitude: MapUtils.toDegrees(fromLngRadians))
  }
  
  /**
  * Returns the LatLng which lies the given fraction of the way between the
  * origin LatLng and the destination LatLng.
  * @param from     The from : LatLng which to start.
  * @param to       The to : LatLngward which to travel.
  * @param fraction A fraction of the distance to travel.
  * @return The interpolated LatLng.
  */
  class func interpolate(from : LatLng, to : LatLng, fraction : Double) -> LatLng
  {
    // http://en.wikipedia.org/wiki/Slerp
    let fromLat = MapUtils.toRadians(from.latitude)
    let fromLng = MapUtils.toRadians(from.longitude)
    let toLat = MapUtils.toRadians(to.latitude)
    let toLng = MapUtils.toRadians(to.longitude)
    let cosFromLat = cos(fromLat)
    let cosToLat = cos(toLat)
  
    // Computes Spherical interpolation coefficients.
    let angle = computeAngleBetween(from, to: to)
    let sinAngle = sin(angle)
    if (sinAngle < 1E-6)
    {
      return from
    }
    let a = sin((1 - fraction) * angle) / sinAngle
    let b = sin(fraction * angle) / sinAngle
  
    // Converts from polar to vector and interpolate.
    let x = a * cosFromLat * cos(fromLng) + b * cosToLat * cos(toLng)
    let y = a * cosFromLat * sin(fromLng) + b * cosToLat * sin(toLng)
    let z = a * sin(fromLat) + b * sin(toLat)
  
    // Converts interpolated vector back to polar.
    let lat = atan2(z, sqrt(x * x + y * y))
    let lng = atan2(y, x)
    return LatLng(latitude: MapUtils.toDegrees(lat), longitude: MapUtils.toDegrees(lng))
  }
  
  /**
  * Returns distance on the unit sphere the arguments are in radians.
  */
  class func distanceRadians(lat1 : Double, lng1 : Double, lat2 : Double, lng2 : Double) -> Double
  {
    return MathUtil.arcHav(MathUtil.havDistance(lat1, lat2: lat2, dLng: lng1 - lng2))
  }
  
  /**
  * Returns the angle between two LatLngs, in radians. This is the same as the distance
  * on the unit sphere.
  */
  class func computeAngleBetween(from : LatLng, to : LatLng) -> Double
  {
    return distanceRadians(MapUtils.toRadians(from.latitude), lng1: MapUtils.toRadians(from.longitude),
      lat2: MapUtils.toRadians(to.latitude), lng2: MapUtils.toRadians(to.longitude))
  }
  
  /**
  * Returns the distance between two LatLngs, in meters.
  */
  class func  computeDistanceBetween(from : LatLng, to : LatLng) -> Double
  {
    return computeAngleBetween(from, to: to) * MathUtil.EARTH_RADIUS
  }
  
  /**
  * Returns the length of the given path, in meters, on Earth.
  */
  class func computeLength(path : [LatLng]) -> Double
  {
    if path.count < 2
    {
      return 0
    }
  
    var length : Double = 0
    let prev = path.get(0)
    var prevLat = MapUtils.toRadians(prev!.latitude)
    var prevLng = MapUtils.toRadians(prev!.longitude)
  
    for point in path
    {
      let lat = MapUtils.toRadians(point.latitude)
      let lng = MapUtils.toRadians(point.longitude)
      length += distanceRadians(prevLat, lng1: prevLng, lat2: lat, lng2: lng)
      prevLat = lat
      prevLng = lng
    }
  
    return length * MathUtil.EARTH_RADIUS
  }
  
  /**
  * Returns the area of a closed path on Earth.
  * @param path A closed path.
  * @return The path's area in square meters.
  */
  class func computeArea(path : [LatLng]) -> Double
  {
    return abs(computeSignedArea(path))
  }
  
  /**
  * Returns the signed area of a closed path on Earth. The sign of the area may be used to
  * determine the orientation of the path.
  * "inside" is the surface that does not contain the South Pole.
  * @param path A closed path.
  * @return The loop's area in square meters.
  */
  class func computeSignedArea(path : [LatLng]) -> Double
  {
    return computeSignedArea(path, radius: MathUtil.EARTH_RADIUS)
  }
  
  /**
  * Returns the signed area of a closed path on a sphere of given radius.
  * The computed area uses the same units as the radius squared.
  * Used by SphericalUtilTest.
  */
  class func computeSignedArea(path : [LatLng], radius : Double) -> Double
  {
    let size = path.count
    if (size < 3)
    {
      return 0
    }
    
    var total : Double = 0
    let prev = path.get(size - 1)
    var prevTanLat = tan((M_PI / 2 - MapUtils.toRadians(prev!.latitude)) / 2)
    var prevLng = MapUtils.toRadians(prev!.longitude)
    // For each edge, accumulate the signed area of the triangle formed by the North Pole
    // and that edge ("polar triangle").
    
    for point in path
    {
      let tanLat = tan((M_PI / 2 - MapUtils.toRadians(point.latitude)) / 2)
      let lng = MapUtils.toRadians(point.longitude)
      total += polarTriangleArea(tanLat, lng1: lng, tan2: prevTanLat, lng2: prevLng)
      prevTanLat = tanLat
      prevLng = lng
    }
    
    return total * (radius * radius)
  }
  
  /**
  * Returns the signed area of a triangle which has North Pole as a vertex.
  * Formula derived from "Area of a spherical triangle given two edges and the included angle"
  * as per "Spherical Trigonometry" by Todhunter, page 71, section 103, point 2.
  * See http://books.google.com/books?id=3uBHAAAAIAAJ&pg=PA71
  * The arguments named "tan" are tan((M_PI/2 - latitude)/2).
  */
  class func polarTriangleArea(tan1 : Double, lng1  : Double, tan2 : Double, lng2 : Double) -> Double
  {
    let deltaLng = lng1 - lng2
    let t = tan1 * tan2
    return 2 * atan2(t * sin(deltaLng), 1 + t * cos(deltaLng))
  }
}

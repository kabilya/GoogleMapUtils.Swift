//
//  MathUtil.swift
//
//  Created by Christian Abella  on 10/10/2015.
//

import Foundation

/**
 * Utility functions that are used by both PolyUtil and SphericalUtil.
 */
class MathUtil
{
  /**
  * The earth's radius, in meters.
  * Mean radius as defined by IUGG.
  */
  static let EARTH_RADIUS : Double = 6371009
  
  /**
  * Restrict x to the range [low, high].
  */
  class func clamp(x : Double, low : Double, high : Double) -> Double
  {
    return x < low ? low : (x > high ? high : x)
  }
  
  /**
  * Wraps the given value into the inclusive-exclusive interval between min and max.
  * @param n   The value to wrap.
  * @param min The minimum.
  * @param max The maximum.
  */
  class func wrap(n : Double,min : Double,max : Double) -> Double
  {
    return (n >= min && n < max) ? n : (mod(n - min, m: max - min) + min)
  }
  
  /**
  * Returns the non-negative remainder of x / m.
  * @param x The operand.
  * @param m The modulus.
  */
  class func mod(x : Double,m : Double) -> Double
  {
    return ((x % m) + m) % m
  }
  
  /**
  * Returns mercator Y corresponding to latitude.
  * See http://en.wikipedia.org/wiki/Mercator_projection .
  */
  class func mercator(lat : Double) -> Double
  {
    return log(tan(lat * 0.5 + M_PI/4))
  }
  
  /**
  * Returns latitude from mercator Y.
  */
  class func inverseMercator(y : Double) -> Double
  {
    return 2 * atan(exp(y)) - M_PI / 2
  }
  
  /**
  * Returns haversine(angle-in-radians).
  * hav(x) == (1 - cos(x)) / 2 == sin(x / 2)^2.
  */
  class func hav(x : Double) -> Double
  {
    let sinHalf = sin(x * 0.5)
    return sinHalf * sinHalf;
  }
  
  /**
  * Computes inverse haversine. Has good numerical stability around 0.
  * arcHav(x) == acos(1 - 2 * x) == 2 * asin(sqrt(x)).
  * The argument must be in [0, 1], and the result is positive.
  */
  class func arcHav(x : Double) -> Double
  {
    return 2 * asin(sqrt(x))
  }
  
  // Given h==hav(x), returns sin(abs(x)).
  class func sinFromHav(h : Double) -> Double
  {
  return 2 * sqrt(h * (1 - h))
  }
  
  // Returns hav(asin(x)).
  class func havFromSin(x : Double) -> Double
  {
    let x2 = x * x
    return x2 / (1 + sqrt(1 - x2)) * 0.5
  }
  
  // Returns sin(arcHav(x) + arcHav(y)).
  class func sinSumFromHav(x : Double,y : Double) -> Double
  {
    let a = sqrt(x * (1 - x))
    let b = sqrt(y * (1 - y))
    return 2 * (a + b - 2 * (a * y + b * x))
  }
  
  /**
  * Returns hav() of distance from (lat1, lng1) to (lat2, lng2) on the unit sphere.
  */
  class func havDistance(lat1 : Double, lat2 : Double, dLng : Double) -> Double
  {
    return hav(lat1 - lat2) + hav(dLng) * cos(lat1) * cos(lat2)
  }
}

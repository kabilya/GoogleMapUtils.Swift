//
//  MapUtils.swift
//
//  Created by Christian Abella  on 19/10/2015.
//

import Foundation
import Darwin

class MapUtils
{
  
  class func getXTile(lon : Double, zoom : UInt) -> UInt
  {
    let tileX : UInt = (UInt)(floor((lon + 180.0) / 360.0 * pow(2.0, Double(zoom))))
    return tileX
  }
  
  
  class func getYTile(lat : Double, zoom : UInt) -> UInt
  {
    let tileY : UInt = (UInt)(floor((1.0 - log( tan(lat * M_PI/180.0) + 1.0 / cos(lat * M_PI/180.0)) / M_PI) / 2.0 * pow(2.0, Double(zoom))))
    return tileY
  }
  
  class func getTileNumber(lat : Double, lon : Double, zoom : UInt) -> String
  {
    let tileX = getXTile(lon,zoom: zoom)
    let tileY =  getYTile(lat,zoom: zoom)
  
    return String(format: "%d/%d/%d.png", zoom, tileX, tileY)
  }
  
  class func TileToLong(x : Int, zoom : Int) -> Double
  {
    return Double(x) / pow(2.0, Double(zoom)) * 360.0 - 180
  }
  
  class func TileToLat(y : Int, zoom: Int) -> Double
  {
    let n : Double = M_PI - (2.0 * M_PI * Double(y)) / pow(2.0, Double(zoom))
    return toDegrees(atan(sinh(n)))
  }
  
  class func getTotalTiles(nMinZoom : UInt, nMaxZoom : UInt) -> UInt
  {
    var total : UInt = 0
  
    for var i : UInt = 1; i <= (nMaxZoom-nMinZoom); i++
    {
      total = total + (UInt)(pow(4.0,Double(i)))
    }
    
    return total
  }
  
  /** Degrees to Radian **/
  class func toRadians( degrees : Double ) -> Double
  {
    return degrees / (180.0 * M_PI)
  }
  
  /** Radians to Degrees **/
  class func toDegrees( radians : Double ) -> Double
  {
    return radians * (180.0 / M_PI)
  }

}

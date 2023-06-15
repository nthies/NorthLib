//
//  CoreGraphicsExtensions.swift
//
//  Created by Norbert Thies on 15.04.16.
//  Copyright © 2016 Norbert Thies. All rights reserved.
//

import UIKit

// CGSize extensions
public extension CGSize {
  
  /// isPortrait returns true if width <= height
  var isPortrait: Bool { return width <= height }
  
  /// isLandscape returns true if width > height
  var isLandscape: Bool { return width > height }
  
  /// toString returns a String representation
  func toString() -> String { return "(w:\(width),h:\(height))" }
  
  /// description simply calls toString
  var description: String { return toString() }
  
}

/// A CGPoint transformation
public struct CGPointTransform {
  public var rowX: CGPoint
  public var rowY: CGPoint
  public init( x: CGPoint, y: CGPoint ) { rowX = x; rowY = y }
  public static func rotation( _ a: CGFloat ) -> CGPointTransform {
    return CGPointTransform( x: CGPoint(x:cos(a), y:sin(a)),
                             y: CGPoint(x:-sin(a), y:cos(a)) )
  }
  public static func scale( x: CGFloat, y: CGFloat ) -> CGPointTransform {
    return CGPointTransform( x: CGPoint(x:x, y:0), y: CGPoint(x:0, y:y) )
  }
}

// Some CGPoint operators

public func * ( t:CGPointTransform, p:CGPoint ) -> CGPoint {
  return CGPoint( x: p.x*t.rowX.x + p.y*t.rowX.y,
                  y: p.x*t.rowY.x + p.y*t.rowY.y)
}

public func * ( t1:CGPointTransform, t2:CGPointTransform ) -> CGPointTransform {
  return CGPointTransform(
    x: CGPoint( x: t1.rowX.x * t2.rowX.x + t1.rowX.y * t2.rowY.x,
                y: t1.rowX.x * t2.rowX.y + t1.rowX.y * t2.rowY.y ),
    y: CGPoint( x: t1.rowY.x * t2.rowX.x + t1.rowY.y * t2.rowY.x,
                y: t1.rowY.x * t2.rowX.y + t2.rowY.y * t2.rowY.y )
  )
}

public func + ( p1:CGPoint, p2:CGPoint ) -> CGPoint {
  return CGPoint( x: p1.x + p2.x, y: p1.y + p2.y )
}

public func + ( p1:CGPoint, p2:(x:CGFloat, y:CGFloat) ) -> CGPoint {
  return CGPoint( x: p1.x + p2.x, y: p1.y + p2.y )
}

public func + ( p1:CGPoint, v:CGFloat ) -> CGPoint {
  return CGPoint( x: p1.x + v, y: p1.y + v )
}

public func + ( v:CGFloat, p1:CGPoint ) -> CGPoint {
  return p1 + v
}

public func - ( p1:CGPoint, v:CGFloat ) -> CGPoint {
  return p1 + -v
}

public prefix func - ( p:CGPoint ) -> CGPoint {
  return CGPoint( x:-p.x, y:-p.y )
}

public func - ( p1:CGPoint, p2:CGPoint ) -> CGPoint {
  return p1 + -p2
}

public func - ( p1:CGPoint, p2:(x:CGFloat, y:CGFloat) ) -> CGPoint {
  return p1 + (-p2.x,-p2.y)
}

public func * ( p:CGPoint, s:CGFloat ) -> CGPoint {
  return CGPoint( x:p.x*s, y:p.y*s )
}

public func * ( s:CGFloat, p:CGPoint ) -> CGPoint { return p*s }

public func / ( p:CGPoint, s:CGFloat ) -> CGPoint { return p*(1/s) }


public extension CGPoint {

  /// returns the length of the vector
  var abs: CGFloat { get { return sqrt(x*x + y*y) } }
  
  /// returns vector from self to *to*
  func vector( _ to:CGPoint ) -> CGPoint { return to-self }

  /// returns the angle of a vector in radians (0...2𝛑)
  var angle: CGFloat {
    let ya = Swift.abs(y)
    let a = asin(ya/abs)
    if x>=0 {
      if y>=0 { return a }
      else { return 2*CGFloat.pi - a }
    }
    else {
      if y<0 { return CGFloat.pi + a }
      else { return CGFloat.pi - a }
    }
  }
  
  /// returns the angle of a vector in degrees (0...360)
  var deg: CGFloat { return (angle/(2*CGFloat.pi))*360.0 }

  /// returns a perpendicular vector, i.e. a vector of given length (or
  /// same length if not given) and an angle turned 90° anti clockwise
  func perpendicular(_ length: CGFloat? = nil) -> CGPoint {
    let len = length ?? self.abs
    let newAngle = (self.angle + CGFloat.pi/2) % (2*CGFloat.pi)
    return CGPoint(length: len, angle: newAngle)
  }
  
  /** returns a pair of Bezier points for a curve from *self* to *to*.
   
    - parameters: 
      - to: CGPoint to which the curve should go
      - bending ([0.0, 1.0]): 0 is no bending, 1 is a bending of
                the size equal to the length of the vector to *to*
  */
  func bezierPoints(_ to:CGPoint, bending:CGFloat) -> (CGPoint, CGPoint) {
    let vec = self.vector(to)
    let perp = vec.perpendicular(vec.abs*bending)
    let rp1 = perp + 0.33*vec, rp2 = perp + 0.66*vec
    return (self + rp1, self + rp2)
  }

  /// toString returns a String representation
  func toString() -> String { return "(x:\(x),y:\(y))" }
  
  /// description simply calls toString
  var description: String { return toString() }
  
  /// create vector from length and angle (in radians)
  init(length: CGFloat, angle: CGFloat) {
    self.init()
    x = length * cos(angle)
    y = length * sin(angle)
  }
  
  /// create vector from length and angle (in degrees)
  init(length: CGFloat, deg: CGFloat) {
    let angle = 2*CGFloat.pi * (deg/360.0)
    self.init(length: length, angle: angle)
  }
  
  /// return true if the point is inside a rect
  func inRect(_ rect: CGRect) -> Bool {
    (x >= rect.origin.x) && (x <= rect.origin.x + rect.size.width) &&
    (y >= rect.origin.y) && (y <= rect.origin.y + rect.size.height)
  }

} // extension CGPoint

public extension UIBezierPath {

  /// draw a circle at *center* with *radius* either clockwise (default)
  /// or anti clockwise
  func circle( _ center:CGPoint, radius:CGFloat, clockwise:Bool = true ) {
    addArc(withCenter: center, radius: radius, startAngle: 0,
           endAngle: 2*CGFloat.pi, clockwise: clockwise)
  }
  
  /// draw an x-like cross at *center* with *radius* of the enclosing
  /// circle
  func cross(_ center: CGPoint, radius: CGFloat) {
    let l = radius * sin(CGFloat.pi/4)
    let upperLeft = CGPoint(x: center.x-l, y: center.y-l)
    let upperRight = CGPoint(x: center.x+l, y: center.y-l)
    let lowerLeft = CGPoint(x: center.x-l, y: center.y+l)
    let lowerRight = CGPoint(x: center.x+l, y: center.y+l)
    move(to: upperRight)
    addLine(to: lowerLeft)
    move(to: upperLeft)
    addLine(to: lowerRight)
  }
  
  /**
   adds a curve to point *to* with the given *bending*
   
   Let *v* be a vector from the current point to *to*, then the drawn curve
   is bended in the direction of a vector perpendicular (anti clockwise)
   to *v*.
   - parameters: 
     - to: CGPoint to which the curve should go
     - bending: [0.0, 1.0] - 0 is no bending, 1 is a bending of
         the size equal to the length of the vector to *to*
  */
  func addCurve(_ to:CGPoint, bending:CGFloat) {
    let (p1,p2) = currentPoint.bezierPoints(to, bending: bending)
    self.addCurve(to: to, controlPoint1: p1, controlPoint2: p2)
  }
  
  /// produces a curve from point *from* to point *to* with given *bending*
  func curve(_ from:CGPoint, to:CGPoint, bending:CGFloat) {
    move(to: from)
    addCurve(to, bending: bending)
  }
  
  /**
   draw a dotted line from point *from* to point *to*. 
 
   All dots are circles with radius *radius*. Between circles is a distance
   of 2 * radius.
   - parameters:
     - from: start point of dotted line
     - to:   end point of dotted line
     - radius: radius of dot (width is 2*radius)
   */
  func dottedLine(from: CGPoint, to: CGPoint, radius r: CGFloat) {
    let vec = from.vector(to)
    let l = vec.abs // length of line
    let d = 2*r // diameter of dots
    let angle = vec.angle // angle of line in rad
    let n = round(l/(2*d)) // number of dots
    let v = CGPoint(length: 2*d, angle: angle) // vector from one dot to the next
    let le = (2*n-1)*d // effective length of dotted line (- start/end whitespace)
    let lstart = (l - le)/2 // length of start/end whitespace
    let vstart = CGPoint(length: lstart + r, angle: angle) // vector to center of first dot
    var p = from + vstart // center of first dot
    for _ in stride(from: 0, to: Int(n), by: 1) {
      let circleOrigin = CGPoint(x: p.x+r-lineWidth, y: p.y)
      move(to: circleOrigin)
      circle(p, radius: r-lineWidth)
      p = p + v
    }
  }

  /**
   strokes a path with a shadow
   
   strokeWithShade uses a shadow with a given *blur* to stroke the current path.
   The light source appears to be immediately above the screen.
   - parameters:
     - blur: A non-negative number specifying the amount of blur.
   */
  func strokeWithShade(_ blur: CGFloat) {
    if let ctx = UIGraphicsGetCurrentContext() {
      UIGraphicsPushContext(ctx)
      ctx.setShadow(offset: CGSize(width: 0.0, height: 0.0), blur: blur)
      ctx.addPath(self.cgPath)
      ctx.setLineWidth(self.lineWidth)
      ctx.setLineJoin(self.lineJoinStyle)
      ctx.strokePath()
      UIGraphicsPopContext()
    }
  }
  
  /**
   fills a path using a shadow
   
   fillWithShade uses a shadow with a given *blur* to fill the current path.
   The light source appears to be immediately above the screen.
   - parameters:
   - blur: A non-negative number specifying the amount of blur.
   */  
  func fillWithShade(_ blur: CGFloat) {
    if let ctx = UIGraphicsGetCurrentContext() {
      UIGraphicsPushContext(ctx)
      ctx.setShadow(offset: CGSize(width: 0.0, height: 0.0), blur: blur)
      ctx.addPath(self.cgPath)
      ctx.drawPath(using: .fill)
      UIGraphicsPopContext()
    }
  }

} // extension UIBezierPath

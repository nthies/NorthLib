//
//  DottedLineView.swift
//
//  Created by Norbert Thies on 21.02.19.
//  Copyright © 2019 Norbert Thies. All rights reserved.
//

import UIKit

/**
 UIView subclass drawing either a horizontal (default) or vertical dotted line
 
 A DottedLineView draws a horizontal or vertical line of dots. When drawing a horizontal
 line, the height of the frame defines the diameter of the dots, when drawing a vertical 
 line, the width defines the diameter. Between two dots is one diameter additional distance.
 The following attributes are available:
 
   * isHorizontal: whether to draw a horizontal (or vertical line, true by default) 
   * fillColor:    the color to fill the dots with (black)
   * strokeColor:  color of the stroked line (black)
   * lineWidth:    width of the stroked line (0)
 */
open class DottedLineView: UIView {
  
  /// draw horizontal line
  open var isHorizontal = true
  /// the color to fill the dots with (black)
  open var fillColor = UIColor.black
  /// color of the stroked line (black)
  open var strokeColor = UIColor.black
  /// width of the stroked line (0)
  open var lineWidth: CGFloat = 0
  
  override open func draw(_ rect: CGRect) {
    let w = bounds.size.width, h = bounds.size.height
    let path = UIBezierPath()
    var from: CGPoint, to: CGPoint, d: CGFloat
    if isHorizontal {
      from = CGPoint(x:0,y:h/2)
      to = CGPoint(x:w,y:h/2)
      d = h
    }
    else {
      from = CGPoint(x:w/2,y:0)
      to = CGPoint(x:w/2,y:h)
      d = w
    }
    path.lineWidth = lineWidth
    path.dottedLine(from: from, to: to, radius: d/2)
    strokeColor.setStroke()
    fillColor.setFill()
    path.fill()
    path.stroke()
  }
  
  override open func layoutSubviews() {
    setNeedsDisplay()
  }
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = UIColor.clear
  }
  
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
}

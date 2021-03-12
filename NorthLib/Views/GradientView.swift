//
//  GradientView.swift
//  NorthLib
//
//  Created by Ringo Müller on 12.03.21.
//  Copyright © 2021 Norbert Thies. All rights reserved.
//

import UIKit

public class VerticalGradientView : UIView {
  
  let gradientLayer = CAGradientLayer()
  var startColor:UIColor = .black
  var endColor:UIColor = UIColor.black.withAlphaComponent(0.0)
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }
  
  public override func layoutSubviews() {
      super.layoutSubviews()
    gradientLayer.frame = self.frame
  }
  
  func setup(){
    gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
    gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
    gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
    gradientLayer.locations = [0,1]
    self.layer.addSublayer(gradientLayer)
    self.addBorder(.red)
  }
}

//
//  String.swift
//
//  Created by Norbert Thies on 20.07.16.
//  Copyright © 2016 Norbert Thies. All rights reserved.
//
//  This file implements various String extensions depending on the 
//  UIKit Framework.
//

import UIKit

/// String extension supporting UIFont related methods.
public extension String {

  /**
   Return UILabel that is just large enough to encompass the actual String
   
   `label` returns to given font (default: preferred for body text) a label
   containing the current object's string of characters so that the string
   just fits. The label returned consists of one row of characters unless
   newlines are enclosed in the string.
   
   - Parameters:
   - font: the text font to use in the label
   - Returns: A new UILabel containing the current String
   */
  func label(font: UIFont? = nil) -> UILabel {
    var fnt: UIFont
    if font == nil { fnt = UIFont.preferredFont(forTextStyle: .body) }
    else { fnt = font! }
    let label =  UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude,
                                       height: CGFloat.greatestFiniteMagnitude))
    label.numberOfLines = 0
    label.text = self
    label.font = fnt
    label.sizeToFit()
    return label
  }
  
  /**
   Returns the size in a given font
   
   `size` returns to given font (default: preferred for body text) a CGSize just
   big enough to fit the string of characters.
   
   - Parameters:
   - font: the text font used to calculate the size
   - Returns: the size of the smallest box encompassing the String
   */
  func size(font: UIFont? = nil) -> CGSize {
    return label(font:font).frame.size
  }

} // extension String

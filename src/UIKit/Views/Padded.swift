//
//  Padded.swift
//  NorthLib
//
//  Created by Ringo on 31.08.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import Foundation
import UIKit

/// Protocol that provides customizable padding properties for common views.
///
/// Conforming views can define `paddingTop` and `paddingBottom` values, allowing for
/// dynamic adjustment of spacing between stacked views when laying out a user interface.
/// These properties are utilized during the layout process, particularly in the
/// `addAndPin()` function, which dynamically arranges views within a container by considering
/// the maximum padding values of adjacent views.
///
/// **Conformance**:
/// Views like `UILabel`, `UIImageView`, `UIButton`, `UIView`, `UITextField`, and `UITextView`
/// can conform to this protocol via the `Padded` struct, gaining support for padding customization.
///
/// **Example Usage**:
/// In the `addAndPin()` function, the `padding()` helper calculates the spacing between
/// two consecutive views by evaluating their `paddingBottom` and `paddingTop` values.
/// This ensures a consistent and flexible layout, accommodating individual padding requirements.
///
public protocol PaddedView {
    /// The top padding for the view, if any.
    /// Determines the space above the view when stacked with others.
    var paddingTop: CGFloat? { get set }
    
    /// The bottom padding for the view, if any.
    /// Determines the space below the view when stacked with others.
    var paddingBottom: CGFloat? { get set }
}

public struct Padded {
  open class Label : UILabel, PaddedView {
    public var paddingTop: CGFloat?, paddingBottom: CGFloat?
  }
  open class ImageView : UIImageView, PaddedView {
    public var paddingTop: CGFloat?, paddingBottom: CGFloat?
  }
  open class Button : UIButton, PaddedView {
    public var paddingTop: CGFloat?, paddingBottom: CGFloat?
  }
  open class View : UIView, PaddedView {
    public var paddingTop: CGFloat?, paddingBottom: CGFloat?
  }
  
  open class TextField : UITextField, PaddedView {
    public var paddingTop: CGFloat?, paddingBottom: CGFloat?
  }
  
  open class TextView : UITextView, PaddedView {
    public var paddingTop: CGFloat?, paddingBottom: CGFloat?
  }
}

// MARK: -  PaddingHelper
/// Max PaddingHelper
public func padding(_ topView:UIView, _ bottomView:UIView) -> CGFloat{
  let padding1 = (topView as? PaddedView)?.paddingBottom ?? 12.0
  let padding2 = (bottomView as? PaddedView)?.paddingTop ?? 12.0
  return max(padding1, padding2)
}

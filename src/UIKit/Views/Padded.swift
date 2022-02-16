//
//  Padded.swift
//  NorthLib
//
//  Created by Ringo on 31.08.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import Foundation
import UIKit

public protocol PaddedView {
  var paddingTop : CGFloat? { get set}
  var paddingBottom : CGFloat? { get set}
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

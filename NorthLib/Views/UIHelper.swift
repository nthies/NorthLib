//
// UIHelper.swift
//
// Created by Ringo Müller-Gromes on 31.07.20.
// Copyright © 2020 Ringo Müller-Gromes for "taz" digital newspaper. All rights reserved.
//
//
//  This file implements some UIView helper

import UIKit

// MARK: - BorderView
/// Just to detect by Classname for borders Helper
public class BorderView : UIView {}

// MARK: - borders Helper
///borders Helper
extension UIView {
  @discardableResult
  public func addBorder(_ color:UIColor,
                 _ width:CGFloat=1.0,
                 only: UIRectEdge? = nil) -> Self{
    if only == nil {
      self.layer.borderColor = color.cgColor
      self.layer.borderWidth = width
      return self
    }
    
    removeBorders()
    
    let b = BorderView()
    b.backgroundColor = color
    
    self.addSubview(b)
    if only == UIRectEdge.top || only == UIRectEdge.bottom {
      b.pinHeight(width)
      pin(b.left, to: self.left)
      pin(b.right, to: self.right)
    }
    else {
      b.pinWidth(width)
      pin(b.top, to: self.top)
      pin(b.bottom, to: self.bottom)
    }
    
    if only == UIRectEdge.top {
      pin(b.top, to: self.top)
    }
    else if only == UIRectEdge.bottom {
      pin(b.bottom, to: self.bottom)
    }
    else if only == UIRectEdge.left {
      pin(b.left, to: self.left)
    }
    else if only == UIRectEdge.right {
      pin(b.right, to: self.right)
    }
    return self
  }
  
  public func removeBorders(){
    self.layer.borderColor = UIColor.clear.cgColor
    self.layer.borderWidth = 0.0
    
    for case let border as BorderView in self.subviews {
      border.removeFromSuperview()
    }
  }
}

// MARK: - frame Helper
extension UIView {
  public func getConvertedFrame(_ childView: UIView) -> CGRect? {
    //check if child is subview of self
    guard childView.isDescendant(of: self) else { return nil }
    guard var curr = childView.superview else { return nil }
    var fr = childView.frame
    while true {
      guard let sv = curr.superview else { return nil }
      fr = curr.convert(fr, to: sv)
      if sv == self { return fr }
      curr = sv
    }
  }
  
  public func getConvertedCenter(_ childView: UIView) -> CGPoint? {
    //check if child is subview of self
    guard childView.isDescendant(of: self) else { return nil }
    guard var curr = childView.superview else { return nil }
    var pt = childView.center
    while true {
      guard let sv = curr.superview else { return nil }
      pt = curr.convert(pt, to: sv)
      if sv == self { return pt }
      curr = sv
    }
  }
}

// MARK: - borders Helper
///borders Helper
extension UIView {
  public func onTapping(closure: @escaping (UITapGestureRecognizer)->()){
    let gr = TapRecognizer()
    gr.onTap(view: self, closure: closure)
  }
}

// MARK: - UILabel setTextAnimated
extension UILabel{
  /// sets the new text animate height and alpha with a smooth Animation
  /// - Parameter newText: text to set
  public func setTextAnimated(_ newText:String?){
    ///usually animate 3 levels heigher in case of ugly behaviour look for an scrollview
    /// or container that is not pinned top and bottom
    let viewToAnimate =
      self.superview?.superview ?? self.superview ?? self
    
    //animate hight while hiding using snaphot
    if true, let snapshot = self.snapshotView(afterScreenUpdates: false){
      snapshot.frame = self.frame
      self.superview?.addSubview(snapshot)
      self.alpha = 0.0
      self.text = newText
      viewToAnimate.setNeedsUpdateConstraints()
       
      UIView.animateKeyframes(withDuration: 2.0, delay: 0.0, animations: {
        UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.55) {
          snapshot.alpha = 0.0 //hide 0...0.4
        }
        UIView.addKeyframe(withRelativeStartTime: 0.25, relativeDuration: 0.5) {
          viewToAnimate.layoutIfNeeded()//height 0.2...0.8
        }
        UIView.addKeyframe(withRelativeStartTime: 0.45, relativeDuration: 0.55) {
          self.alpha = 1.0// show 0.6 ...1
        }
      }, completion:{ (_) in
        snapshot.removeFromSuperview()
      })
    }
    else {//animate in steps, 1st hide then size&alpha
      UIView.animate(withDuration: 1.0, animations: {
        self.alpha = 0.0
      }, completion: { (_) in
        self.text = newText
        viewToAnimate.setNeedsUpdateConstraints()
        UIView.animate(withDuration: 1.5,animations: {
          viewToAnimate.layoutIfNeeded()
        })
        UIView.animate(withDuration: 0.7, delay: 1.3, animations: {
          self.alpha = 1.0
        })
      })
    }
  }
}

// MARK: - extension UIButton:setBackgroundColor
extension UIButton {
  public func setBackgroundColor(color: UIColor, forState: UIControl.State) {
    self.clipsToBounds = true  // support corner radius
    UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
    if let context = UIGraphicsGetCurrentContext() {
      context.setFillColor(color.cgColor)
      context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
      let colorImage = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()
      self.setBackgroundImage(colorImage, for: forState)
    }
  }
}

// MARK: - extension UIButton:touch
extension UIButton {
  public func touch(_ target: Any?, action:Selector){
    self.addTarget(target, action: action, for: .touchUpInside)
  }
}

// MARK: - extension UIImage with systemName fallback named
extension UIImage {
  /// Creates an image
  /// iOS 13 and later: object containing a system symbol image referenced by given name
  /// earlier: using the named image asset
  ///
  /// Example
  /// ```
  /// UIImage(name: "checkmark") // Creates image
  /// ```
  ///
  /// #challenge: SFSymbol's images for iOS 12
  ///  using: https://github.com/davedelong/sfsymbols
  ///  but currently it has an issue, and uses Thin Symbol Images
  ///  so convert images that way:
  ///  sfsymbols --symbol-name eye.slash.fill  --font-file /Library/Fonts/SF-Pro-Display-Regular.otf --font-size 18 --format pdf --output converted
  ///  to ensure same "eye" size eye.slash has font-size 17 and eye font-size 18 ;-)
  ///
  ///  While import to xcassets ensure:
  ///  - Scales: single scale
  ///  - Render as: Template Image
  ///
  /// - Warning: May return nil if Image for given name does not exist
  /// - Parameter name: the image name
  /// - Returns: UIImage related to `name`.
  public convenience init?(name:String) {
    if #available(iOS 13.0, *){
      self.init(systemName: name)
    }
    else{
      ///Symbol Names with a dot like eye.slash cannot be loaded from asset catalog
      let name = name.replacingOccurrences(of: ".", with: "_")
      self.init(named: name)
    }
  }
}

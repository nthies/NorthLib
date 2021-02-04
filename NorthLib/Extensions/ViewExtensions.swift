//
//  ViewExtensions.swift
//
//  Created by Norbert Thies on 2019-02-28
//  Copyright © 2019 Norbert Thies. All rights reserved.
//
//  This file implements some UIView extensions
//

import UIKit

/// Find view controller of given UIView: UIResponder
public extension UIResponder {
  var parentViewController: UIViewController? {
    return next as? UIViewController ?? next?.parentViewController
  }
}

/// A CALayer extension to produce a snapshot
public extension CALayer {
  /// Returns snapshot of current layer as UIImage
  var snapshot: UIImage? {
    let scale = UIScreen.main.scale
    UIGraphicsBeginImageContextWithOptions(frame.size, false, scale)
    defer { UIGraphicsEndImageContext() }
    guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
    render(in: ctx)
    return UIGraphicsGetImageFromCurrentImageContext()
  }
}

/// A UIView extension to produce a snapshot
public extension UIView {
  /// Returns snapshot of current view as UIImage
  var snapshot: UIImage? {
    let renderer = UIGraphicsImageRenderer(size: frame.size)
    return renderer.image { _ in
      drawHierarchy(in: bounds, afterScreenUpdates: true)
    }
  }
}

/// A UIView extension to check visibility of a view
public extension UIView {
  /// Return whether view is visible somewhere on the screen
  var isVisible: Bool {
    if self.window != nil && !self.isHidden {
      let rect = self.convert(self.frame, from: nil)
      return rect.intersects(UIScreen.main.bounds)
    } 
    return false
  }
}

// Layout anchors and corresponding views:
public struct LayoutAnchorX {
  public var anchor: NSLayoutXAxisAnchor
  public var view: UIView
  init(_ view: UIView, _ anchor: NSLayoutXAxisAnchor) 
    { self.view = view; self.anchor = anchor }
}

public struct LayoutAnchorY {
  public var anchor: NSLayoutYAxisAnchor
  public var view: UIView
  init(_ view: UIView, _ anchor: NSLayoutYAxisAnchor) 
    { self.view = view; self.anchor = anchor }
}

public struct LayoutDimension {
  public var anchor: NSLayoutDimension
  public var view: UIView
  init(_ view: UIView, _ anchor: NSLayoutDimension) 
    { self.view = view; self.anchor = anchor }
}

// Mostly Auto-Layout related extensions
public extension UIView {
  
  /// Bottom anchor
  var bottom: LayoutAnchorY { return LayoutAnchorY(self, bottomAnchor) }
  /// Top anchor
  var top: LayoutAnchorY { return LayoutAnchorY(self, topAnchor) }
  /// Vertical center anchor
  var centerY: LayoutAnchorY { return LayoutAnchorY(self, centerYAnchor) }
  /// Left Anchor
  var left: LayoutAnchorX { return LayoutAnchorX(self, leftAnchor) }
  /// Right Anchor
  var right: LayoutAnchorX { return LayoutAnchorX(self, rightAnchor) }
  /// Horizontal center anchor
  var centerX: LayoutAnchorX { return LayoutAnchorX(self, centerXAnchor) }
  /// Width anchor
  var width: LayoutDimension { return LayoutDimension(self, widthAnchor) }
  /// Height anchor
  var height: LayoutDimension { return LayoutDimension(self, heightAnchor) }

  /// Bottom margin anchor
  func bottomGuide(isMargin: Bool = false) -> LayoutAnchorY { 
    let guide = isMargin ? layoutMarginsGuide : safeAreaLayoutGuide
    return LayoutAnchorY(self, guide.bottomAnchor)
  }
  /// Top margin anchor
  func topGuide(isMargin: Bool = false) -> LayoutAnchorY { 
    let guide = isMargin ? layoutMarginsGuide : safeAreaLayoutGuide
    return LayoutAnchorY(self, guide.topAnchor)
  }
  /// Left margin Anchor
  func leftGuide(isMargin: Bool = false) -> LayoutAnchorX { 
    let guide = isMargin ? layoutMarginsGuide : safeAreaLayoutGuide
    return LayoutAnchorX(self, guide.leftAnchor)
  }
  /// Right margin Anchor
  func rightGuide(isMargin: Bool = false) -> LayoutAnchorX { 
    let guide = isMargin ? layoutMarginsGuide : safeAreaLayoutGuide
    return LayoutAnchorX(self, guide.rightAnchor)
  }
  
  /// Pin width of view
  @discardableResult
  func pinWidth(_ width: CGFloat) -> NSLayoutConstraint {
    translatesAutoresizingMaskIntoConstraints = false
    let constraint = widthAnchor.constraint(equalToConstant: width)
    constraint.isActive = true
    return constraint
  }
  @discardableResult
  func pinWidth(_ width: Int) -> NSLayoutConstraint { return pinWidth(CGFloat(width)) }
  
  @discardableResult
  func pinWidth(to: LayoutDimension, dist: CGFloat = 0, factor: CGFloat = 0) 
    -> NSLayoutConstraint { 
      translatesAutoresizingMaskIntoConstraints = false
      let constraint = widthAnchor.constraint(equalTo: to.anchor, 
        multiplier: factor, constant: dist)
      constraint.isActive = true
      return constraint
  }
  
  /// Pin height of view
  @discardableResult
  func pinHeight(_ height: CGFloat, priority: UILayoutPriority? = nil) -> NSLayoutConstraint {
    translatesAutoresizingMaskIntoConstraints = false
    let constraint = heightAnchor.constraint(equalToConstant: height)
    if let prio = priority { constraint.priority = prio }
    constraint.isActive = true
    return constraint
  }
  @discardableResult
  func pinHeight(_ height: Int) -> NSLayoutConstraint { return pinHeight(CGFloat(height)) }
  
  @discardableResult
  func pinHeight(to: LayoutDimension, dist: CGFloat = 0, factor: CGFloat = 0) 
    -> NSLayoutConstraint { 
      translatesAutoresizingMaskIntoConstraints = false
      let constraint = heightAnchor.constraint(equalTo: to.anchor,
        multiplier: factor, constant: dist)
      constraint.isActive = true
      return constraint
  }
  
  /// Pin size (width + height)
  @discardableResult
  func pinSize(_ size: CGSize) -> (width: NSLayoutConstraint, height: NSLayoutConstraint) { 
    return (pinWidth(size.width), pinHeight(size.height))
  }
  
  /// Pin aspect ratio (width/height)
  @discardableResult
  func pinAspect(ratio: CGFloat) -> NSLayoutConstraint {
    translatesAutoresizingMaskIntoConstraints = false
    let constraint = widthAnchor.constraint(equalTo: heightAnchor, multiplier: ratio)
    constraint.isActive = true
    return constraint
  }
  
  static func animate(seconds: Double, delay: Double = 0, closure: @escaping ()->()) {
    UIView.animate(withDuration: seconds, delay: delay, options: .curveEaseOut, 
                   animations: closure, completion: nil)  
  }
  
  /// Centers x axis to superviews x axis
  @discardableResult
  func centerX(_ priority: UILayoutPriority? = nil) -> NSLayoutConstraint? {
    translatesAutoresizingMaskIntoConstraints = false
    guard let sv = self.superview else { return nil }
    return pin(self.centerX, to: sv.centerX, priority: priority)
  }
  
  /// Centers y axis to superviews y axis
  @discardableResult
  func centerY(_ priority: UILayoutPriority? = nil) -> NSLayoutConstraint? {
    translatesAutoresizingMaskIntoConstraints = false
    guard let sv = self.superview else { return nil }
    return pin(self.centerY, to: sv.centerY, priority: priority)
  }
  
  /// Centers  axis to superviews  axis
  @discardableResult
  func center(_ priority: UILayoutPriority? = nil) -> (x: NSLayoutConstraint? ,y: NSLayoutConstraint?)  {
    return (centerX(priority), centerY(priority))
  }
    
} // extension UIView

/// Pin vertical anchor of one view to vertical anchor of another view
@discardableResult
public func pin(_ la: LayoutAnchorY, to: LayoutAnchorY, 
                dist: CGFloat = 0, priority: UILayoutPriority? = nil) -> NSLayoutConstraint {
  la.view.translatesAutoresizingMaskIntoConstraints = false
  let constraint = la.anchor.constraint(equalTo: to.anchor, constant: dist)
  if let prio = priority { constraint.priority = prio }
  constraint.isActive = true
  return constraint
}

/// Pin horizontal anchor of one view to horizontal anchor of another view
@discardableResult
public func pin(_ la: LayoutAnchorX,
                to: LayoutAnchorX,
                dist: CGFloat = 0,
                priority: UILayoutPriority? = nil) -> NSLayoutConstraint {
  la.view.translatesAutoresizingMaskIntoConstraints = false
  let constraint = la.anchor.constraint(equalTo: to.anchor, constant: dist)
  if let prio = priority { constraint.priority = prio }
  constraint.isActive = true
  return constraint
}

/// Pin width/height to width/height of another view
@discardableResult
public func pin(_ la: LayoutDimension, to: LayoutDimension, 
  dist: CGFloat = 0) -> NSLayoutConstraint {
  la.view.translatesAutoresizingMaskIntoConstraints = false
  let constraint = la.anchor.constraint(equalTo: to.anchor, constant: dist)
  constraint.isActive = true
  return constraint
}

/// Pin all edges of one view to the edges of another view
@discardableResult
public func pin(_ view: UIView, to: UIView, dist: CGFloat = 0) -> (top: NSLayoutConstraint, 
  bottom: NSLayoutConstraint, left: NSLayoutConstraint, right: NSLayoutConstraint) {
  let top = pin(view.top, to: to.top, dist: dist)
  let bottom = pin(view.bottom, to: to.bottom, dist: -dist)
  let left = pin(view.left, to: to.left, dist: dist)
  let right = pin(view.right, to: to.right, dist: -dist)
  return (top, bottom, left, right)
}

/// Pin all edges of one view to the edges of another view's safe layout guide
@discardableResult
public func pin(_ view: UIView, toSafe: UIView, dist: CGFloat = 0) -> (top: NSLayoutConstraint, 
  bottom: NSLayoutConstraint, left: NSLayoutConstraint, right: NSLayoutConstraint) {
  let top = pin(view.top, to: toSafe.topGuide(), dist: dist)
  let bottom = pin(view.bottom, to: toSafe.bottomGuide(), dist: -dist)
  let left = pin(view.left, to: toSafe.leftGuide(), dist: dist)
  let right = pin(view.right, to: toSafe.rightGuide(), dist: -dist)
  return (top, bottom, left, right)
}

public typealias tblrConstrains = (
  top: NSLayoutConstraint?,
  bottom: NSLayoutConstraint?,
  left: NSLayoutConstraint?,
  right: NSLayoutConstraint?)

// MARK: - pinnAll Helper
///borders Helper
/// Pin all edges, except one of one view to the edges of another view's safe layout guide
@discardableResult
public func pin(_ view: UIView, to: UIView, dist: CGFloat = 0, exclude: UIRectEdge? = nil) -> tblrConstrains {
  var top:NSLayoutConstraint?, left:NSLayoutConstraint?, bottom:NSLayoutConstraint?, right:NSLayoutConstraint?
  exclude != UIRectEdge.top ? top = NorthLib.pin(view.top, to: to.top, dist: dist) : nil
  exclude != UIRectEdge.left ? left = NorthLib.pin(view.left, to: to.left, dist: dist) : nil
  exclude != UIRectEdge.right ? right = NorthLib.pin(view.right, to: to.right, dist: -dist) : nil
  exclude != UIRectEdge.bottom ? bottom = NorthLib.pin(view.bottom, to: to.bottom, dist: -dist) : nil
  return (top, bottom, left, right)
}

public func pin(_ view: UIView, toSafe: UIView, dist: CGFloat = 0, exclude: UIRectEdge? = nil) -> tblrConstrains {
  var top:NSLayoutConstraint?, left:NSLayoutConstraint?, bottom:NSLayoutConstraint?, right:NSLayoutConstraint?
  exclude != UIRectEdge.top ? top = NorthLib.pin(view.top, to: toSafe.topGuide(), dist: dist) : nil
  exclude != UIRectEdge.left ? left = NorthLib.pin(view.left, to: toSafe.leftGuide(), dist: dist) : nil
  exclude != UIRectEdge.right ? right = NorthLib.pin(view.right, to: toSafe.rightGuide(), dist: -dist) : nil
  exclude != UIRectEdge.bottom ? bottom = NorthLib.pin(view.bottom, to: toSafe.bottomGuide(), dist: -dist) : nil
  return (top, bottom, left, right)
}

/// A simple UITapGestureRecognizer wrapper
open class TapRecognizer: UITapGestureRecognizer {  
  public var onTapClosure: ((UITapGestureRecognizer)->())?  
  @objc private func handleTap(sender: UITapGestureRecognizer) { onTapClosure?(sender) }
  /// Define closure to call upon Tap
  open func onTap(view: UIView, closure: @escaping (UITapGestureRecognizer)->()) { 
    view.isUserInteractionEnabled = true
    view.addGestureRecognizer(self)
    onTapClosure = closure 
  }  
  public init() { 
    super.init(target: nil, action: nil) 
    addTarget(self, action: #selector(handleTap))
  }
}

/// An view with a tap gesture recognizer attached
public protocol Touchable where Self: UIView {
  var tapRecognizer: TapRecognizer { get }
}

extension Touchable {
  /// Define closure to call upon tap
  public func onTap(closure: @escaping (UITapGestureRecognizer)->()) {
    self.tapRecognizer.onTap(view: self, closure: closure)
  }
}

/// A touchable UILabel
public class Label: UILabel, Touchable {
  public var tapRecognizer = TapRecognizer()
}

/// Helpers to add specific UI Attributes just to iOS 13 or not
/// usage.eg: myView.iosLower13?.pinWidth(20)
public extension NSObject{
  var iosLower13 : Self?{
    get{
      if #available(iOS 13, *) {
        return nil
      }
      else {
        return self
        
      }
    }
  }
  
  var iosHigher13 : Self?{
    get{
      if #available(iOS 13, *) {
        return self
      }
      else {
        return nil
      }
    }
  }
}

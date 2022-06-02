//
//  WindowExtensions.swift
//
//  Created by Norbert Thies on 28.02.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit

/// A simple UIWindow extension
public extension UIWindow {

  /// Returns the key window
  static var keyWindow: UIWindow? {
    return UIApplication.shared.windows.first{ $0.isKeyWindow } ?? UIApplication.shared.windows.first
  }
  
  /// Returns the root view controller
  static var rootVC: UIViewController? { return keyWindow?.rootViewController }
  
  /// Returns a snapshot of the key window
  static var snapshot: UIImage? { return keyWindow?.snapshot }
  
  /// Returns a screenshot (ie. snapshot) of the key window
  static var screenshot: UIImage? { return snapshot }
  
  /// Returns the top inset of the window (ie. nodge area)
  static var topInset: CGFloat {
    return keyWindow?.safeAreaInsets.top ?? 0
  }
  
  /// Returns the bottom inset of the window
  static var bottomInset: CGFloat {
    return keyWindow?.safeAreaInsets.bottom ?? 0
  }
  
  /// Returns the max inset for all edges
  static var maxInset: CGFloat {
    let inset = safeInsets
    return max(inset.top, inset.left, inset.bottom, inset.right)
  }
  
  /// Returns the max inset for all edges
  static var maxAxisInset: CGFloat {
    let inset = safeInsets
    return max(inset.top + inset.bottom, inset.left + inset.right)
  }
  
  /// Returns the bottom inset of the window
  static var verticalInsets: CGFloat {
    return safeInsets.top + safeInsets.bottom
  }
  
  /// Returns the bottom inset of the window
  static var horizontalInsets: CGFloat {
    return safeInsets.left + safeInsets.right
  }
  
  /// Returns safe area Insets inset of the window
  static var safeInsets: UIEdgeInsets {
    return keyWindow?.safeAreaInsets ?? .zero
  }
  
  /// Returns size the key window otherwise screen size
  static var size: CGSize {
    if let window = keyWindow {
      return window.frame.size
    }
    return UIScreen.main.bounds.size
  }
  
  /// Returns short side's size of the window
  static var shortSide: CGFloat {
    let s = size
    return min(s.width, s.height)
  }
  
  /// Returns short side's size of the window
  static var longSide: CGFloat {
    let s = size
    return max(s.width, s.height)
  }
  
  /// check if current window's width is smaller than its height
  static var isPortrait: Bool {
    let s = size
    return s.height > s.width
  }
  
  /// check if current window's width is larger than its height
  static var isLandscape: Bool { !UIWindow.isPortrait }

} // UIWindow

/// A simple UIScreen extension
public extension UIScreen {
  /// Returns short side's size of the window
  static var shortSide: CGFloat {
    let s = main.bounds.size
    return min(s.width, s.height)
  }
  
  /// Returns short side's size of the window
  static var longSide: CGFloat {
    let s = main.bounds.size
    return max(s.width, s.height)
  }
}

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
    let app = UIApplication.shared
    if #available(iOS 13, *) {
      return app.windows.first { $0.isKeyWindow }
    }
    else { return app.keyWindow }
  }
  
  /// Returns the root view controller
  static var rootVC: UIViewController? { return keyWindow?.rootViewController }
  
  /// Returns a snapshot of the key window
  static var snapshot: UIImage? { return keyWindow?.layer.snapshot }
  
  /// Returns a screenshot (ie. snapshot) of the key window
  static var screenshot: UIImage? { return snapshot }
  
  /// Returns the top inset of the window (ie. nodge area)
  static var topInset: CGFloat {
    if #available(iOS 11.0, *) {
      if let window = keyWindow { return window.safeAreaInsets.top }
    }
    return 0
  }
  
  /// Returns the bottom inset of the window
  static var bottomInset: CGFloat {
    if #available(iOS 11.0, *) {
      if let window = keyWindow { return window.safeAreaInsets.bottom }
    }
    return 0
  }
  
  /// Returns the bottom inset of the window
  static var verticalInsets: CGFloat {
    if #available(iOS 11.0, *) {
      if let window = keyWindow { return window.safeAreaInsets.top + window.safeAreaInsets.bottom}
    }
    return 0
  }

} // UIWindow

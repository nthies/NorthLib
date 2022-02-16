//
//  HandleRotation.swift
//
//  Created by Norbert Thies on 20.01.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import Foundation

/// The Orientation closure is simply a wrapper around a closure which is
/// called upon orientation changes.
@objc public class OrientationClosure: NSObject {
  
  // The closure to call upon orientation changes
  public var orientationChangedClosure: (()->())? 
  
  // Detect orientation changes and call closure if defined
  @objc public func orientationChangedNotification(notification: Notification) {
    if let closure = self.orientationChangedClosure { closure() }
  }
  
  /// Define the closure to call on orientation changes
  public func onOrientationChange(closure: (()->())?) { 
    if closure != nil {
      UIDevice.current.beginGeneratingDeviceOrientationNotifications()
      NotificationCenter.default.addObserver(self,
        selector: #selector(orientationChangedNotification),
        name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    else if orientationChangedClosure != nil {
      NotificationCenter.default.removeObserver(self)
    }
    orientationChangedClosure = closure 
  }

}

/// HandleOrientation offers a simple method to detect e.g. device rotations (aka
/// orientation changes).
@objc public protocol HandleOrientation: AnyObject {
  /// The closure to call upon orientation changes
  var orientationChangedClosure: OrientationClosure { get set }  
}

public extension HandleOrientation {  
  /// isLandscape returns true if device is rotated to landscape orientation
  var isLandscape: Bool { return UIDevice.current.orientation.isLandscape }
  /// isPortrait returns true if device is rotated to portrait orientation
  var isPortrait: Bool { return UIDevice.current.orientation.isPortrait }
  /// isFaceUp returns true if device is face up
  var isFaceUp: Bool { return UIDevice.current.orientation == .faceUp }
  /// isFaceDown returns true if device is face down
  var isFaceDown: Bool { return UIDevice.current.orientation == .faceDown }
  
  /// Define the closure to call on orientation changes
  func onOrientationChange(closure: (()->())?) { 
    self.orientationChangedClosure.onOrientationChange(closure: closure)
  }
}

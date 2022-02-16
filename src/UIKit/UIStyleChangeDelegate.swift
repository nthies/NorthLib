//
//  AdoptingColorSheme.swift
//  NorthLib
//
//  Created by Ringo on 03.09.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit

public let globalStylesChangedNotification = "globalStylesChanged"

public protocol UIStyleChangeDelegate where Self: UIResponder {
  
  
  /// Function to be called to apply Styles, put your updateable Style Stuff here
  func applyStyles()
  
  /// Register Handler for Current Object
  /// Will call applyStyles() on register @see extension UIStyleChangeDelegate
  /// applyStyles will only be called on iOS 13 the second time if alsoForiOS13AndHigher is true
  /// - Parameter alsoForiOS13AndHigher: also notify if System is iOS 13 and higher
  func registerForStyleUpdates(alsoForiOS13AndHigher:Bool)
}

public extension UIStyleChangeDelegate {
  /// Register Handler for Current Object
  /// execute applyStyles() on call
  /// - Parameter alsoForiOS13AndHigher: add Notification Handler also to iOS 13
  func registerForStyleUpdates(alsoForiOS13AndHigher:Bool = false) {
    self.applyStyles()
    if #available(iOS 13.0, *) {
      if alsoForiOS13AndHigher == true {
        Notification.receive(globalStylesChangedNotification) { [weak self] _ in
          self?.applyStyles()
        }
      }
    } else {
      Notification.receive(globalStylesChangedNotification) { [weak self] _ in
        self?.applyStyles()
      }
    }
  }
}

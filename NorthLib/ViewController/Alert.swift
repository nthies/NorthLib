//
//  Alert.swift
//
//  Created by Norbert Thies on 28.02.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit

/// A wrapper around some UIAlertController using static methods
open class Alert {
  
  /// Popup message to user
  public static func message(title: String? = nil, message: String, closure: (()->())? = nil) {
    self.message(title: title, message: message, closure: closure, additionalActions: nil)
  }
  
  public static func message(title: String? = nil,
                             message: String,
                             closure: (()->())? = nil,
                             additionalActions : [UIAlertAction]? = nil) {
    var actions = additionalActions ?? []
    let okButton = UIAlertAction(title: "OK", style: .cancel) { _ in closure?() }
    actions.append(okButton)
    self.message(title: title, message: message, actions: actions)
  }
  
  public static func message(title: String? = nil,
                             message: String,
                             actions : [UIAlertAction]) {
    onMain {
      let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
      for action in actions {
        alert.addAction(action)
      }
      //present even if there is still a modal View presented
      UIViewController.top()?.present(alert, animated: true, completion: nil)
    }
  }
  
  /// Ask the user for confirmation (as action sheet)
  public static func confirm(title: String? = nil,
                             message: String,
                             okText: String = "OK",
                             cancelText: String = "Abbrechen",
                             isDestructive: Bool = false,
                             closure: ((Bool)->())?) {
    onMain {
      var okStyle: UIAlertAction.Style = .default
      if isDestructive { okStyle = .destructive }
      //Prevent Line Break if no title given
      //message ist automatic title (bold) if no title given!
      let popupMessage = title==nil ? message : "\n\(message)"
      let alert = UIAlertController(title: title, message:popupMessage , preferredStyle: .alert)
      let okButton = UIAlertAction(title: okText, style: okStyle) { _ in closure?(true) }
      let cancelButton = UIAlertAction(title: cancelText, style: .cancel) { _ in closure?(false) }
      alert.addAction(okButton)
      alert.addAction(cancelButton)
      //present even if there is still a modal View presented
      UIViewController.top()?.present(alert, animated: false, completion: nil)
    }
  }

  /// Generates a UIAlertAction
  public static func action(_ title: String, style: UIAlertAction.Style = .default, 
                            closure: @escaping (String)->()) -> UIAlertAction {
    return UIAlertAction(title: title, style: style) {_ in closure(title) }
  }

  /// Presents an action sheet with a number of buttons
  public static func actionSheet(title: String? = nil, message: String? = nil,
                                 actions: [UIAlertAction], completion : (()->())? = nil)  {
    
    /// Add option to store dismiss Handler/completion for actionSheet Function as nested class
    class MyAlertController : UIAlertController {
      var dismissHandler : (()->())?
      override func viewDidDisappear(_ animated: Bool) {
        dismissHandler?()
        super.viewDidDisappear(animated)
      }
    }
    
    onMain {
      var msg: String? = nil
      if let message = message { msg = "\n\(message)" }
      //Use Alert on iPad due provide popoverPresentationControllers Source view is unknown
      let style : UIAlertController.Style = Device.singleton == .iPad ? .alert : .actionSheet
      let alert = MyAlertController(title: title, message: msg, preferredStyle: style)
      let cancelButton = UIAlertAction(title: "Abbrechen", style: .cancel)
      alert.dismissHandler = completion
      for a in actions { alert.addAction(a) }
      alert.addAction(cancelButton)
      UIViewController.top()?.present(alert, animated: true, completion: nil)
    }
  }

  /// Presents an action sheet with a number of buttons
  public static func actionSheet(title: String? = nil, message: String? = nil, 
                                 actions: UIAlertAction...) {
    actionSheet(title: title, message: message, actions: actions)
  }
  
} // Alert

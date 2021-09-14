//
//  Notification.swift
//
//  Created by Norbert Thies on 27.04.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import Foundation

public extension Notification {
  
  typealias Observer = NSObjectProtocol?
  
  /// The sender of a Notification
  var sender: Any? { return object }

  /// info returns value from userInfo
  func info(_ key: String) -> Any? {
    guard let dict = userInfo, let cont = dict[key] else { return nil }
    return cont
  } 
  
  /// The content having been sent
  var content: Any? { info("content") }
  
  /// Has an Error been sent?
  var error: Error? { info("error") as? Error }
  
  /**
   If the Notification has been received via 'receive', this method removes the
   Observer defined by 'receive' and thereby withdraws from further Notifications
   */
  func withdraw() {
    guard let dict = userInfo, let observer = dict["observer"] as? NSObjectProtocol 
      else { return }
    Notification.remove(observer: observer)
  }
  
  /// Send Notification
  static func send(_ message: String, content: Any? = nil, error: Error? = nil, 
                   sender: Any? = nil) {
    let nn = NSNotification.Name(message)
    var dict: [AnyHashable:Any] = [:]
    dict["content"] = content
    dict["error"] = error
    let notification = Notification(name: nn, object: sender, userInfo: dict)
    NotificationCenter.default.post(notification)
  }
  
  /// Send Result<Type,Error> as Notification
  static func send<Type>(_ message: String, result: Result<Type,Error>, 
                         sender: Any? = nil) {
    if let err = result.error() {
      send(message, error: err, sender: sender)
    }
    else if let val = result.value() {
      send(message, content: val, sender: sender)
    }
    else {
      send(message, content: nil, sender: sender)
    }
  }
  
  /// Receive Notification and return observer object
  @discardableResult
  static func receive(_ message: Notification.Name, from: Any? = nil,
                      closure: @escaping (Notification)->()) 
    -> Observer {
    var observer: Observer = nil
    observer = NotificationCenter.default.addObserver(forName: message, 
                     object: from, queue: nil) { notification in
      var notif = notification
      var dict: [AnyHashable:Any] = [:]
      if let passedDict = notification.userInfo { dict = passedDict }
      dict["observer"] = observer
      notif.userInfo = dict
      closure(notif)
    }
    return observer
  }
  
  /// Receive Notification and return observer object
  @discardableResult
  static func receive(_ message: String, from: Any? = nil,
                      closure: @escaping (Notification)->()) 
    -> Observer {
    return receive(NSNotification.Name(message), from: from, closure: closure)
  }
  
  /// Receive Notification and remove observer imediately after receival
  static func receiveOnce(_ message: Notification.Name, from: Any? = nil,
                          closure: @escaping (Notification)->()) {
    receive(message) { notif in
      notif.withdraw()
      closure(notif)
    }
  }
  
  /// Receive Notification and remove observer imediately after receival
  @discardableResult
  static func receiveOnce(_ message: String, from: Any? = nil,
                          closure: @escaping (Notification)->()) -> Observer {
    return receive(message) { notif in
      notif.withdraw()
      closure(notif)
    }
  }
  
  /// Remove observer
  static func remove(observer: Observer) {
    if let observer = observer {
      NotificationCenter.default.removeObserver(observer)
    }
  }
  
} // Notification Extensions

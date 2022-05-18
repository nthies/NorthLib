//
//  ObjectExtension.swift
//  NorthLib
//
//  Created by Ringo Müller on 10.02.21.
//  Copyright © 2021 Norbert Thies. All rights reserved.
//

import Foundation

func hash(_ obj : AnyObject) -> String {
    return String(UInt(bitPattern: ObjectIdentifier(obj)))
}

extension NSObject {
  var hash : String {
    get {
      return String(UInt(bitPattern: ObjectIdentifier(self)))
    }
  }
}


private class OnceExecutedHelper {
  fileprivate static let sharedInstance = OnceExecutedHelper()
  private init(){}
  var timedRun:[String:Date]=[:]
}

public extension String {
  /// Check if entry for given key exists since appStart and time Interval is smaller than given timeInterval
  /// - Parameter intervall: interval to use; default 1 Hour
  /// - Returns: true if exists and not expired
  func existsAndNotExpired(intervall:TimeInterval? = TimeInterval.hour) -> Bool {
    if self.length == 0 {Log.log("failed to execute"); return false }
    
    guard let last = OnceExecutedHelper.sharedInstance.timedRun[self] else {
      OnceExecutedHelper.sharedInstance.timedRun[self] = Date()
      return false
    }
    
    guard let ti = intervall else {  return true }
    if Date().timeIntervalSince(last) < ti { return true }
    
    OnceExecutedHelper.sharedInstance.timedRun[self] = Date()
    return false
  }
}


public extension NSObject {
    
  /// Helper to execute code on the current object (or on a key) once once; or after a lock period has expired.
  /// - Parameters:
  ///   - identifier: id to check; default is bundlename.classname of current/chained object
  ///   - repeatingMinutes: period after last last positive check is expired, nil for only once execution
  /// - Returns: self if still not used or period expired; otherwise nil
  func once(_ identifier:String?=nil, intervall:TimeInterval? = nil) -> Self? {
    let id:String = identifier ?? String(reflecting:self.classForCoder)
    return id.existsAndNotExpired(intervall: intervall) ? nil : self
  }

  /// Helper to chain and execute something on an object once per app execution lifecycle
  var once: Self? { get { return once()} }
  var onceDaily: Self? { get { return once(intervall: .day)} }
  var onceEveryMinute: Self? { get { return once(intervall: .minute)} }
}

/// Helpers to add specific UI Attributes just to iOS 13 or not
/// usage.eg: myView.iosLower13?.pinWidth(20)
public extension NSObject{
  var iosLower14 : Self?{
    get{
      if #available(iOS 14, *) {
        return nil
      }
      else {
        return self
        
      }
    }
  }
  
  var iosHigher14 : Self?{
    get{
      if #available(iOS 14, *) {
        return self
      }
      else {
        return nil
      }
    }
  }
}

public var gt_iOS14 : Bool {
  if #available(iOS 14, *) { return true }
  return false
}

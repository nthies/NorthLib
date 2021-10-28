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

/// Helper to check if identifier has been used since app start
/// - Parameters:
///   - identifier: id to check
///   - repeatingMinutes: period after last last positive check is expired
/// - Returns: true if still not used or period expired; otherwise false
public func once(identifier:String, repeatingMinutes: Int? = nil) -> Bool {
  if identifier.length == 0 {Log.log("failed to execute"); return false }
  guard let last = OnceExecutedHelper.sharedInstance.timedRun[identifier] else {
    OnceExecutedHelper.sharedInstance.timedRun[identifier] = Date()
    return true
  }
  guard let min = repeatingMinutes else {  return false }
  if Date().timeIntervalSince(last) < Double(min)*60.0 { return false }

  OnceExecutedHelper.sharedInstance.timedRun[identifier] = Date()
  return true
}

public extension NSObject {
    
  /// Helper to cain and execute to check if identifier has been used since app start
  /// - Parameters:
  ///   - identifier: id to check; default is bundlename.classname
  ///   - repeatingMinutes: period after last last positive check is expired
  /// - Returns: self if still not used or period expired; otherwise nil
  func once(_ identifier:String?=nil, repeatingMinutes: Int? = nil) -> Self? {
    let id:String = identifier ?? String(reflecting:self.classForCoder)
    return NorthLib.once(identifier:id, repeatingMinutes: repeatingMinutes) ? self : nil
  }
  
  /// Helper to chain and execute something on an object once per app execution lifecycle
  var once: Self? { get { return once()} }
  var onceDaily: Self? { get { return once(repeatingMinutes: 60*24)} }
  var onceEveryMinute: Self? { get { return once(repeatingMinutes: 1)} }
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

public var gt_iOS13 : Bool {
  if #available(iOS 13, *) { return true }
  return false
}


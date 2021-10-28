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

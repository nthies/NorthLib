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

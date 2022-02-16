//
//  CGFloatUIKit.swift
//  NorthLib
//
//  Created by Norbert Thies on 20.06.21.
//  Copyright © 2021 Norbert Thies. All rights reserved.
//

import UIKit

/// Make CGFloat StringConvertible for use in KVStore
extension CGFloat: StringConvertible {
  public static func fromString(_ str: String?) -> Self {
    if let str = str, let d = Double(str) { return Self(d) }
    return 0
  }
  public static func toString(_ val: Self) -> String { "\(val)" }
}

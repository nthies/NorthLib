//
//  DefaultsUIKit.swift
//  NorthLib
//
//  Created by Norbert Thies on 20.06.21.
//  Copyright © 2021 Norbert Thies. All rights reserved.
//

import UIKit

public extension Defaults {
  /// Let Defaults.singleton add a scope of the current Device name
  static var singleton: Defaults = {
    let defaults = Defaults()
    defaults.addScope(Device.singleton.description)
    return defaults
  }()
}


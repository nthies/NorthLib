//
//  KVStoreUIKit.swift
//  NorthLib
//
//  Created by Norbert Thies on 20.06.21.
//  Copyright © 2021 Norbert Thies. All rights reserved.
//

import UIKit

public extension KVStore {
  /// Initialize with optional name and optional suite name, add the device
  /// name as additional scope.
  convenience init(base: KVStoreBase, name: String? = nil, 
                          suite: String? = nil) {
    self.init(base: base, name: name, suite: suite, 
              device: Device.singleton.description)
  }
}

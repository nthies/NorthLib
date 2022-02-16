//
//  ThreadExtensions.swift
//  NorthLib
//
//  Created by Norbert Thies on 30.06.21.
//  Copyright © 2021 Norbert Thies. All rights reserved.
//

import Foundation

public extension Thread {
  /// Id of the current thread
  static var id: Int64 { Thr.id }
  /// thread id of main thread
  static var mainId: Int64 { Thr.mainId }
  /// Are we on main thread
  static var isMain: Bool { Thr.isMain }
}

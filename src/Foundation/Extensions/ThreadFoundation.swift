//
//  ThreadExtensions.swift
//  NorthLib
//
//  Created by Norbert Thies on 30.06.21.
//  Copyright © 2021 Norbert Thies. All rights reserved.
//

import Foundation

public extension Thread {
  static var id: Int64 { Int64(thread_id(thread_current())) }
}

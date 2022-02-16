//
//  DoesLog.swift
//
//  Created by Norbert Thies on 21.08.17.
//  Copyright © 2017 Norbert Thies. All rights reserved.
//


/// Protocol to adopt from types which like to use self.log, self.debug, ...
public protocol DoesLog {
  /// Whether logging in this type is enabled or not
  var isDebugLogging: Bool { get }
}

extension DoesLog {
  /// By default debug logging is enabled
  public var isDebugLogging: Bool {
    get { return true }
  }
}

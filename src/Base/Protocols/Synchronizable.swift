//
//  Synchronizable.swift
//
//  Created by Norbert Thies on 20.01.22.
//  Copyright © 2022 Norbert Thies. All rights reserved.
//

/**
 * Synchronizable is intended as protocol for actors offering a simple method
 * _sync_ to synchronize some closure on this actor.
 */
public protocol Synchronizable {
  /// Synchronize with other closures performed on this actor
  @discardableResult
  func sync<Result>(_ closure: () throws -> Result) async rethrows -> Result
}

extension Synchronizable {
  /// Synchronize with other closures performed on this actor
  @discardableResult
  func sync<Result>(_ closure: () throws -> Result) async rethrows -> Result {
    try closure()
  }
  func sync<Result>(_ closure: () async throws -> Result) async rethrows -> Result {
    try await closure()
  }
}

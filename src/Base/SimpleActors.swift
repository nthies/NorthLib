//
//  Counter.swift
//
//  Created by Norbert Thies on 14.01.22.
//

/**
 * The Counter actor offers methods to synchronize access to an Int counter
 * and to offer a method 'sync' to synchronize closures.
 */
public actor Counter {
  
  /// The Int counter
  public var value: Int = 0
  
  /// Increment operation returning the incremented value
  public func inc() -> Int { value += 1; return value }
  
  /// Synchronize with other closures performed on this actor
  @discardableResult
  func sync<Result>(_ closure: () throws -> Result) rethrows -> Result {
    try closure()
  }
  
  /// Initialize with optional start value (by default 0)
  public init(_ val: Int = 0) { value = val }
  
} // actor Counter

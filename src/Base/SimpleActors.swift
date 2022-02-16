//
//  SimpleActors.swift
//
//  Created by Norbert Thies on 14.01.22.
//

/**
 * Sync is a trivial actor just offering the method _sync_ via the Synchronizable
 * protocol.
 */
public actor Sync: Synchronizable {}

/**
 * The Counter actor offers methods to synchronize access to an Int counter
 * and to offer a method 'sync' to synchronize closures.
 */
public actor Counter: Synchronizable {
  
  /// The Int counter
  public var value: Int = 0
  
  /// Increment operation returning the incremented value
  public func inc() -> Int { value += 1; return value }
  
  /// Decrement operation returning the decremented value
  public func dec() -> Int { value -= 1; return value }
  
  /// Initialize with optional start value (by default 0)
  public init(_ val: Int = 0) { value = val }
  
} // actor Counter

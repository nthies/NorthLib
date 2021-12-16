//
//  Globals.swift
//
//  Created by Norbert Thies on 20.12.18.
//  Copyright © 2018 Norbert Thies. All rights reserved.
//
//  This file implements various global functions.
//

import Foundation

/**
 Executes the passed closure on one of the system's global dispatch queues
 depending on the given quality of service *qos*.
 
 The system maintains a number of threads with different scheduling priorities.
 Using the argument *qos* you select an appropriate thread with its dispatch queue
 for the execution of *closure* concurrently to the main thread.
 If given with the argument *after* the execution is delayed by *after* seonds.
 
 - Parameters:
   - qos: quality of service (default: .userInitiated)
   - after: Number of seconds to defer the execution
   - queue: optional dispatch queue to execute *closure* on
   - closure: closure to execute
 */
public func async(qos: DispatchQoS.QoSClass = .userInitiated, after seconds: Double = 0,
                  queue q: DispatchQueue? = nil, closure: @escaping ()->()) {
  let queue: DispatchQueue = q ?? DispatchQueue.global(qos: qos)
  if seconds =~ 0.0 {
    let deadline = DispatchTime.now() + seconds
    queue.asyncAfter(deadline: deadline, execute: closure)
  }
  else { queue.async(execute: closure) }
}

/**
 Executes the passed closure asynchronously on main thread.
 
 Similar to the global *async* function *onMain* executes a closure asynchronously.
 Unlike *async* the closure is started on the main thread, ie. that thread which
 performs all user interaction.
 
 - Parameters:
   - after: Number of seconds to defer the execution
   - closure: closure to execute
 */
public func onMain(after seconds: Double = 0, closure: @escaping ()->()) {
  async(after: seconds, queue: DispatchQueue.main, closure: closure)
}

/// Ensures that the passed closure is executed in the main thread.
/// If the current thread is already the main thread, the closure is executed immediately,
/// otherwise it is executed asynchronously on main.
/// - Parameter closure: closute to execute
public func ensureMain(closure: @escaping ()->()) {
  if Thread.isMainThread {
    closure()
  }
  else {
    async(after: 0, queue: DispatchQueue.main, closure: closure)
  }
}


/// Delays execution of a closure on the main thread for a number of seconds
public func delay(seconds: Double, closure: @escaping ()->()) {
  onMain(after: seconds, closure: closure)
}

/// Calls a closure every n seconds on current thread
@discardableResult
public func every(seconds: Double, closure: @escaping (Timer)->()) -> Timer {
  return Timer.scheduledTimer(withTimeInterval: seconds, repeats: true, 
                              block: closure)
}

/// perform closure on on main thread after given timeout
/// - Parameters:
///   - timeout: timeout to wait before execute in seconds, default 0,2s
///   - closure: closure to execute
public func onMainAfter(_ timeout : Double = 0.2,
                        closure: @escaping ()->()) {
  DispatchQueue.main.asyncAfter(deadline: .now() + timeout,
                                execute: closure)
}

/// perform closure on own thread
/// - Parameter closure: closure to execute
public func onThread(closure: @escaping ()->()) {
  DispatchQueue.global().async(execute: closure)
}

/// perform closure on own thread after given timeout
/// - Parameters:
///   - timeout: timeout to wait before execute in seconds, default 0,2s
///   - closure: closure to execute
public func onThreadAfter(_ timeout : Double = 0.2,
                          closure: @escaping ()->()) {
  DispatchQueue.global().asyncAfter(deadline: .now() + timeout,
                                    execute: closure)
}

/// returns the type name of an object as String
public func typeName<T>(_ obj: T) -> String { return "\(type(of:obj))" }

/// Returns a path to a unique temporary file
public func tmppath() -> String {
  let dir = FileManager.default.temporaryDirectory
  let uuid = UUID().uuidString
  return "\(dir.path)/\(uuid).tmp"
}

/// Returns address of raw pointer
public func address(_ obj: UnsafeRawPointer) -> Int { Int(bitPattern: obj) }

/// Returns address of object
public func address<T>(_ obj: T) -> Int { unsafeBitCast(obj, to: Int.self) }

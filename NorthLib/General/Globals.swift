//
//  Globals.swift
//
//  Created by Norbert Thies on 20.12.18.
//  Copyright © 2018 Norbert Thies. All rights reserved.
//
//  This file implements various global functions.
//

import Foundation

/// delays execution of a closure for a number of seconds
public func delay(seconds: Double, completion:@escaping ()->()) {
  DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { completion() }
}

/// Calls a closure every n seconds
@discardableResult
public func every(seconds: Double, closure: @escaping (Timer)->()) -> Timer {
  return Timer.scheduledTimer(withTimeInterval: seconds, repeats: true, 
                              block: closure)
}

/// perform closure on main thread
public func onMain(closure: @escaping ()->()) {
  if !Thread.isMainThread {
    DispatchQueue.main.async(execute: closure)
  }
  else { closure() }
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

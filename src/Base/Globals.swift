//
//  Globals.swift
//
//  Created by Norbert Thies on 20.12.18.
//  Copyright © 2018 Norbert Thies. All rights reserved.
//
//  This file implements various global functions.
//


/// returns the type name of an object as String
public func typeName<T>(_ obj: T) -> String { return "\(type(of:obj))" }

/// Returns address of raw pointer
public func address(_ obj: UnsafeRawPointer) -> Int { Int(bitPattern: obj) }

/// Returns address of object
public func address<T>(_ obj: T) -> Int { unsafeBitCast(obj, to: Int.self) }

/// Cast a reference object to C's _void pointer_
func voidptr<T: AnyObject>(obj: T) -> UnsafeMutableRawPointer {
  return UnsafeMutableRawPointer(Unmanaged.passUnretained(obj).toOpaque())
}

/// Cast C's _void pointer_ to a reference object
func voidptr<T: AnyObject>(ptr: UnsafeRawPointer) -> T {
  return Unmanaged<T>.fromOpaque(ptr).takeUnretainedValue()
}

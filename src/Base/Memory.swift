//
//  Memory.swift
//  
//  Created by Norbert Thies on 10.01.22.
//
//  class Memory provides an allocated pointer to a memory area.
//

import NorthLowLevel

public class Memory: Copying {
  
  public var ptr: UnsafeMutableRawPointer?
  public var length: Int
  public var count: Int { self.length }
  
  /// Initialize from raw pointer and #bytes to copy
  public init(ptr: UnsafeRawPointer?, length: Int) {
    self.ptr = mem_heap(ptr, length)
    self.length = Int(length)
  }
  
  /// Just allocate the number of bytes specified
  public init(length: Int) {
    self.ptr = mem_heap(nil, length)
    self.length = length
  }
  
  /// Initialize a Memory object with a reference to the passed pointer, no data
  /// is copied.
  public init (allocated: UnsafeMutableRawPointer?, length: Int32) {
    self.ptr = allocated
    self.length = Int(length)
  }
  
  /// Initialize with nil pointer
  public init() { ptr = nil; length = 0 }
  
  /// Bind pointer to UnsafeMutablePointer<T>
  func pointer<T>() -> UnsafeMutablePointer<T>? {
    ptr?.assumingMemoryBound(to: T.self)
  }
  
  /// Remove the allocated memory
  deinit {
    mem_release(&(self.ptr))
  }
  
  /// Resize to new size (typically re-allocated)
  func resize(length: Int) {
    self.ptr = mem_resize(ptr, length)
    self.length = length
  }
  
  /// Return a newly allocated Memory area and copy the contents
  public func clone() -> Memory { Memory(ptr: self.ptr, length: self.length) }
  
  public required convenience init(_ val: Memory) throws {
    self.init(ptr: val.ptr, length: val.length)
  }
  
  /// Returns the Data as UTF-8 String
  public var string: String {
    mem_0byte(&ptr, &length)
    return String(validatingUTF8: pointer()!)!
  }
  
  /// Returns the data as a String of hex digits.
  public var hex: String {
    let cstr = data_toHex(pointer(), count)
    let str = String(validatingUTF8: cstr!)
    free(cstr)
    return str!
  }
  
  /// Returns the md5 sum as a String of hex digits.
  public var md5: String {
    let cstr = hash_md5(pointer(), count)
    let str = String(validatingUTF8: cstr!)
    free(cstr)
    return str!
  }

  /// Returns the sha1 sum as a String of hex digits.
  public var sha1: String {
    let cstr = hash_sha1(pointer(), count)
    let str = String(validatingUTF8: cstr!)
    free(cstr)
    return str!
  }
  
  /// Returns the sha256 sum as a String of hex digits.
  public var sha256: String {
    let cstr = hash_sha256(pointer(), count)
    let str = String(validatingUTF8: cstr!)
    free(cstr)
    return str!
  }

}  // Memory

//
//  MemoryFoundation.swift
//  
//  Created by Norbert Thies on 10.01.22.
//
//  Memory extension to support Foundation's Data type
//

import Foundation

extension Memory {
  
  /// Provide Data as copy of the memory area
  public var data: Data? {
    if let p = ptr {
      return Data(bytes: p, count: Int(length))
    }
    return nil
  }
  
  /// Provide Data by moving the pointer (and thereby the data) to it
  public func moveToData() -> Data? {
    defer { ptr = nil; length = 0 }
    if let p = ptr {
      return Data(bytesNoCopy: p, count: Int(length), deallocator: .free)
    }
    return nil
  }
  
  /// Initialize with a copy from the given Data object
  convenience init(data: Data) {
    self.init(length: data.count)
    if let ptr = ptr {
      let p = ptr.assumingMemoryBound(to: UInt8.self)
      data.copyBytes(to: p, count: data.count)
    }
  }
  
}

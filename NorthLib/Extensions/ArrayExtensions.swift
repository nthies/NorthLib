//
//  ArrayExtensions.swift
//
//  Created by Norbert Thies on 12.12.18.
//  Copyright © 2018 Norbert Thies. All rights reserved.
//

import Foundation

public extension Array {
  
  /// appends one Element to an array
  @discardableResult
  static func +=(lhs: inout Array<Element>, rhs: Element) -> Array<Element> {
    lhs.append(rhs)
    return lhs
  }

  /// appends an array to an array
  @discardableResult
  static func +=(lhs: inout Array<Element>, rhs: Array<Element>) -> Array<Element> {
    lhs.append(contentsOf: rhs)
    return lhs
  }
  
  /// removes first element
  @discardableResult
  mutating func pop() -> Element? { 
    return self.isEmpty ? nil : self.removeFirst() 
  }
  
  /// appends one element at the end
  mutating func push(_ elem: Element) { self.append(elem) }  
  
  /// rotates elements clockwise (n >0) or anti clockwise (n<0)
  func rotated(_ n: Int) -> Array {
    var ret: Array = []
    if n > 0 {
      ret += self[n..<count]
      ret += self[0..<n]
    }
    else if n < 0 {
      let from = count + n
      ret += self[from..<count]
      ret += self[0..<from]
    }
    else { ret = self }
    return ret
  }
  
  /// creates a copy of the array
  func copy() -> Array {
    self.map { ($0 as! NSCopying).copy() as! Element }
  }
  
  ///Safe acces to Array Items by Index returns null if Index did not exist
  func valueAt(_ index : Int) -> Element?{
    return self.indices.contains(index) ? self[index] : nil
  }
  
} // Array

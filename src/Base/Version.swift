//
//  Version.swift
//
//  Created by Norbert Thies on 22.06.18.
//  Copyright © 2018 Norbert Thies. All rights reserved.
//

import Foundation


/// The Version class offers comparisions of version numbers.
/// 
/// E.g. after:
/// ````
///   let v1 = Version( "1.0" )
///   let v2 = Version( "1.2" )
/// ````
/// you may use:
/// ````
///     v1 < v2; v1 == v2; v1[0]; print(v2)
/// ````
///
open class Version: Comparable, CustomStringConvertible {
  
  public var version: [Int] = []
  public var count: Int { return version.count }
  public var description: String { return toString() }
  
  public init() {}
  
  public init( _ ver: String ) {
    self.fromString(ver)
  }
  
  /// Reads a version number from a String.
  /// - parameters:
  ///   - ver: Version String, e.g. "1.2.0" 
  public func fromString( _ ver: String ) {
    let varray = ver.allMatches(regexp: "[0-9]+")
    self.version = []
    varray.forEach { str in
      self.version.append(Int(str)!)
    }
  }
  
  public func toString() -> String {
    if self.count > 0 {
      var ret = ""
      self.version.forEach { n in
        if ret.count > 0 { ret += "." }
        ret += n.description
      }
      return ret
    }
    else { return "0" }
  }
  
  public subscript( i: Int ) -> Int {
    get {
      if i >= version.count { return 0 }
      else { return version[i] }
    }
    set(val) {
      if version.count <= i {
        var j = version.count
        while j <= i { version.append(0); j += 1 }
      }
      version[i] = val
    }
  }
  
  static public func <(lhs: Version, rhs: Version) -> Bool {
    let n = max(lhs.count, rhs.count)
    var i = 0
    while (i < n) && (lhs[i] == rhs[i]) { i += 1 }
    return lhs[i] < rhs[i]
  }
  
  static public func ==(lhs: Version, rhs: Version) -> Bool {
    let n = max(lhs.count, rhs.count)
    var i = 0
    while (i < n) && (lhs[i] == rhs[i]) { i += 1 }
    return lhs[i] == rhs[i]
  }
  
} // class Version

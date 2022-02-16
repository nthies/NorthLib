//
//  Version.swift
//
//  Created by Norbert Thies on 22.06.18.
//  Copyright © 2018 Norbert Thies. All rights reserved.
//

/**
 * The Version class offers comparisions of version numbers.
 *
 * Internally a Version is an array of integers that is externally represented
 * as a series of numbers *vnum* delimited by a dot character, eg. "1.0.14".
 * This implementation supports an unlimited sequence of *vnum*s.
 *
 * Over the last few years the notion of semantic versioning (SemVer) has been more
 * and more adopted, thus we are offering limited support for it. SemVers use
 * exactly 3 *vnum*s, eg. 1.9.24. Or in general:
 * ````
 *   SemVer := <major>.<minor>.<patch>
 * ````
 * where:
 * * \<major\>: Major version number defining API compatibility, ie. APIs of same
 *            major version number are compatible to each other (no breaking
 *            changes).
 * * \<minor\>: Denote code changes in one major version (compatible new features)
 * * \<patch\>: Denote bug fixes (no new features)
 *
 * An indroduction to semantic versioning is available at
 * [geeksforgeeks.org](https://www.geeksforgeeks.org/introduction-semantic-versioning/).
 * A more formal definition is at [semver.org](https://semver.org/). However we
 * are currently providing **numeric only** versions that may have more than 3 *vnum*s.
 *
 * To compare *Versions* you may use the following code:
 * ````
 *   let v1 = Version( "1.0.1" )
 *   let v2 = Version( "1.2.0" )
 *   v1 < v2, v1 == v2, v1[0], ...
 * ````
 */
open class Version: Comparable, CustomStringConvertible, ToString {
  
  /// Version numbers are stored as Array<Int>
  private(set) var version: [Int] = []
  
  /// Number of *vnum*s in array
  public var count: Int { version.count }
  
  /// Returns representation as String
  public var description: String { toString() }
  
  /// Returns major version number of SemVer
  public var major: Int { self[0] }
  
  /// Returns minor version number of SemVer
  public var minor: Int { self[1] }
  
  /// Returns patch version number of SemVer
  public var patch: Int { self[2] }
  
  /// Returns true if the given Version is SemVer compatible to self
  public func isCompatible(ver: Version) -> Bool { self.major == ver.major }
  
  /// Empty Version
  public init() {}
  
  /// Create Version from String, eg. "1.20.4"
  public init(_ ver: String) {
    self.fromString(ver)
  }
  
  /**
   * Reads a version number from a String.
   *
   * - parameters:
   *   - ver: Version String, e.g. "1.2.0"
   */
  public func fromString(_ ver: String) {
    if let varray = ver.gmatch("@d+") {
      self.version = varray.map { Int($0[0]) ?? 0 }
    }
  }
  
  /// Returns a String representation, eg. "2.4.16"
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
  
  /**
    * Access the i'th *vnum* of the version.
    *
    * If *i* is larger than the size of *version* the following rules apply:
    * - get: 0 is returned
    * - set: all undefined *vnum*s at positions smaller than *i* are set to 0
    */
  public subscript(i: Int) -> Int {
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
  
  /**
   * Version comparision
   *
   * Version a is smaller than Version b, if the first *vnum* of a that is
   * not equal to the *vnum* of b at the same position is smaller than the
   * corresponding *vnum* of b.
   */
  static public func <(lhs: Version, rhs: Version) -> Bool {
    let n = max(lhs.count, rhs.count)
    var i = 0
    while (i < n) && (lhs[i] == rhs[i]) { i += 1 }
    return lhs[i] < rhs[i]
  }
  
  /// Two Versions are equal if all *vnum*s are equal.
  static public func ==(lhs: Version, rhs: Version) -> Bool {
    let n = max(lhs.count, rhs.count)
    var i = 0
    while (i < n) && (lhs[i] == rhs[i]) { i += 1 }
    return lhs[i] == rhs[i]
  }
  
} // class Version

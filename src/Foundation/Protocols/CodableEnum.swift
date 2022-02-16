//
//  CodableEnum.swift
//
//  Created by Norbert Thies on 28.06.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import Foundation

/// An Error that may be thrown during encoding/decoding
public struct CodingError: SimpleError {  
  var msg: String
  public var description: String { 
    return "CodingError: \(msg)" 
  }
}

/// An extension to CaseIterable having enums refer to a rawValue's index
public extension CaseIterable where Self: Equatable {
  var index: Self.AllCases.Index? {
    return Self.allCases.firstIndex { self == $0 }
  }
}

/**
 A CodableEnum is an enum using a String as rawValue which may hold two distinct
 values used during encoding/decoding and to represent the enum as String.
 
 All enum cases are expected to be Strings in the form of:
   case := substring1 ["(" substring2 ")"]
 Each substring is an arbitrary string not containing "()" characters.
 The first substring defines the string used to represent the enums case, ie.
 this is the String returned by 'representation'. If no second 
 substring is given then substring1 also serves as Codable value, ie. is 
 expected as representation when encoding or decoding the enum.
 
 Eg. the following code shows an enum using two cases with two substrings and 
 one case with a single string:
 
     enum TestEnum: String, CodableEnum {
       case one = "one(ONE)"
       case two = "two(TWO)"
       case three = "three"
     }
 
 Here TestEnum.one.representattion will yield "one" but the Encoder will 
 get "ONE".
 If decoding an unknown external representation the value of the enum will
 be set to the value associated with the String "unknown". If such a case is 
 not defined an Error will be thrown.
 */
public protocol CodableEnum: RawRepresentable, CaseIterable, Codable, 
  DoesLog, ToString {
  var rawValue: String { get }
}

public extension CodableEnum {

  /// The representation in case of an unknown rawValue
  static var unknownCase: String { "unknown" }
  
  /// Returns both substrings as tuple
  var pair: (String, String?)? {
    let m = rawValue.groupMatches(regexp: #"([^\(]+)(?:\(([^)|]+)\))?"#)
    if m.count == 1, m[0].count == 3, m[0][1].count > 0 {
      let first = m[0][1]
      let second = (m[0][2].count > 0) ? m[0][2] : nil
      return (first, second)
    }
    else { return nil }
  }
  
  /// Returns the second substring if available, the first otherwise,
  /// this is the external representation used per encode/decode
  var external: String {
    if let p = pair { return (p.1 != nil) ? p.1! : p.0 }
    else { return rawValue }
  }
  
  /// Returns the enum's internal String representation, ie. the first substring
  var representation: String {
    if let p = pair { return p.0 }
    else { return rawValue }    
  }
  
  /// Returns the enums String representation, ie. the first substring
  func toString() -> String { rawValue }
  
  /// Return the enum's value from its internal representation
  static func fromInternal(_ str: String) -> Self? {
    for v in Self.allCases {
      if str == v.representation { return v }
    }
    return nil
  }
  
  /// Return the enum's value from its external representation
  static func fromExternal(_ str: String) -> Self? {
    for v in Self.allCases {
      if str == v.external { return v }
    }
    return nil
  }
  
  /// Initialize from a Decoder - use external substring if available
  init (from decoder: Decoder) throws {
    let s = try decoder.singleValueContainer().decode(String.self)
    if let val = Self.fromExternal(s) { self = val }
    else {
      let err = CodingError(msg: "\(Self.self): Can't decode \"\(s)\"")
      Log.error(err)
      if let val = Self.fromInternal(Self.unknownCase) { self = val }
      else { throw err }
    }
  } 
  
  /// Initialize from internal representation (ie. self.representation)
  init?(_ str: String) {
    if let val = Self.fromInternal(str) { self = val }
    else { return nil }
  }
  
  /// Encode using second substring (if available)
  func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    try container.encode(external)
  }
  
} // CodableEnum

//
//  UsTime.swift
//
//  Created by Norbert Thies on 06.07.18.
//  Copyright © 2018 Norbert Thies. All rights reserved.
//


/**
 Time as seconds and microseconds since 1970-01-01 00:00:00 UTC
 
 This struct is a simple wrapper around the timeval() library struct.
 */ 
public struct UsTime: Comparable {
  
  private var tv = timeval()
  public var sec: Int64 { return Int64(tv.tv_sec) }
  public var usec: Int64 { return Int64(tv.tv_usec) }
  public var double: Double { Double(sec) + (Double(usec) / 1000000.0) }
  
  /// Returns the current time
  public static func now() -> UsTime {
    var ut = UsTime()
    gettimeofday(&(ut.tv), nil)
    return ut
  }
  
  /// Init from number of seconds since 00:00:00 1970 UTC
  public init(_ nsec: Int64) {
    tv.tv_sec = type(of: tv.tv_sec).init(nsec)
  }
  
  /// Init from number of seconds since 00:00:00 1970 UTC expressed as String
  public init(_ nsec: String) {
    if let ns = Int64(nsec) {
      tv.tv_sec = type(of: tv.tv_sec).init(ns)
    }
  }
  
  static public func <(lhs: UsTime, rhs: UsTime) -> Bool {
    if lhs.sec == rhs.sec { return lhs.usec < rhs.usec }
    else { return lhs.sec < rhs.sec }
  }
  
  static public func ==(lhs: UsTime, rhs: UsTime) -> Bool {
    return (lhs.sec == rhs.sec) && (lhs.usec == rhs.usec)
  }
  
}  // struct UsTime

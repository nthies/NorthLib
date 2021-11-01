//
//  Time.swift
//
//  Created by Norbert Thies on 06.07.18.
//  Copyright © 2018 Norbert Thies. All rights reserved.
//

import Foundation

public extension Date {
  
  /// Returns components relative to gregorian calendar in optionally given time zone
  func components(tz: String? = nil) -> DateComponents {
    var cal = Calendar.current
    if let tz = tz {
      if let tmp = TimeZone(identifier: tz) {
        cal = Calendar(identifier: .gregorian)
        cal.timeZone = tmp
      }
    }
    let cset = Set<Calendar.Component>([.year, .month, .day, .hour, .minute, .second, .weekday])
    return cal.dateComponents(cset, from: self)    
  }
 
  /// Returns a String as ISO-Date/Time, ie. "YYYY-MM-DD hh:mm:ss"
  func isoTime(tz: String? = nil) -> String {
    let dc = components(tz: tz)
    return String(format: "%04d-%02d-%02d %02d:%02d:%02d.%06d", dc.year!, dc.month!,
                  dc.day!, dc.hour!, dc.minute!, dc.second!)
  }
 
  /// Returns a String as ISO-Date, ie. "YYYY-MM-DD"
  func isoDate(tz: String? = nil) -> String {
    let dc = components(tz: tz)
    return String(format: "%04d-%02d-%02d", dc.year!, dc.month!, dc.day!)
  }
  
  /// Add (or subtract) number of days
  mutating func addDays(_ days: Int) {
    self = Calendar.current.date(byAdding: .day, value: days, to: self)!
  }
  
  /// Check if an given Date exists and time Interval is smaller than given timeInterval
  /// - Parameters:
  ///   - date: date to compare with now
  ///   - interval: interval to use; default 1 Hour
  /// - Returns: true if exists and not expired
  static func existsAndNotExpired(_ date: Date?, intervall:TimeInterval = TimeInterval.hour) -> Bool {
    guard let d = date else { return false }
    return Date().timeIntervalSince(d) < intervall
  }
} // extension Date

public extension TimeInterval {
  static var day: Double { get { return 24*hour} }
  static var hour: Double { get { return 60*minute} }
  static var minute: Double { get { return 60} }
}

/**
 Time as seconds and microseconds since 1970-01-01 00:00:00 UTC
 
 This class is a simple wrapper around the timeval() library function and provides
 some integration with class Date.
 */ 
public struct UsTime: Comparable, ToString, DoesLog {
  
  private var tv = timeval()
  public var sec: Int64 { return Int64(tv.tv_sec) }
  public var usec: Int64 { return Int64(tv.tv_usec) }
  public var timeInterval: TimeInterval {
    return TimeInterval(sec) + (TimeInterval(usec) / 1000000)
  }
  public var date: Date { return Date(timeIntervalSince1970: timeInterval) }
  
  /// Returns the current time
  public static func now() -> UsTime {
    var ut = UsTime()
    gettimeofday(&(ut.tv), nil)
    return ut
  }
  
  /// Init from optional Date
  public init(_ date: Date? = nil) {
    if let d = date {
      var nsec = d.timeIntervalSince1970
      tv.tv_sec = type(of: tv.tv_sec).init( nsec.rounded(.down) )
      nsec = (nsec - TimeInterval(tv.tv_sec)) * 1000000
      tv.tv_usec = type(of: tv.tv_usec).init( nsec.rounded() )
    }
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
  
  /// Init from date/time components in gregorian calendar
  public init(year: Int, month: Int, day: Int, hour: Int = 12, min: Int = 0, 
              sec: Int = 0, usec: Int = 0, tz: String? = nil) {
    self.init(0)
    let cal = Calendar(identifier: .gregorian)
    var timeZone = TimeZone.current
    if let tz = tz { 
      if let tmp = TimeZone(identifier: tz) { timeZone = tmp } 
      else { fatal("Invalid timezone: \(tz)") }
    }
    let dc = DateComponents(calendar: cal, timeZone: timeZone, year: year,
               month: month, day: day, hour: hour, minute: min, second: sec)
    if dc.isValidDate { 
      self.init(dc.date!)
      tv.tv_usec = type(of: tv.tv_usec).init(usec)
    }
    else { fatal("Invalid date/time: \(dc.description)") }
  }
  
  /// Init from String in ISO8601 format with optional time zone (default: local time zone)
  public init(iso: String, tz: String? = nil) {
    self.init(0)
    let isoRE = #"(\d+)-(\d+)-(\d+)( (\d+):(\d+):(\d+)(\.(\d+))?)?"#
    let dfs = iso.groupMatches(regexp: isoRE)
    if dfs.count >= 1 && dfs[0].count >= 4 {
      let df = dfs[0]
      let year = Int(df[1]), month = Int(df[2]), day = Int(df[3])
      var hour = 12, min = 0, sec = 0, usec = 0
      if df.count >= 8 && df[4].count > 0 {
        hour = Int(df[5])!; min = Int(df[6])!; sec = Int(df[7])!
        if df.count >= 10 && df[9].count > 0 { 
          var digits = df [9];
          let n = digits.count
          if n < 7 { digits += "0" * (6 - digits.count) }
          usec = Int(digits.prefix(6))!
        }
      }
      self.init(year: year!, month: month!, day: day!, hour: hour, min: min, sec: sec, 
                usec: usec, tz: tz)
    }
    else { fatal("Invalid date/time representation: \(iso)") }
  }

  /// Converts UsTime to "YYYY-MM-DD hh:mm:ss.uuuuuu" in given time zone
  public func toString(tz: String?) -> String {
    let dc = date.components(tz: tz)
    return String( format: "%04d-%02d-%02d %02d:%02d:%02d.%06d", dc.year!, dc.month!,
                   dc.day!, dc.hour!, dc.minute!, dc.second!, usec )
  }
  
  /// Converts UsTime to "YYYY-MM-DD hh:mm:ss.uuuuuu" in local time zone
  public func toString() -> String {
    return toString(tz: nil)
  }
  
  /// Converts UsTime to "YYYY-MM-DD" with optionally given time zone
  public func isoDate(tz: String? = nil) -> String {
    let dc = date.components(tz: tz)
    return String(format: "%04d-%02d-%02d", dc.year!, dc.month!, dc.day!)
  }

  static public func <(lhs: UsTime, rhs: UsTime) -> Bool {
    if lhs.sec == rhs.sec { return lhs.usec < rhs.usec }
    else { return lhs.sec < rhs.sec }
  }
  
  static public func ==(lhs: UsTime, rhs: UsTime) -> Bool {
    return (lhs.sec == rhs.sec) && (lhs.usec == rhs.usec)
  }
  
}  // struct UsTime


public extension String {
  /// Convert string of digits to UsTime
  var usTime: UsTime { UsTime(self) }
}

//
//  UsTime.swift
//
//  Created by Norbert Thies on 06.07.18.
//  Copyright © 2018 Norbert Thies. All rights reserved.
//

import NorthLowLevel

/**
 * Time as seconds and microseconds since 1970-01-01 00:00:00 UTC
 *
 * _UsTime_ is a wrapper around some structures and functions working with
 * UNIX System Time, i.e. the number of seconds (and microseconds) since 1970.
 * This class uses the following POSIX data types and functions:
 *
 * * struct timeval  
 *   defined in [sys/time.h](https://pubs.opengroup.org/onlinepubs/009604599/basedefs/sys/time.h.html)
 * * gettimeofday  
 *   defined in [gettimeofday](https://pubs.opengroup.org/onlinepubs/009604599/functions/gettimeofday.html)
 * * struct tm
 *   defined in [time.h](https://pubs.opengroup.org/onlinepubs/009604499/basedefs/time.h.html)
 * * localtime_r
 *   defined in [localtime](https://pubs.opengroup.org/onlinepubs/9699919799/functions/localtime.html)
 * * mktime
 *   defined in [mktime](https://pubs.opengroup.org/onlinepubs/009604499/functions/mktime.html)
 */ 
open class UsTime: Comparable, DoesLog, ToString {
  
  public class Timeval {
    var tv = timeval()
    var sec: Int64 { Int64(tv.tv_sec) }
    var usec: Int64 { Int64(tv.tv_usec) }
    init(sec: Int64, usec: Int64) {
      tv.tv_sec = type(of: tv.tv_sec).init(sec)
      tv.tv_usec = type(of: tv.tv_usec).init(usec)
    }
    init() { gettimeofday(&tv, nil) }
  } // Timeval
  
  public class Values {
    var tmval = tm()
    init() {}
    init(tv: Timeval) {
      guard let _ = localtime_r(&(tv.tv.tv_sec), &tmval) else { 
        tmval.tm_mday = -1 
        return
      }
    }
  } // Values
  
  internal var _time: Timeval?
  internal var _values: Values?
  
  var time: Timeval { 
    if _time == nil { _time = Timeval(); _values = nil }
    return _time!
  }
  
  var values: Values {
    if _values == nil { _values = Values(tv: time) }
    return _values!
  }
  
  public init(time: Timeval, values: Values?) {
    _time = time
    _values = values
  }

  /// Seconds since 1970-01-01 00:00:00 UTC
  public var sec: Int64 { 
    get { return time.sec }
    set { time.tv.tv_sec = type(of: time.tv.tv_sec).init(newValue); _values = nil }
  }
  
  /// Microseconds relative to 'sec'
  public var usec: Int64 { 
    get { return time.usec }
    set (usec) { 
      if usec >= 1_000_000 { sec = sec + usec / 1_000_000 }
      time.tv.tv_usec = type(of: time.tv.tv_usec).init(usec % 1_000_000)
    }
  }
  
  /// sec and usec as Double
  public var double: Double { Double(sec) + (Double(usec) / 1_000_000.0) }
  
  /// Day of month: 1..31
  public var day: Int { Int(values.tmval.tm_mday) }
  /// Month of year: 1..12
  public var month: Int { Int(values.tmval.tm_mon)+1 }
  /// Year: 1970...
  public var year: Int { Int(values.tmval.tm_year + 1900) }
  /// Week day: 0..6 (0=Sunday)
  public var wday: Int { Int(values.tmval.tm_wday) }
  /// Year day: 0..366
  public var yday: Int { Int(values.tmval.tm_yday) }
  /// Hour of the day: 0..24
  public var hour: Int { Int(values.tmval.tm_hour) }
  /// Minute of the hour: 0..60
  public var minute: Int { Int(values.tmval.tm_min) }
  /// Second of the minute: 0..60
  public var second: Int { Int(values.tmval.tm_sec) }
  /// Micosecond of the second: 0..999999
  public var usecond: Int { Int(usec) }
  /// Is daylight saving in effect?
  public var isDst: Bool { values.tmval.tm_isdst > 0 }
  /// Offset to UTC in seconds (east of Greenwhich is negative)
  public var tzOffset: Int { isDst ? Self.tzDstOffset : Self.tzOffset }
  /// Return current timezone as String
  public static var tz: String { 
    let tzdata = tz_get().pointee
    return String(validatingUTF8: tzdata.tz_std_name!)! 
  }
  /// Return daylight saving timezone as optional String
  public static var tzDst: String? {
    let tzdata = tz_get().pointee
    if let dstName = tzdata.tz_dst_name { return String(validatingUTF8: dstName) }
    return nil;
  }
  /// Return standard offset to UTC (no daylight saving, east of Greenwhich is negative)
  public static var tzOffset: Int { Int(tz_get().pointee.tz_std_offset) }
  /// Return daylight saving offset to UTC (east of Greenwhich is negative)
  public static var tzDstOffset: Int { Int(tz_get().pointee.tz_dst_offset) }
  
  /// Initializes to the current time
  public init() { _time = Timeval() }
  
  /// Return UsTime with given date/time values
  public static func date(year: Int, month: Int, day: Int, hour: Int = 12, 
    minute: Int = 0, second: Int = 0, usecond: Int = 0) -> UsTime? {
    if year >= 1970 {
      let v = Values()
      let T = type(of: v.tmval.tm_year)
      v.tmval.tm_mday = T.init(day)
      v.tmval.tm_mon = T.init(month-1)
      v.tmval.tm_year = T.init(year - 1900)
      v.tmval.tm_hour = T.init(hour)
      v.tmval.tm_min = T.init(minute)
      v.tmval.tm_sec = T.init(second)
      v.tmval.tm_isdst = T.init(-1)
      let orig = Values()
      orig.tmval = v.tmval
      let tmp = mktime(&(v.tmval))
      if tmp != -1 {
        if orig.tmval.tm_mday != v.tmval.tm_mday ||
           orig.tmval.tm_mon != v.tmval.tm_mon ||
           orig.tmval.tm_year != v.tmval.tm_year ||
           orig.tmval.tm_hour != v.tmval.tm_hour ||
           orig.tmval.tm_min != v.tmval.tm_min ||
           orig.tmval.tm_sec != v.tmval.tm_sec
        { return nil }
        let tv = Timeval(sec: Int64(tmp), usec: Int64(usecond))
        return UsTime(time: tv, values: v)
      }
    }
    return nil
  }
  
  /// Return UsTime from String in ISO8601 format
  public static func parse(iso: String) -> UsTime? {
    let isoRE = "(@d+)-(@d+)-(@d+)([ ,]+(@d+):(@d+):(@d+)(\\.(@d+))?)?"
    let dfs = iso.match(isoRE)
    if let df = dfs, df.count >= 4 {
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
      return date(year: year!, month: month!, day: day!, hour: hour, 
                  minute: min, second: sec, usecond: usec)
    }
    return nil
  }
  
  /// Converts UsTime to "YYYY-MM-DD hh:mm:ss"
  public func toString() -> String {
    var str = str_tm2iso(&(values.tmval), -1)
    defer { str_release(&str) }
    return String(validatingUTF8: str!)!
  }
 
  /// Returns the current time
  public static var now: UsTime { UsTime() }
  
  /// Init from number of seconds since 00:00:00 1970 UTC
  public init(_ sec: Int64, usec: Int64 = 0) { _time = Timeval(sec: sec, usec: usec) }
  
  /// Init from number of seconds since 00:00:00 1970 UTC expressed as String
  public convenience init(_ nsec: String) {
    if let ns = Int64(nsec) { self.init(ns) }
    else { self.init() }
  }
  
  static public func <(lhs: UsTime, rhs: UsTime) -> Bool {
    if lhs.sec == rhs.sec { return lhs.usec < rhs.usec }
    else { return lhs.sec < rhs.sec }
  }
  
  static public func ==(lhs: UsTime, rhs: UsTime) -> Bool {
    return (lhs.sec == rhs.sec) && (lhs.usec == rhs.usec)
  }
  
  static public func +=(lhs: UsTime, rhs: Int) { lhs.sec = lhs.sec + Int64(rhs) }
  static public func -=(lhs: UsTime, rhs: Int) { lhs.sec = lhs.sec - Int64(rhs) }
  
}  // struct UsTime

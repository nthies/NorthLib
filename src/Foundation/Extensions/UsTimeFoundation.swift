//
//  UsTime.swift
//
//  Created by Norbert Thies on 06.07.18.
//  Copyright © 2018 Norbert Thies. All rights reserved.
//

import Foundation

/// Some extensions to UsTime applying Foundation types
extension UsTime: Comparable, ToString {

  /// Yields Foundation's TimeInterval
  public var timeInterval: TimeInterval { TimeInterval(double) }

  /// Yields Foundation's Date
  public var date: Date { return Date(timeIntervalSince1970: timeInterval) }

  /// Init from optional Date
  public init(_ date: Date? = nil) {
    if let d = date {
      var nsec = d.timeIntervalSince1970
      tv.tv_sec = type(of: tv.tv_sec).init( nsec.rounded(.down) )
      nsec = (nsec - TimeInterval(tv.tv_sec)) * 1000000
      tv.tv_usec = type(of: tv.tv_usec).init( nsec.rounded() )
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

  /// Init from String in ISO8601 format with optional time zone
  /// (default: local time zone)
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
      self.init(year: year!, month: month!, day: day!, hour: hour, min: min, 
                sec: sec, usec: usec, tz: tz)
    }
    else { fatal("Invalid date/time representation: \(iso)") }
  }

  /// Converts UsTime to "YYYY-MM-DD hh:mm:ss.uuuuuu" in given time zone
  public func toString(tz: String?) -> String {
    let dc = date.components(tz: tz)
    return String( format: "%04d-%02d-%02d %02d:%02d:%02d.%06d", 
                   dc.year!, dc.month!, dc.day!, dc.hour!, dc.minute!, 
		   dc.second!, usec )
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

} // extension UsTime

//
//  FileLoggerFoundation.swift
//
//  Created by Norbert Thies on 19.06.19.
//  Copyright © 2019 Norbert Thies. All rights reserved.
//

import Foundation

extension Log.FileLogger {
  
  /// URL of file to log to
  public var url: URL? {
    if let fn = filename { return URL(fileURLWithPath: fn) }
    else { return nil }
  }
  
  /// Default logfile in cache directory
  public static var defaultLogfile: String = "\(Dir.cachePath)/default.log"
  
  /// Logfile from last execution
  public static var lastLogfile: String = defaultLogfile + ".old"
  
  /// FileLogger logging to cache directory
  public static var cached: Log.FileLogger =
    Log.FileLogger(Log.FileLogger.defaultLogfile)
  

} // extension Log.FileLogger

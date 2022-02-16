//
//  FileLogger.swift
//
//  Created by Norbert Thies on 19.06.19.
//  Copyright © 2019 Norbert Thies. All rights reserved.
//

import NorthLowLevel

extension Log {
  
  /// A FileLogger writes all passed log messages to a File
  open class FileLogger: Logger {
    
    /// pathname of file to log to
    public private(set) var filename: String?
    
    /// file descriptor of file to log to
    public private(set) var fp: fileptr_t?
    
    /// contents of logfile as Memory
    public var mem: Memory? {
      if let fn = filename {
        return File(fn).mem
      }
      return nil
    }
    
    /// default logfile
    public static var tmpLogfile: String = "\(Dir.tmpPath)/default.log"
    
    /// The FileLogger must be initialized with a filename
    public init(_ fname: String?) {
      let fn = fname ?? FileLogger.tmpLogfile
      if file_open(&fp, fn, "w") == 0 {
        self.filename = fn
      }
      super.init()
    }
    
    // closes file pointer upon deconstruction
    deinit { file_close(&self.fp) }
    
    /// log a message to the logfile
    public override func log(_ msg: Message) {
      if let fp = self.fp {
        var txt = String(describing: msg)
        if !txt.hasSuffix("\n") { txt = txt + "\n" }
        _ = txt.withCString { file_write(fp, $0, str_len($0)) }
        file_flush(fp)
      }
    }
    
  } // class FileLogger
  
} // extension Log

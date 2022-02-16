//
//  FileLogger.swift
//
//  Created by Norbert Thies on 19.06.19.
//  Copyright © 2019 Norbert Thies. All rights reserved.
//

import Foundation

extension Log {
  
  /// A FileLogger writes all passed log messages to a File
  open class FileLogger: Logger {
    
    /// pathname of file to log to
    private(set) var filename: String?
    
    /// URL of file to log to
    public var url: URL? { 
      if let fn = filename { return URL(fileURLWithPath: fn) }
      else { return nil }
    }
    
    /// file descriptor of file to log to
    private(set) var fp: UnsafeMutablePointer<FILE>?
    
    /// contents of logfile as Data
    public var data: Data? {
      if let url = self.url { return try? Data(contentsOf: url) }
      else { return nil }
    }
    
    /// The FileLogger must be initialized with a filename
    public init(_ fname: String) {
      if let fp = fopen(fname, "w") {
        self.fp = fp
        self.filename = fname
      }
      super.init()
    }
    
    public static var defaultLogfile: String = {
      let cachedirs = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
      let cachedir = cachedirs[0].path
      return "\(cachedir)/default.log"
    }()
    
    public static var lastLogfile: String = {
      return defaultLogfile + ".old"
    }()
    
       
    /// Using a temporary filename
    public convenience override init() {
      self.init(FileLogger.defaultLogfile)
    }
    
    // closes file pointer upon deconstruction
    deinit {
      if let fp = self.fp { fclose(fp) }
    }
    
    /// log a message to the TextView
    public override func log(_ msg: Message) {
      if let fp = self.fp {
        var txt = String(describing: msg)
        if !txt.hasSuffix("\n") { txt = txt + "\n" }
        fwrite(txt.cString(using: .utf8), 1, txt.utf8.count, fp)
        fflush(fp)
      }
    }
    
  } // class FileLogger
  
} // extension Log

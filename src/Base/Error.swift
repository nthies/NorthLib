//
//  Error.swift
//
//  Created by Norbert Thies on 18.06.19.
//  Copyright © 2019 Norbert Thies. All rights reserved.
//

import Foundation

public protocol SimpleError: Swift.Error {
  var description: String { get }
}

extension Swift.Error {
  public func errorText() -> String {
    if let e = self as? SimpleError { return e.description }
    else if let e = self as? LocalizedError,
      let txt = e.errorDescription { return txt }
    return self.localizedDescription
  }
  public var description: String { errorText() }
}

extension Result {
  /// error() is similar to get() and returns the Failure value if available
  public func error() -> Failure? { 
    if case .failure(let err) = self { return err }
    else { return nil }
  }
  
  /// value returns the success value (or nil if no success)
  /// An Error is logged.
  public func value(file: String = #file, line: Int = #line,
    function: String = #function) -> Success? {
    switch self {
    case .success(let val): return val
    case .failure(let err):
      Log.error(err, object: nil, file: file, line: line, function: function)
      return nil
    }
  }
} // Result

extension DoesLog {
  
  @discardableResult  
  public func error(_ msg: String? = nil, file: String = #file, line: Int = #line,
                    function: String = #function) -> Log.Error {
    return Log.error(msg, object: self, file: file, line: line, function: function)
  }
  
  @discardableResult  
  public func check(_ value: Bool, _ msg: String? = nil, file: String = #file, 
                    line: Int = #line, function: String = #function) -> Bool {
    var ret = false
    if value { ret = true }
    else {
      var str = "*** Check failed"
      if let m = msg { str += ": \(m)" }
      Log.error(str, object: self, file: file, line: line, function: function)
    }
    return ret
  }
  
  @discardableResult
  public func error<T: Swift.Error>(_ error: T, file: String = #file, line: Int = #line,
                                    function: String = #function) -> Log.EnclosedError<T> {
    return Log.error(error, object: self, file: file, line: line, function: function)
  }
  
  @discardableResult
  public func logIf<T: Swift.Error>(_ error: T?, file: String = #file, line: Int = #line,
                                    function: String = #function) -> Log.EnclosedError<T>? {
    guard let error = error else { return nil }
    return Log.error(error, object: self, file: file, line: line, function: function)
  }
  
  @discardableResult  
  public func fatal(_ msg: String? = nil, file: String = #file, line: Int = #line,
                    function: String = #function) -> Log.Error {
    return Log.fatal(msg, object: self, file: file, line: line, function: function)
  }
  
  @discardableResult
  public func fatal<T: Swift.Error>(_ error: T, file: String = #file, line: Int = #line,
                                    function: String = #function) -> Log.EnclosedError<T> {
    return Log.fatal(error, object: self, file: file, line: line, function: function)
  }
  
  @discardableResult  
  public func exception(_ msg: String? = nil, file: String = #file, line: Int = #line,
                        function: String = #function) -> Log.Error {
    return Log.exception(msg, object: self, file: file, line: line, function: function)
  }
  
  @discardableResult
  public func exception<T: Swift.Error>(_ error: T, file: String = #file, line: Int = #line,
                                        function: String = #function) -> Log.EnclosedError<T> {
    return Log.exception(error, object: self, file: file, line: line, function: function)
  }
  
} // extension DoesLog


extension Log {
  
  /** 
   A Log.Error is a Log.Message that also serves as an Error and can be thrown
   as an exception.
   
   A logged Error may refer to an Error that may have caused this Error. Therefore
   it may optionally refer to an Error that has occurred previously.
   */
  open class Error: Message, Swift.Error {
    
    /// A previous Exception causing this Exception
    public var previous: Log.Error? = nil
    
    /// The localized description according to the Error protocol
    public var localizedDescription: String { return toString() }

    /// Initialisation with a previous ErrorMessage
    public init( level: LogLevel, className: String?, fileName: String, funcName: String,
                 line: Int, message: String?, previous: Log.Error? ) {
      super.init(level:level, className:className, fileName:fileName, funcName:funcName,
                 line:line, message:message)
      self.previous = previous
    }
    
  } // class Log.Error
  
  open class EnclosedError<T: Swift.Error>: Log.Error {
    
    /// The enclosed Error
    public var enclosed: T
    
    public init(enclosed: T, level: LogLevel, className: String?, fileName: String, 
                funcName: String, line: Int, message: String?, previous: Log.Error?) {
      self.enclosed = enclosed
      super.init(level:level, className:className, fileName:fileName, funcName:funcName,
                 line:line, message:message, previous: previous)
      if let msg = self.message {
        self.message = msg + "\n  " + "Enclosed Error: \(enclosed.errorText())"
      }
      else {
        self.message = "Enclosed Error: \(enclosed.errorText())"
      }
    }

  } // class Log.EnclosedError
    
  @discardableResult
  public static func error(_ message: String? = nil, previous: Log.Error? = nil, object: Any? = nil,
    logLevel: LogLevel = .Error, file: String = #file, line: Int = #line, 
    function: String = #function) -> Log.Error {
    let msg = Error(level: logLevel, className: class2s(object), fileName: file, funcName: function,
                    line: line, message: message, previous: previous)
    log(msg)
    return msg
  }
    
  @discardableResult
  public static func error<T: Swift.Error>(_ error: T, previous: Log.Error? = nil, object: Any? = nil,
                             logLevel: LogLevel = .Error, file: String = #file, line: Int = #line, 
                             function: String = #function) -> EnclosedError<T> {
    let msg = EnclosedError<T>(enclosed: error, level: logLevel, className: class2s(object), 
        fileName: file, funcName: function, line: line, message: nil, previous: previous)
    log(msg)
    return msg
  }
  
  @discardableResult
  public static func exception(_ message: String? = nil, previous: Log.Error? = nil, object: Any? = nil,
                           logLevel: LogLevel = .Error, file: String = #file, line: Int = #line, 
                           function: String = #function) -> Log.Error {
    let msg = Error(level: logLevel, className: class2s(object), fileName: file, funcName: function,
                    line: line, message: message, previous: previous)
    msg.isException = true
    log(msg)
    return msg
  }
  
  @discardableResult
  public static func exception<T: Swift.Error>(_ error: T, previous: Log.Error? = nil, object: Any? = nil,
                                           logLevel: LogLevel = .Error, file: String = #file, line: Int = #line, 
                                           function: String = #function) -> EnclosedError<T> {
    let msg = EnclosedError<T>(enclosed: error, level: logLevel, className: class2s(object), 
                               fileName: file, funcName: function, line: line, message: nil, previous: previous)
    msg.isException = true
    log(msg)
    return msg
  }
 
  @discardableResult
  public static func fatal(_ message: String? = nil, previous: Log.Error? = nil, object: Any? = nil,
                           logLevel: LogLevel = .Fatal, file: String = #file, line: Int = #line, 
                           function: String = #function) -> Log.Error {
    let msg = Error(level: logLevel, className: class2s(object), fileName: file, funcName: function,
                    line: line, message: message, previous: previous)
    log(msg)
    return msg
  }
  
  @discardableResult
  public static func fatal<T: Swift.Error>(_ error: T, previous: Log.Error? = nil, object: Any? = nil,
                                           logLevel: LogLevel = .Fatal, file: String = #file, line: Int = #line, 
                                           function: String = #function) -> EnclosedError<T> {
    let msg = EnclosedError<T>(enclosed: error, level: logLevel, className: class2s(object), 
                               fileName: file, funcName: function, line: line, message: nil, previous: previous)
    log(msg)
    return msg
  }
  
} // extension Log

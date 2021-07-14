//
//  File.swift
//
//  Created by Norbert Thies on 20.11.19.
//  Copyright © 2019 Norbert Thies. All rights reserved.
//

import Foundation

/// Rudimentary wrapper around elementary file operations
open class File: DoesLog {
  
  /// The default file manager
  public static var fm: FileManager { return FileManager.default }

  fileprivate var hasStat: Bool { return getStat() != nil }
  fileprivate var _status: stat_t?
  fileprivate var fp: fileptr_t? = nil
  fileprivate var cpath: [CChar] { return self.path.cString(using: .utf8)! }

  /// File status
  public var status: stat_t? { 
    get { return getStat() }
    set { if let st = newValue { _status = st; stat_write(&_status!, cpath) } }
  }

  /// Pathname of file
  public var path: String { didSet { _status = nil } }
  
  /// File size in bytes
  public var size: Int64 { 
    guard hasStat else { return 0 }
    return Int64(_status!.st_size) 
  }
  
  /// File modification time as #seconds since 01/01/1970 00:00:00 UTC
  public var mtime: Int64 {
    get {
      guard hasStat else { return 0 }
      return Int64(stat_mtime(&_status!)) 
    }
    set {
      if hasStat { 
        stat_setmtime(&_status!, time_t(newValue)) 
        stat_write(&_status!, cpath)
      }
    }
  }
    
  /// File access time as #seconds since 01/01/1970 00:00:00 UTC
  public var atime: Int64 {
    get {
      guard hasStat else { return 0 }
      return Int64(stat_atime(&_status!)) 
    }
    set {
      if hasStat { 
        stat_setatime(&_status!, time_t(newValue)) 
        stat_write(&_status!, cpath)        
      }
    }
  }
  
  /// File mode change time as #seconds since 01/01/1970 00:00:00 UTC
  public var ctime: Int64 {
    guard hasStat else { return 0 }
    return Int64(stat_ctime(&_status!)) 
  }

  /// File modification time as Date
  public var mTime: Date { 
    get { return UsTime(self.mtime).date }
    set { self.mtime = UsTime(newValue).sec }
  }
  
  /// File access time as Date
  public var aTime: Date { 
    get { return UsTime(self.atime).date }
    set { self.atime = UsTime(newValue).sec }
  }
  
  /// File mode change time as Date
  public var cTime: Date { return UsTime(self.ctime).date }

  @discardableResult
  fileprivate func getStat() -> stat_t? { 
    if _status == nil {
      var tmp = stat_t()
      if stat_read(&tmp, cpath) == 0 { self._status = tmp }
    }
    return _status
  }
  
  /// A File has to be initialized with a filename
  public init(_ path: String) {
    self.path = path
  }
  
  /// A File searched for in the main bundle
  public convenience init?(inMain fn: String) {
    let pref = File.progname(fn)
    let ext = File.extname(fn)
    guard let path = Bundle.main.path(forResource: pref, ofType: ext)
      else { return nil }
    self.init(path)
  }
  
  /// Initialisation with directory and file name
  public convenience init(dir: String, fname: String) {
    var str = fn_pathname(dir.cstr, fname.cstr)
    self.init(String(cString: str!))
    str_release(&str)
  }
  
  /// Initialisation with URL
  public convenience init(_ url: URL) {
    self.init(url.path)
  }
  
  /// deinit closes the file pointer if it has been opened
  deinit {
    if fp != nil { fclose(fp) }
  }
  
  /// open opens a File as C file pointer, executes the passed closure and closes
  /// the file pointer
  public static func open(path: String, mode: String = "a", closure: (File)->()) {
    let file = File(path)
    if file_open(&file.fp, file.cpath, mode) == 0 {
      closure(file)
      file_close(&file.fp)
    }
  }
  
  /// Reads one line of characters from the file
  public func readline() -> String? {
    guard fp != nil else { return nil }
    var str = file_readline(fp)
    if let s = str {
      let ret = String(cString: s, encoding: .utf8)
      str_release(&str)
      return ret
    }
    return nil
  }
    
  /// Writes one line of characters to the file, a missing \n is added
  @discardableResult
  public func writeline(_ str: String) -> Int {
    guard fp != nil else { return -1 }
    let ret = file_writeline(fp, str.cString(using: .utf8))
    return Int(ret)
  }
  
  /// Reads one data chunk from the file's current position
  public func read() -> Data? {
    guard fp != nil,
          let buff = mem_heap(nil, 100 * 1024)
    else { return nil }
    let count = file_read(fp, buff, 100 * 1024)
    if count > 0 {
      return Data(bytesNoCopy: buff, count: Int(count), deallocator: .free)
    }
    else { return nil }
  }
  
  /// Writes the passed data to the file's current position
  @discardableResult
  public func write(data: Data) -> Int {
    let ret =  data.withUnsafeBytes { ptr in
      file_write(fp, ptr, Int32(data.count))
    }
    return Int(ret)
  }

  /// Flushes input/output buffers
  public func flush() { 
    guard fp != nil else { return }
    file_flush(fp)
  }
  
  /// Returns true if the file exists and is accessible
  public var exists: Bool { return fn_access(cpath, "e") == 0 }

  /// Returns true if File exists (is accessible) and is a directory
  public var isDir: Bool { return hasStat && (stat_isdir(&_status!) != 0) }
  
  /// Returns true if File exists (is accessible) and is a regular file
  public var isFile: Bool { return hasStat && (stat_isfile(&_status!) != 0) }
  
  /// Returns true if File exists (is accessible) and is a symbolic link
  public var isLink: Bool { return hasStat && (stat_islink(&_status!) != 0) }
  
  /// Returns a file URL
  public var url: URL { return URL(fileURLWithPath: path) }
  
  /// Returns the contents of the file (if it is an existing file)
  public var data: Data { 
    get {
      guard exists && isFile else { return Data() }
      return try! Data(contentsOf: url) 
    }
    set (data) { try! data.write(to: url) }
  }
  
  /// Returns the contents of the file as String (if it is an existing file)
  public var string: String { 
    get {
      guard exists && isFile else { return String() }
      return data.string
    }
    set (string) {
      self.data = string.data(using: .utf8)!
    }
  }

  /// Returns the SHA256 checksum of the file's contents
  public var sha256: String { return data.sha256 }
  
  /// Returns the basename of a given pathname
  public var basename: String {
    var str = fn_basename(path.cString(using: .utf8)!)
    let ret = String(cString: str!)
    str_release(&str)
    return ret
  }
  
  /// Returns the dirname of a given pathname
  public var dirname: String {
    var str = fn_dirname(path.cString(using: .utf8)!)
    let ret = String(cString: str!)
    str_release(&str)
    return ret
  }
  
  /// Returns the progname (basename without extension) of a given pathname
  public var progname: String {
    var str = fn_progname(path.cString(using: .utf8)!)
    let ret = String(cString: str!)
    str_release(&str)
    return ret
  }
  
  /// Returns the prefname (path without extension) of a given pathname
  public var prefname: String {
    var str = fn_prefname(path.cString(using: .utf8)!)
    let ret = String(cString: str!)
    str_release(&str)
    return ret
  }

  /// Returns the extname (extension) of a given pathname
  public var extname: String {
    var str = fn_extname(path.cString(using: .utf8)!)
    let ret = String(cString: str!)
    str_release(&str)
    return ret
  }

  /// Links the file to an existing file 'to' (beeing an absolute path)
  /// (ie. makes self a symbolic link)
  public func link(to: String) {
    file_link(to.cstr, cpath)
  }
  
  /// Copies the file to a new location while maintaining the file status
  public func copy(to: String, isOverwrite: Bool = true) {
    guard exists else { return }
    if isOverwrite {
      let dest = File(to)
      if dest.exists { dest.remove() }
    }
    do {
      Dir(File.dirname(to)).create()
      try FileManager.default.copyItem(atPath: path, toPath: to)
      if hasStat { stat_write(&_status!, to.cstr) }
    }
    catch (let err) { error(err) }
  }
  
  /// Moves the file to a new location while maintaining the file status
  public func move(to: String, isOverwrite: Bool = true) {
    guard exists else { return }
    if isOverwrite {
      let dest = File(to)
      if dest.exists { dest.remove() }
    }
    do {
      Dir(File.dirname(to)).create()
      try FileManager.default.moveItem(atPath: path, toPath: to)
      if hasStat { stat_write(&_status!, to.cstr) }
    }
    catch (let err) { error(err) }
  }
  
  /// Removes the file (and all subdirs if self is a directory)
  public func remove() {
    guard exists else { return }
    if isDir { dir_remove(cpath) }
    else { file_unlink(cpath) }
  }

  /// Returns the basename of a given pathname
  public static func basename(_ fn: String) -> String {
    return Dir(fn).basename
  }
  
  /// Returns the dirname of a given pathname
  public static func dirname(_ fn: String) -> String {
    return Dir(fn).dirname
  }
  
  /// Returns the progname (basename without extension) of a given pathname
  public static func progname(_ fn: String) -> String {
    return Dir(fn).progname
  }
  
  /// Returns the prefname (path without extension) of a given pathname
  public static func prefname(_ fn: String) -> String {
    return Dir(fn).prefname
  }
  
  /// Returns the extname (extension) of a given pathname
  public static func extname(_ fn: String) -> String {
    return Dir(fn).extname
  }

} // File


/// The Dir class models a directory in the local file system
open class Dir: File {
    
  /// Returns true, if the directory at the given path is existent.
  public override var exists: Bool {
    return super.exists && super.isDir
  }
  
  /// Create directory at given path, if not existing. Parent dirs are created as well
  public func create(mode: Int = 0o777) {
    guard !exists else { return }
    var st: stat_t = stat()
    stat_init(&st, mode_t(mode))
    fn_mkpath(cpath, &st)
  }
    
  /// Creates a Dir object with the given path, the directory is not created
  /// automatically.
  public override init(_ dir: String) {
    super.init(dir)
  }
  
  /// Returns an array of the contents of the directory (without preceeding path)
  public func contents() -> [String] {
    guard exists else { return [] }
    do { return try Dir.fm.contentsOfDirectory(atPath: path) }
    catch { return [] }
  }
  
  /// Scans for files and returns an array of absolute pathnames.
  /// 'filter' is an optional predicate to use.
  public func scan(isAbs: Bool = true, filter:((String)->Bool)? = nil) -> [String] {
    var ret: [String] = []
    let contents = self.contents()
    for f in contents {
      let path = isAbs ? "\(self.path)/\(f)" : f
      if let sel = filter { if sel(path) { ret.append(path) } }
      else { ret.append(path) }
    }
    return ret
  }

  /// scanExtensions searches for files beeing matched
  /// by any one in a list of given extensions.
  public func scanExtensions(_ ext: [String]) -> [String] {
    let lext = ext.map { $0.lowercased() }
    return scan { (fn: String) -> Bool in
      let fe = (fn.lowercased() as NSString).pathExtension
      if let _ = lext.firstIndex(of: fe) { return true }
      return false
    }
  }
  
  /// scanExtensions searches for files beeing matched
  /// by any one in a list of given extensions.
  public func scanExtensions( _ ext: String... ) -> [String] {
    return scanExtensions(ext)
  }
  
  /// isBackup determines whether this directory is excluded from backups
  public var isBackup: Bool {
    get {
      guard exists else { return false }
      let val = try! url.resourceValues(forKeys: [.isExcludedFromBackupKey])
      return val.isExcludedFromBackup!
    }
    set {
      guard exists else { return }
      var val = URLResourceValues()
      var url = self.url
      val.isExcludedFromBackup = newValue
      try! url.setResourceValues(val)
    }
  }
  
  /// returns the path to the document directory
  public static var documentsPath: String {
    return try! fm.url(for: .documentDirectory, in: .userDomainMask,
      appropriateFor: nil, create: true).path
  }
  
  /// returns the path to the Inbox directory
  public static var inboxPath: String {
    return "\(Dir.documentsPath)/Inbox"
  }
  
  /// returns the path to the app support directory
  public static var appSupportPath: String {
    return try! FileManager.default.url(for: .applicationSupportDirectory,
      in: .userDomainMask, appropriateFor: nil, create: true).path
  }
  
  /// returns the path to the cache directory
  public static var cachePath: String {
    return try! FileManager.default.url(for: .cachesDirectory,
      in: .userDomainMask, appropriateFor: nil, create: true).path
  }
  
  /// returns the path to the temp directory
  public static var tmpPath: String {
    return NSTemporaryDirectory()
  }

  /// returns the path to the home directory
  public static var homePath: String {
    return NSHomeDirectory()
  }
  
  /// returns the current working directory
  public static var currentPath: String {
    var str = fn_abs(".".cstr)
    let ret = String(cString: str!)
    str_release(&str)
    return ret
  }
  
  /// returns the current working directory
  public static var current: Dir {
    return Dir(Dir.currentPath)
  }

  /// returns the document directory
  public static var documents: Dir {
    return Dir(Dir.documentsPath)
  }

  /// returns the Inbox directory
  public static var inbox: Dir {
    return Dir(Dir.inboxPath)
  }
  
  /// returns the application support directory
  public static var appSupport: Dir {
    return Dir(Dir.appSupportPath)
  }
  
  /// returns the cache directory
  public static var cache: Dir {
    return Dir(Dir.cachePath)
  }
  
  /// returns the home directory
  public static var home: Dir {
    return Dir(Dir.homePath)
  }
  
  /// returns the temp directory
  public static var tmp: Dir {
    return Dir(Dir.tmpPath)
  }

  /// returns a list of files in the inbox
  public static func scanInbox(_ ext: String) -> [String] {
    return Dir.inbox.scanExtensions(ext)
  }
  
} // Dir

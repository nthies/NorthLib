//
//  File.swift
//
//  Created by Norbert Thies on 20.11.19.
//  Copyright © 2019 Norbert Thies. All rights reserved.
//

import NorthLowLevel

/// Rudimentary wrapper around elementary file operations
open class File: DoesLog {
  
  fileprivate var hasStat: Bool { return getStat() != nil }
  fileprivate var _status: stat_t?
  fileprivate var fp: fileptr_t? = nil

  /// File status
  public var status: stat_t? { 
    get { return getStat() }
    set { if let st = newValue { _status = st; stat_write(&_status!, cpath) } }
  }

  /// Pathname as C String
  private(set) var cpath: UnsafeMutablePointer<CChar>
  
  /// Pathname of file
  public var path: String {
    didSet {
      _status = nil
      cpath = path.withCString { str_heap($0, 0) }
    }
  }
  
  /// Absolute pathname
  public func abs() -> String? {
    var str = fn_abs(cpath)
    defer { str_release(&str) }
    if let str = str { return String(validatingUTF8: str) }
    return nil
  }
  
  /// File size in bytes
  public var size: Int64 { 
    guard hasStat else { return 0 }
    return Int64(_status!.st_size) 
  }
  
  /// Returns the contents of the file (if it is an existing file)
  public var mem: Memory? {
    get {
      guard exists && isFile else { return nil }
      var tmp: Memory?
      open(mode: "r") { f in tmp = f.read() }
      return tmp
    }
    set (mem) { if let mem = mem { open(mode: "w") { f in f.write(mem: mem) } } }
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
    self.cpath = path.withCString { str_heap($0, 0) }
  }
  
  /// Initialisation with directory and file name
  public convenience init(dir: String, fname: String) {
    var str = dir.withCString { d in
      fname.withCString { f in fn_pathname(d, f) }
    }
    self.init(String(validatingUTF8: str!)!)
    str_release(&str)
  }
  
  /// deinit closes the file pointer if it has been opened
  deinit {
    if fp != nil { fclose(fp) }
    free(cpath)
  }
  
  /// open opens the File as a C file pointer, executes the passed closure and closes
  /// the file pointer
  public func open(mode: String = "r", closure: (File) throws ->()) rethrows {
    if file_open(&self.fp, self.cpath, mode) == 0 {
      defer { file_close(&self.fp) }
      try closure(self)
    }
  }
      
  /**
   * open opens a File as C file pointer, executes the passed closure and closes
   * the file pointer. 
   * 
   * If the argument _path_ == "-" then, depending on _mode_:
   * * mode == "r": /dev/fd/0 (ie. STDIN) is opened for reading
   * * mode == "w": /dev/fd/1 (ie. STDOUT) is opened for writing
   *
   * - parameters:
   *   - path: pathname of file to open
   *   - mode: open mode (by default "r")
   */ 
  public static func open(path: String, mode: String = "r",
    closure: (File) throws ->()) rethrows {
    var fpath = path
    if path == "-" { fpath = (mode == "r") ? "/dev/fd/0" : "/dev/fd/1" }
    try File(fpath).open(mode: mode, closure: closure)
  }

  /// Reads one line of characters from the file
  public func readline() -> String? {
    guard fp != nil else { return nil }
    var str = file_readline(fp)
    if let s = str {
      let ret = String(validatingUTF8: s)
      str_release(&str)
      return ret
    }
    return nil
  }
    
  /// Writes one line of characters to the file, a missing \n is added
  @discardableResult
  public func writeline(_ str: String) -> Int {
    guard fp != nil else { return -1 }
    let ret = str.withCString { s in file_writeline(fp, s) }
    return Int(ret)
  }
  
  /// Reads mem.length bytes (if available) and stores them in 'mem'.
  public func read(mem: Memory) -> Int {
    guard
      fp != nil,
      mem.length > 0
    else { return -1 }
    return Int(file_read(fp, mem.ptr, Int32(mem.length)))
  }
  
  /// Reads 'nbytes' bytes from the file's current position and stores
  /// them into the returned Memory object. On EOF nil is returned.
  public func read(nbytes: Int = -1) -> Memory? {
    guard fp != nil else { return nil }
    let len: Int = (nbytes < 0) ? Int(self.size) : nbytes
    let mem = Memory(length: len)
    let nbytes = read(mem: mem)
    if nbytes > 0 {
      if nbytes != len { mem.resize(length: nbytes) }
      return mem
    }
    return nil
  }

  /// Writes the passed data to the file's current position
  @discardableResult
  public func write(ptr: UnsafeRawPointer?, length: Int) -> Int {
    guard let ptr = ptr else { return 0 }
    let ret = file_write(fp, ptr, Int32(length))
    return Int(ret)
  }
  
  /// Writes the passed data to the file's current position
  @discardableResult
  public func write(mem: Memory) -> Int {
    let ret = file_write(fp, mem.ptr, Int32(mem.length))
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
  
  /// Returns the basename of a given pathname
  public var basename: String {
    var str = fn_basename(cpath)
    let ret = String(validatingUTF8: str!)
    str_release(&str)
    return ret!
  }
  
  /// Returns the dirname of a given pathname
  public var dirname: String {
    var str = fn_dirname(cpath)
    let ret = String(validatingUTF8: str!)
    str_release(&str)
    return ret!
  }
  
  /// Returns the progname (basename without extension) of a given pathname
  public var progname: String {
    var str = fn_progname(cpath)
    let ret = String(validatingUTF8: str!)
    str_release(&str)
    return ret!
  }
  
  /// Returns the prefname (path without extension) of a given pathname
  public var prefname: String {
    var str = fn_prefname(cpath)
    let ret = String(validatingUTF8: str!)
    str_release(&str)
    return ret!
  }

  /// Returns the extname (extension) of a given pathname
  public var extname: String {
    var str = fn_extname(cpath)
    let ret = String(validatingUTF8: str!)
    str_release(&str)
    return ret!
  }

  /// Links the file to an existing file 'to' (beeing an absolute path)
  /// (ie. makes self a symbolic link)
  public func link(to: String) {
    let _ = to.withCString { file_link($0, cpath) }
  }
  
  /**
   * Copies the file to a new location while maintaining the file status.
   *
   * This method copies regular files only. The status of the destination
   * file is set to the status of the current file.
   *
   * - Parameters:
   *   - to: path name of destination file
   *   - isOverwrite: existing destination files are overwritten
   *
   * - Returns: number of bytes copied or -1 in case of Error
   */
  @discardableResult
  public func copy(to: String, isOverwrite: Bool = true) -> Int {
    guard exists && isFile else { return -1 }
    if isOverwrite {
      let dest = File(to)
      if dest.exists { dest.remove() }
    }
    Dir(File.dirname(to)).create()
    let ret = to.withCString { dest -> Int in
      let nbytes = file_copy(cpath, dest)
      if hasStat && nbytes >= 0 { stat_write(&_status!, dest) }
      return Int(nbytes)
    }
    return ret
  }
  
  /**
   * Moves the file to a new location.
   *
   * This method moves regular files only.
   *
   * - Parameters:
   *   - to: path name of destination file
   *   - isOverwrite: existing destination files are overwritten
   *
   * - Returns: >=0 if successful or -1 in case of Error
   */
  @discardableResult
  public func move(to: String, isOverwrite: Bool = true) -> Int {
    guard exists && isFile else { return -1 }
    if isOverwrite {
      let dest = File(to)
      if dest.exists { dest.remove() }
    }
    Dir(File.dirname(to)).create()
    let ret = to.withCString { dest -> Int in
      let nbytes = file_move(cpath, dest)
      if hasStat && nbytes >= 0 { stat_write(&_status!, dest) }
      return Int(nbytes)
    }
    return ret
  }

  /// Removes the file (and all subdirs if self is a directory)
  public func remove() {
    guard exists else { return }
    if isDir { dir_remove(cpath) }
    else { file_unlink(cpath) }
  }
  
  /**
   * Returns the link name if the current file is a symbolic link.
   *
   * The link name is the path the symbolic link points to.
   *
   * - Returns: Link name or nil if no symbolic link
   */
  public func readlink() -> String? {
    guard exists && isLink else { return nil }
    if let link = file_readlink(cpath) {
      return String(validatingUTF8: link)
    }
    else { return nil }
  }
  
  /// Returns the link name of the file with path name 'path'.
  public static func readlink(path: String) -> String? {
    File(path).readlink()
  }

  /// Returns the basename of a given pathname
  public static func basename(_ fn: String) -> String {
    return File(fn).basename
  }
  
  /// Returns the dirname of a given pathname
  public static func dirname(_ fn: String) -> String {
    return File(fn).dirname
  }
  
  /// Returns the progname (basename without extension) of a given pathname
  public static func progname(_ fn: String) -> String {
    return File(fn).progname
  }
  
  /// Returns the prefname (path without extension) of a given pathname
  public static func prefname(_ fn: String) -> String {
    return File(fn).prefname
  }
  
  /// Returns the extname (extension) of a given pathname
  public static func extname(_ fn: String) -> String {
    return File(fn).extname
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
    if let cont = dir_content(cpath) { return Array<String>(cont) }
    else { return [] }
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
      let fe = File.extname(fn).lowercased()
      if let _ = lext.firstIndex(of: fe) { return true }
      return false
    }
  }
  
  /// scanExtensions searches for files beeing matched by 'ext'.
  public func scanExtensions( _ ext: String... ) -> [String] {
    return scanExtensions(ext)
  }
  
  /// returns the current working directory path
  public static var currentPath: String { Dir(".").abs()! }
  
  /// returns the current working directory
  public static var current: Dir {
    return Dir(Dir.currentPath)
  }
  
  /// returns the temporary directory path
  public static var tmpPath: String { String(validatingUTF8: fn_tmpdir()!)! }

  /// returns the temporary directory
  public static var tmp: Dir { Dir(tmpPath) }

} // Dir

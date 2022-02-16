//
//  ZipFile.swift
//
//  Created by Norbert Thies on 14.07.21.
//  Copyright © 2021 Norbert Thies. All rights reserved.
//

import NorthLowLevel

/// A class to handle zip streams
open class ZipStream {
  
  /// The C++ reader class
  private var reader: UnsafeMutableRawPointer?
  
  // The closure to call upon file found
  private var onFileClosure: ((String, Memory)->())?
  
  /// Define the closure to call upon file found
  public func onFile(closure: @escaping (String, Memory)->()) {
    onFileClosure = closure
  }
  
  public init() {
    reader = zip_stream_init(voidptr(obj: self)) { (context,name,data,length) in
      let ctx: ZipStream = voidptr(ptr: context!)
      let fname = String(validatingUTF8: name!)!
      ctx.onFileClosure?(fname, Memory(ptr: data, length: Int(length)))
    }
  }
  
  deinit { zip_stream_release(reader) }
  
  /// Scan chunk of data for embedded files
  public func scanData(mem: Memory, length: Int) throws {
    if zip_stream_scan(reader, mem.ptr, Int32(length)) < 0 {
      throw String(validatingUTF8: zip_stream_lasterr(reader))!
    }
  }
  
} // class ZipStream

/// A class for handling zip-packed files
open class ZipFile {
  
  var zipStream: ZipStream
  var zipFile: String
  
  /// Initialize with pathname
  public init(path: String) {
    self.zipFile = path
    self.zipStream = ZipStream()
  }
  
  /// Unpack to given directory
  public func unpack(toDir dir: String) throws {
    zipStream.onFile { (name, mem) in
      let path = "\(dir)/\(name)"
      Dir(File.dirname(path)).create()
      File(path).mem = mem
    }
    try File.open(path: zipFile, mode: "r") { [weak self] file in
      guard let self = self else { return }
      while let data = file.read(nbytes: 20*1024) {
        try self.zipStream.scanData(mem: data, length: data.length)
      }
    }
  }
  
}  // class ZipFile

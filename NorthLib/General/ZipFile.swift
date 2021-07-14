//
//  ZipFile.swift
//  NorthLib
//
//  Created by Norbert Thies on 14.07.21.
//  Copyright © 2021 Norbert Thies. All rights reserved.
//

import Foundation

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
  public func unpack(toDir dir: String) {
    zipStream.onFile { (name, data) in
      guard let name = name, let data = data else { return }
      let path = "\(dir)/\(name)"
      Dir(File.dirname(path)).create()
      File(path).data = data
    }
    File.open(path: zipFile, mode: "r") { [weak self] file in
      guard let self = self else { return }
      while let data = file.read() {
        self.zipStream.scanData(data)
      }
    }
  }
  
}

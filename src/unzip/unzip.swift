//
//  unzip.swift
//
//  Created by Norbert Thies on 11.02.22.
//  Copyright © 2022 Norbert Thies. All rights reserved.
//

import NorthBase
import ArgumentParser

@main
class Unzip: ParsableCommand {
  
  static var configuration = CommandConfiguration(
    abstract: "Unpacks files in zip-Format.",
    discussion: """
      This small tool is a streaming zip-File unpacker. It does not read the 
      zip-File's table of contents. Instead it uses the in-stream zip-File header
      preceeding each single file in the zip-Stream to get the name of the
      file to extract.
      If no arguments are given, the zip-File will be read from STDIN.
    """)

  @Flag(name: .shortAndLong, help: "List content only")
  var list: Bool = false
  
  @Flag(name: .shortAndLong, help: "Verbose mode - list files extracted")
  var verbose: Bool = false
  
  @Argument(help: "Name(s) of zip files, \"-\" for STDIN")
  var files: [String] = ["-"]
  
  func run() throws {
    for fn in files {
      if fn == "-" || File(fn).exists {
        let zipStream = ZipStream()
        zipStream.onFile { [weak self] (name, data) in
          guard let self = self else { return }
          if self.list || self.verbose {
            print("\(name): \(data.length) bytes")
          }
          if !self.list { File(name).mem = data }
        }
        try File.open(path: fn) { file in
          let data = Memory(length: 10*1024)
          var nbytes: Int
          repeat {
            nbytes = file.read(mem: data)
            if nbytes > 0 { try zipStream.scanData(mem: data, length: nbytes) }
          } while nbytes > 0
        }
      }
    }
  }
  
  required init() {}
}

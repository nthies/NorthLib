//
//  Utsname.swift
//
//  Created by Norbert Thies on 22.06.18.
//  Copyright © 2018 Norbert Thies. All rights reserved.
//

import NorthLowLevel

/// A wrapper around POSIX's struct utsname
public struct Utsname {
  
  static public var sysname: String { return String(cString: uts_sysname()) }
  static public var nodename: String { return String(cString: uts_nodename()) }
  static public var release: String { return String(cString: uts_release()) }
  static public var version: String { return String(cString: uts_version()) }
  static public var machine: String { return String(cString: uts_machine()) }

} // Utsname

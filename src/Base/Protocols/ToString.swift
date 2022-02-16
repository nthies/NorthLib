//
//  ToString.swift
//
//  Created by Norbert Thies on 26.09.19.
//  Copyright © 2019 Norbert Thies. All rights reserved.
//

import Foundation

/** 
 ToString simply demands a function toString() to return a String representation
 of the receiver.
 
 In addition a var 'description' is provided to conform to  CustomStringConvertible.
 **/
public protocol ToString: CustomStringConvertible {
  func toString() -> String
}

public extension ToString {
  var description: String { return toString() }
  var localizedDescription: String { return toString() }
}

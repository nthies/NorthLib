//
//  Copying.swift
//
//  Created by Norbert Thies on 21.01.2022
//  Copyright © 2022 Norbert Thies. All rights reserved.
//

public protocol Copying {
  init(_ val: Self) throws
  func deepcopy() throws -> Self
}

extension Copying {
  public func deepcopy() throws -> Self { try Self.init(self) }
}

extension String:Copying {}
extension Int:Copying {}
extension Double:Copying {}
extension Float:Copying {}
extension Bool:Copying {}

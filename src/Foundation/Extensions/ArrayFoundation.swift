//
//  ArrayFoundation.swift
//
//  Created by Norbert Thies on 12.12.18.
//  Copyright © 2018 Norbert Thies. All rights reserved.
//

import Foundation

public extension Array where Element: NSCopying {
  
  /// creates a deep copy of the array
  func copy() -> Array {
    self.map { elem in elem.copy() as! Element }
  }
  

}

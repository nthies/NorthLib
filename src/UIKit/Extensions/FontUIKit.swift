//
//  FontExtensions.swift
//
//  Created by Norbert Thies on 04.03.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit

public extension UIFont {

  /// Register font from Data and return name
  static func register(data: Data) -> String? {
    if let dataProvider = CGDataProvider(data: data as NSData),
       let cgFont = CGFont(dataProvider) {
      var error: Unmanaged<CFError>?
      if CTFontManagerRegisterGraphicsFont(cgFont, &error) {
        return cgFont.postScriptName! as String
      }
    }
    return nil
  }
  
  /// Register font from file in local FS and return name
  static func register(path: String) -> String? {
    return register(data: File(path).data)
  }
  
  /// Get font from file with extension ".ttf" in main Bundle
  static func register(name: String) -> String? {
    guard let path = Bundle.main.path(forResource: name, ofType: "ttf") 
      else { return nil }
    return register(path: path)
  }

}

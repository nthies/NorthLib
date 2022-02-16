//
//  Theme.swift
//
//  Created by Norbert Thies on 02.03.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit

@resultBuilder
struct ThemeBuilder {
  static func buildBlock(_ items: Theme...) -> [Theme] {
    return items
  }  
} // ThemeBuilder

public class Theme {
  
  var elements: [Theme]?
  var name: String?
  
  public static var isLight: Bool { 
    if #available(iOS 13.0, *) {
      return UITraitCollection.current.userInterfaceStyle == .light 
    }
    else { return true }
  }
  public static var isDark: Bool { !isLight }

  func lookup<T>() -> T? {
    guard let elems = elements else { return nil }
    for e in elems { if let val = e as? T { return val } }
    return nil
  }
  
  public var color: Element<UIColor>? { return lookup() }
  public var background: Element<Background>? { return lookup() }
  public var font: Element<UIFont>? { return lookup() }
    
  public init(_ name: String?, @ThemeBuilder _ elements: ()->[Theme]) {
    self.name = name
    self.elements = elements()
  }
  
  public init(_ name: String?, @ThemeBuilder _ element: ()->Theme) {
    self.name = name
    self.elements = [element()]
  }
  
  func print(_ indent: Int = 0) {
    let className = type(of: self)
    Swift.print("\(String(repeating: " ", count: indent))\(className): \(name ?? "[undefined]")")
    if let elems = elements { for e in elems { e.print(indent + 2) } }
  }
  
  public class Element<T>: Theme {
    public var light: T
    public var dark: T?
    public var value: T { Theme.isLight ? light : (dark ?? light) }
    public init(name: String?, light: T, dark: T? = nil) {
      self.light = light
      self.dark = dark
      super.init(name, {})
    }
  }
  
  public class Color: Element<UIColor> {
    public init(name: String? = nil, light: Int, dark: Int? = nil, 
                alpha: CGFloat = 1) {
      let darkColor: UIColor? = (dark != nil) ? UIColor.rgb(dark!, alpha: alpha) : nil
      super.init(name: name, light: UIColor.rgb(light, alpha: alpha), dark: darkColor)
    }
  }
  
  public class Background: Color {}
  
  public class Font: Element<UIFont> {
    public init(name: String? = nil, light: String, dark: String? = nil) {
      super.init(name: name, light: UIFont())
    }
    public init(name: String? = nil, light: [String], dark: [String]? = nil) {
      super.init(name: name, light: UIFont())
    }
  }
  
}

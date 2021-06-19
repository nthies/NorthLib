//
//  Defaults.swift
//
//  Created by Norbert Thies on 08.04.17.
//  Copyright © 2017 Norbert Thies. All rights reserved.
//

import UIKit


/// The type of device currently in use
public enum Device: CustomStringConvertible {
  
  case iPad, iPhone, tv, unknown
  
  public var description: String { return self.toString() }
  public func toString() -> String {
    switch self {
    case .iPad:    return "iPad"
    case .iPhone:  return "iPhone"
    case .tv:      return "tv"
    case .unknown: return "unknown"
    }
  }
  
  /// Is true if the current device is an iPad
  public static var isIpad: Bool { return Device.singleton == .iPad }
  /// Is true if the current device is an iPhone
  public static var isIphone: Bool { return Device.singleton == .iPhone }
  /// Is true if the current device is an Apple TV
  public static var isTv: Bool { return Device.singleton == .tv }

  // Use Device.singleton
  fileprivate init() {
    let io = UIDevice.current.userInterfaceIdiom
    switch io {
    case .phone: self = .iPhone
    case .pad:   self = .iPad
    case .tv:    self = .tv
    default:     self = .unknown
    }
  }
  
  public static var deviceType = "apple"
  
  public static var deviceFormat : String {
    switch Device.singleton {
       case .iPad :  return "tablet"
       case .iPhone: return "mobile"
       default: return "desktop"
     }
  }
 
  /// The Device singleton specifying the current device type
  static public let singleton = Device()
  
}

extension Utsname {
  /// Returns mashine id on real device e.g. iPhone 10,6 or Simulator (iPhone X) on Simulator
  static public var machineModel: String {
    if Self.machine == "i386" || Self.machine == "x86_64" {
      return "Simulator (\(UIDevice().name))"
    }
    return Self.machine
  }
}


/** The Defaults class is just some syntactic sugar around iOS' UserDefaults.
 
 In addition to simple key/value pairs this class manages so called scoped key/values.
 A scoped key is a key prefixed by a string "<scope>.". This may be useful if default
 values may depend on whether they are used on an iPad or on an iPhone.
 Eg. 
   let dfl = Defaults.singleton
   dfl["iPhone","width"] = "120"
   dfl["iPad","width"] = "240"
 will create the key/value pairs "iPhone.width"="120" and "iPad.width"="240".
 When Defaults.singleton is created, a scope corresponding to the device currently 
 in use is added. Eg. if running on an iPhone, Defaults.singleton implicitly performs
   addScope("iPhone")
 In addition to scopes you may use Defaults belonging to a suite of apps (ie. some
 apps sharing their default values). To set up this sharing you must define a suiteName 
 before accessing Defaults.singleton, eg:
   Defaults.suiteName = "MyAppGroup"
   let dfl = Defaults.singleton
 Now all Defaults are shared between all apps using the same suitName "MyAppGroup"
 and all keys are prefixed with this suiteName. Eg. dfl["iPad","width"] = "240"
 would create the key/value pair "MyAppGroup.iPad.width"="240".
 */
open class Defaults: NSObject {
  
  /// A Notification used to pass to observers
  public class Notification: NSObject {
    public var key: String
    public var val: String?
    public var scope: String?
    
    private init( key: String, val: String?, scope: String? = nil ) {
      self.key = key
      self.val = val
      self.scope = scope
      super.init()
    }
    public static let name = NSNotification.Name(rawValue: "Defaults.Notification")
    static func send( _ key: String, _ val: String?, _ scope: String? ) {
      NotificationCenter.default.post( name: Notification.name,
        object: Notification(key: key, val: val, scope: scope) )
    }
    static func addObserver(atChange: @escaping (String, String?, String?)->()) {
      NotificationCenter.default.addObserver(forName: Notification.name,
        object: nil, queue: nil ) { (nfc) -> () in
          if let dnfc: Defaults.Notification = nfc.object as? Defaults.Notification {
            atChange( dnfc.key, dnfc.val, dnfc.scope )
          }
      }
    }
    static func removeObserver( _ observer: Any ) {
      NotificationCenter.default.removeObserver(observer)
    }
  }
  
  public typealias Observer = NSObjectProtocol?

  /// Receive Defaults change notification
  @discardableResult
  public static func receive(closure: @escaping (Defaults.Notification)->()) 
    -> Observer {
    let nn = Notification.name
    let observer = NotificationCenter.default.addObserver(forName: nn, 
                     object: nil, queue: nil) { notification in
      if let dnfc = notification.object as? Defaults.Notification {
        closure(dnfc)
      }
    }
    return observer
  }
  
  /// Receive Defaults change notification of a specific key
  public static func receive(key: String, closure: @escaping(String)->()) {
    self.receive { dnfc in
      let (k,_,_) = Defaults.singleton.find(key)
      if dnfc.key == k, let val = dnfc.val { closure(val) }
    }
  }
  
  /// Receive Defaults change notification of a specific key as Bool
  public static func receive(key: String, closure: @escaping(Bool)->()) {
    self.receive { dnfc in
      if dnfc.key == key, let val = dnfc.val?.bool { closure(val) }
    }
  }
  
  /// Receive Defaults change notification of a specific key as Int
  public static func receive(key: String, closure: @escaping(Int)->()) {
    self.receive { dnfc in
      if dnfc.key == key, let str = dnfc.val, let val = Int(str) { closure(val) }
    }
  }

  /// The Values class used to set a dictionary of key/values
  public class Values {
    var scope: String?
    var values: [String:String]
    public init( scope: String?, values: [String:String] ) {
      self.scope = scope
      self.values = values
    }
    public convenience init( _ values: [String:String] )
      { self.init( scope: nil, values: values ) }
  }

  /// iOS UserDefaults
  public var userDefaults: UserDefaults
  
  // prefix of keys (if defined)
  private var _suite: String?
  /// Name of application suite
  public var suite: String? { return _suite }
  
  // List of defined scopes, "iPad" xor "iPhone" is added upon init()
  private var scopes: Set<String> = []
  
  /// Adds scope to list of scopes
  public func addScope( _ scope: String? ) {
    if let sc = scope { scopes.insert(sc) }
  }
  
  /// Removes scope from the list of scopes
  public func removeScope( _ scope: String ) {
    scopes.remove( scope )
  }
  
  /// Removes all scopes
  public func removeAllScopes() {
    scopes = []
  }
  
  private func prefix(_ scope: String? = nil) -> String {
    var pref = ""
    if suite != nil { pref += "\(suite!)." }
    if scope != nil { pref += "\(scope!)." }
    return pref
  }
  
  /// Find value for key in list of scopes
  public func find(_ key: String) -> (key: String, val: String?, scope: String?) {
    var k: String
    for ctx in scopes {
      let pref = prefix(ctx)
      k = pref + key
      if let val = userDefaults.string(forKey: k) {
        return (k, val, ctx)
      }
    }
    k = prefix() + key
    if let val = userDefaults.string(forKey: k) { return (k, val, nil) }
    return (k, nil, nil)
  }
  
  /// defaults[key] - returns the value associated with key in any defined scope
  /// defaults[key] = value - sets the associated value in that scope where key
  /// is defined or in the global scope if key isn't defined in any scope
  /// defaults[key] = nil - removes the key/value pair from Defaults
  public subscript( _ key: String ) -> String? {
    get { return find(key).val }
    set(val) {
      let old = find(key)
      let k = old.key
      if old.val != val {
        if let v = val { userDefaults.set(v, forKey: k) }
        else if old.val != nil { userDefaults.removeObject(forKey: k) }
        else { return }
        userDefaults.synchronize()
        Notification.send(k, val, old.scope)
      }
    }
  }
  
  /// defaults[scope,key] - returns the value associated with key in given scope
  /// defaults[scope,key] = value - sets the associated value in given scope
  /// defaults[scope,key] = nil - removes the key/value pair from Defaults
  public subscript( _ scope: String?, _ key: String ) -> String? {
    get { return userDefaults.string(forKey: prefix(scope) + key) }
    set(val) {
      let k = prefix(scope) + key
      let old = userDefaults.string(forKey: k)
      if old != val {
        if let v = val { userDefaults.set(v, forKey: k) }
        else if old != nil { userDefaults.removeObject(forKey: k) }
        else { return }
        userDefaults.synchronize()
        Notification.send( key, val, scope )
      }
    }
  }
  
  // setIfUndefined sets a key/value pair if there is no previous definition
  private func setIfUndefined( _ key: String, _ val: String, _ scope: String?,
                               _ isNotify: Bool ) {
    var k = prefix() + key
    if scope != nil { k = prefix(scope!) + key }
    let v = userDefaults.string(forKey: k)
    if v == nil {
      userDefaults.set(val, forKey: k)
      if isNotify { Notification.send( key, val, scope ) }
    }
  }
    
  /// setDefaults is used to set all key/value pairs given in 'values'
  /// if they are not already defined.
  public func setDefaults( values: Values, isNotify: Bool = false ) {
    for (k,v) in values.values {
      setIfUndefined(k, v, values.scope, isNotify)
    }
  }
  
  /// Returns true if a given key is associated with a value
  public func isDefined( _ key: String ) -> Bool { return self[key] == nil }
  
  // A new instance is initialized with the global UserDefaults dictionary.
  // In addition the scope of Device.singleton.description is added.
  public init(suiteName: String? = nil) {
    _suite = suiteName
    userDefaults = UserDefaults(suiteName: suiteName)!
    super.init()
    addScope(Device.singleton.description)
  }
  
  /// The suite name (ie name of application group) to use when creating the singleton
  public static var suiteName: String?
  
  /// The singleton instance of the Defaults class
  public static let singleton = Defaults(suiteName: Defaults.suiteName)
  
  /// Print all key/value pairs
  public static func print() {
    let ds = Defaults.singleton
    if !ds.scopes.isEmpty {
      Swift.print("Scopes:", terminator:" ")
      for s in Defaults.singleton.scopes {
        Swift.print(s,terminator:" ")
      }
      Swift.print()
    }
    let dict = ds.userDefaults.dictionaryRepresentation()
    let p = ds.prefix()
    for (k,v) in dict {
      if !(k.starts(with: p)) { continue }
      var val: String
      switch v {
        case let s as String:
          val = s
        case let conv as CustomStringConvertible:
          val = conv.description
        default:
          val = "[unknown]"
      }
      Swift.print( "\(k): \(val)" )
    }
  }
  
} // class Defaults

/// Protocol for types converting a String to itself and vice versa
public protocol StringConvertible {
  static func fromString(_ str: String?) -> Self
  static func toString(_ val: Self) -> String
}

extension String: StringConvertible {
  public static func fromString(_ str: String?) -> String { str ?? "" }
  public static func toString(_ val: String) -> String { val }
}

extension Bool: StringConvertible {
  public static func fromString(_ str: String?) -> Bool {
    if let str = str { return str.bool }
    return false
  }
  public static func toString(_ val: Bool) -> String {
    return val ? "true" : "false"
  }
}

extension Int: StringConvertible {
  public static func fromString(_ str: String?) -> Int {
    if let str = str { return Int(str) ?? 0 }
    return 0
  }
  public static func toString(_ val: Int) -> String { "\(val)" }
}

extension Double: StringConvertible {
  public static func fromString(_ str: String?) -> Self {
    if let str = str { return Self(str) ?? 0 }
    return 0
  }
  public static func toString(_ val: Self) -> String { "\(val)" }
}

extension CGFloat: StringConvertible {
  public static func fromString(_ str: String?) -> Self {
    if let str = str, let d = Double(str) { return Self(d) }
    return 0
  }
  public static func toString(_ val: Self) -> String { "\(val)" }
}

/// A property wrapper for Defaults
@propertyWrapper public class Default<T: StringConvertible> {
  
  /// Type of closure to call when the value has been changed from outside
  public typealias ChangeClosure = (T)->()
  
  /// The String to use as Defaults key
  public var key: String
  
  /// The optional associated closure to call if the Default value has been changed
  private var onChangeClosure: ThreadClosure<T>?
  
  /// The wrapped value is in essence Defaults.singleton[key]
  public var wrappedValue: T {
    get { T.fromString(Defaults.singleton[key]) }
    set { Defaults.singleton[key] = T.toString(newValue) }
  }
  
  /// The projected value is the wrapper itself
  public var projectedValue: Default<T> { self }
  
  private func setupNotifications() {
    guard onChangeClosure == nil else { return }
    Defaults.receive(key: key) { [weak self] (val: String) in
      self?.onChangeClosure?.call(arg: T.fromString(val))
    }
  }
  
  /// Use onChange to define a closure that is called when the Default value has
  /// been changed
  public func onChange(closure: @escaping ChangeClosure) {
    setupNotifications()
    onChangeClosure = ThreadClosure(closure)
  }
  
  /// Delete Defaults entry
  public func delete() { Defaults.singleton[key] = nil }

  public init(_ key: String) { self.key = key }
}

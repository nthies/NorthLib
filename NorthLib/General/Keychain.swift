//
//  Keychain.swift
//
//  Created by Norbert Thies on 24.02.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import Foundation

/** 
 A simple wrapper around Apples's keychain functions
 
 This class allows you to access values in Apple's keychain as a subscript of 
 the singleton keychain object. Eg.:
 ````
   let kc = Keychain.singleton // access singleton Keychain object
   kc["password"] = "secret"   // store String "secret" under key "password"
   print(kc["password"])       // access the String stored under key "password"
   kc["password"] = nil        // delete the String stored under key "password"   
 ````
 TODO: Implement sharing of secrets across all devices an Apple-ID is logged into,
       currently only the device having stored the key/value pairs may access them
*/
open class Keychain: DoesLog {
  
  /// Set accessGroup to your keychain group prefixed by your team ID
  public static var accessGroup: String?
  public static var singleton: Keychain = Keychain()
  private init() {}
  
  private func query(key: String) -> [String:Any] {
    var ret: [String:Any] = [
      kSecAttrService as String : App.bundleIdentifier,
      kSecClass as String : kSecClassGenericPassword as String,
      kSecAttrAccount as String : key,
      kSecAttrSynchronizable as String : kCFBooleanTrue!
    ]
    if let group = Keychain.accessGroup {
      ret[kSecAttrAccessGroup as String] = group
    }
    return ret
  }
  
  private func handleError(_ status: OSStatus) {
    if status != errSecSuccess {
      if #available(iOS 11.3, *) {
        if let str = SecCopyErrorMessageString(status, nil) { error("\(str)") }
      } else {
        error("Can't access keychain: Error \(status)")
      }
    }
  }
  
  /// delete key/value from keychain
  public func delete(key: String) {
    let query = query(key: key)
    let status: OSStatus = SecItemDelete(query as CFDictionary)
    if status != errSecSuccess && status != errSecItemNotFound {
      handleError(status)
    }
  }
  
  // get value from keychain
  private func get(key: String) -> String? {
    var query = query(key: key)
    query[kSecReturnData as String] = kCFBooleanTrue!
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    var ret: AnyObject?
    let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &ret)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      handleError(status)
      return nil
    }
    if let data = ret as? Data { return String(data: data, encoding: .utf8) }
    return nil
  }
  
  // put value into keychain
  private func set(key: String, value: String) {
    if let old = get(key: key) {
      if old == value { return }
      delete(key: key)
    }
    let data = value.data(using: .utf8)!
    var query = query(key: key)
    query[kSecValueData as String] = data
    let status = SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else {
      handleError(status)
      return
    }
    Notification.send("Keychain", content: (key: key, val: value))
  }
  
  /// obj[key] - returns the value associated with key
  /// obj[key] = value - sets the associated value
  /// obj[key] = nil - removes the key/value pair from Keychain
  open subscript(_ key: String) -> String? {
    get { return get(key: key) }
    set(val) {
      if let v = val { set(key: key, value: v) }
      else { delete(key: key) }
    }
  }

} // Keychain

/// A property wrapper for Keychain values
@propertyWrapper public class Key<T: StringConvertible> {
  
  /// Type of closure to call when the value has been changed from outside
  public typealias ChangeClosure = (T)->()
  
  /// The String to use as Keychain key
  public var key: String
  
  /// The optional associated closure to call if the Keychain value has been changed
  private var onChangeClosure: ThreadClosure<T>?
  
  /// Shall we sync this key/value pait to user defaults?
  private var isSync = false
 
  /// The raw String? value (in essence Keychain.singleton[key])
  public var value: String? {
    get {
      if let kval = Keychain.singleton[key] { return kval }
      else if isSync {
        if let dval = Defaults.singleton[key] {
          Keychain.singleton[key] = dval
          return dval
        }
      }
      return nil
    }
    set {
      Keychain.singleton[key] = newValue
      if isSync { Defaults.singleton[key] = newValue }
    }
  }

  /// The wrapped value is the interpreted value as type T
  public var wrappedValue: T {
    get { T.fromString(value) }
    set { value = T.toString(newValue) }
  }
  
  /// The projected value is the wrapper itself
  public var projectedValue: Key<T> { self }
  
  private func setupNotifications() {
    guard onChangeClosure == nil else { return }
    Notification.receive("Keychain") { [weak self] notif in
      if let (key,val) = notif.content as? (String, String), self?.key == key {
        self?.onChangeClosure?.call(arg: T.fromString(val))
      }
    }
  }
  
  /// Use onChange to define a closure that is called when the Keychain value has
  /// been changed
  public func onChange(closure: @escaping ChangeClosure) {
    setupNotifications()
    onChangeClosure = ThreadClosure(closure)
  }
  
  /// Delete Keychain entry
  public func delete() { Keychain.singleton[key] = nil }
  
  public init(_ key: String, sync: Bool = false) {
    self.key = key
    isSync = sync
  }
}

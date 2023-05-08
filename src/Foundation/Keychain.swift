//
//  Keychain.swift
//
//  Created by Norbert Thies on 24.02.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import Foundation

/** 
 A simple wrapper around Apples's keychain functions
 
 This class allows you to access values in Apple's keychain as a
 subscript of the singleton keychain object. Eg.:
 ````
   let kc = Keychain.singleton // access singleton Keychain object
   kc["password"] = "secret"   // store String "secret" under key "password"
   print(kc["password"])       // access the String stored under key "password"
   kc["password"] = nil        // delete the String stored under key "password"   
 ````
*/
public final class Keychain: KVStore, Singleton {
  
  /// Key/Value base for UserDefaults
  struct KeychainBase: KVStoreBase, DoesLog {
    private var accessGroup: String?
    
    init(suite: String? = nil) { accessGroup = suite }
    
    // Produce query array
    private func query(key: String) -> [String:Any] {
      var ret: [String:Any] = [
        kSecAttrService as String : App.bundleIdentifier,
        kSecClass as String : kSecClassGenericPassword as String,
        kSecAttrAccount as String : key,
        kSecAttrSynchronizable as String : kCFBooleanTrue!
      ]
      if let group = accessGroup {
        ret[kSecAttrAccessGroup as String] = group
      }
      return ret
    }
    
    // Log error from Keychain DB
    private func handleError(_ status: OSStatus) {
      if status != errSecSuccess,
         let str = SecCopyErrorMessageString(status, nil) {
        error("\(str)")
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
    
    /// get value from keychain
    public func get(key: String) -> String? {
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
    
    /// put value into keychain
    public func set(key: String, val: String) {
      if let old = get(key: key) {
        if old == val { return }
        delete(key: key)
      }
      let data = val.data(using: .utf8)!
      var query = query(key: key)
      query[kSecValueData as String] = data
      let status = SecItemAdd(query as CFDictionary, nil)
      guard status == errSecSuccess else {
        handleError(status)
        return
      }
    }
    
    /// A dummy for Keychains
    func synchronize() {}
  }
  
  /// The singleton Keychain array
  public static var singleton: Keychain = Keychain()
  
  /// Init with suite name to share key/values between apps
  private init(suite: String? = nil) {
    super.init(base: KeychainBase(suite: suite), name: nil, suite: suite, device: nil)
  }

}
  
@propertyWrapper
public class Key<T: StringConvertible>: KeyValue<Keychain,T> {
  
  /// The wrapped value is interpreted as type T
  public override var wrappedValue: T {
    get { T.fromString(value) }
    set { value = T.toString(newValue) }
  }
  /// The projected value is the wrapper itself
  public override var projectedValue: Key<T> { self }

}

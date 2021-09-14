//
//  App.swift
//
//  Created by Norbert Thies on 22.06.18.
//  Copyright © 2018 Norbert Thies. All rights reserved.
//

import UIKit

extension String {
  public static func fromC(_ cstr: Int8...) -> String {
    return withUnsafePointer(to: cstr) {
      $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout.size(ofValue: cstr)) {
        String(cString: $0)
      }
    }
  }
}

/// A wrapper around POSIX's struct utsname
open class Utsname {
  
  static public var sysname: String { return String(cString: uts_sysname()) }
  static public var nodename: String { return String(cString: uts_nodename()) }
  static public var release: String { return String(cString: uts_release()) }
  static public var version: String { return String(cString: uts_version()) }
  static public var machine: String { return String(cString: uts_machine()) }

} // Utsname

/// The type of device currently in use
public enum Device: CustomStringConvertible {
  
  case iPad, iPhone, mac, tv, unknown
  
  public var description: String { return self.toString() }
  public func toString() -> String {
    switch self {
      case .iPad:    return "iPad"
      case .iPhone:  return "iPhone"
      case .mac:     return "Mac"
      case .tv:      return "TV"
      case .unknown: return "unknown"
    }
  }
  
  /// Is true if the current device is an iPad
  public static var isIpad: Bool { return Device.singleton == .iPad }
  /// Is true if the current device is an iPhone
  public static var isIphone: Bool { return Device.singleton == .iPhone }
  /// Is true if the current device is a Mac
  public static var isMac: Bool { return Device.singleton == .mac }
  /// Is true if the current device is an Apple TV
  public static var isTv: Bool { return Device.singleton == .tv }
  
  /// Is true if the current device is an Simulator
  public static var isSimulator:Bool {
      #if targetEnvironment(simulator)
        return true
      #else
        return false
      #endif
  }

  // Use Device.singleton
  fileprivate init() {
    let io = UIDevice.current.userInterfaceIdiom
    switch io {
      case .phone: self = .iPhone
      case .pad:   self = .iPad
      case .mac:   self = .mac
      case .tv:    self = .tv
      default:     self = .unknown
    }
  }
  
  public static var deviceType = "apple"
  
  public static var deviceFormat : String {
    switch Device.singleton {
      case .iPad :  return "tablet"
      case .iPhone: return "mobile"
      case .tv:     return "tv"
      default:      return "desktop"
    }
  }
  
  /// The Device singleton specifying the current device type
  static public let singleton = Device()
  
}

extension Utsname {
  /// Returns mashine id on real device e.g. iPhone 10,6 or Simulator (iPhone X) on Simulator
  static public var machineModel: String {
    #if targetEnvironment(simulator)
      return "Simulator (\(UIDevice().name))"
    #else
      return Self.machine
    #endif
  }
}

/// App description from Apple's App Store
open class StoreApp {
  
  public enum AppError: Error {
    case appStoreLookupFailed
  }
  
  /// Bundle identifier of app
  public var bundleIdentifier: String
  
  /// App store info
  public var info: [String:Any] = [:]
  
  /// App store version
  public var version: Version { return Version(info["version"] as! String) }
  
  /// URL of app store entry
  public var url: URL { return URL(string: info["trackViewUrl"] as! String)! }

  /// Minimal OS version of app in store
  public var minOsVersion: Version { return Version(info["minimumOsVersion"] as! String) }
  
  /// Release notes of last app update in store
  public var releaseNotes: String { return info["releaseNotes"] as! String }
  
  /// Lookup app store info of app with given bundle identifier
  public static func lookup(_ id: String) throws -> [String:Any] {
    let surl = "http://itunes.apple.com/lookup?bundleId=\(id)"
    let url = URL(string: surl)!
    do {
      let data = try Data(contentsOf: url)
      let json = try JSONSerialization.jsonObject(with: data,
          options: [.allowFragments]) as! [String: Any]
      if let result = (json["results"] as? [Any])?.first as? [String: Any] {
        return result
      }
      else { throw AppError.appStoreLookupFailed }
    }
    catch {
      throw AppError.appStoreLookupFailed
    }
  }
  
  /// Open app store with app description
  public func openInAppStore() {
    UIApplication.shared.open(url)
  }
  
  /// Retrieve app store data of app with given bundle identifier
  public init( _ bundleIdentifier: String ) throws {
    self.bundleIdentifier = bundleIdentifier
    self.info = try StoreApp.lookup(bundleIdentifier)
  }
  
} // class StoreApp

/// Currently running app
open class App {
  
  /// Info dictionary of currently running app
  public static let info = Bundle.main.infoDictionary!
  
  /// The current device
  public static let device = UIDevice.current
  
  /// Version string of currently running app
  public static var bundleVersion: String {
    return info["CFBundleShortVersionString"] as! String
  }
  
  /// Name of currently running app
  public static var name: String {
    return info["CFBundleDisplayName"] as! String
  }

  /// Build number of currently running app
  public static var buildNumber: String {
    return info["CFBundleVersion"] as! String
  }
  
  /// Is this release a beta version (last two digits of buildNumber < 60 and >= 30)
  public static var isBeta: Bool = {
    let nn = Int(buildNumber.suffix(2))!
    return (30 <= nn) && (nn < 60)
  }()
    
  /// Is this release an alpha version (last two digits of buildNumber < 30 and >= 0)
  public static var isAlpha: Bool = {
    let nn = Int(buildNumber.suffix(2))!
    return (0 <= nn) && (nn < 30)
  }()

  /// Is this release a Release (ie AppStore) version (last two digits of 
  /// buildNumber < 100 and >= 60)
  public static var isRelease: Bool = {
    let nn = Int(buildNumber.suffix(2))!
    return (60 <= nn) && (nn < 100)
  }()
  
  
  /// Get info is new Features are available
  /// Previously used Compiler Flags, unfortunatly they are harder to find within Source Code Search
  /// and dependecy to Alpha App Versions must be set for each Build
  /// - Parameter feature: Feature to check
  /// - Returns: true if Feature is Available
  public static func isAvailable(_ feature: Feature) -> Bool {
    switch feature {
      case .INTERNALBROWSER:
        return isAlpha //Only in Alpha Versions
      case .PDFEXPORT:
        return isAlpha //Only in Alpha Versions
    }
  }
  
  /// List of upcomming Features
  /// showBottomTilesAnimation is a ConfigVariable
  public enum Feature { case  PDFEXPORT, INTERNALBROWSER}

  /**
   Set alternate icon depending on alpha/beta/release version
   there must be PNG images named alpha@[23]x.png, beta[23]x.png
   and release[23]x.png available.
   
   If the current icon differs from the icon that should be used on
   the home screen, the App icon is changed. This invokes an
   Apple controlled alert telling the user that the icon will change.
   If given, a prepare closure is called before and after the icon
   change.
   
   - parameters:
     - alpha: Name of icon to use for alpha versions
     - beta: Name of icon to use for beta versions
     - release: Name of icon to use for release versions
     - prepare: Closure to call before and after icon changes
                The Bool argument indicates whether the closure
                is called before (true) or after the icon change
  **/
  public static func setAlternateIcon(alpha: String = "Alpha", 
    beta: String = "Beta", release: String = "Release",
    prepare: ((String?, String, Bool)->())? = nil) {
    if UIApplication.shared.supportsAlternateIcons {
      let oldName = UIApplication.shared.alternateIconName
      var newName: String?
      if isAlpha { newName = "Alpha" }
      else if isBeta { newName = "Beta" }
      else { newName = nil }
      if oldName != newName {
        if newName == nil { newName = "Release" }
        prepare?(oldName, newName!, true)
        UIApplication.shared.setAlternateIconName(newName) { err in
          if err != nil { 
            Log.error("Can't set alternate icon to: \(newName!)") 
          }
          prepare?(oldName, newName!, false)
        }
      }
    }
    else { Log.error("Alternate Icons are not supported") }
  }
  
  /// Bundle identifier of currently running app
  public static var bundleIdentifier: String {
    return info["CFBundleIdentifier"] as! String
  }
  
  /// Version of running app
  public static var version = Version(App.bundleVersion)
  
  /// AppStore app information
  public static var store: StoreApp? = {
    do { return try StoreApp(App.bundleIdentifier) }
    catch { return nil }
  }()
  
  /// Version of running OS
  public static var osVersion = Version(device.systemVersion)
  
  /// Returns true if a newer version is available at the app store
  public static func isUpdatable() -> Bool {
    if let sversion = store?.version {
      return (version < sversion) && (osVersion >= store!.minOsVersion)
    }
    else { return false }
  }
  
  /// Calls the passed closure if an update is avalable at the app store
  public static func ifUpdatable(closure: @escaping ()->()) {
    DispatchQueue.global().async {
      if App.isUpdatable() {
        DispatchQueue.main.async { closure() }
      }
    }
  }
  
  /// Returns the largest AppIcon
  private static var _icon: UIImage?
  public static var icon: UIImage? {
    if _icon == nil {
      guard 
        let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? NSDictionary,
        let primaryIconsDictionary = iconsDictionary["CFBundlePrimaryIcon"] as? NSDictionary,
        let iconFiles = primaryIconsDictionary["CFBundleIconFiles"] as? NSArray,
        let lastIcon = iconFiles.lastObject as? String,
        let img = UIImage(named: lastIcon) else { return nil }
      _icon = img
    }
    return _icon
  }
  
  /// InstallationId: A String uniquely identifying this App's installation on this
  /// unique device (called identifierForVendor by Apple)
  fileprivate static var _installationId: String?
  public static var installationId: String { 
    if _installationId == nil {
      let dfl = Defaults.singleton
      if let iid = dfl["installationId"] { _installationId = iid }
      else { 
        _installationId = UUID().uuidString 
        dfl["installationId"] = _installationId
      }
    }
    return _installationId!
  }
  
  public init() {}
  
} // class App

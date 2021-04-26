//
//  Database.swift
//
//  Created by Norbert Thies on 10.04.19.
//  Copyright © 2019 Norbert Thies. All rights reserved.
//

import Foundation
import CoreData

open class Database: DoesLog, ToString {
  
  /// name of database
  public var name: String
  
  /// name of data model
  public var modelName: String
  
  /// URL of model
  public lazy var modelURL = 
    Bundle.main.url(forResource: modelName, withExtension: "mom")!
  
  /// the model object
  public lazy var model = NSManagedObjectModel(contentsOf: modelURL)!
  
  /// the persistent store coordinator
  public lazy var coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
  
  /// The persistent store
  public var persistentStore: NSPersistentStore?
  
  /// application support directory
  public static var appDir: String { return Dir.appSupportPath }
    
  /// directory where DB is stored
  public static var dbDir: String { return Database.appDir + "/database" }
  
  /// path of database with given database name
  public static func dbPath(name: String) -> String
    { return Database.dbDir + "/\(name).sqlite" }
  
  /// returns true if a database with given name exists
  public static func exists(name: String) -> Bool {
    File(Database.dbPath(name: name)).exists
  }
  
  /// remove database
  public static func dbRemove(name: String) 
    { File(Database.dbPath(name: name)).remove() }
  
  /// rename database
  public static func dbRename(old: String, new: String) {
    let o = File(Database.dbPath(name: old))
    let n = File(Database.dbPath(name: new))
    if o.exists { o.move(to: n.path) }
  }
  
  /// path of database
  public var dbPath: String { return Database.dbPath(name: name) }
  
  /// managed object context of database
  public var context: NSManagedObjectContext?
  
  /// create/open database once
  private func openOnce(closure: @escaping (Error?)->()) {
    self.context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    self.context?.persistentStoreCoordinator = coordinator
    let path = Database.dbPath(name: name)
    Dir(Database.dbDir).create()
    let dbURL = URL(fileURLWithPath: path)
    let queue = DispatchQueue.global(qos: .userInteractive)
    queue.async { [weak self] in
      guard let self = self else { return }
      do {
        // let's do lightweight migration if possible
        let options = [NSMigratePersistentStoresAutomaticallyOption: true, 
                       NSInferMappingModelAutomaticallyOption: true]
        self.persistentStore = try self.coordinator.addPersistentStore(ofType:
          NSSQLiteStoreType, configurationName: nil, at: dbURL, options: options)
        DispatchQueue.main.sync { closure(nil) }
      }
      catch let err {
        closure(self.error(err))
      }
    }
  }

  public func open(closure: @escaping (Error?)->()) {
    self.openOnce { [weak self] err in
      guard let self = self else { return }
      if err != nil {
        Database.dbRemove(name: self.name)
        self.openOnce { [weak self] err in
          guard let self = self else { return }
          if err != nil { 
            closure(self.error("Can't create create database"))
          }
          else { closure(nil) }
        }
      }
      else { closure(nil) }
    }
  }
  
  /// Closes the DB
  public func close() {
    if let ps = persistentStore { try! coordinator.remove(ps) }
  }
  
  /// Removes DB and opens a new initialized version
  public func reset(closure: @escaping (Error?)->()) {
    close()
    Database.dbRemove(name: self.name)
    open(closure: closure)
  }
 
  public init(name: String,  model: String) {
    self.modelName = model
    self.name = name
  }
  
  public func toString() -> String {
    "\(name), model(\(modelName)):\n  \(dbPath)"
  }

  public func save(_ context: NSManagedObjectContext? = nil) {
    let ctx = (context != nil) ? context : self.context
    if ctx!.hasChanges { try! ctx!.save() }
  }
  
  public func inBackground(_ closure: @escaping (NSManagedObjectContext)->()) {
    let ctx = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    ctx.persistentStoreCoordinator = self.coordinator
    ctx.perform {
      closure(ctx)
      self.save(ctx)
    }
  }
  
} // class Database

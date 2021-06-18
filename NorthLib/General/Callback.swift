//
//  Callback.swift
//
//  Created by Norbert Thies on 25.05.21.
//  Copyright © 2021 Norbert Thies. All rights reserved.
//

import Foundation

/**
 A ThreadClosure wraps a closure and the Thread it was defined on for later
 execution.
 
 Assume you create a ThreadClosure object on Thread *A* like this:
 ````
 let tclosure = ThreadClosure { _ in print("test") }
 ````
 and later on a different (or the same) Thread *B* do:
 ````
 tclosure.call()
 ````
 then the closure stored in *tclosure* will be performed on Thread *A* and "test"
 will be printed to the console.
 */
open class ThreadClosure<T>: NSObject {
  /// The Thread this closure should execute on
  var thread: Thread
  /// The closure passed to init
  var closure: (T)->()
  
  /// Initialize with given closure in current thread of execution
  public init(_ closure: @escaping (T)->()) {
    self.closure = closure
    self.thread = Thread.current
  }
  
  /// Calls the closure on the Thread it was defined on
  public func call(arg: T, wait: Bool = false) {
    self.perform(#selector(callClosure), on: thread, with: arg,
                 waitUntilDone: wait)
  }
  @objc private func callClosure(arg: Any) { closure(arg as! T) }
}

/**
 Callback defines a property wrapper which manages callbacks to closures
 and sends notifications to interested parties.
 
 Let's start with a simple example:
 ````
 class A {
   ...
   @Callback
   var whenReady: Callback.Store
   ...
 }
 ````
 This defines a simple class *A* defining a variable *whenReady* which is in
 effect a function storing closures in an array hidden inside the wrapper.
 The idea is to call these closures when some method of *A* wishes
 to notify them.
 
 Let's further examine the use of *whenReady*:
 ````
 let a = A()
 a.whenReady { _ in print(1) }
 a.whenReady { _ in print(2) }
 ````
 and an extension to *A* notifying the closures `{print(1)}, {print(2)}`
 ````
 extension A {
   func someMethod() {
     $whenReady.notify(sender: self)
   }
 }
 ````
 The extension uses the projected value of *whenReady* to refer to the wrapper
 itself and uses its method *notify* to call the closures which in turn print
 *1* and *2*.
 
 The closures are called with an argument arg: Callback.Arg which is the tuple
 (content: Any?, sender: Any?). By convention *sender* is the object calling
 the closure and *content* is *some* arbitrary content. We could augment the
 above noted method as follows:
 ````
 extension A {
   func someMethod() {
     $whenReady.notify(sender: self, content: "test")
   }
 }
 ````
 and outside of *A* we could write the closure to call as:
 ````
 a.whenReady { arg in
   if let (content, sender) = arg as? Callback.Arg {
     // do somthing with content and sender
   }
 }
 ````
 
 # Callbacks to different threads
 
 Along with each closure beeing stored in the wrapper's closure array the thread
 in which the closure was defined is stored as well. When calling the closures
 each is called in that thread it was defined in. All closures are called by the
 run loop and not by the object notifying the closures. Hence closures notifying
 closures recursively will not lead to a stack full of closures and possible reference
 cycles.
 
 # Callbacks as Notifications

 In addition to closure calls the Callback property wrapper may also be used to
 send Notifications for a looser coupling of program code. To receive notifications
 access to the sending object is not necessary. The receiving party must only know
 the notification's message name. The class defining the wrapper could use the following
 syntax to send a Notification "test" when *whenReady* closures are called:
 ````
 class A {
   ...
   @Callback("test")
   var whenReady: Callback.Store
   ...
 }
 ````
 Somewhere else in your source code the Notification may be received using:
 ````
 Notification.receive("test") { notif in
   if let sender = notif.sender { /* do somthing with sender */ }
   if let content = notif.content { /* do something with content */ }
 }
 ````
 However it's not necessary to specify the Notification name when defining the
 property wrapper. You may do it at a later time:
 ````
   let a = A()
   a.$whenReady.notification = "test2"
 ````
 This would emit notifications with message name "test2".
 To disable *whenReady* Notifications set the notification name to nil:
 ````
   a.$whenReady.notification = nil
 ````
 
 # Remarks
 
 - Sometimes it's necessary to perform some computations before calling back to
 the closures. If these computations should only be performed when there are
 any closures defined or Notifications have been enabled then check this using:
 ````
   if $whenReady.needsNotification {
     // perform computations
     $whenReady.notify(...)
   }
 ````
 
 - If some setup is only needed when there are any closures added or notifications
 enabled you can define a closure to be called:
 ````
   $whenReady.whenActivated { isActivated in
     if isActivated { /* closure added or notification enabled */ }
     else { /* no more closures waiting and no notification defined */ }
   }
 ````
 
 - There are two generic convenience Callback methods to access sender and content
 parts of the argument passed to the closures - `Callback.sender` and
 `Callback.content`, e.g.:
 ````
   whenReady { arg in
     if let sender: A = Callback.sender(arg) { ... }
     if let content: Bool = Callback.content(arg) { ... }
   }
 ````
 */
@propertyWrapper
open class Callback {
  
  // Syntactic sugar
  public typealias Closure = (Any?)->()
  public typealias Store = (@escaping Closure)->()
  public typealias Arg = (content: Any?, sender: Any?)
  
  /// Returns content of closure argument
  public static func content<T>(_ arg: Any?) -> T? {
    if let (c,_) = arg as? Arg, let v = c as? T {
      return v
    }
    else { return nil }
  }
  
  /// Returns sender of closure argument
  public static func sender<T>(_ arg: Any?) -> T? {
    if let (_,s) = arg as? Arg, let v = s as? T {
      return v
    }
    else { return nil }
  }
  
  // Array of closures
  private var closures: [ThreadClosure<Any?>] = []
  // Semaphore protecting access to *closures*
  private var semaphore = DispatchSemaphore(value: 1)
  // Activation closure
  private var activated: ((Bool)->())? = nil
  
  /// Define closure to call when closures are stored in/removed from the array
  /// or when notifications change
  public func whenActivated(closure: ((Bool)->())?) {
    activated = closure
    activated?(needsNotification)
  }
  
  /// Name of notification to send (if any)
  public var notification: String? = nil {
    didSet { activated?(needsNotification) }
  }
  
  /// Is a Notification defined or are there closures defined?
  public var needsNotification: Bool { notification != nil || closures.count > 0 }
  
  /// The wrapped value is a function storing closures in the closure arry.
  public lazy var wrappedValue: Store = { closure in self.store(closure: closure) }
  
  /// Store a closure in the closure array and return its index which
  /// can be used to remove the closure from the array at a later time.
  @discardableResult
  public func store(closure: @escaping Closure) -> Int {
    self.semaphore.wait()
    self.closures.append(ThreadClosure(closure))
    let ret = self.closures.count - 1
    self.semaphore.signal()
    activated?(needsNotification)
    return ret
  }
  
  /// The projected value is the wrapper itself
  public var projectedValue: Callback { self }
  
  /// Notify all closures and send an optional Notification
  public func notify(sender: Any?, content: Any? = nil, wait: Bool = false) {
    self.semaphore.wait()
    let list = self.closures
    self.semaphore.signal()
    for closure in list { closure.call(arg: (content, sender), wait: wait) }
    if let notification = self.notification {
      Notification.send(notification, content: content, sender: sender)
    }
  }
  
  /// Removes a single closure from the array
  @discardableResult
  public func remove(_ index: Int) -> ThreadClosure<Any?>? {
    guard index >= 0 && index < closures.count else { return nil }
    self.semaphore.wait()
    let ret = closures.remove(at: index)
    self.semaphore.signal()
    activated?(needsNotification)
    return ret
  }
  
  /// Removes all closures from the array
  public func removeAll() {
    closures = []
    activated?(needsNotification)
  }
  
  /// Directs the wrapper to send an additional notification
  public init(notification: String) {
    self.notification = notification
  }
  
  /// Directs the wrapper to not send any notifications
  public init() {}
}


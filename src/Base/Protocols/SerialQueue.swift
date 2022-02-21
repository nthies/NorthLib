//
//  SerialQueue.swift
//
//  Created by Norbert Thies on 20.01.22.
//  Copyright © 2022 Norbert Thies. All rights reserved.
//

/**
 * SerialQueue is intended as protocol for types offering a simple method
 * _queue_ to put a closure on a serial queue for later processing.
 */
public protocol SerialQueue {
  /// Queue label
  var label: String { get set }
  /// Put closure on a serial queue
  func queue(closure: @escaping ()->())
  /// Initialize with queue name
  init(label: String)
}

extension SerialQueue {
  /// Since Swifts standard library doesn't support serial queues, we simply
  /// call the closure.
  public func queue(closure: ()->()) {
    closure()
  }
}

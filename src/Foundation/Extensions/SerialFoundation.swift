//
//  SimpleActors.swift
//
//  Created by Norbert Thies on 14.01.22.
//

import Foundation

/**
 * This extension executes a closure on a serial dispatch queue
 */
public extension SerialQueue {
  func queue(closure: @escaping ()->()) {
    let q = DispatchQueue(label: label)
    q.async { closure() }
  }
}

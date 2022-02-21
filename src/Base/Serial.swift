//
//  Serial.swift
//
//  Created by Norbert Thies on 14.01.22.
//

/**
 * Since serial queues are not available in Swift's standard library we
 * use the default non queue implementation.
 */
public class Serial: SerialQueue {
  public var label: String
  required public init(label: String) { self.label = label }
}

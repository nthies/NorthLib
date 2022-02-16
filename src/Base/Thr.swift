//
//  Thread.swift
//
//  Created by Norbert Thies on 14.01.22.
//
import NorthLowLevel

/// This struct defines some simple thread related methods
public struct Thread {
  
  /// A thread id type (as returned from pthreads)
  public typealias Id = Int64
  
  /// Id of the currents thread
  public static var id: Id { Id(thread_id(thread_current())) }
  
  /// thread id of main thread
  public async var mainId: Id { await Thread.getMainId() }
  
  @MainActor
  private static func getMainId() async -> Id { Thread.id }
  

}

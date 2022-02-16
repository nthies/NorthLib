//
//  Thr.swift
//
//  Created by Norbert Thies on 14.01.22.
//
import NorthLowLevel

/// This struct defines some simple thread related methods
public struct Thr {
  
  /// A thread id type (as returned from pthreads)
  public typealias Id = Int64
  
  /// Id of the current thread
  public static var id: Id { Id(thread_id(thread_current())) }
  
  /// thread id of main thread
  public static var mainId: Id { Id(thread_main_id()) }
  
  /// Are we on main thread
  public static var isMain: Bool { id == mainId }

}

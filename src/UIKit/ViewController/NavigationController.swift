//
//  NavigationController.swift
//
//  Created by Norbert Thies on 30.04.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit

public protocol HandlesEdgeSwipes {
  /// is called by NavigationController when a left/right edge swipe has been 
  /// detected
  func edgeSwiped(recognizer: UIScreenEdgePanGestureRecognizer)  
}

/// A simple UINavigationController offering left/right edge swipe detection
open class NavigationController: UINavigationController, UIGestureRecognizerDelegate {

  // left edge pan gesture recognizer
  private lazy var edgePanLeft = UIScreenEdgePanGestureRecognizer(target: self,
                                 action: #selector(swipeFromEdge))
  // right edge pan gesture recognizer
  private lazy var edgePanRight = UIScreenEdgePanGestureRecognizer(target: self,
                                  action: #selector(swipeFromEdge))  
  open var isEdgeDetection: Bool = false {
    didSet {
      if isEdgeDetection {
        onPopViewController(closure: nil)
        edgePanLeft.edges = .left
        edgePanLeft.delegate = self
        edgePanRight.delegate = self
        edgePanRight.edges = .right
        view.addGestureRecognizer(edgePanLeft)
        view.addGestureRecognizer(edgePanRight)
      }
      else {
        view.removeGestureRecognizer(edgePanLeft)
        view.removeGestureRecognizer(edgePanRight)
      }
    }
  }
  
  // closure to call when swipe from left edge to pop view controller
  private var popViewControllerClosure: ((UIViewController)->(Bool))?
  open var isPopViewController: Bool { popViewControllerClosure != nil }
  
  /// Defines a closure to call if an edge left swipe should possibly remove
  /// the top view controller
  open func onPopViewController(closure: ((UIViewController)->(Bool))? = nil) {
    if closure != nil { 
      isEdgeDetection = false 
      // allow swipe from left edge to pop view controllers
      interactivePopGestureRecognizer?.delegate = self
    }
    else {
      interactivePopGestureRecognizer?.delegate = nil
    }
    popViewControllerClosure = closure
  }
  
  // edge pan handler
  @objc private func swipeFromEdge(recog: UIScreenEdgePanGestureRecognizer) {
    guard recog.state == .recognized else { return }
    let top = topViewController
    if let vc = top as? HandlesEdgeSwipes {
      debug("delegating edge swipe to \(type(of: vc))")
      vc.edgeSwiped(recognizer: recog)
    }
    else {
      if let vc = top {
        debug("edge swipe: \(type(of: vc)) doesn't support 'HandlesEdgeSwipes'")
      }
    }
  }
  
  /// Replace the top view controller
  public func replaceTopViewController(with vc: UIViewController, animated: Bool) {
    var vcs = viewControllers
    vcs[vcs.count - 1] = vc
    setViewControllers(vcs, animated: animated)
  }

  // UIGestureRecognizerDelegate protocol
  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return isEdgeDetection || isPopViewController
  }

  public func gestureRecognizerShouldBegin(_ recog: UIGestureRecognizer) -> Bool {
    if recog == interactivePopGestureRecognizer {
      if let closure = popViewControllerClosure,
         let top = topViewController {
        return closure(top)
      }
    }
    return true
  }
  
} // NavigationController

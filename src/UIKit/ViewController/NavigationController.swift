//
//  NavigationController.swift
//
//  Created by Norbert Thies on 30.04.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit
import MessageUI

/// A simple UINavigationController offering left/right edge swipe detection
open class NavigationController: UINavigationController, 
  UIGestureRecognizerDelegate, MailingVC {
  
  open override func viewDidLoad() {
    super.viewDidLoad()
    self.interactivePopGestureRecognizer?.delegate = self
  }
  
  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return self.viewControllers.count > 1
  }
  
  /// Replace the top view controller
  public func replaceTopViewController(with vc: UIViewController, animated: Bool) {
    var vcs = viewControllers
    vcs[vcs.count - 1] = vc
    setViewControllers(vcs, animated: animated)
  }
  
  /// Dismiss mail composition controller when finished
  public func mailComposeController(_ controller: MFMailComposeViewController, 
    didFinishWith result: MFMailComposeResult, error: Error?) {
    Mail.dismiss(controller: controller, result: result, error: error)
  }
  
} // NavigationController

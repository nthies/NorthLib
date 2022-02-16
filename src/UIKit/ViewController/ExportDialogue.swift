//
//  ExportDialogue.swift
//
//  Created by Norbert Thies on 02.05.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit

open class ExportDialogue<T>: NSObject, UIActivityItemSource {

  /// The item to export
  var item: T?
  /// The alternate text for Twitter etc.
  var altText: String?
  /// A String describing the item (ie used as Subject in eMails
  var subject: String?
  
  public func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
    if let item = item { return item }
    else { return "Error" }
  }
  
  public func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
    if let item = item {
      if let activityType = activityType,
         let altText = altText {
        switch activityType {
          case .addToReadingList, .postToFacebook, .postToWeibo,
               .postToVimeo, .postToFlickr, .postToTwitter,
               .postToTencentWeibo: return altText
          default: return item
        }
      }
      else { return item }
    }
    else { return "Error" }
  }
  
  public func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
    if let str = subject { return str }
    else { return "" }
  }
  
  /// Create export dialogue
  public func present(item: T, altText: String?, view: UIView? = nil,
                      subject: String? = nil) {
    self.item = item
    self.altText = altText
    self.subject = subject
    let aController = UIActivityViewController(activityItems: [self],
      applicationActivities: nil)
    aController.presentAt(view)
  }
  
  /// Create export dialogue
  public func present(item: T, view: UIView? = nil, subject: String? = nil) {
    present(item: item, altText: nil, view: view, subject: subject)
  }

} // ExportDialogue


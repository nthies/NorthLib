//
//  Mail.swift
//
//  Created by Norbert Thies on 23.02.2022
//  Copyright © 2022 Norbert Thies. All rights reserved.
//

import UIKit
import MessageUI

/// A shorthand for MFMailComposeViewControllerDelegate
public protocol MailingVC: MFMailComposeViewControllerDelegate 
  where Self: UIViewController {
}

/**
 Mail is a simple wrapper around MFMailComposeViewController.
 
 To send a mail using this class you need a view (or navigation) controller
 adopting the MFMailComposeViewControllerDelegate protocol (or as a 
 shorthand _MailingVC_). The class NavigationController from NorthLib
 automatically adopts this protocol. Eg. let _vc_ be such a view controller,
 then:
 ````
   if let mail = try? Mail(vc) { // creates a mail object
     mail.to += "mailadress@foo.com" // adds recipient
     mail.subject = "Test" // add s a mail subject
     mail.body = "Some mail body"
     try! mail.present { result in // presents mail composition VC
       // VC has been dismissed, evaluate result
     }
     // present fails if another mail is currently been presented
   }
   else { // mailing for this app is not allowed
     ...
   }
 ```` 
 */
 open class Mail: DoesLog {
 
  /// The mail composer VC
  public var mailVC: MFMailComposeViewController
  
  /// The calling view controller
  public var vc: MailingVC
  
  /// The recipients
  public var to = [String]()
  
  /// Carbon copy to
  public var cc = [String]()
  
  /// Blind carbon copy to
  public var bcc = [String]()
  
  /// Subject
  public var subject = "" { didSet { mailVC.setSubject(subject) } }
  
  /// Mail body as simple text
  public var body = "" { didSet { mailVC.setMessageBody(body, isHTML: false) } }
  
  /// Mail body as HTML text
  public var htmlBody = "" { didSet { mailVC.setMessageBody(htmlBody, isHTML: true) } }
  
  public typealias ResultType = Result<MFMailComposeResult,Error>
  public var completion: ((ResultType)->())?
  
  public static var currentlyPresenting: Mail? = nil
  
  /// Initialize with optional recipient
  public init(vc: MailingVC) throws {
    guard MFMailComposeViewController.canSendMail()
    else { throw Log.error("Can't send mail") }
    self.vc = vc
    mailVC = MFMailComposeViewController()
    mailVC.mailComposeDelegate = vc
  }
  
  /// Add attachment
  public func attach(data: Data, mimeType: String, fname: String) {
    mailVC.addAttachmentData(data, mimeType: mimeType, fileName: fname)
  }
  
  /// Attach an image in Jpeg format
  public func attach(image: UIImage, fname: String = "Image.jpg") {
    if let data = image.jpeg {
      attach(data: data, mimeType: "image/jpeg", fname: fname)
    }
  }
    
  /// Attach Data as text
  public func attach(data: Data, fname: String = "Data.txt") {
    attach(data: data, mimeType: "text/plain", fname: fname)
  }
  
  /// Attach String as text
  public func attach(str: String, fname: String = "Text.txt") {
    if let data = str.data(using: .utf8) {
      attach(data: data, mimeType: "text/plain", fname: fname)
    }
  }
  
  /// Attach screenshot of current window in Jpeg format
  public func attachScreenshot(fname: String = "Screenshot.jpg") {
    if let img = UIWindow.screenshot { attach(image: img, fname: fname) }
  }
  
  /// Convert MFMailComposeResult to String
  public static func mailResult(_ res: MFMailComposeResult) -> String {
    switch res {
      case .cancelled: return "User canceled the operation"
      case .saved: return "Email message was saved"
      case .sent: return "Email was queued in the user’s outbox"
      case .failed: return "Email was not saved or queued (error)"
      default: return "Unknown state"
    }
  }
  
  /// Present mail compose view controller on top most view controller
  @MainActor
  public func present(completion: ((ResultType)->())? = nil) throws {
    guard Mail.currentlyPresenting == nil 
    else { throw error("Mail composition already in progress") }
    let vc = self.vc.topmostModalVc
    if let closure = completion { self.completion = closure }
    else { 
      self.completion = { result in
        if let res = result.value() {
          Log.log("Mail: \(Mail.mailResult(res))")
        }
      }
    }
    if !to.isEmpty { mailVC.setToRecipients(to) }
    if !cc.isEmpty { mailVC.setCcRecipients(cc) }
    if !bcc.isEmpty { mailVC.setBccRecipients(bcc) }
    Mail.currentlyPresenting = self
    vc.present(mailVC, animated: true)
  }
  
  @MainActor
  public static func dismiss(controller: MFMailComposeViewController, 
    result: MFMailComposeResult, error: Error?) {
    if let mail = Mail.currentlyPresenting {
      if let err = error { mail.completion?(.failure(err)) }
      else { mail.completion?(.success(result)) }
      Mail.currentlyPresenting = nil
    }
    controller.dismiss(animated: true)
  }
    
} // Mail

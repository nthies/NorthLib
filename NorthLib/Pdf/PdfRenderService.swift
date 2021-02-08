//
//  PdfRenderService.swift
//  taz.neo
//
//  Created by Ringo Müller-Gromes on 13.11.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit
import PDFKit


/// Service that renders PDF's on limited count of Threads,
/// each parallel render open its own file handle
/// to avoid memory leaks within unclosed UIGraphicsContext PDF File handles
class PdfRenderService : DoesLog{

  private static let sharedInstance = PdfRenderService()
  private init(){}
  
  private let userInteractiveSemaphore = DispatchSemaphore(value: 2)//How many 1:! Renderings parallel?
  private let backgroundSemaphore = DispatchSemaphore(value: 4)//How many 1:! Renderings parallel?
  
  private let userInteractiveQueue = DispatchQueue.init(label: "imageRendererQueue",
                                 qos: .userInteractive,
                                 attributes: .concurrent,
                                 autoreleaseFrequency: .workItem,
                                 target: nil)
  
  private let backgroundQueue = DispatchQueue.init(label: "backgroundImageRendererQueue",
                                 attributes: .concurrent,
                                 autoreleaseFrequency: .workItem,
                                 target: nil)
    
  public static func render(item:ZoomedPdfImageSpec,
                            scale:CGFloat = 1.0,
                            backgroundRenderer : Bool = false,
                            finishedCallback: @escaping((UIImage?)->())){
    sharedInstance.enqueueRender(item: item,
                               scale: scale,
                               backgroundRenderer : backgroundRenderer,
                               finishedCallback: finishedCallback)
  }
  
  public static func render(item:ZoomedPdfImageSpec,
                            width: CGFloat,
                            screenScaled: Bool = true,
                            backgroundRenderer : Bool = false,
                            finishedCallback: @escaping((UIImage?)->())){
    sharedInstance.enqueueRender(item: item,
                               width: width,
                               screenScaled: screenScaled,
                               backgroundRenderer : backgroundRenderer,
                               finishedCallback: finishedCallback)
  }
  
  public static func render(item:ZoomedPdfImageSpec,
                            height: CGFloat,
                            backgroundRenderer : Bool = false,
                            finishedCallback: @escaping((UIImage?)->())){
    sharedInstance.enqueueRender(item: item,
                               height: height,
                               backgroundRenderer : backgroundRenderer,
                               finishedCallback: finishedCallback)
  }
  
  private func enqueueRender(item:ZoomedPdfImageSpec,
                             scale:CGFloat = 1.0,
                             width: CGFloat? = nil,
                             height: CGFloat? = nil,
                             screenScaled: Bool = true,
                             backgroundRenderer : Bool = false,
                             finishedCallback: (@escaping(UIImage?)->())){
    let queue = backgroundRenderer ? backgroundQueue : userInteractiveQueue
    let semaphore = backgroundRenderer ? backgroundSemaphore : userInteractiveSemaphore
    
    queue.async { [weak self] in
      let debugEnqueuedStart = Date()
      guard let url = item.pdfUrl else {
        finishedCallback(nil)
        return
      }
      guard let index = item.pdfPageIndex else{
        finishedCallback(nil)
        return
      }
      semaphore.wait()
      let debugRenderStart = Date()
      let pdfPage = PDFDocument(url: url)?.page(at: index)
      ///Check if stopped meanwhile
      if let pdfPage = pdfPage, item.renderingStoped == false {
        var img : UIImage?
        if let w = width {
          img = pdfPage.image(width: w, screenScaled)
        }
        else if let h = height {
          img = pdfPage.image(height: h)
        }
        else {
          img = pdfPage.image(scale:scale)
        }
        self?.log("Render for PageIdx: \(item.pdfPageIndex ?? 0) done"
              + "\n   scale: \(scale) width: \(width ?? 0) height: \(height ?? 0) screenScaled: \(screenScaled)"
              + "\n   screenScaled: \(screenScaled) backgroundRenderer: \(backgroundRenderer)"
              + "\n   Duration since enqueued: \(Date().timeIntervalSince(debugEnqueuedStart)) "
              + "renderStart: \(Date().timeIntervalSince(debugRenderStart))",
                  logLevel: .Debug)
        finishedCallback(img)
      }
      semaphore.signal()
    }
  }
}

extension PDFPage : DoesLog {
  fileprivate func image(scale: CGFloat = 1.0) -> UIImage? {
    var img: UIImage?
    guard let ref = self.pageRef else { return nil}
    var _frame = self.bounds(for: .mediaBox)
    _frame.size.width *= scale
    _frame.size.height *= scale
    _frame.origin.x = 0
    _frame.origin.y = 0
    if _frame.width > 300 {
      self.log("TRY TO RENDER IMAGE WITH: \(_frame.size)", logLevel: .Debug)
    }
    
    if avoidRenderDueExpectedMemoryIssue(_frame, scale) { return nil }
    
    UIGraphicsBeginImageContext(_frame.size)
    
    if let ctx = UIGraphicsGetCurrentContext() {
      ctx.saveGState()
      UIColor.white.set()
      ctx.fill(_frame)
      ctx.translateBy(x: 0.0, y: _frame.size.height)
      ctx.scaleBy(x: 1.0, y: -1.0)
      ctx.scaleBy(x: scale, y: scale)
      ctx.drawPDFPage(ref)
      img = UIGraphicsGetImageFromCurrentImageContext()
      ctx.restoreGState()
    }
    
    UIGraphicsEndImageContext()
    if _frame.width > 300 {
      log("rendered image width: \(_frame.width) imagesize: \(img?.mbSize ?? 0) MB", logLevel: .Debug)
    }
    return img
  }
  
  private func avoidRenderDueExpectedMemoryIssue(_ frame:CGRect, _ scale:CGFloat? = nil) -> Bool {
    /// Limit to max Device RAM Usage
    var maxPercentageRamUsage : UInt64 = 45
    /// In CGContextRender iOS lower than 13.7 crash on low memory. Higher versions do not!
    var isProblematicSystemVersion = false
    
    if #available(iOS 13.7, *) { }
    else {
      maxPercentageRamUsage = 30//Page 1 from 2020-11-18 kill all plans! :-(
      isProblematicSystemVersion = true
    }
    
    let expectedImageSize = Int64(frame.size.width*frame.size.height*4)
    let maxUseableRam = Int64(maxPercentageRamUsage*ProcessInfo.processInfo.physicalMemory/100)
    let tooBig = expectedImageSize > maxUseableRam
    let scaleInfo = scale != nil ? " @\(Double(round(100*scale!)/100))x " : ""
    
    //Print Debug Info
    if isProblematicSystemVersion, tooBig {
      self.log("⚠️ image rendering \(scaleInfo) is expected to fail! 🛑 Do Not Render! expectedImageSize: \(expectedImageSize/(1024*1024)) MB > \(maxUseableRam/(1024*1024)) MB useable RAM", logLevel: .Debug)
    }
    else if tooBig {
      self.log("⚠️ image rendering \(scaleInfo) is expected to fail! expectedImageSize: \(expectedImageSize/(1024*1024)) MB > \(maxUseableRam/(1024*1024)) MB useable RAM", logLevel: .Debug)
    } else {
      self.log("no expecting render issues  \(scaleInfo) expectedImageSize: \(expectedImageSize/(1024*1024)) MB, \(maxUseableRam/(1024*1024)) MB useable RAM", logLevel: .Debug)
    }
    return isProblematicSystemVersion && tooBig
  }

  
  fileprivate func image(width: CGFloat, _ screenScaled: Bool = true) -> UIImage? {
    guard let frame = self.frame else { return nil }
    if screenScaled == false {
      return image(scale:  width/frame.size.width)
    }
    return image(scale:  width/frame.size.width)?.scaled()
  }
  
  fileprivate func image(height: CGFloat) -> UIImage? {
    guard let frame = self.frame else { return nil }
    return image(scale:  height/frame.size.height)?.scaled()
  }
  
  var frame: CGRect? { self.pageRef?.getBoxRect(.cropBox) }
}


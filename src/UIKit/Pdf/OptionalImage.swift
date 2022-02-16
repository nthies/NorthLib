//
//  OptionalImage.swift
//  NorthLib
//
//  Created by Ringo Müller-Gromes on 06.11.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import Foundation
import PDFKit

public enum PdfPageType { case left, right, double}

// MARK: - ZoomedPdfImageSpec : OptionalImage (Protocol)
public protocol ZoomedPdfImageSpec : OptionalImage, DoesLog {
  var sectionTitle: String? { get set}
  var pageTitle: String? { get set}
  var renderingStoped: Bool { get }
  var preventNextRenderingDueFailed: Bool { get }
  var pdfPage : PDFPage? { get }
  /// ratio between current zoom and next zoom
  var doubleTapNextZoomStep : CGFloat? { get }
  var pageType : PdfPageType { get }
  var size : CGSize { get }
  var fullScreenPageHeight : CGFloat? { get }
  
//  func resetToSingleScaleIfNeeded()
  func renderImageWithNextScale(finishedCallback: ((Bool) -> ())?)
//  func renderFullscreenImageIfNeeded(_ sizeToFit: CGSize, finishedCallback: ((Bool) -> ())?)
  func renderFullscreenImageIfNeeded(finishedCallback: ((Bool) -> ())?)
  func renderImageWithScale(scale: CGFloat, finishedCallback: ((Bool) -> ())?)
}

//public enum ContentAlignment { case left, right, fill }

open class ZoomedPdfImage: OptionalImageItem, ZoomedPdfImageSpec, Equatable {
  public static func == (lhs: ZoomedPdfImage, rhs: ZoomedPdfImage) -> Bool {
    return lhs.pdfPage == rhs.pdfPage &&  rhs.pdfPage != nil
  }
  
  open var pageType : PdfPageType = .left
  public var size: CGSize = CGSize(width: 100, height: 80)
  public var sectionTitle: String?
  open var pageTitle: String?
  public var fullScreenPageHeight : CGFloat?
  public private(set) var pdfUrl: URL?
  public private(set) var pdfPageIndex: Int?
  
  open var pdfPage: PDFPage? {
    get {
      guard let url = pdfUrl else { return nil }
      guard let index = pdfPageIndex else { return nil }
      return PDFDocument(url: url)?.page(at: index)
    }
  }
  
  lazy var zoomScales = ZoomScales()
  
  convenience init(url:URL?, index:Int) {
    self.init()
    self.pdfUrl = url
    self.pdfPageIndex = index
  }
    
  public override var image: UIImage? {
    didSet{
      if image == nil {
        zoomScales.reset()
      }
    }
  }
  
  /**
   Next Challange: on disappear do not hold more than 1x scale!
      => iPad Air 2 13MB => 84MB => 214MB Page disappear throw Away!
      => Better Do Not hold any Resolution!!! >0.99 rendering is fast enought!
   
   Idea seams to work generelly but 2 Issues:
    -  Black Screen in some situations
   *****WHY****
    - memory Leak! increasing from 40MB to 60MB ...but nit necesary!
   
   */
  public var preventNextRenderingDueFailed: Bool {
    get {
      return zoomScales.nextScreenScale != nil
    }
  }
  
  public var doubleTapNextZoomStep: CGFloat? {
    get {
      return zoomScales.doubleTapNextZoomStep
    }
  }
  
  public var renderingStoped = false
  private var rendering = false
  
  public private(set) var pageDescription: String = ""
 /*
  open func renderFullscreenImageIfNeeded(_ sizeToFit: CGSize, singlePageRatio: CGFloat, finishedCallback: ((Bool) -> ())?){
    //    self.renderImageWithScale(scale:1.0, finishedCallback: finishedCallback)
    if rendering { return }//Prevent double render
    rendering = true
    let finishedBlock: ((UIImage?)->()) = { img in
      onMain { [weak self] in
        guard let self = self else { return }
        
        self.rendering = false
        
        if self.renderingStoped {
          /// handle cancelation
          return
        }
        
        guard let newImage = img else {
          self.zoomScales.setLastRenderSucceed(false)
          finishedCallback?(false)
          return
        }
        self.zoomScales.setLastRenderSucceed(true)
        self.image = newImage
        finishedCallback?(true)
      }
    }
    let cropBoxSize = self.pdfPage?.bounds(for: .cropBox).size
    let
    
    if let targetHeight = fullScreenPageHeight {
      PdfRenderService.render(item: self,
                              height: targetHeight*UIScreen.main.scale,
                              finishedCallback: finishedBlock)
    } else {
      PdfRenderService.render(item: self,
                              width: UIScreen.main.bounds.width*UIScreen.main.scale,
                              finishedCallback: finishedBlock)
    }
  }*/
    
  open func renderFullscreenImageIfNeeded(finishedCallback: ((Bool) -> ())?) {
    //    self.renderImageWithScale(scale:1.0, finishedCallback: finishedCallback)
    if rendering { return }//Prevent double render
    rendering = true
    let finishedBlock: ((UIImage?)->()) = { img in
      onMain { [weak self] in
        guard let self = self else { return }
        
        self.rendering = false
        
        if self.renderingStoped {
          /// handle cancelation
          return
        }
        
        guard let newImage = img else {
          self.zoomScales.setLastRenderSucceed(false)
          finishedCallback?(false)
          return
        }
        self.zoomScales.setLastRenderSucceed(true)
        self.image = newImage
        finishedCallback?(true)
      }
    }
    
    if let targetHeight = fullScreenPageHeight {
      PdfRenderService.render(item: self,
                              height: targetHeight*UIScreen.main.scale,
                              finishedCallback: finishedBlock)
    } else {
      PdfRenderService.render(item: self,
                              width: UIScreen.main.bounds.width*UIScreen.main.scale,
                              finishedCallback: finishedBlock)
    }
  }
  
  public func renderImageWithNextScale(finishedCallback: ((Bool) -> ())?){
    renderImageWithScale(zoomScales.nextScreenScale, finishedCallback: finishedCallback)
  }
  
  public func renderImageWithScale(scale: CGFloat, finishedCallback: ((Bool) -> ())?) {
    renderImageWithScale(scale, finishedCallback: finishedCallback)
  }
  
  func renderImageWithScale(_ scale: CGFloat?, finishedCallback: ((Bool) -> ())?) {
    guard let scale = scale else {
      onMain {
        finishedCallback?(false)
      }
      return
    }
    
    if let currentScale = zoomScales.currentScreenScale,
       scale == nextafter(0.01, currentScale) {
      ///Requested Zoom is similar to current ...do not render my rendering is called twice
      return
    }
    
    if rendering { return }//Prevent double render
    rendering = true
    
    //Prevent Multiple time max rendering
    let baseWidth = UIScreen.main.bounds.width*UIScreen.main.scale
    log("Optional Image, render Image with scale: \(scale) is width: \(baseWidth*scale) 1:1 image width should be: \(baseWidth)")
    PdfRenderService.render(item: self,
                            width: baseWidth*scale) { img in
      onMain { [weak self] in
        guard let self = self else { return }
        
        self.rendering = false
        
        if self.renderingStoped {
          /// handle cancelation
          return
        }
        
        guard let newImage = img else {
          self.log("Optional Image, render Image with scale: \(scale) FAILED")
          self.zoomScales.setLastRenderSucceed(false)
          finishedCallback?(false)
          return
        }
        self.log("Optional Image, render Image with scale: \(scale) SUCCEED ImgSize: \(newImage.size), \(newImage.mbSize) MB")
        self.zoomScales.setLastRenderSucceed(true)
        self.image = newImage
        finishedCallback?(true)
      }
    }
  }
  
  public func stopRendering(){
    self.renderingStoped = true
    self.image = nil
   
  }
  
  //Device Types: iPhone, iPad
  /**
    iPhone: (personal categorization) What about Screen Scales
      small: iPhone 5+, SE1
      medium 6s, 7, 8, 12mini
      large: 6s+, 7+, 8+, X, XS, 11, 11Pro, XR, SE2, 12, 12Pro
      extra large: XSMax, 11 Pro Max, 12 Pro Max
    iPad:
      Mini 2-5 (7,9")
      iPad 5-8th (9,7"-10,2")
      Air 1-4 (9,7 / 10,5 / 10,9")
      Pro 1.-4. Gen (9,7 / 11" / 12,9")
    iPad Problematic
      - older iPads have less CPU Power and smaller RAM => Max Zoom is Limited
        => Limit scould be handled by 40% RAM Usage of Render Function
          @see: PdfRenderService.swift => extension PDFPage => image/avoidRenderDueExpectedMemoryIssue
        => so i can use higher zoom scales
      - diffferent screen Scales let UserExperiance may be different e.g. difference between iPad and iPhone 5s
      - different Padges with different Layout e.g. 2 Column vs. 6 Column make double Tap & Zoom difficult
      - But User expects every time same depth
      - is Double Tap 1 Level enought?  Problem User zoomed in 2nd Time he cannot go back to 1st Step by Double Tap
      => Solutions
        => Create Model wich allows more than 2 Presets
        => may create own DSL
        => structure needs Step 0 == 1:1, ...
        => getter for next/prev/max
        => bool if last render failed, and was higher than 1.0
      ....Lets GO!
   */
}

/**
 Good Idea but What about RealLife?
 Where is the Page base Resolution NEEDED?
 Where is the current SCale memory? NEEDED?
 */


public class ZoomScales {
  /// Zoom Behaviour for Device Type
  /// - Parameters:
  ///   - zoomSteps: the Zoom Steps from lowest Zoom usually 1 to heigest Zoom e.g. 8
  ///                means Device Width * 8 is the width of the max Image
  ///   - renderFailedLimit: After how Many Attempts the rendering should be stopped and not
  ///                        tried again, depends on **minZoomStepIdxForTryAgain** if this is not reached rendering would be try again
  ///   - minZoomStepIdxForTryAgain:min Step to reach to stop rendering on **renderFailedLimit**
  ///                            maximum can only be zoomSteps.count
  typealias ZoomBehaviour = (zoomSteps:[CGFloat],
                             renderFailedLimit:Int,
                             minZoomStepIdxForTryAgain:Int)

  struct Steps {
    static let iPad:ZoomBehaviour = ([1,2.5,4], 2, 1)
    static let iPhone:ZoomBehaviour = ([1,4,6],2,1)
    static var zoomBehaviour : ZoomBehaviour {
      get{
        /// May use the following in future
        /// public enum ZoomScaleType  {case phoneS, phoneM, phoneL, phoneXL, iPadS, iPadL}
        switch Device.singleton {
          case .iPhone:
            return Steps.iPhone
          case .iPad:
            fallthrough
          default:
            return Steps.iPad
        }
      }
    }
  }
  
  /// the Zoom behaviour
  let zoomBehaviour : ZoomBehaviour = Steps.zoomBehaviour
    
  public func reset(){
    self.renderNextFailedCount = 0
    self.currentZoomStepIndex = nil
  }
    
  public func setLastRenderSucceed(_ success : Bool){
    if success {
      self.renderNextFailedCount = 0
      
      if let currIdx = currentZoomStepIndex {
        self.currentZoomStepIndex = currIdx + 1
      }
      else {
        self.currentZoomStepIndex = 0
      }
    }
    else {
      self.renderNextFailedCount += 1
    }
  }
  
  /// How many failed Renderings happen for next Zoom Scale
  var renderNextFailedCount:Int = 0

  /// current Index of zoomBehaviour.zoomSteps
  var currentZoomStepIndex : Int? = nil
  
  public var doubleTapNextZoomStep : CGFloat? {
    get {
      /**
        User is on 1.0 double Tap => [1,4,6] return 4.0
        User is on 4.0 and not 1st zoom step... double tap zoom out
        User is on 6.0 and not 1st zoom step... double tap zoom to 4.0 which is 4/6
          => User jumps between same zoom scales
       */

      guard let first = zoomBehaviour.zoomSteps.valueAt(0),
            let second = zoomBehaviour.zoomSteps.valueAt(1) else { return 2.0 }
      //There is no
      guard let currIdx = currentZoomStepIndex,
            let current = zoomBehaviour.zoomSteps.valueAt(currIdx) else { return second/first}
      return second/current
    }
  }
  
  /// Current Screen Scale for Rendering or nil if no more Rendering
  public var currentScreenScale : CGFloat? {
    get {
      guard let currentStep = self.currentZoomStepIndex else {
        ///Nothing is rendered yet, render first Step
        return nil
      }
      return zoomBehaviour.zoomSteps.valueAt(currentStep)
    }
  }
  
  /// Next Screen Scale for Rendering or nil if no more Rendering
  public var nextScreenScale : CGFloat? {
    get {
      guard let currentStep = self.currentZoomStepIndex else {
        ///Nothing is rendered yet, render first Step
        return zoomBehaviour.zoomSteps.first
      }
      
      if renderNextFailedCount > zoomBehaviour.renderFailedLimit,
         currentStep >= zoomBehaviour.minZoomStepIdxForTryAgain {
        ///Failed too much and zoom step is enought do not render anymore
        return nil
      }
      
      //return next if any or nil if last zoom reaches
      return zoomBehaviour.zoomSteps.valueAt(currentStep+1)
    }
  }
}

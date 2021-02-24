//
//  PdfModel.swift
//  NorthLib
//
//  Created by Ringo Müller-Gromes on 15.10.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import Foundation
import PDFKit

struct PdfDisplayOptions {
  struct Overview{
    static let singlePageItemsPerRow:Int = 2 //need calculation later for landscape or ipad layout
    static let sideSpacing:CGFloat = 4.0
    static let interItemSpacing:CGFloat = 12
    static let rowSpacing:CGFloat = 12.0
    static let labelHeight:CGFloat = 30.0
    
    /// width of pdf menu slider, page sizes are calculated for this
    /// |-sideSpacing-[Page]-interItemSpacing-[Page]-sideSpacing-|
    /// |-sideSpacing-[               PanoramaPage           ]-sideSpacing-|
    static let sliderWidth:CGFloat = {
      let screenWidth = min(UIScreen.main.bounds.size.width,
                            UIScreen.main.bounds.size.height)
      return 0.6*screenWidth
    }()
    
    static let fallbackPageSize:CGSize = CGSize(width: 300, height: 500)
  }
}


// MARK: PdfArrayModel
protocol PdfModel {
  var count : Int { get }
  var imageSizeMb : UInt64 { get }
  var index : Int { get set }
  var defaultRawPageSize: CGSize? { get }
  var singlePageSize: CGSize? { get }
  var panoPageSize: CGSize? { get }
  var defaultItemSize : CGSize? { get }
  func item(atIndex: Int) -> ZoomedPdfImageSpec?
  func size(forItem atIndex: Int) -> CGSize?
  func pageTitle(forItem atIndex: Int) -> String?
  func allignment(forItem atIndex: Int) -> Toolbar.Direction
  func thumbnail(atIndex: Int, finishedClosure: ((UIImage?)->())?) -> UIImage?
}

// MARK: PdfDocModel
class PdfModelItem : PdfModel, DoesLog/*, PDFOutlineStructure*/ {
  private var url:URL?
  
  var count: Int = 0
  var index: Int = 0
  var defaultItemSize: CGSize?
    
  var defaultRawPageSize: CGSize?
  var singlePageSize: CGSize?
  var panoPageSize: CGSize?
  
  func item(atIndex: Int) -> ZoomedPdfImageSpec? {
    return images.valueAt(atIndex)
  }
  #warning("Needed anymore?")
  static let previewDeviceWithScale : CGFloat = 0.25//4 in a row
  
  var images : [ZoomedPdfImage] = []
  
  var pageMeta : [Int:String] = [:]
  
  var imageSizeMb : UInt64 {
    get{
      var totalSize:UInt64 = 0
      for img in self.images {
        log("page: \(img.pdfPageIndex ?? -1) size:\(img.image?.mbSize ?? 0)")
        totalSize += UInt64(img.image?.mbSize ?? 0)
      }
      return totalSize
    }
  }
  
  init(url:URL?) {
    guard let url = url else { return }
    guard let pdfDocument = PDFDocument(url: url) else { return }
    self.url = url
      
    self.count = pdfDocument.pageCount
    //ensure pageWidth != 0 to prevent division by zero
    //early return with guard let not possible
    //crash not allowed, ..need to used fallback values
    guard let rawPageSize = pdfDocument.page(at: 0)?.frame?.size,
          rawPageSize.width > 0 else { return }
    
    self.defaultRawPageSize = rawPageSize
    let panoPageWidth
      = PdfDisplayOptions.Overview.sliderWidth
      - 2*PdfDisplayOptions.Overview.sideSpacing
    let singlePageWidth
      = (panoPageWidth - PdfDisplayOptions.Overview.interItemSpacing)/2
    let pageHeight = singlePageWidth * rawPageSize.height / rawPageSize.width
    self.singlePageSize = CGSize(width: singlePageWidth,
                                 height: pageHeight + PdfDisplayOptions.Overview.labelHeight)
    self.panoPageSize = CGSize(width: panoPageWidth,
                               height: pageHeight + PdfDisplayOptions.Overview.labelHeight)
    
    for pagenumber in 0...pdfDocument.pageCount-1{
      self.images.append(ZoomedPdfImage(url: url, index: pagenumber))
    }
  }
  
  /// Pin side or not to Pin Side?
  /// 1=>0 weil Seite 1 allein stehen soll    LEFT
  /// 4=>3 weil reale Pano Page                LEFT/GIGHT
  /// 7=>6 weil seite 7 allein stehen soll    RIGHT
  let doublePages = [0, 3, 6]
  
  func allignment(forItem atIndex: Int) -> Toolbar.Direction {
    switch atIndex {
      case 0:
        return .left
      case 3:
        return .center
      case 6:
        return .right
      default:
        return .center
    }
  }
  
  func size(forItem atIndex: Int) -> CGSize? {
    return doublePages.contains(atIndex)
      ? self.panoPageSize
      : self.singlePageSize
  }
  
  func pageTitle(forItem atIndex: Int) -> String? {
    return "Seite:\(atIndex)"
  }
  
  func thumbnail(atIndex: Int, finishedClosure: ((UIImage?)->())?) -> UIImage? {
    guard var pdfImg = self.item(atIndex: atIndex) else {
      return nil
    }
    if let waitingImage = pdfImg.waitingImage {
      return waitingImage
    }
    
    let height
      = singlePageSize?.height ?? PdfDisplayOptions.Overview.fallbackPageSize.height
      - PdfDisplayOptions.Overview.labelHeight
    
    PdfRenderService.render(item: pdfImg,
                            height: height*UIScreen.main.scale,
                            screenScaled: false,
                            backgroundRenderer: true){ img in
      pdfImg.waitingImage = img
      finishedClosure?(img)
    }
    return nil
  }
}

// MARK: PdfModelHelper
class PdfModelHelper{
  
  static func demoDocUrl() -> URL? {
    guard var pdfUrls
      = Bundle.main.urls(forResourcesWithExtension: "pdf",
                         subdirectory: "DemoPdf") else { return nil }
    pdfUrls.sort { $0.absoluteString.compare(
      $1.absoluteString, options: .caseInsensitive) == .orderedDescending
    }
    return pdfUrls.first
  }
}

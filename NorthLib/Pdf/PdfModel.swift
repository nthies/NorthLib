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
    fileprivate static let totalRowSpacing = (2 * PdfDisplayOptions.Overview.spacing) + (CGFloat(itemsPerRow - 1) * spacing)
    static let itemsPerRow:Int = 2 //need calculation later for landscape or ipad layout
    static let spacing:CGFloat = 12.0
  }
}


// MARK: PdfArrayModel
protocol PdfModel {
  var count : Int { get }
  var imageSizeMb : UInt64 { get }
  var index : Int { get set }
  var defaultItemSize : CGSize? { get }
  func item(atIndex: Int) -> ZoomedPdfImageSpec?
  func thumbnail(atIndex: Int, finishedClosure: ((UIImage?)->())?) -> UIImage?
}

// MARK: PdfDocModel
class PdfModelItem : PdfModel, DoesLog/*, PDFOutlineStructure*/ {
  
  var defaultItemSize: CGSize?
  var index: Int = 0
  var count: Int = 0
  var url:URL?
  
  //Ip 7+ ::: ScreenScale(414 - 12*5)/4
  let thumbWidth = UIScreen.main.scale*(UIScreen.main.bounds.size.width - PdfDisplayOptions.Overview.totalRowSpacing)/CGFloat(PdfDisplayOptions.Overview.itemsPerRow)
  
  func item(atIndex: Int) -> ZoomedPdfImageSpec? {
    return images.valueAt(atIndex)
  }
  
  static let previewDeviceWithScale : CGFloat = 0.25//4 in a row
  
  var images : [ZoomedPdfImage] = []
  
  var pageMeta : [Int:String] = [:]
  
  var imageSizeMb : UInt64 { get{
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
    self.defaultItemSize = pdfDocument.page(at: 0)?.frame?.size
    
    for pagenumber in 0...pdfDocument.pageCount-1{
      self.images.append(ZoomedPdfImage(url: url, index: pagenumber))
    }
  }
  
  func thumbnail(atIndex: Int, finishedClosure: ((UIImage?)->())?) -> UIImage? {
    guard var pdfImg = self.item(atIndex: atIndex) else {
      return nil
    }
    if let waitingImage = pdfImg.waitingImage {
      return waitingImage
    }
    
    PdfRenderService.render(item: pdfImg,
                            width: thumbWidth,
                            screenScaled: false,
                            backgroundRenderer: true){ [weak self] img in
      guard let self = self else { return }
      let img = img?.scaled(self.thumbWidth/UIScreen.main.bounds.width)
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

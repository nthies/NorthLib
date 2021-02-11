//
//  PdfDoc.swift
//
//  Created by Norbert Thies on 08.06.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit
import QuartzCore

/**
 PdfPage is a simple Quartz based class to handle single PDF pages and to convert
 them to images.
 */
open class PdfPage {
  
  /// A single PDF page
  public var page: CGPDFPage
  
  /// The frame of the page's media box - "defines the boundaries of the physical
  ///  medium on which the page is intended to be displayed or printed"
  public var mediaBox: CGRect { page.getBoxRect(.mediaBox) }
  
  /// The frame of the page's crop box - "defines the visible region of default
  ///  user space. When the page is displayed or printed, its contents are to be
  ///   clipped to this rectangle"
  public var frame: CGRect { page.getBoxRect(.cropBox) }
  
  public func image(scale: CGFloat = 1.0) -> UIImage? {
    var img: UIImage?
    var frame = self.frame
    frame.size.width *= scale
    frame.size.height *= scale
    frame.origin.x = 0
    frame.origin.y = 0
    UIGraphicsBeginImageContext(frame.size)
    if let ctx = UIGraphicsGetCurrentContext() {
      ctx.saveGState()
      UIColor.white.set()
      ctx.fill(frame)
      ctx.translateBy(x: 0.0, y: frame.size.height)
      ctx.scaleBy(x: 1.0, y: -1.0)
      ctx.scaleBy(x: scale, y: scale)
      ctx.drawPDFPage(page)
      img = UIGraphicsGetImageFromCurrentImageContext()
    }
    UIGraphicsEndImageContext()
    return img
  }
  
  public func image(width: CGFloat) -> UIImage? {
    let frame = self.frame
    return image(scale:  UIScreen.main.scale * width/frame.size.width)?.scaled()
  }
  
  public func image(height: CGFloat) -> UIImage? {
    let frame = self.frame
    return image(scale:  UIScreen.main.scale * height/frame.size.height)?.scaled()
  }
  
  fileprivate init(page: CGPDFPage) { self.page = page }
}


/**
 PdfDoc is a simple Quartz based class to open PDF documents and to convert
 them to an Image.
 */
open class PdfDoc {
  
  /// The document
  public var doc: CGPDFDocument?  
  
  private var _fname: String?
  /// The file name of a PDF document
  public var fname: String? {
    get { return _fname }
    set {
      _fname = newValue
      if let fn = _fname {
        doc = CGPDFDocument(URL.init(fileURLWithPath: fn) as CFURL)
      } else { doc = nil }
    }
  }
  
  /// Number of pages in document
  public var count: Int { doc!.numberOfPages }
  
  /// PdfDoc[n] returns the n'th page (0<=n)
  public subscript(n: Int) -> PdfPage? {
    if let doc = self.doc, 
       n < count,
       let pg = doc.page(at: n+1) { 
      return PdfPage(page: pg)
    }
    else { return nil }
  }
  
  /// Init with raw PDF data
  public init(data: Data) {
    doc = CGPDFDocument(CGDataProvider(data: data as CFData)!)
  }
  
  /// Init with file name (path)
  public init(fname: String) {
    self.fname = fname
  }
  
}

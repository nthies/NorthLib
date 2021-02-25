//
//  PdfViewController.swift
//  NorthLib
//
//  Created by Ringo Müller-Gromes on 14.10.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit

/// Provides functionallity to interact between PdfOverviewCollectionVC and Pages with PdfPagesCollectionVC
open class PdfViewController : UIViewController, CanRotate{
  public private(set) var thumbnailController : PdfOverviewCollectionVC?
  public internal(set) var pageController : PdfPagesCollectionVC?
  public internal(set) var overlay : Overlay?
  
   var pdfModel : PdfModel?
  
  ///Difficult decission
  /// Light status bar because of black background TBD at Zoom in the white Newspaper is in bg on zoom out the black bg
  /// Simple solution => white BG!
  ///  darkmode lightMode depending
  override public var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
    
  
  public init(_ pdfModel : PdfModel? = nil) {
    if pdfModel == nil {
      self.pdfModel = PdfModelItem(url: PdfModelHelper.demoDocUrl())
    }
    else {
      self.pdfModel = pdfModel
    }
    guard let pdfModel = pdfModel else { fatalError("init() pdfModel is nil cannot show something usefull") }
    Log.minLogLevel = .Debug
    thumbnailController = PdfOverviewCollectionVC(pdfModel:pdfModel)
    pageController = PdfPagesCollectionVC(data: pdfModel)
    super.init(nibName: nil, bundle: nil)
    guard let detailController = pageController else {return }
    overlay = Overlay(overlay:detailController , into: self)
    overlay?.closeRatio = 0.8//Fix ScrollView e.g. ZoomedImageView in ScrollView close Ratio Issue
    overlay?.onRequestUpdatedCloseFrame(closure: { [weak self] in
      guard let self = self else { return nil}
      return self.thumbnailController?.frameAtIndex(index: self.pageController?.index ?? 0)
    })
    detailController.onX { [weak self] in
      guard let self = self else { return}
      self.overlay?.close(animated: true)
      self.log("All Images current Size: \(pdfModel.imageSizeMb) MB", logLevel: .Debug)
    }
    detailController.onTap { (oimg, x, y) in
      guard let zpdfi = oimg as? ZoomedPdfImage else { return }
      print("On item at Index: \(zpdfi.pdfPageIndex ?? -1) tapped at: \(x)/\(y)")
    }
  }
  
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  open override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if isBeingDismissed {
      print("cleanup")
      ///Cleanup
      for ctrl in self.children {
        ctrl.removeFromParent()
      }
      pageController?.onX {}
      pageController?.pdfModel = nil
      pageController?.images = []
      pageController?.menuItems = []
      pageController?.collectionView = nil
      pageController?.removeFromParent()
      thumbnailController?.clickCallback = nil
      thumbnailController?.pdfModel = nil
      thumbnailController?.menuItems = []
      thumbnailController?.removeFromParent()
      thumbnailController = nil
      overlay?.onClose(closure: nil)
      overlay?.onRequestUpdatedCloseFrame(closure: nil)
      pageController = nil
      overlay = nil
      pdfModel = nil
    }
  }
  
  open override func viewDidLoad() {
    super.viewDidLoad()
    guard let thumbnailController = thumbnailController else {return }
    thumbnailController.clickCallback = { [weak self] (sourceFrame, pdfModel) in
      guard let self = self else { return }
      guard let overlay = self.overlay else { return }
      self.pageController?.pdfModel = pdfModel
      var snapshot:UIImageView?
      var toFrame : CGRect = self.pageController?.view.frame ?? CGRect.zero
      if let pdfModel = pdfModel,
        let thumb = pdfModel.thumbnail(atIndex: pdfModel.index,
                                        finishedClosure: nil) {
        if thumb.size.width > thumb.size.height {
          toFrame.size.width = 2 * toFrame.size.width
        }
        snapshot = UIImageView(frame: sourceFrame)
        snapshot?.image = thumb
      }
      
      overlay.openAnimated(fromFrame: sourceFrame,
                           toFrame: toFrame,
                           snapshot:snapshot,
                           animateTargetSnapshot: false)
    }
    
    self.view.addSubview(thumbnailController.view)
    pin(thumbnailController.view, to: self.view)
    
    self.overlay?.maxAlpha = 0.9
    self.overlay?.open(animated: false, fromBottom: false)
    self.overlay?.setCloseActionToShrink() //Fix where to close to
  }
  
}

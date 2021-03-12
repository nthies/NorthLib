//
//  PdfOverviewCollectionVC.swift
//  NorthLib
//
//  Created by Ringo Müller-Gromes on 14.10.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit

/// Provides tile Overview either of various PDF Files or of various Pages of one PDF File
//may work just with IMages and delegate handles what hapen on tap
public class PdfOverviewCollectionVC : UICollectionViewController, CanRotate{
  
  // MARK: - Properties used in: UIScrollViewDelegate Extension
  // The closure to call when content scrolled more than scrollRatio
  private var whenScrolledClosure: ((CGFloat)->())?
  private var scrollRatio: CGFloat = 0
  // content y offset at start of dragging
  private var startDragging: CGFloat?
  
  /// Define the menu to display on long touch of a MomentView
  public var menuItems: [(title: String, icon: String, closure: (String)->())] = [] 
  public var cellLabelFont:UIFont? = UIFont.systemFont(ofSize: 8)
  public var cellLabelLinesCount = 0
  
  // MARK: - Properties
  private let reuseIdentifier = "pdfCell"
  
  var pdfModel: PdfModel
  public var clickCallback: ((CGRect, PdfModel?)->())?
  
  public init(pdfModel: PdfModel) {//Wrong can also be pdfpage
    self.pdfModel = pdfModel
    let layout = TwoColumnUICollectionViewFlowLayout(pdfModel: pdfModel)
    layout.sectionInset = UIEdgeInsets(top: PdfDisplayOptions.Overview.sideSpacing,
                                       left: PdfDisplayOptions.Overview.sideSpacing,
                                       bottom: PdfDisplayOptions.Overview.sideSpacing,
                                       right: PdfDisplayOptions.Overview.sideSpacing)
    /// reduced currently to 0 because label not filled
    /// possible data may come from datamodel, can be: titel, Seite 1 // taz 2, Seite 14 //  die wahrheit; S. 20
    /// Daten sind da, da die PDF diese enthällt
    layout.minimumLineSpacing = PdfDisplayOptions.Overview.rowSpacing
    layout.minimumInteritemSpacing = PdfDisplayOptions.Overview.interItemSpacing - 0.5//fix misscalculation bug
    super.init(collectionViewLayout: layout)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    collectionView?.showsVerticalScrollIndicator = false
    collectionView?.showsHorizontalScrollIndicator = false
    // Register cell classes
    collectionView?.register(PdfOverviewCvcCell.self, forCellWithReuseIdentifier: reuseIdentifier)
    if let cv = self.collectionView, let cvsv = cv.superview {
      pin(cv.bottom, to: cvsv.bottom)
      pin(cv.top, to: cvsv.topGuide())
      // TODO@Ringo: Where to Pin?, need Design Decission
//      pin(cv.top, to: cvsv.top)
      pin(cv.left, to: cvsv.leftGuide())
      pin(cv.right, to: cvsv.rightGuide())
      /* TODO@Ringo: Demo top Gradient, need Design Decission
      let topGradient = VerticalGradientView()
      topGradient.pinHeight(UIWindow.topInset)
      cvsv.addSubview(topGradient)
      pin(topGradient.left, to: cvsv.leftGuide())
      pin(topGradient.right, to: cvsv.rightGuide())
      pin(topGradient.top, to: cvsv.top)
      */
    }
  }
  
  // MARK: UICollectionViewDataSource
  public override func numberOfSections(in collectionView: UICollectionView) -> Int {
    // #warning Incomplete implementation, return the number of sections
    return 1
  }
  
  public override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return pdfModel.count
  }
  
  public override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let _cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
    guard let cell = _cell as? PdfOverviewCvcCell else { return _cell }
    cell.label.font = self.cellLabelFont
    cell.label.textColor = .white
    
    cell.imageView.image =  self.pdfModel.thumbnail(atIndex: indexPath.row, finishedClosure: { (img) in
      onMain { cell.imageView.image = img  }
    })
    
    guard let item = self.pdfModel.item(atIndex: indexPath.row) else {
      return cell
    }
    cell.label.numberOfLines = self.cellLabelLinesCount
    cell.label.text = item.pageTitle
    cell.menu?.menu = self.menuItems
    cell.imageView.contentMode = .scaleToFill
    return cell
  }
  
  public override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let attributes = collectionView.layoutAttributesForItem(at: indexPath)
    var sourceFrame = CGRect.zero
    if let attr = attributes {
      sourceFrame = self.collectionView.convert(attr.frame, to: self.collectionView.superview?.superview)
    }
    pdfModel.index = indexPath.row
    clickCallback?(sourceFrame, pdfModel)
  }
  
  /// Returns Cell Frame for given Index
  /// - Parameters:
  ///   - index: index of requested Frame
  ///   - fixFullFrame: if cell is out of view this returns a full cell size
  /// - Returns: frame for requested cell at index Path
  ///
  /// **Warning** Only used for Source and Target Frame to animate transition between background
  /// thumbnails and foreground full page - did not define cell's frame e.g. for change cell alignment
  /// ...unfortunately this is more complex
  public func frameAtIndex(index:Int, fixFullFrame:Bool = false) -> CGRect {
     let indexPath = IndexPath(row: index, section: 0)
     
     let attributes = collectionView.layoutAttributesForItem(at: indexPath)
     let size = collectionView(collectionView,
     layout: collectionViewLayout,
     sizeForItemAt: indexPath)
     
     var sourceFrame = CGRect.zero
     if let attr = attributes {
     sourceFrame = self.collectionView.convert(attr.frame, to: self.collectionView.superview?.superview)
     sourceFrame.size = size
     }
     return sourceFrame
  }
}

// MARK: - PdfOverviewCollectionVC
extension PdfOverviewCollectionVC {
  
  /// Define closure to call when web content has been scrolled
  public func whenScrolled( minRatio: CGFloat, _ closure: @escaping (CGFloat)->() ) {
    scrollRatio = minRatio
    whenScrolledClosure = closure
  }
  
  open override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    startDragging = scrollView.contentOffset.y
  }
  
  open override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if let sd = startDragging {
      let scrolled = sd-scrollView.contentOffset.y
      let ratio = scrolled / scrollView.bounds.size.height
      if let closure = whenScrolledClosure, abs(ratio) >= scrollRatio {
        closure(ratio)
      }
    }
    startDragging = nil
  }
}

// MARK: - UICollectionViewDelegateFlowLayout
/// Not scrollable if not available!
extension PdfOverviewCollectionVC: UICollectionViewDelegateFlowLayout {
  public func collectionView(_ collectionView: UICollectionView,
                             layout collectionViewLayout: UICollectionViewLayout,
                             sizeForItemAt indexPath: IndexPath) -> CGSize {
    return self.pdfModel.size(forItem: indexPath.row)
  }
}

class TwoColumnUICollectionViewFlowLayout : UICollectionViewFlowLayout {
  
  //An array to cache the calculated attributes
  fileprivate var cache = [UICollectionViewLayoutAttributes]()
  fileprivate var calculatedContentSize : CGSize?

  let pdfModel: PdfModel
  let cellHeight: CGFloat
  
  init(pdfModel: PdfModel) {
    self.pdfModel = pdfModel
    self.cellHeight = pdfModel.singlePageSize.height
    super.init()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  //The attributes for the item at the indexPath
  override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    return cache[indexPath.item]
  }
  
  override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    guard let attributesArray = super.layoutAttributesForElements(in: rect) else {
      return []
    }
    ///Bugfix disappering cells
    /// this is called by system and loads cells screen by screen, unfortunatly 1 cell disapperas, at the transition
    /// between 2 screens, fix it by just adding previous (missing) cell
    /// in Tests on iPhone 12Pro Simulator this happen on cells 13,21,29
    /// depending on pano page before and advertisig page
    /// if no pano pages this happend for pages [14,15] and [22,23] 
    var items:[UICollectionViewLayoutAttributes]? = attributesArray.map { attributes in
      if attributes.representedElementCategory == .cell {
        return self.layoutAttributesForItem(at:attributes.indexPath) ?? attributes
      }
      return attributes
    }
    if let first = attributesArray.first,
       first.indexPath.row > 0,
       let missing = self.layoutAttributesForItem(at:IndexPath(row: first.indexPath.row-1, section: first.indexPath.section)) {
      items?.append(missing)
    }
    return items
  }
  
  override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
      guard let collectionView = collectionView else { return false }
      return !newBounds.size.equalTo(collectionView.bounds.size)
  }
  
  override func prepare() {
    //We begin measuring the location of items only if the cache is empty
    guard cache.isEmpty == true, let collectionView = collectionView else {return}
    let spacing = self.minimumInteritemSpacing
    let rowHeight = self.cellHeight + self.minimumLineSpacing
    var yOffset = self.sectionInset.top
    let xLeft = self.sectionInset.left
    // |-sectionInset.left-[cell]-spacing-[cell]-sectionInset.right-|
    let panoWidth = max(0, collectionView.frame.size.width - self.sectionInset.left - self.sectionInset.right)
    let singleWidth = max(0, panoWidth/2 - spacing/2)
    let xRight = singleWidth + spacing + xLeft
    var prevPageType : PdfPageType?
    for idx in 0..<pdfModel.count {
      let indexPath = IndexPath(item: idx, section: 0)
      let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
      if let item = pdfModel.item(atIndex: idx) {
        //print("Layout Item \(item.pageTitle) type: \(item.pageType) atIndex: \(idx)")
        switch (prevPageType, item.pageType) {
        case (.left, .right):
          attributes.frame = CGRect(x: xRight, y: yOffset, width: singleWidth, height: cellHeight)
        case (_, .double):
          yOffset += rowHeight
          attributes.frame = CGRect(x: xLeft, y: yOffset, width: panoWidth, height: cellHeight)
        case (.right, .right):
          yOffset += rowHeight
          attributes.frame = CGRect(x: xRight, y: yOffset, width: singleWidth, height: cellHeight)
        case (_, .left):
          fallthrough
        default:
          if prevPageType != nil { yOffset += rowHeight}
          attributes.frame = CGRect(x: xLeft, y: yOffset, width: singleWidth, height: cellHeight)
        }
        prevPageType = item.pageType
      }
      cache.append(attributes)
    }
    calculatedContentSize = CGSize(width: collectionView.frame.size.width,
                                   height: yOffset + rowHeight)
  }
  
  override var collectionViewContentSize: CGSize {
    get {
      return calculatedContentSize ?? super.collectionViewContentSize
    }
  }

  override func invalidateLayout() {
    super.invalidateLayout()
    cache = []
    calculatedContentSize = nil
  }
}

//
//  PageCollectionVC.swift
//
//  Created by Norbert Thies on 10.09.18.
//  Copyright © 2018 Norbert Thies. All rights reserved.
//

import UIKit

fileprivate var countVC = 0


open class PageCollectionVC: UIViewController {
  
  /// The collection view displaying OptionalViews
  open var collectionView:PageCollectionView? = PageCollectionView()
  
  /// The Layout object determining the size of the cells
  open var cvLayout: UICollectionViewFlowLayout!

  /// A closure providing the optional views to display
  open var provider: ((Int, OptionalView?)->OptionalView)? = nil
  
  /// inset from top/bottom/left/right as factor to min(width,height)
  open var inset = 0.025
  
  // The raw cell size (without bounds)
  private var rawCellsize: CGSize { return self.collectionView?.bounds.size ?? CGSize.zero }
  
  // The default margin of cells (ie. left/right/top/bottom insets)
  private var margin: CGFloat {
    let s = rawCellsize
    return min(s.height, s.width) * CGFloat(inset)
  }
  
  // The size of a cell is defined by the collection views bounds minus margins
  private var cellsize: CGSize {
    let s = rawCellsize
    return CGSize(width: s.width - 2*margin, height: s.height - 2*margin)
  }
  
  // View which is currently displayed
  public var currentView: OptionalView? { 
    if let i = index { return collectionView?.optionalView(at: i) }
    else { return nil }
  }
  
  /// Index of current view, change it to scroll to a certain cell
  open var index: Int? {
    get { return collectionView?.index }
    set { collectionView?.index = newValue }
  }

  /// Define and change the number of views to display, will reload data
  open var count: Int {
    get { return collectionView?.count ?? 0 }
    set { collectionView?.count = newValue }
  }
  
  private var topConstraint: NSLayoutConstraint?
  private var bottomConstraint: NSLayoutConstraint?
  
  // Pin top of collectionView
  private func pinTop() {
    topConstraint?.isActive = false
    guard let collectionView = collectionView else { return }
    if pinTopToSafeArea {
      topConstraint = pin(collectionView.top, to: self.view.topGuide())
    }
    else { topConstraint = pin(collectionView.top, to: self.view.top) }
  }
  
  // Pin bottom of collectionView
  private func pinBottom() {
    bottomConstraint?.isActive = false
    guard let collectionView = collectionView else { return }
    if pinBottomToSafeArea {
      bottomConstraint = pin(collectionView.bottom, to: self.view.bottomGuide())
    }
    else { bottomConstraint = pin(collectionView.bottom, to: self.view.bottom) }
  }
  
  /// Pin collection view to top safe area?
  open var pinTopToSafeArea: Bool = true { didSet { pinTop() } }

  /// Pin collection view to bottom safe area?
  open var pinBottomToSafeArea: Bool = false { didSet { pinBottom() } }

  public init() { super.init(nibName: nil, bundle: nil) }
  
  public required init?(coder: NSCoder) { super.init(coder: coder) }

  /// Define closure to call when a cell is newly displayed  
  public func onDisplay(closure: @escaping (Int, OptionalView?)->()) {
    collectionView?.onDisplay(closure: closure)
  }
  
  /// Define closure to call when a cell is newly displayed
  public func onEndDisplayCell(closure: @escaping (Int, OptionalView?)->()) {
    collectionView?.onEndDisplayCell(closure: closure)
  }
    
  /// Defines the closure which delivers the views to display
  open func viewProvider(provider: @escaping (Int, OptionalView?)->OptionalView) {
    collectionView?.viewProvider(provider: provider)
  }
 
  // MARK: - Life Cycle

  override open func loadView() {
    super.loadView()
    collectionView?.isPagingEnabled = true
    collectionView?.relativePageWidth = 1
    collectionView?.relativeSpacing = 0
    collectionView?.backgroundColor = UIColor.white
    guard let collectionView = collectionView else { return }
    self.view.addSubview(collectionView)
    pinTop()
    pinBottom()
    pin(collectionView.left, to: self.view.left)
    pin(collectionView.right, to: self.view.right)
  }
  
  open override func viewDidLoad() {
    super.viewDidLoad()
    if count != 0 { collectionView?.reloadData() }
  }
  
  // TODO: transition/rotation better with collectionViewLayout subclass as described in:
  // https://www.matrixprojects.net/p/uicollectionviewcell-dynamic-width/
  open override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
    super.willTransition(to: newCollection, with: coordinator)
    coordinator.animate(alongsideTransition: nil) { [weak self] ctx in
      self?.collectionView?.collectionViewLayout.invalidateLayout()
    }
  }
  
} // PageCollectionVC

//
//  CarouselView.swift
//
//  Created by Norbert Thies on 06.04.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit

/**
 A CarouselFlowLayout models a horizontal cell layout with a scaling effect
 to have the central cell enlarged.
 */
public class CarouselFlowLayout: UICollectionViewFlowLayout, DoesLog {
  
  /// The maximum scale to use when increasing the size of the central cell
  var maxScale: CGFloat = 1.3

  /// Increase the requested cell up to maxScale
  private func scaleAttribute(_ attr: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
    guard let cv = self.collectionView else { return attr }
    let visibleRect = CGRect(origin: cv.contentOffset, size: cv.bounds.size)
    let attr = attr.copy() as! UICollectionViewLayoutAttributes
    if attr.representedElementCategory == .cell {
      if attr.frame.intersects(visibleRect) {
        let dist = abs(visibleRect.midX - attr.center.x)
        var cellSize: CGSize = self.itemSize
        if let delegate = cv.delegate as? UICollectionViewDelegateFlowLayout,
           let csize = delegate.collectionView?(cv, layout: self, sizeForItemAt: attr.indexPath) {
          cellSize = csize
        }
        if dist < cellSize.width {
          let scale = 1 + (maxScale - 1) * (1 - abs(dist/cellSize.width))
          attr.transform3D = CATransform3DMakeScale(scale, scale, 1)
        }
      }
    }
    return attr
  }
  
  /// Increase the visible cells up to maxScale
  /// ToDo: Missing Cache calculation!
  public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    guard let _ = self.collectionView else { return nil }
    if let attrs = super.layoutAttributesForElements(in: rect) {
      return attrs.map { attr in scaleAttribute(attr) }
    }
    return nil
  }
  
  /// Increase the cell at indexPath up to maxScale
  /// ToDo: Remove unused!
  public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    return super.layoutAttributesForItem(at: indexPath)
  }
  
  /// Recalculate layout when scrolling
  public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
    return true
  }
  
} // CarouselFlowLayout

/**
 A CarouselView is a PageCollectionView subclass presenting a number of views in a
 carousel like fashion.
  */
open class CarouselView: PageCollectionView {
  
  /// maximum scale of center page
  open var maxScale: CGFloat = 1.3 { 
    didSet { 
      (self.collectionViewLayout as? CarouselFlowLayout)?.maxScale = maxScale
      self.setNeedsLayout() 
    } 
  }
  
  // Setup the CarouselView
  private func setup() {
    guard let layout = self.collectionViewLayout as? CarouselFlowLayout else { return }
    relativeSpacing = 0.12
    relativePageWidth = 0.6
    layout.maxScale = maxScale
  }
  
  public init(frame: CGRect) {
    super.init(frame: frame, layout: CarouselFlowLayout())
    setup()
  }
  
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }

  public convenience init() { self.init(frame: CGRect()) }
  
} // CarouselView

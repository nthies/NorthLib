//
//  PdfOverviewCvcCell.swift
//  NorthLib
//
//  Created by Ringo.Mueller on 14.10.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit

public class PdfOverviewCvcCell : UICollectionViewCell {
  
  public let imageView = UIImageView()
  public let label = UILabel()
  public let button = UIButton()
  private let wrapper = UIView()
  
  var menu:ContextMenu?
  
  private var leftSideContentConstraint : NSLayoutConstraint?//pinned to left side
  private var rightSideContentConstraint : NSLayoutConstraint?//pinned to right side
  private var leftCenterContentConstraint : NSLayoutConstraint?//left pinned to center
  private var rightCenterContentConstraint : NSLayoutConstraint?//right pinned to center

  public var cellAlignment : ContentAlignment {
    didSet {
      switch cellAlignment {
        case .left:
          leftCenterContentConstraint?.isActive = false
          rightSideContentConstraint?.isActive = false
          leftSideContentConstraint?.isActive = true
          rightCenterContentConstraint?.isActive = true
        case .right:
          leftSideContentConstraint?.isActive = false
          rightCenterContentConstraint?.isActive = false
          rightSideContentConstraint?.isActive = true
          leftCenterContentConstraint?.isActive = true
        case .fill:
          leftCenterContentConstraint?.isActive = false
          rightCenterContentConstraint?.isActive = false
          leftSideContentConstraint?.isActive = true
          rightSideContentConstraint?.isActive = true
      }
    }
  }
  
  public override func prepareForReuse() {
    self.imageView.image = nil
    self.label.text = nil
  }
  
  override init(frame: CGRect) {
    cellAlignment = .left
    super.init(frame: frame)
    /**
     Bugfix after Merge
     set ImageViews BG Color to same color like Collection Views BG fix white layer on focus
     UIColor.clear or UIColor(white: 0, alpha: 0) did not work
     Issue is not in last Build before Merge 0.4.18-2021011501 ...but flickering is there on appearing so its half of the bug
     - was also build with same xcode version/ios sdk
     issue did not disappear if deployment target is set back to 11.4
     */
    imageView.backgroundColor = .black
    imageView.contentMode = .scaleAspectFit
    menu = ContextMenu(view: imageView)
    
    wrapper.addSubview(imageView)
    pin(imageView, to: wrapper, exclude: .bottom)
    pin(imageView.bottom,
        to: wrapper.bottom,
        dist: -PdfDisplayOptions.Overview.labelHeight,
        priority: .defaultHigh)
    
    label.numberOfLines = 2
    wrapper.addSubview(label)
    pin(label, to: wrapper, exclude: .top)
    label.pinHeight(PdfDisplayOptions.Overview.labelHeight)
    
    wrapper.addSubview(button)
    pin(button, to: wrapper, exclude: .top)
    button.pinHeight(PdfDisplayOptions.Overview.labelHeight, priority: .defaultHigh)
    
    button.imageEdgeInsets = UIEdgeInsets(top: 2, left: 8, bottom: -2, right: -8)
    button.semanticContentAttribute = UIApplication.shared
      .userInterfaceLayoutDirection == .rightToLeft ? .forceLeftToRight : .forceRightToLeft
    button.imageView?.tintColor = .white
    
    contentView.addSubview(wrapper)
    pin(wrapper.top, to: contentView.top)
    pin(wrapper.bottom, to: contentView.bottom)
    
    let centerOffset = PdfDisplayOptions.Overview.interItemSpacing/2
    
    leftSideContentConstraint = pin(wrapper.left, to: contentView.left)
    leftSideContentConstraint?.isActive = false
    
    leftCenterContentConstraint = pin(wrapper.left,
                                      to: contentView.centerX,
                                      dist: centerOffset)
    leftCenterContentConstraint?.isActive = false
    
    rightSideContentConstraint = pin(wrapper.right, to: contentView.right)
    rightSideContentConstraint?.isActive = false
    
    rightCenterContentConstraint = pin(wrapper.right,
                                      to: contentView.centerX,
                                      dist: -centerOffset)
    rightCenterContentConstraint?.isActive = false
    cellAlignment = .left
//    
    self.addBorder(.green, 1.0)
    self.contentView.addBorder(.yellow, 2.0)
    self.wrapper.addBorder(.red, 4.0)
    self.imageView.addBorder(.blue, 6.0)
    
  }
  
  public var text : String? {
    didSet {
      button.setTitle(text, for: .normal)
    }
  }
  
  public var cloudHidden : Bool = false {
    didSet {
      if cloudHidden {
        button.setImage(nil, for: .normal)
      }
      else {
        button.setImage(UIImage(name: "icloud.and.arrow.down"), for: .normal)
      }
    }
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

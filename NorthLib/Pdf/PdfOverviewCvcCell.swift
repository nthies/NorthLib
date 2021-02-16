//
//  PdfOverviewCvcCell.swift
//  NorthLib
//
//  Created by Ringo.Mueller on 14.10.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit

public class PdfOverviewCvcCell : UICollectionViewCell {
  
  public let imageView:UIImageView? = UIImageView()
  public let label:UILabel? = UILabel()
  public let button:UIButton? = UIButton()
  var menu:ContextMenu?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    if let iv = imageView {
      /**
        Bugfix after Merge
        set ImageViews BG Color to same color like Collection Views BG fix white layer on focus
       UIColor.clear or UIColor(white: 0, alpha: 0) did not work
       Issue is not in last Build before Merge 0.4.18-2021011501 ...but flickering is there on appearing so its half of the bug
          - was also build with same xcode version/ios sdk
       issue did not disappear if deployment target is set back to 11.4
       */
      iv.backgroundColor = .black
      menu = ContextMenu(view: iv)
    }
    if let imageView = imageView {
      imageView.contentMode = .scaleAspectFit
      self.contentView.addSubview(imageView)
      pin(imageView, to: contentView, exclude: .bottom)
      pin(imageView.bottom, to: contentView.bottom, priority: .defaultHigh)
    }
    
    if let label = label {
      label.numberOfLines = 2
      self.contentView.addSubview(label)
      pin(label, to: contentView, exclude: .top)
      label.pinHeight(30)
    }
    
    if let button = button {
      self.contentView.addSubview(button)
      pin(button, to: contentView, exclude: .top)
      button.pinHeight(30, priority: .defaultHigh)
      button.imageEdgeInsets = UIEdgeInsets(top: 2, left: 8, bottom: -2, right: -8)
      button.semanticContentAttribute = UIApplication.shared
          .userInterfaceLayoutDirection == .rightToLeft ? .forceLeftToRight : .forceRightToLeft
      button.imageView?.tintColor = .white
    }
    
    if let label = label, let imageView = imageView  {
      pin(label.top, to: imageView.bottom, dist: 3, priority: .required)
    }
    if let button = button, let imageView = imageView  {
      pin(button.top, to: imageView.bottom, priority: .required)
    }
  }
  
  public var text : String? {
    didSet {
      guard let button = button else { return }
      button.setTitle(text, for: .normal)
    }
  }
  
  public var cloudHidden : Bool = false {
    didSet {
      guard let button = button else { return }
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

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
  
  var menu:ContextMenu?
 
  public override func prepareForReuse() {
    self.imageView.image = nil
    self.label.text = nil
  }
  
  override init(frame: CGRect) {
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
    
    contentView.addSubview(imageView)
    pin(imageView, to: contentView)
    
    label.numberOfLines = 0
    contentView.addSubview(label)
    pin(label.leftGuide(), to: contentView.leftGuide())
    pin(label.rightGuide(), to: contentView.rightGuide())
    //Pin the Label outside of the cell simplifies everything!
    pin(label.topGuide(), to: contentView.bottomGuide(), dist: 2.0)
    
//    self.addBorder(.green, 0.5)
//    self.contentView.addBorder(.yellow, 1.0)
//    self.imageView.addBorder(.blue, 1.5)
//    self.label.addBorder(.orange, 1.0)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}


//public class PdfOverviewTitleCvcCell : PdfOverviewCvcCell {
//  public let dateLabel = UILabel()
//  override init(frame: CGRect) {
//    super.init(frame: frame)
//    contentView.addSubview(dateLabel)
//  }
//  
//  required init?(coder: NSCoder) {
//    fatalError("init(coder:) has not been implemented")
//  }
//}

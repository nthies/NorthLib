//
//  Label.swift
//
//  Created by Norbert Thies on 16.06.22.
//

import UIKit

/**
 * This small extension allows to directly use HTM strings in UILabels
 * via transforming the HTML to an attributed text.
 */
extension UILabel {
  var htmlText: String? {
    get { 
      let attr = [NSAttributedString.DocumentAttributeKey.documentType: 
                  NSAttributedString.DocumentType.html]
      if let txt = attributedText,
         let data = try? txt.data(from: NSMakeRange(0, txt.length), 
                                  documentAttributes: attr),
         let str = String(data: data, encoding: .utf8) {
        return str
      }
      return nil
    }
    set {
      guard let newValue = newValue else { return }
      let str = String(format:"""
        <span style=\"font-family: '-apple-system', 'HelveticaNeue'; 
         font-size: \(self.font!.pointSize - 2)\">%@</span>
      """, newValue)
      if let astr = try? NSAttributedString(
        data: str.data(using: .unicode, allowLossyConversion: true)!,
        options: [.documentType: NSAttributedString.DocumentType.html,
                  .characterEncoding: String.Encoding.utf8.rawValue], 
        documentAttributes: nil) {
        self.attributedText = astr
      }
    }
  }
}

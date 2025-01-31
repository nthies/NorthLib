//
//  Label.swift
//
//  Created by Norbert Thies on 16.06.22.
//

import UIKit

/**
 * Helper to access taz Font from taz app target NorthLib
 * a 2nd font register is not possible!
 * => this is a kind of a Registry Pattern to solve it
 * alternative refactor or move all Toast Code to taz App Project
 */
public class SharedTazFont {
  private static let shared = SharedTazFont()
  private var font: UIFont?
  static var font: UIFont? { shared.font }
  public static func register(_ font:UIFont){ shared.font = font }
}

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
      if let astr = try? NSMutableAttributedString(
        data: str.data(using: .unicode, allowLossyConversion: true)!,
        options: [.documentType: NSAttributedString.DocumentType.html,
                  .characterEncoding: String.Encoding.utf8.rawValue], 
        documentAttributes: nil) {
        
        if astr.string.contains("🐾") == true,
           let tazFont = SharedTazFont.font {
          let logoRange = (astr.string as NSString).range(of: "🐾")
          astr.addAttribute(.font, value: tazFont, range: logoRange)
        }
        
        self.attributedText = astr
      }
    }
  }
}

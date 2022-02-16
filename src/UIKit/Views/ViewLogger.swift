//
//  ViewLogger.swift
//
//  Created by Norbert Thies on 16.05.19.
//  Copyright © 2019 Norbert Thies. All rights reserved.
//

import UIKit

/// A LogView is used to display log messages
public protocol LogView: Touchable {
  /// Append text at the end of the LogView (which is scrolled if necessary)
  func append(txt: String, color: UIColor?)
  /// Scroll to the bottom of the LogView
  func scrollToBottom()
}

extension LogView {  
  /// Pin view to other view
  public func pinToView(_ view: UIView) {
    pin(top, to: view.topGuide())
    pin(bottom, to: view.bottom)
    pin(left, to: view.left)
    pin(right, to: view.right)
  }
}

/// A minimalistic LogView consisting of a TextView only
open class SimpleLogView: UITextView, LogView, Touchable {  
 
  /// The default font for log messages
  public static var font = UIFont(name: "Menlo-Regular", size: 14.0)
  
  /// The tap recognizer
  public var tapRecognizer = TapRecognizer()
  
  /// Append colored text
  public func append(txt: String, color: UIColor? = UIColor.black) {
    let astr = NSMutableAttributedString()
    astr.append(self.attributedText)
    var str = txt
    if !txt.hasSuffix("\n") { str += "\n" }
    let msg = NSMutableAttributedString(string: str, attributes: 
      [NSAttributedString.Key.foregroundColor: color as Any,
       NSAttributedString.Key.font: SimpleLogView.font as Any])
    astr.append(msg)
    self.attributedText = astr
    if isVisible { scrollToBottom() }
  }
  
  /// Scroll textView to the bottom
  public func scrollToBottom() {
    let range = NSMakeRange(text.count - 1, 0)
    scrollRangeToVisible(range)
  }

  private func setup() {
    isEditable = false
    text = ""
  }
  
  public init(frame: CGRect) {
    super.init(frame: frame, textContainer: nil)
    setup()
  }
  
  public convenience init() { self.init(frame: CGRect()) }
  
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }
  
}

extension Log {
  
  /// A ViewLogger writes all passed log messages to a TextView
  open class ViewLogger: Logger {
    
    // Colors to use in LogView
    static var colors: [Log.LogLevel:UIColor] = [
      .Debug : UIColor.rgb(0x0000aa),
      .Info  : UIColor.black,
      .Error : UIColor.orange,
      .Fatal : UIColor.red
    ]
    /// TextView to log to
    public var logView: LogView
    
    /// The ViewLogger must be initialized with a TextView
    public init(logView: LogView? = nil) {
      if let lv = logView { self.logView = lv }
      else { self.logView = SimpleLogView() }
    }
    
    /// log a message to the LogView
    public override func log(_ msg: Message) {
      DispatchQueue.main.async { [weak self] in
        if let this = self {
          let txt = String(describing: msg)
          this.logView.append(txt: txt, color: ViewLogger.colors[msg.logLevel])
        }
      }
    }
    
  } // class ViewLogger
  
} // extension Log

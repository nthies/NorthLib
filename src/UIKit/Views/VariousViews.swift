//
//  VariousViews.swift
//
//  Created by Norbert Thies on 06.04.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit

/**
 A placeholder view
 
 An *UndefinedView* may be used as placeholder for a view that is currently not
 available. It consists of a label showing a question mark which is resized to fit
 the view's dimensions. The view's background color is *clear* and the question mark
 is written in *yellow*.
 */
open class UndefinedView: UIView {
  public var label = UILabel()
  
  private func setup() {
    backgroundColor = UIColor.red
    label.backgroundColor = UIColor.clear
    label.font = UIFont.boldSystemFont(ofSize: 200)
    label.textColor = UIColor.yellow
    label.textAlignment = .center
    label.adjustsFontSizeToFitWidth = true
    label.text = "?"
    addSubview(label)
    pin(label.centerX, to: self.centerX)
    pin(label.centerY, to: self.centerY)
    pin(label.width, to: self.width, dist: -20)
  }
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }
}

/**
 A view that may currently not be available
 
 Sometimes a view that should be displayed is not immediately available or
 its contents is in an undefined state.
 In such situations it may be pratical to display another view as placeholder
 until the *real* view's contents becomes available.
 The OptionalView addresses this situation. It consists of two optional views,
 the *mainView* being the view that should be displayed and a *waitingView* which
 is displayed when *mainView* is not available.
 */
public protocol OptionalView {
  /// The *real* view to display
  var mainView: UIView? { get }
  /// The placeholder view
  var waitingView: UIView? { get }
  /// Returns true if the *real* view (mainView) is available
  var isAvailable: Bool { get }
  /// Defines a closure to call when *mainView* becomes available
  var whenAvailable: Callback<Void>.Store { get }
  /// Load the *mainView's* contents
  func loadView()
}

public extension OptionalView {
  /// Returns the view that should currently be displayed
  var activeView: UIView { return isAvailable ? mainView! : (waitingView ?? UndefinedView()) }
}

/// Common Views can be optional
extension UIView: OptionalView {
  public var mainView: UIView? { return self }
  public var waitingView: UIView? { return nil }
  public var isAvailable: Bool { return true }
  public var whenAvailable: Callback<Void>.Store { {_ in} }
  public func loadView() {}
}

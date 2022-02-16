//
//  Picker.swift
//
//  Created by Norbert Thies on 25.03.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit

/** 
 A Picker is a straight forward UIPickerView subclass intended to simplify
 UIPickerView usage. This implementation only supports one component.
 */
open class Picker: UIPickerView, UIPickerViewDelegate, UIPickerViewDataSource {
  
  /// The array of Strings to present as selection
  open var items: [String] = [] { didSet { reloadAllComponents() } }
  
  /// The currently selected index
  open var index: Int {
    get { return selectedRow(inComponent: 0) }
    set { selectRow(newValue, inComponent: 0, animated: false) }
  }
  
  /// The color to use for text
  open var textColor = UIColor.black
  
  // The closure to call upon selection
  var selectionClosure: ((Int)->())?
  
  /// Define the closure to call upon selection
  open func onSelection(closure: ((Int)->())?) { selectionClosure = closure }
  
  func setup() {
    delegate = self
    dataSource = self
  }
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }
  
  /// Initialize with Array of Strings
  public convenience init(items: [String]) {
    self.init(frame: CGRect())
    self.items = items
  }
  
  // MARK: - UIPickerViewDataSource protocol
  public func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
  
  public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return items.count
  }
  
  // MARK: - UIPickerViewDelegate protocol  
  public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
    var label = view as? UILabel
    if label == nil {
      label = UILabel()
      label?.textAlignment = .center
      label?.font = UIFont.preferredFont(forTextStyle: .headline)
    }
    label!.textColor = textColor
    label!.text = items[row]
    return label!
  }
  
  public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    self.selectionClosure?(row)
  }
  
} // Picker

//
//  MonthPicker.swift
//  NorthLib
//
//  Created by Ringo on 23.09.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import Foundation
import UIKit

open class MonthPickerController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
  
  public var doneHandler: (() -> ())?
  var initialSelectedDate : Date?
  public var pickerFont : UIFont?
  
  public var selectedDate : Date {
    get {
      let selected = _selectedDate
      if selected > data.maximumDate { return data.maximumDate }
      if selected < data.minimumDate { return data.minimumDate }
      return selected
    }
  }
  
  var _selectedDate : Date {
    get {
      return DateComponents(calendar: Calendar.current,
                                    year: self.picker.selectedRow(inComponent: 1) + data.minimumYear,
                                    month: self.picker.selectedRow(inComponent: 0) + 1,
                                    day: 1,
                                    hour: 12).date
        ?? Date()
    }
  }
  
  public init(minimumDate:Date, maximumDate:Date, selectedDate:Date) {
    data = DatePickerData(minimumDate: minimumDate, maximumDate: maximumDate)
    initialSelectedDate = selectedDate
    super.init(nibName: nil, bundle: nil)
  }
  
  required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  let data : DatePickerData
  
  let picker = UIPickerView()
  public let content = UIView()
  let applyButton = UIButton()
  
  open override func viewDidLoad() {
    picker.delegate = self
    picker.dataSource = self
    
    content.addSubview(picker)
    pin(picker.bottomGuide(), to: content.bottomGuide())
    pin(picker.topGuide(), to: content.topGuide())
    let dist = UIScreen.main.scale * 30
    pin(picker.leftGuide(), to: content.leftGuide(), dist: dist)
    pin(picker.rightGuide(), to: content.rightGuide(), dist: -dist)
    
    applyButton.setImage(UIImage(name: "arrow.2.circlepath"), for: .normal)
    applyButton.imageView?.tintColor = textColor
    
    applyButton.pinSize(CGSize(width: 70, height: 70))
    applyButton.backgroundColor = .clear
    applyButton.addTarget(self, action: #selector(donedatePicker), for: .touchUpInside)
    
    content.addSubview(applyButton)
    pin(picker.rightGuide(), to: applyButton.leftGuide(), dist: 10)
    pin(picker.centerY, to: applyButton.centerY)
    
    self.view.addSubview(content)
    pin(content.topGuide(), to: self.view.topGuide(), priority: .fittingSizeLevel)
    content.pinHeight(181, priority:.required)
    pin(content.bottom, to: self.view.bottomGuide(), dist: -Toolbar.ContentToolbarHeight)
    
    pin(content.width, to: self.view.width).priority = .defaultHigh
    content.pinWidth(500.0, relation: .lessThanOrEqual, priority: .required)
    content.centerX()
    
    
    if let dateToSet = self.initialSelectedDate {
      self.setDate(dateToSet, animated: false)
      self.initialSelectedDate = nil //disable on re-use
    }
  }
  
  /// The currently selected index
  open var index: Int {
    get { return self.picker.selectedRow(inComponent: 0) }
    set { self.picker.selectRow(newValue, inComponent: 0, animated: false) }
  }
  
  /// The color to use for text
  open var textColor = UIColor.white
  
  // The closure to call upon selection
  var selectionClosure: ((Int)->())?
  
  /// Define the closure to call upon selection
  open func onSelection(closure: ((Int)->())?) { selectionClosure = closure }
  
  @objc func donedatePicker(){
    doneHandler?()
  }
}

// MARK: - UIPickerViewDelegate protocol
extension MonthPickerController {
  
  public func selectedVal()->String{
    
    return "\(data.monthLabel(idx: self.picker.selectedRow(inComponent: 0))) - \(data.yearLabel(idx: self.picker.selectedRow(inComponent: 1)))"
  }
  
  public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
    var label = view as? UILabel
    if label == nil {
      label = UILabel()
      label?.textAlignment = .center
      label?.font = pickerFont ?? UIFont.preferredFont(forTextStyle: .headline)
    }
    label!.textColor = textColor
    if component == 0 {
      label!.text = data.monthLabel(idx: row)
    }
    else if component == 1 {
      label!.text = data.yearLabel(idx: row)
      
    } else {
      label!.text = "*"
    }
    
    return label!
  }
  
  public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    let kRotationAnimationKey = "rotationanimationkey"
    if self.applyButton.layer.animation(forKey: kRotationAnimationKey) == nil {
      let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
      rotationAnimation.fromValue = 0.0
      rotationAnimation.toValue = Float.pi * 2.0
      rotationAnimation.duration = 0.9
      rotationAnimation.repeatCount = 1
      
      self.applyButton.imageView?.layer.add(rotationAnimation, forKey: kRotationAnimationKey)
    }
    
    if self._selectedDate < self.data.minimumDate {
      self.setDate(self.data.minimumDate, animated : true)
      return;
    } else if self._selectedDate > self.data.maximumDate {
      self.setDate(self.data.maximumDate, animated : true)
      return;
    }
    
    self.selectionClosure?(row)
  }
  
  func setDate(_ date:Date, animated:Bool){
    self.picker.selectRow((date.components().month ?? 1) - 1, inComponent: 0, animated: animated)
    self.picker.selectRow((date.components().year ?? 0) - data.minimumYear, inComponent: 1, animated: animated)
  }
}

// MARK: - UIPickerViewDataSource protocol
extension MonthPickerController{
  
  public func numberOfComponents(in pickerView: UIPickerView) -> Int { 2 }
  
  public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    if component == 0 {
      return data.monthIniciesCount
    }
    else if component == 1 {
      return data.yearIniciesCount
    }
    return 0
  }
}

// MARK: - ext:MPC DatePickerData
/// Data Helper as inner class
extension MonthPickerController {
  class DatePickerData {
    
    var germanMonthNames : [String] = ["Januar", "Februar", "März", "April", "Mai", "Juni", "Juli", "August", "September", "Oktober", "November", "Dezember"]
    let minimumDate : Date
    let maximumDate : Date
    let minimumYear : Int
    let monthIniciesCount : Int
    let yearIniciesCount : Int
    
    init(minimumDate : Date, maximumDate : Date) {
      self.minimumDate = minimumDate
      self.maximumDate = maximumDate
      
      minimumYear = minimumDate.components().year ?? 0
      
      let intervall = Calendar.current.dateComponents([.month, .year], from: minimumDate, to: maximumDate)
      
      yearIniciesCount = 1 + (intervall.year ?? 0)
      monthIniciesCount = 12
    }
    
    func monthLabel(idx:Int) -> String {
      return "\(germanMonthNames.valueAt(idx) ?? "")"
    }
    
    func yearLabel(idx:Int) -> String {
      return "\(minimumYear + idx)"
    }
  }
}

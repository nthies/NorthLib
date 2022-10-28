//
//  DownloadStatusButton.swift
//  Test App UIKit
//
//  Created by Ringo Müller on 17.03.21.
//

import Foundation
import UIKit

public enum DownloadStatusIndicatorState { case notStarted, process, justDone, done, waiting }

public class DownloadStatusButton : UIView {
   
  private var indicatorHeight:CGFloat = 25.0

  
  public private(set) var indicator = DownloadStatusIndicator()
  public private(set) var label = UILabel()
  
  func setup() {
    self.addSubview(label)
    self.addSubview(indicator)
   
    indicator.pinSize(CGSize(width: indicatorHeight, height: indicatorHeight))

    label.numberOfLines = 1

    pin(label.left, to: self.left)
    pin(indicator.left, to: label.right, dist: 1.0, priority: .fittingSizeLevel)
    pin(indicator.right, to: self.right)
    
    indicator.centerY()
    label.centerY()
  }
  
  override public init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }
}

public class DownloadStatusIndicator: UIView {
  //a wrapper for CALayer and Animation
  private var circleWrapper = UIView()
  //the CALayer and Animation
  private var circle = ProgressCircle()
  //the icon e.g. for a cloud or checkmark icon
  private var imageWrapper = UIImageView()
  //the label for text to display
 
  private var circleHeightConstraint: NSLayoutConstraint?
  public private(set) var circleHeightRatio:CGFloat? {
    didSet {
      if circleHeightRatio == oldValue { return }
      if circleWrapper.superview != self { return }
      circleHeightConstraint?.isActive = false
//      if let c = circleHeightConstraint { circleWrapper.removeConstraint(c)}
      guard let newValue = circleHeightRatio else { return }
      circleHeightConstraint
      = circleWrapper.pinHeight(to: self.height, factor: newValue)
    }
  }
  
  private var imageHeightConstraint: NSLayoutConstraint?
  public private(set) var imageHeightRatio:CGFloat? {
    didSet {
      if imageHeightRatio == oldValue { return }
      if imageWrapper.superview != self { return }
      imageHeightConstraint?.isActive = false
      guard let newValue = imageHeightRatio else { return }
      imageHeightConstraint
      = imageWrapper.pinHeight(to: self.height, factor: newValue)
    }
  }
  
  private var circleYConstraint: NSLayoutConstraint?
  private var imageYConstraint: NSLayoutConstraint?

  public private(set) var circleOffsetY:CGFloat
  = 1.0 { didSet { circleYConstraint?.constant = circleOffsetY }}

  private var cloudImage : UIImage? = UIImage(named: "download")
  private var checkmarkImage : UIImage? = UIImage(name: "checkmark")

  public var downloadState: DownloadStatusIndicatorState? {
    didSet{ if oldValue != downloadState { update()}}}
  
  func update(){
    switch downloadState {
      case .notStarted:
        percent = 0.0
        image = cloudImage
        circleWrapper.isHidden = true
      case .process:
        image = nil
        circleWrapper.isHidden = false
      case .done:
        percent = 1.0
        image = nil
        circleWrapper.isHidden = true
      case .justDone:
        image = checkmarkImage
        circleWrapper.isHidden = true
      case .waiting:
        image = nil
        circleWrapper.isHidden = false
        circle.waiting = true
      default:
        image = nil
        circleWrapper.isHidden = true
    }
  }
  
  public var percent:Float = 0.0 {
    didSet {
      if downloadState == .process, oldValue != percent {
        circle.progress = percent
        if percent == 1.0 {
          downloadState = .justDone
          onMainAfter(2.0) { [weak self] in
            self?.downloadState = .done
          }
        }
      }
    }
  }
  
  public var image : UIImage? {
    didSet {
      if imageWrapper.image == image { return }
      imageWrapper.image = image
      switch image {
        case cloudImage:
          imageYConstraint?.constant = 3.2
          imageHeightRatio = 0.78
        case checkmarkImage:
          imageYConstraint?.constant = 0.0
          imageHeightRatio = 0.7
        default:
          break;
      }
    }
  }
    
  public override func tintColorDidChange() {
    super.tintColorDidChange()
    self.circle.color = self.tintColor
  }
  
  var lastSize: CGSize = .zero
  
  public override func layoutSubviews() {
    super.layoutSubviews()
    if self.frame.size == lastSize { return }
    lastSize = self.frame.size
    circle.frame = CGRect(origin: .zero, size: circleWrapper.frame.size)
    imageWrapper.doLayout()
    circleWrapper.setNeedsUpdateConstraints()
    circleWrapper.updateConstraintsIfNeeded()
  }
  
  public override func didMoveToSuperview() {
    super.didMoveToSuperview()
    
  }
  
  public override var frame: CGRect {
    didSet {
      if oldValue == frame { return }
      print("set ned frame \(self.frame.size)")
    }
  }
  
  
  func setup() {
    circleWrapper.layer.addSublayer(circle)
    self.addSubview(circleWrapper)
    self.addSubview(imageWrapper)
    
    imageWrapper.contentMode = .scaleAspectFit
    
    pin(circleWrapper.right, to: self.right)
    pin(imageWrapper.right, to: self.right)
    
    circleWrapper.pinAspect(ratio: 1.0)
    imageWrapper.pinAspect(ratio: 1.0)
    
    circleHeightRatio = 0.75
        
    circleYConstraint = circleWrapper.centerY(dist: circleOffsetY)
    imageYConstraint = imageWrapper.centerY()
    update()
  }
  
  
  var progress: Float {
    set { circle.progress = newValue }
    get { circle.progress }
  }
  
  var waiting: Bool {
    set { circle.waiting = newValue }
    get { circle.waiting }
  }
  
  override public init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }
}

class ProgressCircle: CALayer {
  ///track line width
  let lw:CGFloat = 1.3
  
  override var frame: CGRect
  { didSet { if oldValue != frame { updateComponents() }}}
    
  public var progress: Float = 0.0 {
    didSet{
      waiting = false
      if let tv = self.animation.toValue as? Float, progress - tv < 0.1 { return }
      self.progressCircle.strokeColor = color.cgColor
      onMain { [weak self] in
        guard let self = self else { return }
        self.animation.fromValue = oldValue
        self.animation.toValue = self.progress
        if self.progressCircle.animation(forKey: "ani1") != nil {
          self.progressCircle.removeAnimation(forKey: "ani1")
          self.progressCircle.add(self.animation, forKey: "ani2")
        } else {
          self.progressCircle.removeAnimation(forKey: "ani2")
          self.progressCircle.add(self.animation, forKey: "ani1")
        }
        self.stopIcon.backgroundColor = self.color.cgColor
      }
    }
  }
  
  public var waiting: Bool = false {
    didSet{
      if waiting == oldValue { return }
      
      self.progressCircle.strokeColor = color.cgColor
      self.progressCircle.strokeEnd = 0.3
      onMain { [weak self] in
        guard let self = self else { return }
        if self.waiting == false
            && self.progressCircle.animation(forKey: "waitingAnimation") != nil{
          self.progressCircle.removeAnimation(forKey: "waitingAnimation")
          return
        }
        self.progressCircle.add(self.waitingAnimation, forKey: "waitingAnimation")
      }
    }
  }
  
  
  /// Properties
  public var color:UIColor = UIColor.red {
    didSet{
      let col = progress > 0.0 ? color.cgColor : UIColor.clear.cgColor
      progressCircle.strokeColor = col
      stopIcon.backgroundColor = col
    }
  }
  
  public var trackColor:UIColor = UIColor.gray {
    didSet{
      progressTrackCircle.strokeColor = trackColor.cgColor
    }
  }
  
  /// UI Components
  private lazy var progressCircle : CAShapeLayer = {
    let circle = CAShapeLayer ()
    circle.strokeColor = UIColor.clear.cgColor
    circle.fillColor = UIColor.clear.cgColor
    circle.lineWidth = lw
    circle.strokeStart = 0.0
    circle.strokeEnd = 0.0
    circle.backgroundColor = UIColor.systemTeal.cgColor
    return circle
  }()
  
  private lazy var progressTrackCircle : CAShapeLayer = {
    let circle = CAShapeLayer ()
    circle.strokeColor = trackColor.cgColor
    circle.fillColor = UIColor.clear.cgColor
    circle.lineWidth = lw
    circle.backgroundColor = UIColor.orange.cgColor
    return circle
  }()
  
  private lazy var stopIcon = CALayer ()
  
  private lazy var animation : CABasicAnimation = {
    let animation = CABasicAnimation(keyPath: "strokeEnd")
    animation.duration = 0.3
    animation.isAdditive = true
    animation.fillMode = CAMediaTimingFillMode.forwards
    animation.isRemovedOnCompletion = false
    return animation
  }()
  
  private lazy var waitingAnimation : CABasicAnimation = {
    let rotation : CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation")
    rotation.toValue = NSNumber(value: Double.pi * 2)
    rotation.duration = 1
    rotation.isCumulative = true
    rotation.repeatCount = Float.greatestFiniteMagnitude
    rotation.isRemovedOnCompletion = true
    return rotation
  }()
  
  
  fileprivate func updateComponents(){
    addSublayerIfNeeded()
    //stroke width
    let s = lw/2
    //Layout Circle
    let diam = self.bounds.height
    
    let rect = CGRect(origin: CGPoint(x: -diam/2+s, y: -diam/2+s),
                      size: CGSize(width: diam-lw, height: diam-lw))
    
    let path = UIBezierPath(roundedRect: rect, cornerRadius: diam/2).cgPath
    let pos = CGPoint(x: diam/2, y: diam/2)
    progressCircle.backgroundColor = UIColor.blue.withAlphaComponent(0.4).cgColor
    progressTrackCircle.path = path
    progressTrackCircle.position = pos
    progressCircle.path = path
    progressCircle.position = pos
    
    //Layout square in Circle
    let squareSize:CGFloat = self.bounds.height/5
    stopIcon.frame = CGRect(x: (diam - squareSize)/2,
                            y: (diam - squareSize)/2,
                            width: squareSize,
                            height: squareSize)
    stopIcon.backgroundColor = trackColor.cgColor
  }
  
  private func addSublayerIfNeeded(){
    if progressCircle.superlayer != nil { return }
    self.addSublayer(progressTrackCircle)
    self.addSublayer(progressCircle)
    self.addSublayer(stopIcon)
  }
}

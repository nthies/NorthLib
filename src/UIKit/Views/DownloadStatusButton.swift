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
    
    pin(label.left, to: self.left)
    pin(indicator.left, to: label.right, dist: 5.0)
    pin(indicator.right, to: self.right)
    
    indicator.centerY()
    label.centerY()
    
    indicator.pinSize(CGSize(width: indicatorHeight, height: indicatorHeight))
    
    indicator.addBorder(.green)
    label.addBorder(.blue)
    self.addBorder(.red)
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
      if let c = circleHeightConstraint { circleWrapper.removeConstraint(c)}
      guard let newValue = circleHeightRatio else { return }
      circleHeightConstraint
      = circleWrapper.pinHeight(to: self.height, factor: newValue)
    }
  }
  
  private var imageHeightConstraint: NSLayoutConstraint?
  public private(set) var imageHeightRatio:CGFloat? {
    didSet {
      if imageHeightRatio == oldValue { return }
      if circleWrapper.superview != self { return }
      if let c = imageHeightConstraint { imageWrapper.removeConstraint(c)}
      guard let newValue = imageHeightRatio else { return }
      imageHeightConstraint
      = imageWrapper.pinHeight(to: self.height, factor: newValue)
    }
  }
  
  private var circleYConstraint: NSLayoutConstraint?
  private var imageYConstraint: NSLayoutConstraint?

  public private(set) var circleOffsetY:CGFloat
  = 0.0 { didSet { circleYConstraint?.constant = circleOffsetY }}
  
  func updateImageAlignment(){
    var yOffset:CGFloat
    switch image {
      case cloudImage: yOffset = cloudImageOffsetY
      case checkmarkImage: yOffset = checkmarkImageOffsetY
      default: yOffset = imageOffsetY;
    }
    if imageYConstraint?.constant != yOffset {
      imageYConstraint?.constant = yOffset
    }
  }
  
  var imageOffsetY:CGFloat = 0.0
  var cloudImageOffsetY : CGFloat = 3.0
  var checkmarkImageOffsetY : CGFloat = 0.0

  private var cloudImage : UIImage? = UIImage(named: "download")
  private var checkmarkImage : UIImage? = UIImage(name: "checkmark")

  public var downloadState: DownloadStatusIndicatorState = .notStarted {
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
        //Center Label
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
  
  public var image : UIImage? { didSet{ updateImageAlignment() }   }
    
  public override func tintColorDidChange() {
    super.tintColorDidChange()
    self.circle.color = self.tintColor
  }
  
  public override func layoutSubviews() {
    super.layoutSubviews()
    circle.frame = CGRect(origin: .zero, size: circleWrapper.frame.size)
  }
  
  func setup() {
    self.addSubview(circleWrapper)
    self.addSubview(imageWrapper)
    
    imageWrapper.contentMode = .scaleAspectFit
    
    pin(circleWrapper.right, to: self.right)
    pin(imageWrapper.right, to: self.right)
    
    circleHeightRatio = 1.0
    imageHeightRatio = 1.0
        
    circleYConstraint = circleWrapper.centerY(dist: circleOffsetY)
    imageYConstraint = imageWrapper.centerY(dist: imageOffsetY)
    
    self.onTapping {[weak self] _ in
      self?.handleButtonPress()
    }
    
    circleWrapper.addBorder(.yellow)
    imageWrapper.addBorder(.orange)
    
    update()
  }
  
  public var startHandler : (()->())?
  public var stopHandler : (()->())?
  
  
  func handleButtonPress(){
    if downloadState == .notStarted, let handler = startHandler {
      downloadState = .process
      percent = 0.0
      handler()
    }
    else if downloadState == .process,
            percent < 1.0,
            let handler = stopHandler {
      downloadState = .notStarted
      percent = 0.0
      handler()
    }
  }
  
  var progress: Float {
    set { circle.progress = newValue }
    get { circle.progress }
  }
  
  var waiting: Bool {
    set { circle.waiting = newValue }
    get { circle.waiting }
  }
}

class ProgressCircle: CALayer {
  
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
          self.progressCircle.add(self.animation, forKey: "ani2")
          self.progressCircle.removeAnimation(forKey: "ani1")
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
    circle.lineWidth = 1.5
    circle.strokeStart = 0.0
    circle.strokeEnd = 0.0
    return circle
  }()
  
  private lazy var progressTrackCircle : CAShapeLayer = {
    let circle = CAShapeLayer ()
    circle.strokeColor = trackColor.cgColor
    circle.fillColor = UIColor.clear.cgColor
    circle.lineWidth = 1.5
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
    //Layout Circle
    let diam = self.bounds.height
    let rect = CGRect(origin: CGPoint(x: -diam/2, y: -diam/2), size: CGSize(width: diam, height: diam))
    let circlePath = UIBezierPath(roundedRect: rect, cornerRadius: diam/2)
    progressTrackCircle.path = circlePath.cgPath
    progressTrackCircle.position = CGPoint(x: diam/2, y: diam/2)
    progressCircle.path = circlePath.cgPath
    progressCircle.position = CGPoint(x: diam/2, y: diam/2)
    
    //Layout square in Circle
    let squareSize:CGFloat = self.bounds.height/5
    stopIcon.frame = CGRect(x: self.bounds.width - diam/2 - squareSize/2,
                            y: diam/2 - squareSize/2,
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

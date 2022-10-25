//
//  DownloadStatusButton.swift
//  Test App UIKit
//
//  Created by Ringo Müller on 17.03.21.
//

import Foundation
import UIKit

public enum DownloadStatusButtonState { case notStarted, process, justDone, done, waiting }

public class DownloadStatusButton : UIView {
  
  //The Circle a UIView with CALayer and Animation
  private var progressCircle = ProgressCircleWrapper()
  //the icon e.g. for a cloud or checkmark icon
  private var imageView = UIImageView()
  //the label for text to display
  public private(set) var label = UILabel()
  //wrapper for progress circle and image view, just one is displayed at a time
  public private(set) var statusWrapper = UIView()
  
  private let imageSize:CGSize = CGSize(width: 22, height: 22)
  private var cloudImageSize:CGSize = CGSize(width: 25, height: 25)
  private var checkmarkImageSize:CGSize = CGSize(width: 22, height: 22)
  
  private let circleSize:CGSize = CGSize(width: 22, height: 22)

  private let circleOffsetY:CGFloat = 0.0
  private let imageOffsetY:CGFloat = 0.0
  private var cloudImageOffsetY : CGFloat = 3.0
  private var checkmarkImageOffsetY : CGFloat = 0.0

  private var cloudImage : UIImage? = UIImage(named: "download")
  private var checkmarkImage : UIImage? = UIImage(name: "checkmark")

  private var imageOffsetConstraint: NSLayoutConstraint?
  private var imageSizeWConstraint: NSLayoutConstraint?
  private var imageSizeHConstraint: NSLayoutConstraint?

  public var downloadState: DownloadStatusButtonState = .notStarted {
    didSet{
      if oldValue == downloadState { return }
      switch downloadState {
        case .notStarted:
          percent = 0.0
        case .done:
          percent = 1.0
        default:
          break
      }
      self.update()
    }
  }
  
  public var percent:Float = 0.0 {
    didSet {
      if downloadState == .process, oldValue != percent {
        progressCircle.progress = percent
        if percent == 1.0 {
          downloadState = .justDone; update()
          onMainAfter(2.0) { [weak self] in
            self?.downloadState = .done
            self?.update()
          }
        }
      }
    }
  }
  
  public var image : UIImage? {
    didSet{
      if oldValue != image {
        imageView.image = image
        switch image {
          case cloudImage:
            imageOffsetConstraint?.constant = cloudImageOffsetY
            imageSizeWConstraint?.constant = cloudImageSize.width
            imageSizeHConstraint?.constant = cloudImageSize.height
          case checkmarkImage:
            imageOffsetConstraint?.constant = checkmarkImageOffsetY
            imageSizeWConstraint?.constant = checkmarkImageSize.width
            imageSizeHConstraint?.constant = checkmarkImageSize.height
          default:
            imageOffsetConstraint?.constant = imageOffsetY
            imageSizeWConstraint?.constant = imageSize.width
            imageSizeHConstraint?.constant = imageSize.height
        }
      }
    }
  }
  
  func update() {
    switch downloadState {
      case .notStarted:
        image = cloudImage
        progressCircle.isHidden = true
      case .process:
        image = nil
        progressCircle.isHidden = false
        //Center Label
      case .done:
        image = nil
        progressCircle.isHidden = true
      case .justDone:
        image = checkmarkImage
        progressCircle.isHidden = true
      case .waiting:
        image = nil
        progressCircle.isHidden = false
        progressCircle.waiting = true
    }
  }
  
  public override func tintColorDidChange() {
    super.tintColorDidChange()
    self.progressCircle.tintColor = self.tintColor
  }
  
  public override func layoutSubviews() {
    super.layoutSubviews()
    progressCircle.frame = CGRect(origin: .zero, size: statusWrapper.frame.size)
  }

  
  func setup() {
    statusWrapper.addSubview(progressCircle)
    progressCircle.centerY(dist: circleOffsetY)
    progressCircle.pinSize(circleSize)
    pin(progressCircle.right, to: statusWrapper.right, dist: 0.0)
    
    statusWrapper.addSubview(imageView)
    imageOffsetConstraint
    = imageView.centerY(dist: imageOffsetY)
    let imageSizeConstraints = imageView.pinSize(imageSize)
    imageSizeWConstraint
    = imageSizeConstraints.width
    imageSizeHConstraint
    = imageSizeConstraints.height
    pin(imageView.right, to: statusWrapper.right, dist: 0.0)
    imageView.contentMode = .scaleAspectFit
    
    self.addSubview(statusWrapper)
    pin(statusWrapper.right, to: self.right, dist: 0.0)
    pin(statusWrapper.top, to: self.top, dist: 0.0)
    pin(statusWrapper.bottom, to: self.bottom, dist: 0.0)
    statusWrapper.pinAspect(ratio: 1.0)

    self.addSubview(label)
    label.centerY()
    pin(label.left, to: self.left, dist: 0.0)
    
    pin(label.right, to: statusWrapper.left, dist: -5.0)

    
    statusWrapper.addBorder(.red)
    imageView.addBorder(.blue)
    progressCircle.addBorder(.green)
    self.addBorder(.yellow)
    label.addBorder(.systemPink)
    
    update()
    
    self.onTapping {[weak self] _ in
      self?.handleButtonPress()
    }
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
  
  override public init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }
}

class ProgressCircleWrapper: UIView {
  
  private var circle = ProgressCircle()
  
  var progress: Float {
    set { circle.progress = newValue }
    get { circle.progress }
  }
  
  var waiting: Bool {
    set { circle.waiting = newValue }
    get { circle.waiting }
  }
  
  public override func tintColorDidChange() {
    super.tintColorDidChange()
    self.circle.color = self.tintColor
  }

  
  override func layoutSubviews() {
    super.layoutSubviews()
    if circle.frame.size != self.frame.size {
      circle.frame = CGRect(origin: .zero, size: self.frame.size)
      circle.updateComponents()
    }
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

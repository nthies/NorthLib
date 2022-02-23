//
//  DownloadStatusButton.swift
//  Test App UIKit
//
//  Created by Ringo Müller on 17.03.21.
//

import Foundation
import UIKit

public enum DownloadStatusButtonState { case notStarted, process, justDone, done, waiting }

public class DownloadStatusButton : UIButton {
  private var lastBounds:CGRect?
  
  private var customImageView = UIImageView()
  
  private lazy var progressCircle = ProgressCircle()
  
  private let iconPadding:CGFloat = 3.0
  private let verticalPadding:CGFloat = 6.0

  public var startHandler : (()->())?
  public var stopHandler : (()->())?
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
//            self?.startHandler = nil
//            self?.stopHandler = nil HAVE NO STOP DOWNLOAD OPTION YET!
            self?.update()
          }
        }
      }
    }
  }
  
  public var cloudImage : UIImage? = UIImage(named: "download")
  public var checkmarkImage : UIImage? = UIImage(name: "checkmark")
  
  public var buttonImage : UIImage? {
    didSet{
      if oldValue != buttonImage {
        customImageView.image = buttonImage
      }
    }
  }
  
  func update() {
    let offset = progressCircle.bounds.width + 2*iconPadding
    switch downloadState {
      case .notStarted:
        buttonImage = cloudImage
        progressCircle.isHidden = true
        self.titleEdgeInsets = UIEdgeInsets(top: 0, left: offset,
                                            bottom: 0, right: 0)
      case .process:
        buttonImage = nil
        progressCircle.isHidden = false
        self.titleEdgeInsets = UIEdgeInsets(top: 0, left: offset,
                                            bottom: 0, right: offset)
        //Center Label
      case .done:
        buttonImage = nil
        progressCircle.isHidden = true
        self.titleEdgeInsets = .zero
      case .justDone:
        buttonImage = checkmarkImage
        progressCircle.isHidden = true
        self.titleEdgeInsets = .zero
      case .waiting:
        buttonImage = nil
        progressCircle.isHidden = false
        progressCircle.waiting = true
        self.titleEdgeInsets = UIEdgeInsets(top: 0, left: offset,
                                            bottom: 0, right: offset)
    }
    self.titleLabel?.setNeedsUpdateConstraints()
    self.titleLabel?.updateConstraintsIfNeeded()
  }
  
  public override func tintColorDidChange() {
    super.tintColorDidChange()
    self.progressCircle.color = self.tintColor
  }
  
  public override func willMove(toSuperview newSuperview: UIView?) {
    if newSuperview != nil { setup(); update() }
    super.willMove(toSuperview: newSuperview)
  }

  
  func setup() {
    self.addTarget(self,
                   action: #selector(self.handleButtonPress),
                   for: .touchUpInside)
    self.layer.addSublayer(progressCircle)
    self.addSubview(customImageView)
    customImageView.centerY()
    customImageView.pinWidth(23.8)
    customImageView.contentMode = .scaleAspectFit
    pin(customImageView.right, to: self.right)
  }

  @objc func handleButtonPress(){
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
      
  private func updateBoundsIfNeeded(){
    if lastBounds == self.bounds { return }
    lastBounds = self.bounds
    
    let diam = self.bounds.height - 2*verticalPadding
    let offsetRight = self.bounds.width - diam - iconPadding
    progressCircle.frame =  CGRect(x: offsetRight,
                                   y: verticalPadding,
                                   width: diam,
                                   height: diam)
  }
  
  public override func layoutSubviews() {
    updateBoundsIfNeeded()
    super.layoutSubviews()
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
  
  
  override var frame: CGRect {
    didSet {
      updateComponentsIfNeeded()
    }
  }
  
  private var lastBounds:CGRect?
  
  private func updateComponentsIfNeeded(){
    if lastBounds == self.bounds { return }
    addSublayerIfNeeded()
    lastBounds = self.bounds
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

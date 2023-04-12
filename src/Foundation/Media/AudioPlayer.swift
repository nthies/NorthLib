//
//  AudioPlayer.swift
//
//  Created by Norbert Thies on 10.05.19.
//  Copyright © 2019 Norbert Thies. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

/// UIImage extension to resize an image:
extension UIImage {
  func resize(to size: CGSize) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: size)
    let image = renderer.image { _ in
      self.draw(in: CGRect.init(origin: CGPoint.zero, size: size))
    }
    return image.withRenderingMode(self.renderingMode)
  }
}

/// A very simple audio player utilizing AVPlayer
open class AudioPlayer: NSObject, DoesLog {
  
  private var _file: String? = nil
  
  /// file or String url to play
  public var file: String? {
    get { return _file }
    set {
      if newValue != _file { close() }
      _file = newValue
    }
  }
  
  /// Title of the track being played
  public var title = ""
  
  /// Name of the album being played
  public var album = ""
  
  /// Artist of the track being played
  public var artist = ""
  
  // The resized image for the lock screen player UI
  private var resizedImage: UIImage?
  
  /// The image to display while playing
  public var image: UIImage? { didSet { resizedImage = nil } }
  
  /// current playback position
  public var currentTime: CMTime {
    get { return player?.currentTime() ?? CMTime(seconds: 0, preferredTimescale: 0) }
    set { player?.seek(to: newValue) }
  }
  
  // the player
  private var player: AVPlayer? = nil
  
  // The timer updating the playing info
  private var timer: Timer?
  
  // Are we playing a stream?
  private var isStream = false
  
  // Should we be playing
  private var wasPlaying = false
      
  /// returns true if the player is currently playing
  public var isPlaying: Bool { return (player?.rate ?? 0.0) > 0.001 }
  
  /// closure to call in case of error
  public func onError(closure:  ((String,Error)->())?) { _onError = closure }
  private var _onError: ((String,Error)->())?
  
  /// closure to call when playing has ended
  public func onEnd(closure: ((Error?)->())?) { _onEnd = closure }
  private var _onEnd: ((Error?)->())?
  
  // the observation object (in case of errors)
  private var observation: NSKeyValueObservation?
    
  private func open() {
    guard player == nil else { return }
    guard let file = self.file else { return }
    openRemoteCommands()
    var url = URL(string: file)
    if url == nil {
      url = URL(fileURLWithPath: file)
      isStream = false
    }
    else { isStream = true }
    let item = AVPlayerItem(url: url!)
    observation = item.observe(\.status) { [weak self] (item, change) in
      if item.status == .failed {
        if let closure = self?._onError { closure(item.error!.localizedDescription, item.error!) }
        else { self?.error(item.error!.localizedDescription) }
        self?.close()
      }
      else if item.status == .readyToPlay {}
    }
    self.player = AVPlayer(playerItem: item)
    if #available(iOS 15.0, *) {
      self.player?.audiovisualBackgroundPlaybackPolicy = .continuesIfPossible
    } 
    updatePlayingInfo()
    NotificationCenter.default.addObserver(self, selector: #selector(playerHasFinished),
      name: .AVPlayerItemDidPlayToEndTime, object: item)
    NotificationCenter.default.addObserver(self, selector:
      #selector(playerHasFinishedWithError(notification:)),
      name: .AVPlayerItemFailedToPlayToEndTime, object: item)
   NotificationCenter.default.addObserver(self, selector: #selector(playerIsInterrupted),
      name: AVAudioSession.interruptionNotification, object: nil)
    timer = every(seconds: 1) { [weak self] _ in self?.updatePlayingInfo() }
  }
  
  // player has finished playing medium
  @objc private func playerHasFinished() {
    _onEnd?(nil)
    close()
  }
  
  // player has finished with error
  @objc private func playerHasFinishedWithError(notification: Notification) {
    let err = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey]
    if let err = err as? Error { _onEnd?(err) }
    else { _onEnd?(error("Player couldn't finish successfully")) }
    close()
  }
  
  // player is beeing interrupted
  @objc private func playerIsInterrupted(notification: Notification) {
    guard let userInfo = notification.userInfo,
          let typeInt = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
          let type = AVAudioSession.InterruptionType(rawValue: typeInt) 
    else { return }
    switch type {
      case .began:
        print("Interrupt received")
        if isPlaying {
          stop()
          wasPlaying = true
        }
      case .ended:
        if let optionInt = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
          let options = AVAudioSession.InterruptionOptions(rawValue: optionInt)
          if options.contains(.shouldResume) {
            print("Resume after interrupt")
            if wasPlaying { play() }
          }
        }
      default: print("unknown AV interrupt notification")
    }
  }
  
  // defines playing info on lock/status screen
  private func updatePlayingInfo() {
    if let player = self.player {
      var info = [String:Any]()
      if let image = image {
        info[MPMediaItemPropertyArtwork] =
        MPMediaItemArtwork(boundsSize: image.size) { [weak self] s in 
          guard let self = self else { return UIImage() }
          if self.resizedImage == nil {
            self.resizedImage = image.resize(to: s) 
            if self.resizedImage == nil {
              self.error("Can't resize image from \(image.size) to \(s)")
            }
          }
          return self.resizedImage ?? UIImage()
        }
      }
      info[MPMediaItemPropertyTitle] = title
      info[MPMediaItemPropertyAlbumTitle] = album
      info[MPMediaItemPropertyArtist] = artist
      info[MPNowPlayingInfoPropertyIsLiveStream] = false
      info[MPMediaItemPropertyPlaybackDuration] = player.currentItem!.asset.duration.seconds
      info[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
      info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentItem!.currentTime().seconds
      MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    else {
      MPNowPlayingInfoCenter.default().nowPlayingInfo = nil      
    }
  }
  
  /// play plays the currently defined audio file
  public func play() {
    open()
    guard let player = self.player else { return }
    wasPlaying = true
    player.play()
  }
  
  /// stop stops the current playback (pauses it)
  public func stop() {
    guard let player = self.player else { return }
    wasPlaying = false
    player.pause()  
  }
  
  /// toggle either (re-)starts or stops the current playback
  public func toggle() {
    if self.player != nil {
      if isPlaying { self.stop(); return }
    }
    self.play()
  }
  
  /// close stops the player (if playing) and deactivates the audio session
  public func close() {
    do {
      timer?.invalidate()
      timer = nil
      closeRemoteCommands()
      self.stop()
      self.player = nil
      updatePlayingInfo()
      NotificationCenter.default.removeObserver(self)
      try AVAudioSession.sharedInstance().setActive(false)
    }
    catch let err {
      error(err)
    }      
  }

  // remote commands
  private var playCommand: Any?
  private var pauseCommand: Any?
  private var seekCommand: Any?
  
  // enable remote commands
  private func openRemoteCommands() {
    let commandCenter = MPRemoteCommandCenter.shared()
    // Add handler for Play Command
    playCommand = commandCenter.playCommand.addTarget { [unowned self] event in
      self.play()
      self.updatePlayingInfo()
      return .success
    }    
    // Add handler for Pause Command
    pauseCommand = commandCenter.pauseCommand.addTarget { [unowned self] event in
      self.stop()
      self.updatePlayingInfo()
      return .success
    }
    // Add handler for Seek Command
    seekCommand = commandCenter.changePlaybackPositionCommand.addTarget { [unowned self] event in
      let pos = (event as! MPChangePlaybackPositionCommandEvent).positionTime
      self.currentTime = CMTime(seconds: pos, preferredTimescale: 600)
      return .success
    }
  }
  
  // disable remote commands
  private func closeRemoteCommands() {
    let commandCenter = MPRemoteCommandCenter.shared()
    commandCenter.playCommand.removeTarget(playCommand)
    commandCenter.pauseCommand.removeTarget(pauseCommand)
    commandCenter.changePlaybackPositionCommand.removeTarget(seekCommand)
  } 
  
  public override init() {
    do {
      super.init()
      try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
//      try AVAudioSession.sharedInstance().setActive(true) //Stops Background Audio Playback e.g. from Apple Music on enter Issue
    }
    catch let err {
      error(err)
      close()
    }
  }
  
}  // AudioPlayer

//
//  AudioPlayer.swift
//
//  Created by Norbert Thies on 10.05.19.
//  Copyright © 2019 Norbert Thies. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

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
  
  /// title is the title of the track being played
  public var title = ""
  
  /// album is the name of the album being played
  public var album = ""
  
  /// current playback position
  public var currentTime: CMTime {
    get { return player?.currentTime() ?? CMTime(seconds: 0, preferredTimescale: 0) }
    set { player?.seek(to: newValue) }
  }
  
  // the player
  private var player: AVPlayer? = nil
  
  // Are we playing a stream?
  private var isStream = false
  
  // Should we be playing
  private var wasPlaying = false
      
  /// returns true if the player is currently playing
  public var isPlaying: Bool { return (player?.rate ?? 0.0) > 0.001 }
  
  /// closure to call in case of error
  public func onError(_ closure:  @escaping (String,Error)->()) { _onError = closure }
  private var _onError: ((String,Error)->())?
  
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
    updatePlayingInfo()
    NotificationCenter.default.addObserver(self, selector: #selector(playerHasFinished),
                                           name: .AVPlayerItemDidPlayToEndTime, object: item)
    NotificationCenter.default.addObserver(self, selector: #selector(playerIsInterrupted),
                                           name: AVAudioSession.interruptionNotification, object: nil)
  }
    
  // player has finished playing medium
  @objc private func playerHasFinished() {
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
      info[MPMediaItemPropertyTitle] = title
      info[MPMediaItemPropertyAlbumTitle] = album
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
      try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default,
            options: [.mixWithOthers, .allowAirPlay])
      try AVAudioSession.sharedInstance().setActive(true)
    }
    catch let err {
      error(err)
      close()
    }
  }
  
}  // AudioPlayer

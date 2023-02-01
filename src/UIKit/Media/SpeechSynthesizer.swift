//
//  SpeechSynthesizer.swift
//  NorthLib
//
//  Created by Ringo Müller on 08.02.21.
//  Copyright © 2021 Norbert Thies. All rights reserved.
//
import Foundation
import AVFoundation
import MediaPlayer
import WebKit

public typealias SpeechData = (text: String, albumTitle:String, trackTitle:String)


/// TTS (Test to Speech) Helper Class, Singleton for enqueue multiple Text
public class SpeechSynthesizer : AVSpeechSynthesizer {
  ///all next enqueued Articles and more
  var nextArticles : [[SpeechData]] = []
  /// current Articles Paragraphes
  var currentArticleItems : [SpeechData] = []
  var nextIndex : Int = 0
  var lastArticleItems : [SpeechData] = []
  var speechUtteranceRate:Float = 0.50 //default:0.5 min:0.0 max: 1.0
  
  var canSpeakNext : Bool = true
  var partStarted:Date = Date()
  
  public static let sharedInstance = SpeechSynthesizer()
  #warning("Use the right Lang!")
  private var germanVoice = AVSpeechSynthesisVoice(language: "de-DE")
  fileprivate var finishedClosure:(()->())?
  private var lastSpeechUtterance:AVSpeechUtterance?
  private let commandCenter = MPRemoteCommandCenter.shared()
  var nowPlayingInfo: [String: AnyObject] = [ : ]
  
  var hasNext : Bool {
    get {
      if nextArticles.count > 0 { return true }
      if nextIndex < currentArticleItems.count { return true }
      return false
    }
  }
  
  var hasPrevious : Bool {
    get {
      if lastArticleItems.count > 0 { return true }
      if nextIndex > 0  { return true }
      return false
    }
  }
  
  private override init(){
    super.init()
    self.delegate = self
    setupVoice()
    setupAVAudioSession()
    setupNowPlayingInfo()
    setupCommandCenter()
  }
  
  /// enqueue text for tts
  /// - Parameters:
  ///   - albumTitle: albumTitle for been displayed in MediaPlayer
  ///   - trackTitle: trackTitle  for been displayed in MediaPlayer
  ///   - attributedString:text for tts
  static func speak(albumTitle:String,trackTitle:String, _ attributedString:NSAttributedString){
    let textParagraphs = attributedString.string.components(separatedBy: "\n")
    var parts : [SpeechData] = []
    
    for pieceOfText in textParagraphs {
      parts.append((text: pieceOfText,
                          albumTitle:albumTitle,
                    trackTitle:trackTitle))
    }
    
    sharedInstance.nextArticles.append(parts)
    
    if sharedInstance.nextArticles.count == 1 {
      sharedInstance.speakNext()
    }
  }
  
  //Update MediaPlayer Title, Track, Artist Artwork/Image
  /// @see: https://developer.apple.com/documentation/mediaplayer/mpmediaquery
  /// @more for album artwork: https://stackoverflow.com/questions/58435382/how-to-show-mpmediaitem-artwork-in-a-swiftui-list
  func updatePlayInfo(_ itm : SpeechData){
    nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = itm.albumTitle as AnyObject
    nowPlayingInfo[MPMediaItemPropertyTitle] = itm.trackTitle as AnyObject
    
    //25 Buchstaben / 5s == 5Buchst/s bei 0.5
    /// expected duration: 108 for: 24      expected duration: 90 for: 19      expected duration: 78 for: 16
    /*** GUESS DURATION ***/
    let germanLetterSpeedBase:Float = 7.5/speechUtteranceRate
    let duration = max(Int(Float(itm.text.count)/germanLetterSpeedBase), 2)
    //    print("expected duration: \(duration) for:\n \(itm.text)")
    
    nowPlayingInfo[MPMediaItemPropertyAlbumTrackCount] = "\(currentArticleItems.count)" as AnyObject
    nowPlayingInfo[MPMediaItemPropertyAlbumTrackNumber] = "\(nextIndex-1)" as AnyObject
    
    nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = "\(duration)" as AnyObject
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
  }
  
  func speakDataItem(_ itm:SpeechData){
    canSpeakNext = false
    self.stopSpeaking(at: .immediate)
    
    let speechUtterance = AVSpeechUtterance(string: itm.text)
    speechUtterance.voice = germanVoice
    speechUtterance.postUtteranceDelay = 0.015
    speechUtterance.rate = speechUtteranceRate
    updatePlayInfo(itm)
    updateCommandCenter()
    partStarted = Date()
    DispatchQueue.global(qos: .background).async { [weak self] in
      self?.speak(speechUtterance)//enqueue
    }
  }
  
  func speakNext(){
    if canSpeakNext == false { return }
    if let next = currentArticleItems.valueAt(nextIndex) {
      nextIndex += 1
      speakDataItem(next)
    }
    else if let nextArticle = nextArticles.pop() {
      nextIndex = 0
      currentArticleItems = nextArticle
      speakNext()
    }
    else {
      finishedClosure?()
      commandCenter.playCommand.isEnabled = false
      commandCenter.pauseCommand.isEnabled = false
    }
  }
  
  func nextTrackCommand(){
    speakNext()
  }
  
  func previousTrackCommand(){
    if -partStarted.timeIntervalSinceNow < 2 {
      ///speak previous
      nextIndex = max(0, nextIndex-2)
    }
    else {
      ///restart current, prevent negative Index
      nextIndex = max(0, nextIndex-1)
    }
    speakNext()
  }
  
  func setupNowPlayingInfo(){
    nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "taz" as AnyObject
    nowPlayingInfo[MPMediaItemPropertyTitle] = "Artikel" as AnyObject
    
    let artwork = MPMediaItemArtwork(boundsSize: CGSize(width: 1024, height: 1024)) { size -> UIImage in
      if let img = UIImage(named: "StartupLogo") {
        guard let cgi = img.cgImage else { return img }
        let scale = size.width/1024
        return UIImage(cgImage: cgi, scale: scale, orientation: img.imageOrientation)
      }
      print("Image not found! PS: Requested size: \(size)")
      return UIImage()
    }
    nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
  }
  
  
  func setupVoice(){
    if let name = germanVoice?.name, name.contains("(Erweitert)"){
      Toast.show("Benutze \(name) zur TTS Sprachausgabe.")
      return
    }
    
    for voice in AVSpeechSynthesisVoice.speechVoices() {
      if voice.language != "de-DE" {
        //print("Skip: \(voice.language)")
        continue
      }
      
      if voice.name.contains("(Erweitert)"){
        return
      }
      
      if voice.name.contains("(Erweitert)"){
        Toast.show("Benutze \(voice.name) zur TTS Sprachausgabe.")
        germanVoice = voice
        return
      }
    }
    Toast.show("Benutze \(germanVoice?.name ?? "") zur TTS Sprachausgabe.", .alert)
  }
  
  func setupAVAudioSession(){
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback)
      try AVAudioSession.sharedInstance().setMode(.spokenAudio)
    }
    catch let error as NSError {
      print("Error: Could not set audio category: \(error), \(error.userInfo)")
    }
    
    do {
      try AVAudioSession.sharedInstance().setActive(true)
    }
    catch let error as NSError {
      print("Error: Could not setActive to true: \(error), \(error.userInfo)")
    }
  }
  
  func updateCommandCenter(){
    commandCenter.nextTrackCommand.isEnabled = hasNext
    commandCenter.previousTrackCommand.isEnabled = hasPrevious
    commandCenter.playCommand.isEnabled = true
    commandCenter.pauseCommand.isEnabled = true
  }
  
  func setupCommandCenter(){
    commandCenter.nextTrackCommand.addTarget { [weak self] _ in
      self?.nextTrackCommand(); return .success
    }
    
    commandCenter.previousTrackCommand.addTarget { [weak self] _ in
      self?.previousTrackCommand(); return .success
    }
    
    commandCenter.pauseCommand.addTarget { _ in
      self.pauseSpeaking(at: .word)
      print("pauseCommand"); return .success;
    }
    commandCenter.playCommand.addTarget { _ in
      self.continueSpeaking()
      print("playCommand"); return .success;
    }
    ///Not seen
    //    commandCenter.stopCommand.addTarget { _ in
    //      print("stopCommand"); return .success;
    //    }
    ///Not seen
    //    commandCenter.togglePlayPauseCommand.addTarget { _ in
    //      print("togglePlayPauseCommand"); return .success;
    //    }
    //Replaces Next/Prev with +10s or -10s
    //    commandCenter.skipForwardCommand.addTarget { _ in
    //      print("skipForwardCommand"); return .success;
    //    }
    //    commandCenter.skipBackwardCommand.addTarget { _ in
    //      print("skipBackwardCommand"); return .success;
    //    }
  }
  
}


extension SpeechSynthesizer : AVSpeechSynthesizerDelegate{
  public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    speakNext()
  }
  
  public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
    canSpeakNext = true
  }
}

/// WKWebView extension to TTS Full Web Content
extension WKWebView {
  public func speakHtmlContent(albumTitle:String,trackTitle:String, _ finishedClosure:@escaping (()->())) {
    self.evaluateJavaScript("document.body.innerHTML.toString()",
                            completionHandler: { (html: Any?, error: Error?) in
                              if let htmlString = html as? String,
                                 let attrString = htmlString.htmlAttributed{
                                SpeechSynthesizer.speak(albumTitle:albumTitle,
                                                        trackTitle:trackTitle,
                                                        attrString)
                              }
                              else {
                                SpeechSynthesizer.speak(albumTitle:albumTitle,
                                                        trackTitle:trackTitle,
                                                        NSAttributedString(string: "kein Inhalt gefunden"))
                              }
                              //may need an array of finished closures
                              SpeechSynthesizer.sharedInstance.finishedClosure = finishedClosure
                            })
  }
}

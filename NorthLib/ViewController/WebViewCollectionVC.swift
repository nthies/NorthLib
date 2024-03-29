//
//  WebViewCollectionVC.swift
//
//  Created by Norbert Thies on 06.08.18.
//  Copyright © 2018 Norbert Thies. All rights reserved.
//

import UIKit
import WebKit

/// An URL with a waiting view that is to display if the URL is not yet available
public protocol WebViewUrl {
  var url: URL { get }
  var isAvailable: Bool { get }
  var whenAvailable: Callback<Void>.Store { get }
  func waitingView() -> UIView?
}

/// An optional WebView using a "waiting view" as long as the web contents is not available
class OptionalWebView: OptionalView, DoesLog {
    
  var url: WebViewUrl { didSet { urlChanged() } }
  var webView: WebView?
  var mainView: UIView? { return webView }
  var waitingView: UIView? { url.waitingView() }
  var baseDir: String?

  @SingleCallback
  public var whenAvailable: Callback<Void>.Store
  
  var isAvailable = false
  var willBeAvailable: Bool { url.isAvailable }
  func loadView() {
    if url.isAvailable { webView?.load(url: url.url) }
  }
  
  fileprivate func urlChanged() {
    isAvailable = false
    if let webView = self.webView { webView.stopLoading() }
    else { createWebView() }
    if url.isAvailable { loadView() }
    else {
      url.whenAvailable { [weak self] in self?.loadView() }
    }
  }
  
  fileprivate func createWebView() {
    self.webView = WebView(frame: .zero)
    guard let webView = self.webView else { return }
    webView.isOpaque = false
    webView.backgroundColor = UIColor.clear
    webView.scrollView.backgroundColor = UIColor.clear
    webView.allowsBackForwardNavigationGestures = false
    webView.scrollView.isDirectionalLockEnabled = true
    webView.scrollView.showsHorizontalScrollIndicator = false
    webView.minScrollRatio = 0.01
    webView.baseDir = baseDir
    webView.whenLoaded { [weak self] _ in
      self?.isAvailable = true
      self?.$whenAvailable.notify(sender: self)
    }
  }

  init(url: WebViewUrl, baseDir: String?) {
    self.url = url
    self.baseDir = baseDir
    urlChanged()
  }
      
} // OptionalWebView

/// A very simple file based WebViewUrl
public struct FileUrl: WebViewUrl {
  public var url: URL
  public var path: String { url.path }
  public var isAvailable: Bool { File(path).exists }
  public var whenAvailable: Callback<Void>.Store { {_ in} }
  public func waitingView() -> UIView? { nil }
  public init(path: String) { self.url = URL(fileURLWithPath: path) }
}

/// A WebViewCollectionVC manages a hoizontal collection of web views
open class WebViewCollectionVC: PageCollectionVC {
    
  /// The list of URLs to display in WebViews
  public var urls: [WebViewUrl] = []
  public var baseDir: String?
  public var current: WebViewUrl? { 
    if let i = index { return urls[i] }
    else { return nil }
  }
  fileprivate var initialUrl: URL?
  
  /// The bridge (if any) to use for JS interaction
  public var bridge: JSBridgeObject?
  /// Set to true if JS logging should be bridged
  public var isBridgeLogging = false
  
  public var currentWebView: WebView? { return currentView?.activeView as? WebView }
  public var indicatorStyle:  UIScrollView.IndicatorStyle = .default

  // The closures to call when loading is completed
  @Callback
  public var whenLoaded: Callback<Void>.Store

  // The closures to call when a link is pressed
  @Callback<(URL?,URL?)>
  public var whenLinkPressed: Callback<(URL?,URL?)>.Store
  
  // The closures to call when the webview has been scrolled more than 5%
  @Callback<CGFloat>
  public var whenScrolled: Callback<CGFloat>.Store
  
  // End of content closures
  @Callback<Bool>
  public var atEndOfContent: Callback<Bool>.Store
  
  /// reload contents of current WebView
  open func reload() {
    if let wv = currentWebView { wv.reload() }
  }
    
  public func displayUrls(urls: [WebViewUrl]? = nil) {
    if let urls = urls { self.urls = urls }
    self.count = self.urls.count
    if let iurl = initialUrl {
      initialUrl = nil
      gotoUrl(url: iurl)
    }
  }
  
  public func gotoUrl(url: URL) {
    if urls.count == 0 { self.initialUrl = url; return }
    var idx = 0
    debug("searching for: \(url.lastPathComponent)")
    for u in urls {
      if u.url == url { 
        self.index = idx 
        debug("found at index: \(idx)")
        return 
      }
      idx += 1
    }
    debug("not found")
  }
  
  public func gotoUrl(_ url: String) {
    let url = URL(fileURLWithPath: url)
    gotoUrl(url: url)
  }
  
  public func gotoUrl(path: String, file: String) { 
    gotoUrl(path + "/" + file)
  }
  
  var optionalWebViews:[OptionalWebView] = []
  
  open func reloadAllWebViews(){
    optionalWebViews.forEach{
      $0.webView?.reload()
      $0.webView?.scrollView.indicatorStyle = indicatorStyle
    }
  }
  
  open override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = UIColor.white
    inset = 0
    viewProvider { [weak self] (index, oview) in
      guard let self = self else { return UIView() }
      if let ov = oview as? OptionalWebView {
        ov.webView?.scrollView.indicatorStyle = self.indicatorStyle
        ov.url = self.urls[index]
        return ov
      }
      else { 
        let owv = OptionalWebView(url: self.urls[index], baseDir: self.baseDir)
        self.initWebView(oView: owv)
        self.optionalWebViews.append(owv)
        if let bridge = self.bridge {
          owv.webView?.addBridge(bridge)
          owv.webView?.scrollView.indicatorStyle = self.indicatorStyle
          if self.isBridgeLogging { owv.webView?.log2bridge(bridge) }
        }
        return owv
      }
    }
  }
  
  func initWebView(oView: OptionalWebView) {
    guard let webView = oView.webView else { return }
    webView.whenLoadError { [weak self] err in
      guard let self = self else { return }
      self.error("WebView Load Error on \"\(webView.originalUrl?.lastPathComponent ?? "[undefined URL]")\":\n  \(err.description)")
    }
    webView.whenLinkPressed { [weak self] arg in
      self?.$whenLinkPressed.notify(sender: self, content: arg)
      self?.onPageChange()
    }
    webView.whenLoaded { [weak self] _ in
      self?.$whenLoaded.notify(sender: self)
    }
    webView.whenScrolled { [weak self] ratio in
      self?.$whenScrolled.notify(sender: self, content: ratio)
    }
    if $atEndOfContent.count > 0 {
      webView.atEndOfContent { [weak self] isAtEnd in
        self?.$atEndOfContent.notify(sender: self, content: isAtEnd)
      }
    }
  }
    
  ///Overrideable
  open func onPageChange(){}
  
}

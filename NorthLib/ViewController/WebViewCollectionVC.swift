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
  func whenAvailable(closure: @escaping ()->())
  func waitingView() -> UIView?
}

/// An optional WebView using a "waiting view" as long as the web contents is not available
struct OptionalWebView: OptionalView, DoesLog {
  
  var url: WebViewUrl
  var webView: WebView?
  var waitingView: UIView?
  
  var isAvailable: Bool { return url.isAvailable }
  func whenAvailable(closure: @escaping () -> ()) { url.whenAvailable(closure: closure) }
  var mainView: UIView? { return webView }
  func loadView() { if isAvailable { webView?.load(url: url.url) } }
  
  fileprivate mutating func createWebView(vc: WebViewCollectionVC) {
    self.webView = WebView(frame: .zero)
    guard let webView = self.webView else { return }
    webView.isOpaque = false
    webView.backgroundColor = UIColor.clear
    webView.scrollView.backgroundColor = UIColor.clear
    vc.addWebViewClosures(webView: webView)
    webView.allowsBackForwardNavigationGestures = false
    webView.scrollView.isDirectionalLockEnabled = true
    webView.scrollView.showsHorizontalScrollIndicator = false
    webView.baseDir = vc.baseDir
    webView.minScrollRatio = 0.01
    webView.whenScrolled { [weak vc] ratio in vc?.didScroll(ratio: ratio) }
    if let closure = vc.atEndOfContentClosure {
      webView.atEndOfContent { isAtEnd in closure(isAtEnd) }
    }
  }

  init(vc: WebViewCollectionVC, url: WebViewUrl) {
    self.url = url
    self.waitingView = url.waitingView()
    createWebView(vc: vc)
  }
  
  @discardableResult
  mutating func update(vc: WebViewCollectionVC, url: WebViewUrl) -> OptionalWebView {
    debug("updating WebView")
    self.url = url
    self.waitingView = url.waitingView()
    webView?.stopLoading()
//    createWebView(vc: vc)
    return self
  }
    
} // OptionalWebView

/// A very simple file based WebViewUrl
public struct FileUrl: WebViewUrl {
  public var url: URL
  public var path: String { return url.path }
  public var isAvailable: Bool { return File(path).exists }
  public func whenAvailable(closure: ()->()) {}
  public func waitingView() -> UIView? { return nil }
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

  // The closure to call when loading completed
  private var _whenLoaded: (()->())?
  
  /// Define closure to call when content is loaded
  public func whenLoaded(_ closure: @escaping ()->()) {
    _whenLoaded = closure
  }

  // The closure to call when link is pressed
  private var _whenLinkPressed: ((URL?,URL?)->())?
  
  /// Define closure to call when link is pressed
  public func whenLinkPressed( _ closure: @escaping (URL?,URL?)->() ) {
    _whenLinkPressed = closure
  }
  
  // The closure to call when the webview has been scrolled more than 5%
  private var _whenScrolled: ((CGFloat)->())?
  
  /// Define closure to call when more than 5% has b een scrolled
  public func whenScrolled(_ closure: ((CGFloat)->())?) {
    _whenScrolled = closure
  }
  
  // End of content closure
  var atEndOfContentClosure: ((Bool)->())?

  /// Define closure to call when the end of the web content will become 
  /// visible
  public func atEndOfContent(closure: @escaping (Bool)->()) {
    atEndOfContentClosure = closure
  }
  
  /// reload contents of current WebView
  open func reload() {
    if let wv = currentWebView { wv.reload() }
  }
  
  /// Scroll of WebView detected
  public func didScroll(ratio: CGFloat) { 
    guard let closure = _whenScrolled else { return }
    closure(ratio)
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
//    print("Reloading #\(optionalWebViews.count) Webviews")
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
      guard let this = self else { return UIView() }
      if var ov = oview as? OptionalWebView {
        ov.webView?.scrollView.indicatorStyle = self?.indicatorStyle ?? .default
        return ov.update(vc: this, url: this.urls[index])
      }
      else { 
        let owv = OptionalWebView(vc: this, url: this.urls[index]) 
        self?.optionalWebViews.append(owv)
        if let bridge = this.bridge { 
          owv.webView?.addBridge(bridge)
          owv.webView?.scrollView.indicatorStyle = self?.indicatorStyle ?? .default
          if this.isBridgeLogging { owv.webView?.log2bridge(bridge) }
        }
        return owv
      }
    }
  }
  
  public func addWebViewClosures(webView: WebView) {
    webView.whenLoadError { [weak self] err in
      guard let self = self else { return }
      self.error("WebView Load Error on \"\(webView.originalUrl?.lastPathComponent ?? "[undefined URL]")\":\n  \(err.description)")
    }
    webView.whenLinkPressed { [weak self] arg in
      guard let self = self else { return }
      self._whenLinkPressed?(arg.from, arg.to)
      self.onPageChange()
    }
    webView.whenLoaded { [weak self] _ in
      guard let self = self else { return }
      self._whenLoaded?()
    }
  }
    
  ///Overrideable
  open func onPageChange(){}
  
}

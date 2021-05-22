//
//  WebView.swift
//
//  Created by Norbert Thies on 01.08.18.
//  Copyright © 2018 Norbert Thies. All rights reserved.
//

import UIKit
import WebKit

/// A JSCall-Object describes a native call from JavaScript to Swift
open class JSCall: DoesLog, ToString {
  
  /// name of the NativeBridge object
  public var objectName = ""
  /// name of the method called
  public var method = ""
  /// callback ID
  public var callback: Int?
  /// array of arguments
  public var args: [Any]?
  /// WebView object receiving the call
  public weak var webView: WebView?
  
  /// A new JSCall object is created using a WKScriptMessage
  public init(_ msg: WKScriptMessage) throws {
    if let dict = msg.body as? Dictionary<String,Any> {
      objectName = msg.name
      webView = msg.webView as? WebView
      if let m = dict["method"] as? String {
        method = m
        callback = dict["callback"] as? Int
        args = dict["args"] as? [Any]
      }
      else { throw exception( "JSCall without name of method" ) }
    }
    else { throw exception( "JSCall without proper message body" ) }
  }
  
  /// Call back to JS
  public func callback(arg: Any) {
    if let callbackIndex = self.callback {
      let dict: [String:Any] = ["callback": callbackIndex, "result": arg]
      let callbackJson = dict.json
      let execString = "\(self.objectName).callback(\(callbackJson))"
      webView?.jsexec(execString, closure: nil)
    }
  }
  
  /// Return arguments as String
  public func arguments2s(delimiter: String = "") -> String {
    var ret = ""
    if let args = args, args.count > 0 {
      for arg in args {
        if let str = arg as? CustomStringConvertible {
          if ret.isEmpty { ret = str.description }
          else { ret += "\(delimiter)\(str.description)" }
        }
      }
    }
    return ret
  }
  
  public func toString() -> String {
    var ret = "JSCall: \(objectName).\(method)\n"
    if let cb = callback { ret += "  callback ID: \(cb)" }
    if let args = args, args.count > 0 {
      ret += "\n  \(args.count) Argument(s):"
      for arg in args {
        if let str = arg as? CustomStringConvertible {
          ret += "\n    \(type(of: arg)) \"\(str.description)\""
        }
      }
    }
    return ret
  }
  
} // class JSCall

/// A JSBridgeObject describes a JavaScript object containing
/// methods that are passed to native functions
open class JSBridgeObject: DoesLog {
  
  /// Name of JS object
  public var name: String
  /// Dictionary of JS function names to native closures
  public var functions: [String:(JSCall)->Any] = [:]
  
  /// calls a native closure
  public func call(_ jscall: JSCall) {
    if let f = functions[jscall.method] {
      let method = jscall.method
      if method != "log" && method != "alert" {
        debug( "From JS: '\(jscall.objectName).\(jscall.method)' called" )
      }
      let retval = f(jscall)
      jscall.callback(arg: retval)
    }
    else {
      error( "From JS: undefined function '\(jscall.objectName).\(jscall.method)' called" )
    }
  }
  
  /// Initialize with name of JS object
  public init(name: String) { 
    self.name = name 
    addfunc("log") { jscall in
      self.log("JS: \(jscall.arguments2s())")
      return NSNull()
    }
    addfunc("alert") { jscall in
      Alert.message(message: jscall.arguments2s())
      return NSNull()
    }
  }
  
  /// Add a JS function defined by a native closure
  public func addfunc(_ name: String, closure: @escaping (JSCall)->Any) {
    self.functions[name] = closure
  }

  /// The JS code defining the JS class for the bridge object:
  public static var js: String = """
  /// The NativeBridge offers an interface to iOS native functions. By default
  /// every bridge offers the functions 'log' and 'alert'.
  class NativeBridge {

    /// Initialize with a String defining the name of the bridge object,
    /// this name is also used on the native side to identify this object.
    constructor(bridgeName) {
      this.bridgeName = bridgeName;
      this.callbacks = {};
      this.lastId = 1;
    }

    /// call a native function named 'method', give a callback function 'func'
    /// and a number of arguments to pass to the native side as native objects.
    call(method, func, ...args) {
      var nativeCall = {};
      nativeCall.method = method;
      if ( func != undefined && typeof func == "function" ) {
        nativeCall.callback = this.lastId;
        this.callbacks[this.lastId] = func;
        this.lastId++;
      }
      if ( args.length > 0 ) {
        nativeCall.args = args;
      }
      let str = "webkit.messageHandlers." + this.bridgeName + ".postMessage(nativeCall)"
      try { eval(str) }
      catch (error) {
        this.log("Native call error: " + error )
      }
    }
    
    /// Is called by the native side to call the callback function
    callback(ret) {
      if (ret.callback) {
        var func = this.callbacks[ret.callback];
        if ( func ) {
          delete this.callbacks[ret.callback];
          func.apply( null, [ret.result] );
        }
      }
    } 
    
    /// Send a log message to the native side
    log(...args) {
      var callArgs = ["log", undefined];
      callArgs = callArgs.concat(args);
      this.call.apply(this, callArgs);
    }
    
    /// Pop up a native alert message
    alert(...args) {
      var callArgs = ["alert", undefined];
      callArgs = callArgs.concat(args);
      this.call.apply(this, callArgs);    
    }
    
  }  // class NativeBridge

  /// Define window.alert and console.log as bridge functions
  function log2bridge(bridge) {
    console.log = function (...args) { bridge.log.apply(bridge, args); };
    window.alert = function (...args) { bridge.alert.apply(bridge, args); };
  }

  """
  
} // class JSBridgeObject

extension WKNavigationAction: ToString {
  
  public func navtype2a() -> String {
    switch self.navigationType {
    case .backForward:     return "backForward"
    case .formResubmitted: return "formResubmitted"
    case .formSubmitted:   return "formSubmitted"
    case .linkActivated:   return "linkActivated"
    case .other:           return "other"
    case .reload:          return "reload"
    default:               return "[undefined]"
    }
  }
  
  public func toString() -> String {
    return "WebView Navigation: \(navtype2a())\n  \(request.toString())"
  }
  
}

open class WebView: WKWebView, WKScriptMessageHandler, UIScrollViewDelegate,
                    WKNavigationDelegate {

  /// JS NativeBridge objects
  public var bridgeObjects: [String:JSBridgeObject] = [:]
  
  /// Directory which local web pages may access for resources
  public var baseDir: String?
  public var baseUrl: URL? { 
    if let d = baseDir { return URL(fileURLWithPath: d) } 
    else { return nil } 
  }
  /// The original URL to load
  public var originalUrl: URL?
  
  // The closure to call when link is pressed
  private var _whenLinkPressed: ((URL?,URL?)->())?
  
  /// Define closure to call when link is pressed
  public func whenLinkPressed( _ closure: @escaping (URL?,URL?)->() ) {
    _whenLinkPressed = closure
  }
  
  // Default LinkPressed closure
  private func linkPressed(from: URL?, to: URL?) {
    guard let to = to else { return }
    self.debug("Calling application for: \(to.absoluteString)")
    if UIApplication.shared.canOpenURL(to) {
      UIApplication.shared.open(to, options: [:], completionHandler: nil)
    }
    else {         
      error("No application or no permission for: \(to.absoluteString)")         
    }
  }
  
  /// Define Bridge Object
  public func addBridge(_ object: JSBridgeObject, isExec: Bool = false) {
    if isExec {
      if self.bridgeObjects.isEmpty { self.jsexec(JSBridgeObject.js) }
      self.jsexec("var \(object.name) = new NativeBridge(\"\(object.name)\")")
    }
    self.bridgeObjects[object.name] = object
    self.configuration.userContentController.add(self, name: object.name)
  }
  
  /// Perform console.log and window.alert via bridge
  public func log2bridge(name: String) {
    if let bridge = bridgeObjects[name] {
      self.jsexec("log2bridge(\(bridge.name))")
    }
  }
  /// Perform console.log and window.alert via bridge
  public func log2bridge(_ bridge: JSBridgeObject) {
    self.jsexec("log2bridge(\(bridge.name))")
  }

  // The closure to call when content scrolled more than scrollRatio
  private var whenScrolledClosure: ((CGFloat)->())?
  private var scrollRatio: CGFloat = 0
  
  /// Define closure to call when web content has been scrolled
  public func whenScrolled( minRatio: CGFloat, _ closure: @escaping (CGFloat)->() ) {
    scrollRatio = minRatio
    whenScrolledClosure = closure
  }
  
  // The closure to call when some dragging (scrolling) has been done
  private var whenDraggedClosure: ((CGFloat)->())?

  /// Define closure to call when web content has been dragged, the value passed
  /// is the number of points scrolled down divided by the content's height
  public func whenDragged(closure: @escaping (CGFloat)->()) {
    whenDraggedClosure = closure
  }
  
  // content y offset at start of dragging
  private var startDragging: CGFloat?
  
  /// Define closure to call when the end of the web content will become 
  /// visible
  public func atEndOfContent(closure: @escaping (Bool)->()) {
    atEndOfContentClosure = closure
  }
  
  // end of content closure
  private var atEndOfContentClosure: ((Bool)->())?
  
  /// Returns true if the end of the content is visible
  /// (in vertical direction)
  public var isAtEndOfContent: Bool {
    return isAtEndOfContent(offset: scrollView.contentOffset.y)
  }

  /// Returns true if at a given offset the end of the content is visible
  /// (in vertical direction)
  public func isAtEndOfContent(offset: CGFloat) -> Bool {
    let end = scrollView.contentSize.height
    return (offset + bounds.size.height) >= end
  }
  
  /// jsexec executes the passed string as JavaScript expression using
  /// evaluateJavaScript, if a closure is given, it is only called when
  /// there is no error.
  public func jsexec(_ expr: String, closure: ((Any?)->Void)? = nil) {
    self.evaluateJavaScript(expr) {
      [weak self] (retval, error) in
      if let err = error {
        self?.error("JavaScript error: " + err.localizedDescription)
      }
      else {
        if let callback = closure {
          callback(retval)
        }
      }
    }
  }
  
  /// calls a native closure
  public func call(_ jscall: JSCall) {
    if let bo = bridgeObjects[jscall.objectName] {
      bo.call(jscall)
    }
    else {
      error("From JS: undefined bridge object '\(jscall.objectName) used")
    }
  }
  
  @discardableResult
  public func load(url: URL) -> WKNavigation? {
    if isLoading { stopLoading() }
    self.originalUrl = url
    if url.isFileURL {
      debug("load: \(url.lastPathComponent)")
      var base = self.baseUrl
      if base == nil { base = url.deletingLastPathComponent() }
      return loadFileURL(url, allowingReadAccessTo: base!)
    }
    else {
      let request = URLRequest(url: url)
      return load(request)
    }
  }
  
  @discardableResult
  public func load(_ string: String) -> WKNavigation? {
    if let url = URL(string: string) {
      return load(url: url)
    }
    else { return nil }
  }
  
  @discardableResult
  public func load(html: String) -> WKNavigation? {
    return loadHTMLString(html, baseURL: baseUrl)
  }
  
  public func setup() {
    self.navigationDelegate = self
    whenLinkPressed { (from, to) in self.linkPressed(from: from, to: to) }
  }
  
  override public init(frame: CGRect, configuration: WKWebViewConfiguration? = nil) {
    var config = configuration
    if config == nil { config = WKWebViewConfiguration() }
    super.init(frame: frame, configuration: config!)
    setup()
  }
  
  required public init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }
  
  public func scrollToTop() {
    scrollView.setContentOffset(CGPoint(x:0, y:0), animated: false)
  }
  
  // MARK: - WKScriptMessageHandler protocol
  public func userContentController(_ userContentController: WKUserContentController,
                                    didReceive message: WKScriptMessage) {
    if let jsCall = try? JSCall( message ) {
      call( jsCall)
    }
  }

  // MARK: - UIScrollViewDelegate protocol
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//      if let sd = startDragging {
//        if scrollView.isDragging {
//          let scrolled = sd-scrollView.contentOffset.y
//          let ratio = scrolled / scrollView.bounds.size.height
//          //debug("scrolled: \(scrolled), ratio = \(ratio)")
//        }
//      }
//  }
//
  public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    startDragging = scrollView.contentOffset.y
  }

  public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if let sd = startDragging {
      let scrolled = sd-scrollView.contentOffset.y
      let ratio = scrolled / scrollView.bounds.size.height
      if let closure = whenScrolledClosure, abs(ratio) >= scrollRatio {
        closure(ratio)
      }
    }
    startDragging = nil
    if let closure = whenDraggedClosure {
      let ratio = scrollView.contentOffset.y / scrollView.contentSize.height
      closure(ratio)
    }
  }
  
  // When dragging stops, check whether the end of content is visible  
  public func scrollViewWillEndDragging(_ scrollView: UIScrollView, 
    withVelocity velocity: CGPoint, 
    targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    if let closure = atEndOfContentClosure {
      let offset = targetContentOffset.pointee.y
      closure(isAtEndOfContent(offset: offset))
    }
  }

  // MARK: - WKNavigationDelegate protocol
  public func webView(_ webView: WKWebView, decidePolicyFor nav: WKNavigationAction,
                      decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    if let wv = webView as? WebView {
      let from = wv.originalUrl?.absoluteString
      let to = nav.request.description
      if from != to, to != "about:blank" {
        if let closure = _whenLinkPressed {
          closure(wv.originalUrl, URL(string: to)) 
        }
        decisionHandler(.cancel)
      }
      else { decisionHandler(.allow) }
    }
  }
  
} // class WebView

/**
 An embedded WebView with a button at the bottom which is displayed when the 
 WebView has been scrolled to its vertical end. In addition a cross (or X) button 
 can be displayed using the "onX"-Method to define a closure that is called when 
 the X-Button has been pressed.
 */
open class ButtonedWebView: UIView {
  
  public class LabelButton: UIView, Touchable {
    public var tapRecognizer = TapRecognizer()
    public var label = UILabel()
    private var bwv: ButtonedWebView!
    public var text: String? { 
      get { label.text }
      set { label.text = newValue; bwv.adaptLayoutConstraints() }     
    }
    public var textColor: UIColor {
      get { label.textColor }
      set { label.textColor = newValue }
    }
    public var font: UIFont {
      get { label.font }
      set { label.font = newValue }
    }
    public var hasContent: Bool { text != nil }
    init(bwv: ButtonedWebView) {
      self.bwv = bwv
      super.init(frame: CGRect())
      self.addSubview(label)
      self.isUserInteractionEnabled = true
      label.backgroundColor = .clear
      pin(label.centerX, to: self.centerX)
      pin(label.centerY, to: self.centerY)
      pinHeight(50)
      pinWidth(250)
    }    
    required init?(coder: NSCoder) { super.init(coder: coder) }
  } 
  
  public var webView = WebView()
  /// The label acting as a button
  public lazy var buttonLabel = LabelButton(bwv: self)
  /// The X-Button (may be used to close the webview)
  public lazy var xButton = Button<CircledXView>()
  /// Distance between button and bottom as well as button and webview
  public var buttonMargin: CGFloat = 8 { didSet { adaptLayoutConstraints() } }
  private var isButtonVisible = false
  
  private var buttonBottomConstraint: NSLayoutConstraint?
  private var webViewBottomConstraint: NSLayoutConstraint?
  
  private var tapClosure: ((String)->())?
  private var xClosure: (()->())?
  
  /// This closure is called when the buttonLabel has been pressed
  public func onTap(closure: @escaping (String)->()) { tapClosure = closure }
  /// This closure is called when the X-Button has been pressed
  public func onX(closure: @escaping ()->()) {
    xClosure = closure
    xButton.isHidden = false
    xButton.onPress {_ in
      self.xClosure?()
    }
  }
  
  private func adaptLayoutConstraints() {
    let willShow = buttonLabel.hasContent && isButtonVisible
    let buttonDist = willShow ? -buttonMargin : buttonLabel.frame.height
    let webViewDist = willShow ? -buttonMargin : 0
    buttonBottomConstraint?.isActive = false
    webViewBottomConstraint?.isActive = false
    buttonBottomConstraint = pin(buttonLabel.bottom, to: self.bottom, dist: buttonDist)
    webViewBottomConstraint = pin(webView.bottom, to: buttonLabel.top, dist: webViewDist)
    layoutIfNeeded()
  }  
  
  private func adaptLayout(animated: Bool = false) {
    if animated {
      UIView.animate(seconds: 0.5) { [weak self] in 
        self?.adaptLayoutConstraints()
      }
    } 
    else { adaptLayoutConstraints() }
  }
  
  private func setup() {
    self.backgroundColor = .white
    self.addSubview(webView)
    self.addSubview(buttonLabel)
    self.addSubview(xButton)
    pin(webView.top, to: self.top)
    pin(webView.left, to: self.left)
    pin(webView.right, to: self.right)
    pin(buttonLabel.centerX, to: self.centerX)
    pin(xButton.right, to: self.right, dist: -15)
    pin(xButton.top, to: self.top, dist: 50)
    xButton.pinHeight(35)
    xButton.pinWidth(35)
    xButton.color = .black
    xButton.buttonView.isCircle = true
    xButton.buttonView.circleColor = UIColor.rgb(0xdddddd)
    xButton.buttonView.color = UIColor.rgb(0x707070)
    xButton.buttonView.innerCircleFactor = 0.5
    xButton.isHidden = true
    webView.atEndOfContent { [weak self] isAtEnd in
      guard let self = self else { return }
      if self.isButtonVisible != isAtEnd {
        self.isButtonVisible = isAtEnd
        self.adaptLayout(animated: true)
      }
    }
    buttonLabel.onTap { recog in self.tapClosure?(self.buttonLabel.text!) }
  }
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }
  
  public override func layoutSubviews() {
    adaptLayoutConstraints()
  }
}

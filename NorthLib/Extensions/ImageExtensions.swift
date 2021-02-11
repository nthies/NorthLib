//
//  ImageExtensions.swift
//
//  Created by Norbert Thies on 28.02.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit

public extension UIImage {
  
  /// Get Jpeg data from Image with a quality of 50%
  var jpeg: Data? { return jpegData(compressionQuality: 0.5) }
  
  /// Save the image as jpeg data to a file
  func save(to: String) {
    if let data = self.jpeg {
      try! data.write(to: URL(fileURLWithPath: to), options: [])
    }
  }
    
  /// Returns GIF frame delay in seconds at index
  static private func gifDelay(source: CGImageSource, index: Int) -> Double {
    var delay = 0.1
    let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
    let gifProperties: CFDictionary = unsafeBitCast(CFDictionaryGetValue(cfProperties,
            Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque()),
            to: CFDictionary.self)
    var delayObject: AnyObject = unsafeBitCast(
        CFDictionaryGetValue(gifProperties,
        Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()),
        to: AnyObject.self)
    if delayObject.doubleValue == 0 {
      delayObject = unsafeBitCast(CFDictionaryGetValue(gifProperties,
        Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()), 
                                  to: AnyObject.self)
    }
    delay = delayObject as! Double
    if delay < 0.1 { delay = 0.1 }
    return delay
  }
  
  /// Initialize with animated gif data
  static func animatedGif(_ data: Data) -> UIImage? {
    guard let source =  CGImageSourceCreateWithData(data as CFData, nil) 
      else { return nil }
    var images = [CGImage]()
    var delays = [Int]()
    var duration: Double = 0
    let imageCount = CGImageSourceGetCount(source)
    for i in 0..<imageCount {
      if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
        images += image
        let delay = gifDelay(source: source, index: i)
        delays += Int(delay * 1000)
        duration += delay
      }
    }
    let div = gcd(delays)
    var frames = [UIImage]()
    for i in 0..<imageCount {
      let frame = UIImage(cgImage: images[i])
      var frameCount = delays[i] / div
      while frameCount > 0 { frames += frame; frameCount -= 1 }
    }
    return UIImage.animatedImage(with: frames, duration: duration)
  }
  
  /// Change Image Scale without expensive Rendering
  func scaled(_ scaleFactor:CGFloat = UIScreen.main.scale) -> UIImage {
    guard let cgi = self.cgImage else { return self }
    let img = UIImage(cgImage: cgi,
                   scale: scaleFactor,
                   orientation: self.imageOrientation)
    //ToDo How To Exclude log just DiesLog and log did not work
//    Log.log("Scale Image with: \(scaleFactor):"
//            + "\n  UIImage     size: \(self.size) scale: \(self.scale)x"
//            + "\n  cgImage     size: \(cgi.width)x\(cgi.height)"
//                + "\n  new UIImage size: \(img.size) scale: \(img.scale)x",
//              object: self,
//              logLevel: .Debug,
//              file: #file,
//              line: #line,
//              function: #function)
    return img
  }
  
} // UIImage

extension UIImage {
  public var mbSize: CGFloat{
    var i = 0
    i += 2
    
    guard let cgimg = self.cgImage else { return 0}
    return CGFloat((10*cgimg.height * cgimg.bytesPerRow)/(1024*1024))/10;
  }
}

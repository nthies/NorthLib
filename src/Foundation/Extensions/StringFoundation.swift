//
//  String.swift
//
//  Created by Norbert Thies on 20.07.16.
//  Copyright © 2016 Norbert Thies. All rights reserved.
//
//  This file implements various String extensions depending on the 
//  Foundation Framework.
//

import Foundation

/// String extension supporting regular expression matches.
public extension String {

  /// allMatches returns an array of strings representing all matches
  /// of the passed regular expression in 'self'.
  func allMatches(regexp: String) -> [String] {
    do {
      let re = try NSRegularExpression(pattern: regexp)
      let res = re.matches(in: self, range: NSRange(self.startIndex..., in: self))
      return res.map {
        String(self[Range($0.range, in: self)!])
      }
    } catch { return [] }
  }
  
  /// groupMatches returns an array of strings representing matches of the passed 
  /// regular expression. 
  /// 
  /// Each match itself is an array
  /// of strings matching the groups used in the regular expression. The first
  /// element of the String array is always the completely matched regular expression.
  /// Ie. "<123> <456>".groupMatches(regexp: #"<(\d+)>"#) yields 
  /// [["<123>", "123"], ["<456>", "456"]].
  /// If a group contains subgroups then the match representing the enclosing 
  /// group preceeds the subgroup in the array. Ie "<123>".groupMatches(#"<(1(\d+))>"#)
  /// returns ["<123>", "123", "23"].
  func groupMatches(regexp: String) -> [[String]] {
    do {
      let re = try NSRegularExpression(pattern: regexp)
      let res = re.matches(in: self, range: NSRange(self.startIndex..., in: self))
      return res.map { match in
        return (0..<match.numberOfRanges).map {
          let rangeBounds = match.range(at: $0)
          guard let range = Range(rangeBounds, in: self) else { return "" }
          return String(self[range])
        }
      }
    } catch let error {
      Log.fatal(error)
      return []
    }
  }

} // extension String

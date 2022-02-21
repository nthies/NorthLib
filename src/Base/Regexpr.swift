//
//  Regexpr.swift
//
//  Created by Norbert Thies on 31.01.2022
//

import NorthLowLevel

/**
 * Regexpr is a wrapper around libc's POSIX regex functions.
 *
 * A regular expression is compiled from a String and may be used to match against
 * other Strings. For example:
 * ````
 *   let re = Regexpr("[0-9]+")
 *   let m = re.match("abc 123 def")
 * ````
 * returns in `m` an array of matched strings. In `m[0]` the complete matching
 * string is stored (in this example "123"). Other elements of `m`, `m[i]` may
 * contain matching (sub-)groups. Consider:
 * ````
 *   let re = Regexpr("([0-9]+)-([0-9]+)")
 *   let m = re.match("abc 123-456 def")
 * ````
 * then the resulting match array `m` is:
 * ````
 *   m.count == 3
 *   m[0] == "123-456"
 *   m[1] == "123"
 *   m[2] == "456"
 * ````
 * In addition to POSIX regular expressions (see regex manpage) the following
 * character class shortcuts may be used (either introduced by a leading \ or
 * a leading @):
 *   * @d: a digit
 *   * @D: no digit
 *   * @s: white space
 *   * @S: no white space
 *   * @a: alpha character
 *   * @A: no alpha character
 *   * @w: a word character (alpha-numeric plus underscore)
 *   * @W: no word character
 *   * @n: newline
 *   * @r: carriage return
 *   * @t: tab
 *
 * - warning: Since the POSIX standard doesn't support alternate character
 *            representations, it may be possible that character classes don't
 *            work as expected.
 */
open class Regexpr {
  
  private var re: re_t // compiled regular expression
  
  /// The pattern used to initialize the Regexpr
  public var pattern: String {
    get { String(validatingUTF8: re_get_pattern(re))! }
    set { newValue.withCString { re_set_pattern(re, $0) } }
  }
  
  /// Shall we ignore character case while matching?
  public var ignoreCase: Bool {
    get { re_get_icase(re) != 0 }
    set { re_set_icase(re, newValue ? 1 : 0) }
  }
  
  /**
   * Shall a newline be interpreted as 'end-of-string' (ie. $-pattern)?
   *
   * By default a newline is treated as ordinary character, e.g. it is matched
   * by a **dot**-Pattern. If *newlineSensitive* is true, then a **dot** doesn't
   * match a newline and **$** matches the empty string just in front of a newline.
   * A caret (**^**) similarly matches the empty string just behind the newline.
   */
  public var newlineSensitive: Bool {
    get { re_get_sensnl(re) != 0 }
    set { re_set_sensnl(re, newValue ? 1 : 0) }
  }

  /// Initialize with String pattern
  public init(_ pattern: String) throws {
    re = pattern.withCString { re_init($0) }
    var err: UnsafeMutablePointer<CChar>? = re_last_error(re)
    if err != nil { 
      defer { str_release(&err) }
      throw String(validatingUTF8: err!)! 
    }
  }
  
  /// Initialize with C's re_t
  public init(re: re_t) { self.re = re }
  
  deinit { re_release(re) }
  
  /// Returns true if RE matches the passed String
  public func matches(_ str: String) -> Bool {
    str.withCString { re_matches(re,$0) } != 0
  }
 
  /**
   * Returns an array of Strings describing the first match.
   *
   * After
   * ````
   *   let m = re.match(str)
   * ````
   * - m[0] contains the first complete matching String.
   * - m[1] contains the first matching group.
   * - m[i] where 1<i<m.count contain the i'th matching group.
   *
   * - parameters:
   *   - str: String the RE is matched against
   *
   * - returns: nil: String isn't matched,
   *            array of matching Strings otherwise
   */
  public func match(_ str: String) -> [String]? {
    let ret = str.withCString { s in re_match(re, s) }
    if let m = ret {
      defer { av_release(m) }
      return Array<String>(m)
    }
    return nil
  }
  
  /**
   * Returns an array of match results describing all matches.
   *
   * After
   * ````
   *   let m = re.gmatch(str)
   * ````
   * - m[0] contains the first match result as returned by 'match'.
   * - m[i] where 0<i<m.count contain the i'th 'match' result.
   *
   * All match results m[i] are arrays of Strings as described in 'match'.
   *
   * - parameters:
   *   - str: String the RE is matched against
   *
   * - returns: nil: String isn't matched, array of match results otherwise
   */
  public func gmatch(_ str: String) -> [[String]]? {
    var ret: [[String]] = []
    str.withCString { str in
      var s: UnsafePointer<CChar>? = str
      while let m = re_rmatch(re, &s) {
        ret += Array<String>(m)
        av_release(m)
      }
    }
    return (ret.count == 0) ? nil : ret
  }
  
  /**
   * Returns a String where pattern matches are substituted.
   *
   * The first match is substituted by the String 'with' may include so called
   * back references to the matching pattern or enclosed match groups.
   * The following back references are supported:
   *
   * - &: refers to the complete matching string
   * - &1: refers to the first pattern group
   * - &i: refers to the i'th pattern group
   * - \i: also refers to the i'th pattern group
   *
   * Optionally a single '#' in 'with' is substituted by the 'num' argument
   * (if specified and >= 0). Using ndig > 0 the number of digits substituting
   * the '#' may be specified (leading 0s).
   *
   * - parameters:
   *   - str:  String the RE is matched against
   *   - with: Substitution string optionally containing back references
   *   - num:  Optional number substitution
   *   - ndig: Optional number of digits to use in number substitution
   *   - isGlobal: Substitute all occurrences
   *
   * - returns: nil: String isn't matched, substituted string otherwise
   */
  public func subst(_ str: String, with: String, num: Int = -1, ndig: Int = -1,
                    isGlobal: Bool = false) -> String? {
    str.withCString { str in
      with.withCString { with in
        var s: UnsafePointer<CChar>? = str
        var ret: UnsafeMutablePointer<CChar>?
        if isGlobal {
          ret = re_ngsubst(re, &s, with, Int32(num), Int32(ndig))
        }
        else { ret = re_nsubst(re, &s, with, Int32(num), Int32(ndig)) }
        defer { str_release(&ret) }
        if let ret = ret { return String(validatingUTF8: ret) }
        else { return nil }
      }
    }
  }
  
  /**
   * Returns a String where pattern matches are substituted.
   *
   * All matches are substituted by the String 'with' may include so called
   * back references to the matching pattern or enclosed match groups.
   * See 'subst' for further discussion.
   *
   * - parameters:
   *   - str:  String the RE is matched against
   *   - with: Substitution string optionally containing back references
   *   - num:  Optional number substitution
   *   - ndig: Optional number of digits to use in number substitution
   *
   * - returns: nil: String isn't matched, substituted string otherwise
   */
  public func gsubst(_ str: String, with: String, num: Int = -1, ndig: Int = -1)
    -> String? { subst(str, with: with, num: num, ndig: ndig, isGlobal: true) }
  
  /**
   * Returns a String where pattern matches are substituted.
   *
   * The passed String 'str' is substituted according to the substitution
   * specification given with 'by'. This is an sed-like String encompassing
   * the pattern and the substitution string (eg. "/<pattern>/<substitution>/").
   * The delimiter character ("/" in this example) may be any ASCII (not multibyte)
   * character, so ",<pattern>,<substitution>," is also valid. If the last delimiter
   * is followed by the character "g", a global substitution is performed. E.g.
   * ````
   *   Regexpr.subst("abc123def456ghi", "/@d+/<&>/g")
   * ````
   * yields:
   * ````
   *   "abc<123>def<456>ghi"
   * ````
   *
   * - parameters:
   *   - str:  String the RE is matched against
   *   - by:   Substitution specification a la sed
   *   - num:  Optional number substitution
   *   - ndig: Optional number of digits to use in number substitution
   *
   * - returns: nil: String isn't matched, substituted string otherwise
   */
  public static func subst(_ str: String, by spec: String, num: Int = -1,
                           ndig: Int = -1) -> String? {
    str.withCString { str in
      spec.withCString { spec in
        var ret: UnsafeMutablePointer<CChar>?
        defer { str_release(&ret) }
        ret = re_nstrsubst(str, spec, Int32(num), Int32(ndig))
        if let ret = ret { return String(validatingUTF8: ret) }
        else { return nil }
      }
    }
  }
  
  /**
   * Checks whether the passed String 'spec' is a valid substitution specification.
   * 
   * isValidSubst can be used to verify whether a given substitution specification
   * as used in the 'subst' method is valid, ie. is of the correct syntax.
   * 
   * - returns: true => valid, false otherwise
   */
  public static func isValidSubst(spec: String) -> Bool {
    Substexpr.isValid(spec: spec)
  }
  
} // Regexpr

/**
 * Substexpr objects are used to perform pattern based String substitutions.
 *
 * The initializer is called with an sed-like substitution specification encompassing
 * the pattern and the substitution string (eg. "/<pattern>/<substitution>/").
 * The delimiter character ("/" in this example) may be any ASCII (not multibyte)
 * character, so ",<pattern>,<substitution>," is also valid. If the last delimiter
 * is followed by the character "g", a global substitution is performed. E.g.
 * ````
 *   let se = Substexpr("/@d+/<&>/g")
 * ````
 * creates a substitution expression which seaches in a given String for patterns
 * @d+ (a sequence of digits - at least one). Each of these patterns found in the
 * String are substituted by the same pattern enclosed in <>. E.g.
 *  
 * ````
 *   se.subst("abc123def456ghi")
 * ````
 * yields:
 * ````
 *   "abc<123>def<456>ghi"
 * ````
 * This example uses in its substitution string so called back references (&)
 * to the matching pattern or enclosed match groups.
 * The following back references are supported:
 *
 * - &: refers to the complete matching string
 * - &1: refers to the first pattern group
 * - &i: refers to the i'th pattern group
 * - \i: also refers to the i'th pattern group
 *
 * Optionally a single '#' in the sustitution string is substituted by the 
 * index variable in the Substexpr object (if defined). The index is incremented
 * after each successful substitution. Using the variables 'count' or 'ndig' 
 * the number of 0-filled digits can be specified.
 */
open class Substexpr {
  
  /// The pattern to search for
  public var re: Regexpr!
  /// The substitution String
  public var subst: String!
  /// Whether to perform global substitions (ie. substitute all matches)
  public var isGlobal: Bool!
  /// Index of substitution (for #-substitutions)
  public var index: Int = -1
  /// Number of digits for #-substitions (will be set by 'count')
  public var ndig: Int = -1 {
    didSet { if index == -1 { index = 1 } }
  }
  /// Total number of Strings to substitue (evaluates 'ndig') 
  public var count: Int? {
    didSet {
      if ndig == -1 { 
        let n = Double(count!)
        ndig = Int(n.log(base: 10)) + 1 
      }
    }
  }
  
  /// Initialize with substitution specification (see ``Substexpr``)
  public init(_ spec: String) throws {
    var cre: re_t?
    var subst: UnsafeMutablePointer<CChar>?
    var isGlobal: Int32 = 0
    try spec.withCString { s in
      if re_split_subst(s, &cre, &subst, &isGlobal) ==  0 {
        defer { str_release(&subst) }
        self.re = Regexpr(re: cre!)
        self.subst = String(validatingUTF8: subst!)
        self.isGlobal = isGlobal != 0
      }
      else { throw "\(spec): Invalid Substitution expression" }
    }
  }
  
  /// Perform the substitution and return a substituted String if the pattern
  /// matches (see ``Substexpr``).
  public func subst(_ str: String) -> String? {
    let s = re.subst(str, with: subst, num: index, ndig: ndig, isGlobal: isGlobal)
    if s != nil && index != -1 { index += 1 }
    return s
  }
  
  /**
   * Checks whether the passed String 'spec' is a valid substitution specification.
   * 
   * isValid can be used to verify whether a given substitution specification
   * as used in Substexpr.init is valid, ie. is of correct syntax.
   * 
   * - parameters:
   *   - spec:  substituion specification
   *   
   * - returns: true => valid, false otherwise
   */
  public static func isValid(spec: String) -> Bool {
    spec.withCString { spec in
      return re_is_valid_subst(spec) != 0
    }
  }

} // Substexpr

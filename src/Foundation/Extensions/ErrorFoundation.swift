//
//  ErrorFoundation.swift
//
//  Created by Norbert Thies on 18.06.19.
//  Copyright © 2019 Norbert Thies. All rights reserved.
//

import Foundation

/// Since Swift.Error only defines _localizedDescription_ we provide a definition
/// of _description_ which by default yields _localizedDescription_
extension Error {
  public var description: String { localizedDescription }
}

/// Provide _description_ for localized errors
extension LocalizedError {
  public var description: String { errorDescription ?? localizedDescription }
}


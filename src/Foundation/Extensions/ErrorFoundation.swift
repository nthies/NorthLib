//
//  ErrorFoundation.swift
//
//  Created by Norbert Thies on 18.06.19.
//  Copyright © 2019 Norbert Thies. All rights reserved.
//

import Foundation

/// Provide _description_ for localized errors
extension LocalizedError {
  public var description: String { errorDescription ?? localizedDescription }
}


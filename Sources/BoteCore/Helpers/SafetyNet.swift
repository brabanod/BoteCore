//
//  SafetyNet.swift
//  bote-core
//
//  Created by Pascal Braband on 02.01.20.
//  Copyright © 2020 Pascal Braband. All rights reserved.
//

import Foundation

public enum SafetyNetError: Error {
    case unauthorized(String)
}

class SafetyNet {
    
    private let basePath: String
    
    
    init(basePath: String) {
        self.basePath = basePath
    }
    
    
    /**
     Checks if the given paths are inside the basepath, with which the object was initialized.
     
     - parameters:
        - path: A list of paths as `String`'s. These are the paths, that `SafetyNet` compares to the basepath.
    
     - throws:
        - `SafetyNetError`: If one of the given paths is outside of the basepath, an error is thrown.
     */
    func intercept(path: String...) throws {
        // Should prevent accidently operating on wrong path in file system
        if path.allSatisfy({ $0.hasPrefix(basePath) }) {
            // Search for if there is a correct slash set between the two path components
            if path.allSatisfy({
                let rest = $0.deletingPrefix(basePath)
                if rest == "" {
                    return true
                } else if rest.first == "/" {
                    return true
                } else if basePath.last == "/" {
                    return true
                } else {
                    return false
                }
            }) {
                // Check for illegal characters in the rest component
                if path.allSatisfy({
                    let rest = $0.deletingPrefix(basePath)
                    if rest.contains("..") {
                        return false
                    } else {
                        return true
                    }
                }) {
                    return
                }
            }
        }
        throw SafetyNetError.unauthorized("Operating on unauthorized path: \(path).\n Only operations on \(basePath) are allowed.")
    }
}

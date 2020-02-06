//
//  String+PathExtensions.swift
//  bote-core
//
//  Created by Pascal Braband on 02.01.20.
//  Copyright © 2020 Pascal Braband. All rights reserved.
//

import Foundation

extension String {
    
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
    
    func deletingSuffix(_ suffix: String) -> String {
        guard self.hasSuffix(suffix) else { return self }
        return String(self.dropLast(suffix.count))
    }
    
    func escapeSpaces() -> String {
        return self.replacingOccurrences(of: " ", with: "\\ ")
    }
    
    func replace(localBasePath: String, with remoteBasePath: String) -> String {
        // Subtract localBasePath from given path
        // Then append the rest to remoteBasePath return it
        let pathComponent = self.replacingOccurrences(of: localBasePath, with: "")
        
        let remotePath = remoteBasePath.deletingSuffix("/")
        let filePath = pathComponent.deletingPrefix("/")

        return remotePath + "/" + filePath
    }
}

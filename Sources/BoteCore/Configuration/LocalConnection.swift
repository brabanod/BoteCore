//
//  LocalConnection.swift
//  bote-core
//
//  Created by Pascal Braband on 10.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import Foundation

public class LocalConnection: Connection {
    public let type: ConnectionType = ConnectionType.local
    
    public var path: String
    
    public func remove() { }
    
    public init(path: String) {
        self.path = path
    }
    
    public func isEqual(to: Connection) -> Bool {
        if to.type == self.type,
            let con = to as? LocalConnection,
            self.path == con.path {
            return true
        } else {
            return false
        }
    }
}

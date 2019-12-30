//
//  Connection.swift
//  bote-core
//
//  Created by Pascal Braband on 23.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import Foundation

protocol Connection: Codable {
    var type: ConnectionType { get }
    var path: String { get set }
    
    /**
     This method gets called, when a configuration is deleted. Custom deletion operations for a specific `Connection` implementation can be performed in this method.
     */
    func remove()
}


enum ConnectionType : Int, Codable {
    case local
    case sftp

    func getType() -> Connection.Type {
        switch self {
            case .local: return LocalConnection.self
            case .sftp: return SFTPConnection.self
        }
    }
}

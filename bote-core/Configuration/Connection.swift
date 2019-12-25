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

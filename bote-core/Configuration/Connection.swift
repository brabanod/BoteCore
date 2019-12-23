//
//  Connection.swift
//  bote-core
//
//  Created by Pascal Braband on 23.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import Foundation

protocol Connection {
    var type: ConnectionType { get }
    var path: String { get set }
    
    init()

    func encode(to encoder: Encoder) throws
    mutating func decode(from decoder: Decoder) throws
}


enum ConnectionType : Int, Codable {
    case local
    case sftp

    func createConnection() -> Connection {
        switch self {
            case .local: return LocalConnection()
            case .sftp: return SFTPConnection()
        }
    }
}

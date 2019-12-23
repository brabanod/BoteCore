//
//  Configuration.swift
//  bote-core
//
//  Created by Pascal Braband on 10.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import Foundation

struct Configuration {
    var from: Connection
    var to: Connection
    var fromType: ConnectionType
    var toType: ConnectionType
    
    private var id: String = UUID.init().uuidString
}


extension Configuration: Codable {

    enum CodingKeys: String, CodingKey {
        case from, to, fromType, toType, id
    }
    
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(String.self, forKey: .id)
        
        self.fromType = try container.decode(ConnectionType.self, forKey: .fromType)
        self.from = self.fromType.createConnection()
        try self.from.decode(from: decoder)
        
        self.toType = try container.decode(ConnectionType.self, forKey: .toType)
        self.to = self.toType.createConnection()
        try self.to.decode(from: decoder)
    }
    
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.id, forKey: .id)
        
        try container.encode(self.fromType, forKey: .fromType)
        try from.encode(to: encoder)
        
        try container.encode(self.toType, forKey: .toType)
        try to.encode(to: encoder)
    }
}

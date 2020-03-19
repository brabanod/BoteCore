//
//  Configuration.swift
//  bote-core
//
//  Created by Pascal Braband on 10.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import Foundation

public class Configuration: Codable, Equatable {
    public var name: String = ""
    public var from: Connection
    public var to: Connection
    
    public var fromType: ConnectionType { return from.type }
    public var toType: ConnectionType { return to.type }
    
    public private(set) var id: String = UUID.init().uuidString
    
    
    public init(from: Connection, to: Connection) {
        self.from = from
        self.to = to
    }
    
    
    public init(from: Connection, to: Connection, name: String) {
        self.from = from
        self.to = to
        self.name = name
    }
    
    
    func setId(_ id: String) {
        self.id = id
    }
    
    
    func remove() {
        from.remove()
        to.remove()
    }
    
    
    
    
    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case from, to, fromType, toType, id, name
    }
    
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)

        var type: ConnectionType
        
        type = try container.decode(ConnectionType.self, forKey: .fromType)
        let fromDecoder = try container.superDecoder(forKey: .from)
        self.from = try type.getType().init(from: fromDecoder)

        type = try container.decode(ConnectionType.self, forKey: .toType)
        let toDecoder = try container.superDecoder(forKey: .to)
        self.to = try type.getType().init(from: toDecoder)
    }
    
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.id, forKey: .id)
        try container.encode(self.name, forKey: .name)

        try container.encode(self.fromType, forKey: .fromType)
        let fromContainer = container.superEncoder(forKey: .from)
        try from.encode(to: fromContainer)

        try container.encode(self.toType, forKey: .toType)
        let toContainer = container.superEncoder(forKey: .to)
        try to.encode(to: toContainer)
    }
    
    
    
    
    // MARK: - Equatable
    
    public static func == (lhs: Configuration, rhs: Configuration) -> Bool {
        if lhs.name == rhs.name,
            lhs.fromType == rhs.fromType,
            lhs.toType == rhs.toType,
            lhs.from.isEqual(to: rhs.from),
            lhs.to.isEqual(to: rhs.to) {
            return true
        } else {
            return false
        }
    }
}

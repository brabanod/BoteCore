//
//  LocalConnection.swift
//  bote-core
//
//  Created by Pascal Braband on 10.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import Foundation

struct LocalConnection: Connection {
    let type: ConnectionType = ConnectionType.local
    var path: String
    
    
    init() {
        self.path = ""
    }
    
    
    init(path: String) {
        self.path = path
    }
    
    
    
    
    // MARK: - Encoding/Decoding
    
    enum CodingKeys: String, CodingKey {
        case localPath
    }

    
    /**
    Encodes the object for a given Encoder.
    */
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.path, forKey: .localPath)
    }
    
    
    /**
    Decodes the object for a given Decoder.
    */
    mutating func decode(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        path = try container.decode(String.self, forKey: .localPath)
    }
}

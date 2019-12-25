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
}

//
//  Configuration.swift
//  bote-core
//
//  Created by Pascal Braband on 10.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import Foundation

struct Configuration: Codable {
    //let from: ConnectionConfiguration
    //let to: ConnectionConfiguration
    let from: Int
    let to: Int
}


protocol ConnectionConfiguration: Codable {
    var path: String { get set }
}


// Each configuration has a unique ID

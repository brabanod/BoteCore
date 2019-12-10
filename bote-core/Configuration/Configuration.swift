//
//  Configuration.swift
//  bote-core
//
//  Created by Pascal Braband on 10.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import Foundation

struct Configuration {
    let from: ConnectionConfiguration
    let to: ConnectionConfiguration
}


protocol ConnectionConfiguration {
    var path: String { get }
}

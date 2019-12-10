//
//  SFTPConfiguration.swift
//  bote-core
//
//  Created by Pascal Braband on 10.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import Foundation

struct SFTPConfiguration: ConnectionConfiguration {
    var path: String
    var host: String
    var port: Int
    var user: String
    var password: String
}

// FIXME: Save username and password in keychain and save keychain id in SFTPConfiguration
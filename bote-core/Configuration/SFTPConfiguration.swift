//
//  SFTPConfiguration.swift
//  bote-core
//
//  Created by Pascal Braband on 10.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import Foundation

enum SFTPAuthentication {
    case password(keychainId: Int)
    case key(path: String)
}

struct SFTPConfiguration: ConnectionConfiguration {
    var path: String
    var host: String
    var port: Int
    var authentication: SFTPAuthentication
}

// FIXME: Save username and password in keychain and save keychain id in SFTPConfiguration
// TODO: Either supply user/password or path to SSH Key

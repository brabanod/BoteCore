//
//  TestsCommon.swift
//  bote-core
//
//  Created by Pascal Braband on 12.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import Foundation


let testsBasepath = "/private/tmp/bote-core-tests"


struct SFTPServer {
    static let host = "192.168.193"
    static let port: Int? = nil
    static let user = "pi"
    static let password = "mypi100"
    static let keypath = "/Users/pascal/.ssh/id_rsa.pub"
}

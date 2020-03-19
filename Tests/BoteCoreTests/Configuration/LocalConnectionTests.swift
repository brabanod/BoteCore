//
//  LocalConnectionTests.swift
//  bote-core-tests
//
//  Created by Pascal Braband on 19.03.20.
//  Copyright © 2020 Pascal Braband. All rights reserved.
//

import XCTest
@testable import BoteCore

class LocalConnectionTests: XCTestCase {

    override func setUp() {
    }

    override func tearDown() {
        do {
            try KeychainGuard.removeItem(user: SFTPServer.user, server: SFTPServer.host)
        } catch _ {
            print("NOTE: There was no keychain item to be deleted in tearDown.")
        }
    }
    
    func testIsEqualTo() throws {
        let a = LocalConnection(path: testsBasepath)
        let b = LocalConnection(path: testsBasepath)
        let c = LocalConnection(path: "other\(testsBasepath)")
        let d = try SFTPConnection(path: SFTPServer.path, host: SFTPServer.host, port: SFTPServer.port, user: SFTPServer.user, authentication: .password(value: SFTPServer.password))
        
        XCTAssertTrue(a.isEqual(to: b))
        XCTAssertTrue(b.isEqual(to: a))
        
        XCTAssertFalse(a.isEqual(to: c))
        XCTAssertFalse(c.isEqual(to: a))
        
        XCTAssertFalse(a.isEqual(to: d))
        XCTAssertFalse(b.isEqual(to: d))
        XCTAssertFalse(c.isEqual(to: d))
    }

}
    

//
//  SFTPSyncHandlerTests.swift
//  bote-core-tests
//
//  Created by Pascal Braband on 02.01.20.
//  Copyright © 2020 Pascal Braband. All rights reserved.
//

import XCTest

class SFTPSyncHandlerTests: XCTestCase {
    
    let fileA = testsBasepath + "/test_file_a"
    let fileB = testsBasepath + "/test_file_b"
    let dirA = testsBasepath + "/test_dir_a"
    
    let fileAA = testsBasepath + "/test_dir_a/test_file_aa"
    let fileAB = testsBasepath + "/test_dir_a/test_file_ab"
    let dirAA = testsBasepath + "/test_dir_a/test_dir_aa"
    
    let fileAAA = testsBasepath + "/test_dir_a/test_dir_aa/test_file_aaa"
    let fileAAB = testsBasepath + "/test_dir_a/test_dir_aa/test_file_aab"

    override func setUp() {
        createDir(at: testsBasepath)
        createFile(at: fileA)
        createFile(at: fileB)
        createDir(at: dirA)
        
        createFile(at: fileAA)
        createFile(at: fileAB)
        createDir(at: dirAA)
        
        createFile(at: fileAAA)
        createFile(at: fileAAB)
    }

    override func tearDown() {
        removeDir(at: testsBasepath)
        do {
            try KeychainGuard.removeItem(user: SFTPServer.user, server: SFTPServer.host)
        } catch _ {
            print("NOTE: There was no keychain item to be deleted in teadDown.")
        }
    }
    
    func testConnectWithKey() {
        XCTFail("Implement")
    }

    func testConnectWithPassword() {
        XCTFail("Implement")
    }
    
    func testUpload() throws {
        // Generate data
        let f = LocalConnection(path: testsBasepath)
        let t = try SFTPConnection(path: testsBasepath, host: SFTPServer.host, port: SFTPServer.port, user: SFTPServer.user, authentication: .password(value: SFTPServer.password))
        
        let syncHandler = SFTPSyncHandler.init(from: f, to: t)
        syncHandler.upload(path: dirA , isDir: true)
    }

}

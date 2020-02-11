//
//  IntegrationTests.swift
//  
//
//  Created by Pascal Braband on 23.01.20.
//

import XCTest
@testable import BoteCore

class IntegrationTests: XCTestCase {
    
    var defaultTransferHandler: SFTPTransferHandler?

    override func setUp() {
        // Create remote test directory
        do {
            let f = LocalConnection(path: testsBasepath)
            let t = try SFTPConnection(path: SFTPServer.path, host: SFTPServer.host, port: SFTPServer.port, user: SFTPServer.user, authentication: .password(value: SFTPServer.password))
            defaultTransferHandler = SFTPTransferHandler.init(from: f, to: t)
            try defaultTransferHandler?.upload(path: testsBasepath, isDir: true)
        } catch let error {
            if error is KeychainError {
                fatalError("Couldn't create SFTPConnection object.\nERROR: \(error)")
            } else {
                fatalError("Couldn't upload remote test directory at path \'\(SFTPServer.path)\'.\nERROR: \(error)")
            }
        }
    }
    
    override func tearDown() {
        // Remove keychain item
        do {
            try KeychainGuard.removeItem(user: SFTPServer.user, server: SFTPServer.host)
        } catch _ {
            print("NOTE: There was no keychain item to be deleted in tearDown.")
        }
        
        // Remove remote test directory
        do {
            try defaultTransferHandler?.remove(path: testsBasepath, isDir: true)
        } catch _ {
            print("NOTE: There was no remote test directory to be deleted in tearDown.")
        }
    }
    
    
    func testExample() throws {
        //let confs = ConfigurationManager.init(())
        let f = LocalConnection(path: testsBasepath)
        let t = try SFTPConnection(path: SFTPServer.path, host: SFTPServer.host, port: SFTPServer.port ?? 0, user: SFTPServer.user, authentication: .password(value: SFTPServer.password))
        
        let c = Configuration(from: f, to: t)
        let so = try SyncOrchestrator(configurations: [c]) { (item, error) in
            print("ERROR:\nItem: \(item)\nMessage: \(error)")
        }
        
        let ex = XCTestExpectation(description: "indef")
        wait(for: [ex], timeout: 10000)
    }

}

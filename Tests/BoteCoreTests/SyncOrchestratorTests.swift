//
//  SyncOrchestratorTests.swift
//  
//
//  Created by Pascal Braband on 23.01.20.
//

import XCTest
@testable import BoteCore

class SyncOrchestratorTests: XCTestCase {
    
    var defaultTransferHandler: SFTPTransferHandler?
    
//    override func setUp() {
//        // Create local test directory
//        createDir(at: testsBasepath)
//
//        // Create remote test directory
//        do {
//            let f = LocalConnection(path: testsBasepath)
//            let t = try SFTPConnection(path: SFTPServer.path, host: SFTPServer.host, port: SFTPServer.port, user: SFTPServer.user, authentication: .password(value: SFTPServer.password))
//            defaultTransferHandler = SFTPTransferHandler.init(from: f, to: t)
//            try defaultTransferHandler?.upload(path: testsBasepath, isDir: true)
//        } catch let error {
//            if error is KeychainError {
//                fatalError("Couldn't create SFTPConnection object.\nERROR: \(error)")
//            } else {
//                fatalError("Couldn't upload remote test directory at path \'\(SFTPServer.path)\'.\nERROR: \(error)")
//            }
//        }
//    }
//
//    override func tearDown() {
//        // Remove keychain item
//        do {
//            try KeychainGuard.removeItem(user: SFTPServer.user, server: SFTPServer.host)
//        } catch _ {
//            print("NOTE: There was no keychain item to be deleted in tearDown.")
//        }
//
//        // Remove local test directory
//        removeDir(at: testsBasepath)
//
//        // Remove remote test directory
//        do {
//            try defaultTransferHandler?.remove(path: testsBasepath, isDir: true)
//        } catch _ {
//            print("NOTE: There was no remote test directory to be deleted in tearDown.")
//        }
//    }
    
    // Tests if status is updated properly
    func testStatusUpdates() throws {
        let f = LocalConnection(path: testsBasepath)
        let t = try SFTPConnection(path: SFTPServer.path, host: SFTPServer.host, port: SFTPServer.port ?? 0, user: SFTPServer.user, authentication: .password(value: SFTPServer.password))
        
        let c = Configuration(from: f, to: t)
        let so = SyncOrchestrator()

        let expectLastStatus = XCTestExpectation(description: "Expecting the last status update.")
        let expectStatusProgress = XCTestExpectation(description: "Expecting the stateProgress array to be processed (empty) at the end.")
        var stateProgress: [SyncStatus] = [.inactive, .active, .active, .connected, .active, .inactive]
        
        // Register configuration
        let syncItem = try so.register(configuration: c)
        let syncSub = syncItem.$status.sink { (status) in
            // Test publisher
            print(status)
            XCTAssertEqual(stateProgress.first!, status)
            stateProgress.remove(at: 0)
            
            if stateProgress.count == 0 {
                expectStatusProgress.fulfill()
            }
        }
        XCTAssertEqual(syncItem.status, SyncStatus.inactive)
        
        // Start Sync
        try so.startSynchronizing(for: syncItem) { (item, error) in
            XCTFail("Failed to synchronize with error:\n \(error)")
        }
        
        // Start connection manual
        try (syncItem.transferHandler as! SFTPTransferHandler).connect()
        
        // Wait for connection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            XCTAssertEqual(syncItem.status, SyncStatus.connected)
            
            // Terminate connection
            (syncItem.transferHandler as! SFTPTransferHandler).terminate()
            XCTAssertEqual(syncItem.status, SyncStatus.active)
            
            // Stop sync
            so.stopSynchronizing(for: syncItem)
            XCTAssertEqual(syncItem.status, SyncStatus.inactive)
            
            expectLastStatus.fulfill()
        }
        
        wait(for: [expectLastStatus, expectStatusProgress], timeout: 1)
    }
    
    
    // Test if file are uploaded automatically
    func testFileUpload() throws {
        let f = LocalConnection(path: testsBasepath)
        let t = try SFTPConnection(path: SFTPServer.path, host: SFTPServer.host, port: SFTPServer.port ?? 0, user: SFTPServer.user, authentication: .password(value: SFTPServer.password))
        
        let c = Configuration(from: f, to: t)
        let so = SyncOrchestrator()
        
        // Register configuration
        let syncItem = try so.register(configuration: c)
        
        // Start Sync
        try so.startSynchronizing(for: syncItem) { (item, error) in
            XCTFail("Failed to synchronize with error:\n \(error)")
        }
        
        // Add files/dirs
        createFile(at: testsBasepath + #"/simpleFile"#)
        createFile(at: testsBasepath + #"/file\ with\ spaces.txt"#)
        createDir(at: testsBasepath + #"/dir\ with\ space"#)
        createFile(at: testsBasepath + #"/dir\ with\ space/fileInDir"#)
        
        let uploadExpectation = XCTestExpectation(description: "All local files should be uploaded to remote")
        
        // Check if added files/dirs are uploaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            do {
                XCTAssertTrue(try self.checkIfExists(path: SFTPServer.path + #"/simpleFile"#, isDir: false), "Failed for " + #"/simpleFile"#)
                XCTAssertTrue(try self.checkIfExists(path: SFTPServer.path + #"/file\ with\ spaces.txt"#, isDir: false), "Failed for " + #"/file\ with\ spaces.txt"#)
                XCTAssertTrue(try self.checkIfExists(path: SFTPServer.path + #"/dir\ with\ space"#, isDir: true), "Failed for " + #"/dir\ with\ space"#)
                XCTAssertTrue(try self.checkIfExists(path: SFTPServer.path + #"/dir\ with\ space/fileInDir"#, isDir: false), "Failed for " + #"/dir\ with\ space/fileInDir"#)
                uploadExpectation.fulfill()
            } catch _ { }
        }
        
        let removeExpectation = XCTestExpectation(description: "Specified files should be remove from remote")
        
        // Remove files/dirs
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            removeDir(at: testsBasepath + #"/dir\ with\ space"#)
            removeFile(at: testsBasepath + #"/file\ with\ spaces.txt"#)
        }
        
        // Check if removed files/dirs are removed remotely
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            do {
                XCTAssertTrue(try self.checkIfExists(path: SFTPServer.path + #"/simpleFile"#, isDir: false), "Failed for " + #"/simpleFile"#)
                XCTAssertTrue(try self.checkIfNotExists(path: SFTPServer.path + #"/file\ with\ spaces.txt"#, isDir: false), "Failed for " + #"/file\ with\ spaces.txt"#)
                XCTAssertTrue(try self.checkIfNotExists(path: SFTPServer.path + #"/dir\ with\ space"#, isDir: true), "Failed for " + #"/dir\ with\ space"#)
                XCTAssertTrue(try self.checkIfNotExists(path: SFTPServer.path + #"/dir\ with\ space/fileInDir"#, isDir: false), "Failed for " + #"/dir\ with\ space/fileInDir"#)
                removeExpectation.fulfill()
            } catch _ { }
        }
        
        wait(for: [uploadExpectation, removeExpectation], timeout: 2.0)
    }
    
    
    // Test register/startSync/stopSync/unregister SyncItem works
    func testManagingItems() throws {
        let f = LocalConnection(path: testsBasepath)
        let t = try SFTPConnection(path: SFTPServer.path, host: SFTPServer.host, port: SFTPServer.port ?? 0, user: SFTPServer.user, authentication: .password(value: SFTPServer.password))

        let c = Configuration(from: f, to: t)
        let so = SyncOrchestrator()

        // Register
        let syncItem = try so.register(configuration: c)
        XCTAssertEqual(so.syncItems.count, 1)
        XCTAssertEqual(so.syncItems.first?.configuration.id, syncItem.configuration.id)
        XCTAssertEqual(so.syncItems.first?.status, .inactive)
        XCTAssertEqual(syncItem.status, .inactive)

        // Start Sync
        try so.startSynchronizing(for: syncItem) { (item, error) in
            XCTFail("Failed to synchronize with error:\n \(error)")
        }
        XCTAssertEqual(so.syncItems.first?.status, .active)
        XCTAssertEqual(syncItem.status, .active)
        
        // Stop Sync
        so.stopSynchronizing(for: syncItem)
        XCTAssertEqual(so.syncItems.first?.status, .inactive)
        XCTAssertEqual(syncItem.status, .inactive)
        
        // Unregister
        so.unregister(configuration: syncItem.configuration)
        XCTAssertEqual(so.syncItems.count, 0)
    }
    
    
    // Test initializing with multiple configurations
    func testInitConfigurations() throws {
        let f1 = LocalConnection(path: "f1\(testsBasepath)")
        let t1 = try SFTPConnection(path: "t1\(testsBasepath)", host: "t1\(SFTPServer.host)", port: (SFTPServer.port ?? 0) + 1, user: "t1\(SFTPServer.user)", authentication: .key(path: "t1\(SFTPServer.keypath)"))
        
        let f2 = LocalConnection(path: "f2\(testsBasepath)")
        let t2 = try SFTPConnection(path: "t2\(testsBasepath)", host: "t2\(SFTPServer.host)", port: (SFTPServer.port ?? 0) + 2, user: "t2\(SFTPServer.user)", authentication: .key(path: "t2\(SFTPServer.keypath)"))
        
        let f3 = LocalConnection(path: "f3\(testsBasepath)")
        let t3 = try SFTPConnection(path: "t3\(testsBasepath)", host: "t3\(SFTPServer.host)", port: (SFTPServer.port ?? 0) + 3, user: "t3\(SFTPServer.user)", authentication: .key(path: "t3\(SFTPServer.keypath)"))
        
        let c1 = Configuration(from: f1, to: t1)
        let c2 = Configuration(from: f2, to: t2)
        let c3 = Configuration(from: f3, to: t3)
        
        // Init SyncOrchestrator with multiple Configurations
        let so = try SyncOrchestrator(configurations: [c1, c2, c3]) { (item, error) in
            XCTFail("Synchronizing failed with error \(error).")
        }
        
        XCTAssertEqual(so.syncItems.count, 3)
    }
    
    
    func testUpdateSyncItemConfiguration() throws {
        let f = LocalConnection(path: "f\(testsBasepath)")
        let t = try SFTPConnection(path: "t\(testsBasepath)", host: "t\(SFTPServer.host)", port: (SFTPServer.port ?? 0) + 1, user: "t\(SFTPServer.user)", authentication: .key(path: "t\(SFTPServer.keypath)"))
        
        let c = Configuration(from: f, to: t)
        
        let so = SyncOrchestrator()
        _ = try so.register(configuration: c)
        
        XCTAssertEqual((so.syncItems[0].configuration.from as! LocalConnection).path, f.path)
        XCTAssertEqual((so.syncItems[0].configuration.to as! SFTPConnection).path, t.path)
        XCTAssertEqual((so.syncItems[0].configuration.to as! SFTPConnection).host, t.host)
        XCTAssertEqual((so.syncItems[0].configuration.to as! SFTPConnection).port, t.port)
        XCTAssertEqual((so.syncItems[0].configuration.to as! SFTPConnection).user, t.user)
        XCTAssertEqual((so.syncItems[0].configuration.to as! SFTPConnection).authentication, t.authentication)
        
        let fNew = try SFTPConnection(path: "fn\(testsBasepath)", host: "fn\(SFTPServer.host)", port: (SFTPServer.port ?? 0) + 1, user: "fn\(SFTPServer.user)", authentication: .key(path: "fn\(SFTPServer.keypath)"))
        let cNew = Configuration(from: fNew, to: t)
        
        so.syncItems[0].configuration = cNew
        
        XCTAssertEqual((so.syncItems[0].configuration.from as! SFTPConnection).path, fNew.path)
        XCTAssertEqual((so.syncItems[0].configuration.from as! SFTPConnection).host, fNew.host)
        XCTAssertEqual((so.syncItems[0].configuration.from as! SFTPConnection).port, fNew.port)
        XCTAssertEqual((so.syncItems[0].configuration.from as! SFTPConnection).user, fNew.user)
        XCTAssertEqual((so.syncItems[0].configuration.from as! SFTPConnection).authentication, fNew.authentication)
        XCTAssertEqual((so.syncItems[0].configuration.to as! SFTPConnection).path, t.path)
        XCTAssertEqual((so.syncItems[0].configuration.to as! SFTPConnection).host, t.host)
        XCTAssertEqual((so.syncItems[0].configuration.to as! SFTPConnection).port, t.port)
        XCTAssertEqual((so.syncItems[0].configuration.to as! SFTPConnection).user, t.user)
        XCTAssertEqual((so.syncItems[0].configuration.to as! SFTPConnection).authentication, t.authentication)
    }
    
    
    // Test if lastSynced is set correctly
    // Test lastSynced Publisher
    func testLastSynced() throws {
        let f = LocalConnection(path: testsBasepath)
        let t = try SFTPConnection(path: SFTPServer.path, host: SFTPServer.host, port: SFTPServer.port ?? 0, user: SFTPServer.user, authentication: .password(value: SFTPServer.password))
        
        let c = Configuration(from: f, to: t)
        let so = SyncOrchestrator()
        
        // Register configuration
        let syncItem = try so.register(configuration: c)
        
        // Start Sync
        try so.startSynchronizing(for: syncItem) { (item, error) in
            XCTFail("Failed to synchronize with error:\n \(error)")
        }
        
        let dateExpectation = XCTestExpectation(description: "LastSynced date should be published")
        
        // Subscibe to lastSync Publisher
        let lastSyncedSub = syncItem.$lastSynced.sink { (lastSynced) in
            if let syncTime = lastSynced?.timeIntervalSince1970 {
                XCTAssertEqual(syncTime, Date().timeIntervalSince1970, accuracy: 1.0)
                dateExpectation.fulfill()
            }
        }
        
        // Add file
        createFile(at: testsBasepath + #"/simpleFile"#)
        
        wait(for: [dateExpectation], timeout: 1.0)
    }
    
    
    func testSyncStatusComparable() {
        XCTAssertTrue(SyncStatus.connected > SyncStatus.active)
        XCTAssertTrue(SyncStatus.connected > SyncStatus.failed)
        XCTAssertTrue(SyncStatus.connected > SyncStatus.inactive)
        
        XCTAssertTrue(SyncStatus.active > SyncStatus.failed)
        XCTAssertTrue(SyncStatus.active > SyncStatus.inactive)
        
        XCTAssertTrue(SyncStatus.failed > SyncStatus.inactive)
        
        XCTAssertFalse(SyncStatus.active > SyncStatus.connected)
        XCTAssertFalse(SyncStatus.failed > SyncStatus.connected)
        XCTAssertFalse(SyncStatus.inactive > SyncStatus.connected)
        
        XCTAssertFalse(SyncStatus.failed > SyncStatus.active)
        XCTAssertFalse(SyncStatus.inactive > SyncStatus.active)
        
        XCTAssertFalse(SyncStatus.inactive > SyncStatus.failed)
    }
    
    
    
    
    // MARK: - Helper Methods
    
    /**
     - returns:
     Checks if item (file or directory) exists on remote server and returns according boolean value.
     
     - parameters:
        - path: The path, on which to check if item exists.
        - isDir: A boolean value, indicating whether the item is a directory or not.
     */
    func checkIfExists(path: String, isDir: Bool) throws -> Bool {
        let ssh = defaultTransferHandler!.sshSession!
        let option = isDir ? "-d" : "-f"
        let (status, contents) = try ssh.capture("if test \(option) \(path); then echo \"exists\"; fi")
        if status == 0, contents.components(separatedBy: "\n")[0] == "exists" {
            return true
        } else {
            return false
        }
    }
    
    /**
     - returns:
     Checks if item (file or directory) doesn't exist on remote server and returns according boolean value.
     
     - parameters:
        - path: The path, on which to check if item exists.
        - isDir: A boolean value, indicating whether the item is a directory or not.
     */
    func checkIfNotExists(path: String, isDir: Bool) throws -> Bool {
        let ssh = defaultTransferHandler!.sshSession!
        let option = isDir ? "-d" : "-f"
        let (status, contents) = try ssh.capture("if test ! \(option) \(path); then echo \"removed\"; fi")
        if status == 0, contents.components(separatedBy: "\n")[0] == "removed" {
            return true
        } else {
            return false
        }
    }
    
}

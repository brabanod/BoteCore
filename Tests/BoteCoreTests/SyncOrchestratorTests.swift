//
//  SyncOrchestratorTests.swift
//  
//
//  Created by Pascal Braband on 23.01.20.
//

import XCTest
@testable import BoteCore

class SyncOrchestratorTests: XCTestCase {
    
    // Tests if status is updated properly
    func testStatusUpdates() throws {
        let f = LocalConnection(path: testsBasepath)
        let t = try SFTPConnection(path: SFTPServer.path, host: SFTPServer.host, port: SFTPServer.port ?? 0, user: SFTPServer.user, authentication: .password(value: SFTPServer.password))
        
        let c = Configuration(from: f, to: t)
        let so = SyncOrchestrator()

        let expectLastStatus = XCTestExpectation(description: "Expecting the last status update.")
        let expectStatusProgress = XCTestExpectation(description: "Expecting the stateProgress array to be processed (empty) at the end.")
        var stateProgress: [SyncStatus] = [.inactive, .active, .active, .connected, .active, .inactive]
        
        // Register
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
        
        // Start connection
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
    
    
    // TODO: Test if file are uploaded automatically
    func testFileUpload() {
        
    }
    
    
    // TODO: Test registering/startSync/stopSync/unregistering SyncItem works
    func testManagingItems() {
        
    }
    
    
    // TODO: Test initializing with multiple configurations
    func testInitConfigurations() {
        
    }
    
    
    // TODO: Test if lastSynced is set correctly
    // Also test if lastSynced is NOT set, when upload failed
    func testLastSynced() {
        
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
    
}

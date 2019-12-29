//
//  PreferencesManagerTests.swift
//  bote-core-tests
//
//  Created by Pascal Braband on 26.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import XCTest

class PreferencesManagerTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        PreferencesManager.removeAll()
    }

    func testSaveLoadSingle() throws {
        // Generate data
        let f = LocalConnection(path: testsBasepath)
        let t = try SFTPConnection(path: testsBasepath, host: SFTPServer.host, port: SFTPServer.port, user: SFTPServer.user, authentication: .key(path: SFTPServer.keypath))
        let conf = Configuration(from: f, to: t)
        
        // Save to UserDefaults
        try PreferencesManager.save(configuration: conf)
        
        // Load from UserDefaults
        guard let loadedConf = try PreferencesManager.load(for: conf.id) else { XCTFail("Failed to load configuration"); return }
        guard let loadedF = loadedConf.from as? LocalConnection else { XCTFail("Failed to load configuration.from"); return }
        guard let loadedT = loadedConf.to as? SFTPConnection else { XCTFail("Failed to load configuration.to"); return }
        
        XCTAssertEqual(loadedConf.fromType, ConnectionType.local)
        XCTAssertEqual(loadedConf.toType, ConnectionType.sftp)
        XCTAssertEqual(loadedConf.id, conf.id)
        
        XCTAssertEqual(loadedF.type, ConnectionType.local)
        XCTAssertEqual(loadedF.path, testsBasepath)
        
        XCTAssertEqual(loadedT.type, ConnectionType.sftp)
        XCTAssertEqual(loadedT.path, testsBasepath)
        XCTAssertEqual(loadedT.host, SFTPServer.host)
        XCTAssertEqual(loadedT.port, SFTPServer.port)
        XCTAssertEqual(loadedT.user, SFTPServer.user)
        XCTAssertEqual(loadedT.authentication, SFTPAuthentication.key(path: SFTPServer.keypath))
    }
    
    func testSaveLoadAll() throws {
        // Generate data
        let f1 = LocalConnection(path: "f1\(testsBasepath)")
        let t1 = try SFTPConnection(path: "t1\(testsBasepath)", host: "t1\(SFTPServer.host)", port: (SFTPServer.port ?? 0) + 1, user: "t1\(SFTPServer.user)", authentication: .key(path: "t1\(SFTPServer.keypath)"))
        
        let f2 = try SFTPConnection(path: "f2\(testsBasepath)", host: "f2\(SFTPServer.host)", port: (SFTPServer.port ?? 0) + 2, user: "f2\(SFTPServer.user)", authentication: .key(path: "f2\(SFTPServer.keypath)"))
        let t2 = try SFTPConnection(path: "t2\(testsBasepath)", host: "t2\(SFTPServer.host)", port: (SFTPServer.port ?? 0) + 3, user: "t2\(SFTPServer.user)", authentication: .key(path: "t2\(SFTPServer.keypath)"))
        
        let f3 = try SFTPConnection(path: "f3\(testsBasepath)", host: "f3\(SFTPServer.host)", port: (SFTPServer.port ?? 0) + 4, user: "f3\(SFTPServer.user)", authentication: .key(path: "f3\(SFTPServer.keypath)"))
        let t3 = LocalConnection(path: "t3\(testsBasepath)")
        
        let c1 = Configuration(from: f1, to: t1)
        let c2 = Configuration(from: f2, to: t2)
        let c3 = Configuration(from: f3, to: t3)
        
        // Save to user defaults
        try PreferencesManager.save(configurations: [c1, c2, c3])
        
        // Load from user defaults
        guard let loadedConfs = try PreferencesManager.loadAll() else { XCTFail("Failed to load all configurations from UserDefaults."); return}
        
        guard let loadedC1 = loadedConfs[c1.id] else { XCTFail("Failed to extract c1 from all configurations."); return }
        guard let loadedC2 = loadedConfs[c2.id] else { XCTFail("Failed to extract c2 from all configurations."); return }
        guard let loadedC3 = loadedConfs[c3.id] else { XCTFail("Failed to extract c3 from all configurations."); return }
        
        // Test c1
        guard let loadedC1F = loadedC1.from as? LocalConnection else { XCTFail("Failed to load configuration.from"); return }
        guard let loadedC1T = loadedC1.to as? SFTPConnection else { XCTFail("Failed to load configuration.to"); return }
        
        XCTAssertEqual(loadedC1.fromType, ConnectionType.local)
        XCTAssertEqual(loadedC1.toType, ConnectionType.sftp)
        XCTAssertEqual(loadedC1.id, c1.id)
        
        XCTAssertEqual(loadedC1F.type, ConnectionType.local)
        XCTAssertEqual(loadedC1F.path, "f1\(testsBasepath)")
        
        XCTAssertEqual(loadedC1T.type, ConnectionType.sftp)
        XCTAssertEqual(loadedC1T.path, "t1\(testsBasepath)")
        XCTAssertEqual(loadedC1T.host, "t1\(SFTPServer.host)")
        XCTAssertEqual(loadedC1T.port, (SFTPServer.port ?? 0) + 1)
        XCTAssertEqual(loadedC1T.user, "t1\(SFTPServer.user)")
        XCTAssertEqual(loadedC1T.authentication, SFTPAuthentication.key(path: "t1\(SFTPServer.keypath)"))
        
        // Test c2
        guard let loadedC2F = loadedC2.from as? SFTPConnection else { XCTFail("Failed to load configuration.from"); return }
        guard let loadedC2T = loadedC2.to as? SFTPConnection else { XCTFail("Failed to load configuration.to"); return }
        
        XCTAssertEqual(loadedC2.fromType, ConnectionType.sftp)
        XCTAssertEqual(loadedC2.toType, ConnectionType.sftp)
        XCTAssertEqual(loadedC2.id, c2.id)
        
        XCTAssertEqual(loadedC2F.type, ConnectionType.sftp)
        XCTAssertEqual(loadedC2F.path, "f2\(testsBasepath)")
        XCTAssertEqual(loadedC2F.host, "f2\(SFTPServer.host)")
        XCTAssertEqual(loadedC2F.port, (SFTPServer.port ?? 0) + 2)
        XCTAssertEqual(loadedC2F.user, "f2\(SFTPServer.user)")
        XCTAssertEqual(loadedC2F.authentication, SFTPAuthentication.key(path: "f2\(SFTPServer.keypath)"))
        
        XCTAssertEqual(loadedC2T.type, ConnectionType.sftp)
        XCTAssertEqual(loadedC2T.path, "t2\(testsBasepath)")
        XCTAssertEqual(loadedC2T.host, "t2\(SFTPServer.host)")
        XCTAssertEqual(loadedC2T.port, (SFTPServer.port ?? 0) + 3)
        XCTAssertEqual(loadedC2T.user, "t2\(SFTPServer.user)")
        XCTAssertEqual(loadedC2T.authentication, SFTPAuthentication.key(path: "t2\(SFTPServer.keypath)"))
        
        // Test c1
        guard let loadedC3F = loadedC3.from as? SFTPConnection else { XCTFail("Failed to load configuration.from"); return }
        guard let loadedC3T = loadedC3.to as? LocalConnection else { XCTFail("Failed to load configuration.to"); return }
        
        XCTAssertEqual(loadedC3.fromType, ConnectionType.sftp)
        XCTAssertEqual(loadedC3.toType, ConnectionType.local)
        XCTAssertEqual(loadedC3.id, c3.id)
        
        XCTAssertEqual(loadedC3F.type, ConnectionType.sftp)
        XCTAssertEqual(loadedC3F.path, "f3\(testsBasepath)")
        XCTAssertEqual(loadedC3F.host, "f3\(SFTPServer.host)")
        XCTAssertEqual(loadedC3F.port, (SFTPServer.port ?? 0) + 4)
        XCTAssertEqual(loadedC3F.user, "f3\(SFTPServer.user)")
        XCTAssertEqual(loadedC3F.authentication, SFTPAuthentication.key(path: "f3\(SFTPServer.keypath)"))
        
        XCTAssertEqual(loadedC3T.type, ConnectionType.local)
        XCTAssertEqual(loadedC3T.path, "t3\(testsBasepath)")
    }
    
    func testUpdate() throws {
        // Generate original data
        let fOld = LocalConnection(path: "fOld\(testsBasepath)")
        let tOld = try SFTPConnection(path: "tOld\(testsBasepath)", host: "tOld\(SFTPServer.host)", port: (SFTPServer.port ?? 0) + 1, user: "tOld\(SFTPServer.user)", authentication: .key(path: "tOld\(SFTPServer.keypath)"))
        let cOld = Configuration(from: fOld, to: tOld)
        
        // Save to UserDefaults
        try PreferencesManager.save(configuration: cOld)
        
        // Load configuration from UserDefaults
        guard var updateConf = try PreferencesManager.load(for: cOld.id) else { XCTFail("Failed to load configuration"); return }
        
        // Generate update data
        let fNew = try SFTPConnection(path: "fNew\(testsBasepath)", host: "fNew\(SFTPServer.host)", port: (SFTPServer.port ?? 0) + 2, user: "fNew\(SFTPServer.user)", authentication: .key(path: "fNew\(SFTPServer.keypath)"))
        let tNew = LocalConnection(path: "tNew\(testsBasepath)")
        
        // Update configuration
        updateConf.from = fNew
        updateConf.to = tNew
        
        // Save updated configuration to UserDefaults
        try PreferencesManager.save(configuration: updateConf)
        
        
        // Load from UserDefaults
        guard let loadedConf = try PreferencesManager.load(for: updateConf.id) else { XCTFail("Failed to load configuration"); return }
        guard let loadedF = loadedConf.from as? SFTPConnection else { XCTFail("Failed to load configuration.from"); return }
        guard let loadedT = loadedConf.to as? LocalConnection else { XCTFail("Failed to load configuration.to"); return }
        
        XCTAssertEqual(loadedConf.fromType, ConnectionType.sftp)
        XCTAssertEqual(loadedConf.toType, ConnectionType.local)
        XCTAssertEqual(loadedConf.id, updateConf.id)
        XCTAssertEqual(loadedConf.id, cOld.id)
        
        XCTAssertEqual(loadedF.type, ConnectionType.sftp)
        XCTAssertEqual(loadedF.path, "fNew\(testsBasepath)")
        XCTAssertEqual(loadedF.host, "fNew\(SFTPServer.host)")
        XCTAssertEqual(loadedF.port, (SFTPServer.port ?? 0) + 2)
        XCTAssertEqual(loadedF.user, "fNew\(SFTPServer.user)")
        XCTAssertEqual(loadedF.authentication, SFTPAuthentication.key(path: "fNew\(SFTPServer.keypath)"))
        
        XCTAssertEqual(loadedT.type, ConnectionType.local)
        XCTAssertEqual(loadedT.path, "tNew\(testsBasepath)")
    }
    
    func testRemove() throws {
        // Generate data
        let f1 = LocalConnection(path: "f1\(testsBasepath)")
        let t1 = try SFTPConnection(path: "t1\(testsBasepath)", host: "t1\(SFTPServer.host)", port: (SFTPServer.port ?? 0) + 1, user: "t1\(SFTPServer.user)", authentication: .key(path: "t1\(SFTPServer.keypath)"))
        
        let f2 = try SFTPConnection(path: "f2\(testsBasepath)", host: "f2\(SFTPServer.host)", port: (SFTPServer.port ?? 0) + 2, user: "f2\(SFTPServer.user)", authentication: .key(path: "f2\(SFTPServer.keypath)"))
        let t2 = try SFTPConnection(path: "t2\(testsBasepath)", host: "t2\(SFTPServer.host)", port: (SFTPServer.port ?? 0) + 3, user: "t2\(SFTPServer.user)", authentication: .key(path: "t2\(SFTPServer.keypath)"))
        
        let f3 = try SFTPConnection(path: "f3\(testsBasepath)", host: "f3\(SFTPServer.host)", port: (SFTPServer.port ?? 0) + 4, user: "f3\(SFTPServer.user)", authentication: .key(path: "f3\(SFTPServer.keypath)"))
        let t3 = LocalConnection(path: "t3\(testsBasepath)")
        
        let c1 = Configuration(from: f1, to: t1)
        let c2 = Configuration(from: f2, to: t2)
        let c3 = Configuration(from: f3, to: t3)
        
        // Save to user defaults
        try PreferencesManager.save(configurations: [c1, c2, c3])
        
        // Remove two configurations
        let countBeforeRemove = try PreferencesManager.loadAll()?.count
        PreferencesManager.remove(for: [c1.id, c3.id])
        guard let afterRemove = try PreferencesManager.loadAll() else { XCTFail("loadAll() was empty."); return }
        let countAfterRemove = afterRemove.count
        
        XCTAssertEqual(countBeforeRemove, 3)
        XCTAssertEqual(countAfterRemove, 1)
        
        guard let loadedConf = afterRemove[c2.id] else { XCTFail("Failed to load configuration"); return }
        guard let loadedF = loadedConf.from as? SFTPConnection else { XCTFail("Failed to load configuration.from"); return }
        guard let loadedT = loadedConf.to as? SFTPConnection else { XCTFail("Failed to load configuration.to"); return }
        
        XCTAssertEqual(loadedConf.fromType, ConnectionType.sftp)
        XCTAssertEqual(loadedConf.toType, ConnectionType.sftp)
        XCTAssertEqual(loadedConf.id, c2.id)
        
        XCTAssertEqual(loadedF.type, ConnectionType.sftp)
        XCTAssertEqual(loadedF.path, "f2\(testsBasepath)")
        XCTAssertEqual(loadedF.host, "f2\(SFTPServer.host)")
        XCTAssertEqual(loadedF.port, (SFTPServer.port ?? 0) + 2)
        XCTAssertEqual(loadedF.user, "f2\(SFTPServer.user)")
        XCTAssertEqual(loadedF.authentication, SFTPAuthentication.key(path: "f2\(SFTPServer.keypath)"))
        
        XCTAssertEqual(loadedT.type, ConnectionType.sftp)
        XCTAssertEqual(loadedT.path, "t2\(testsBasepath)")
        XCTAssertEqual(loadedT.host, "t2\(SFTPServer.host)")
        XCTAssertEqual(loadedT.port, (SFTPServer.port ?? 0) + 3)
        XCTAssertEqual(loadedT.user, "t2\(SFTPServer.user)")
        XCTAssertEqual(loadedT.authentication, SFTPAuthentication.key(path: "t2\(SFTPServer.keypath)"))
    }
    
    func testRemoveAll() throws {
        // Generate data
        let f1 = LocalConnection(path: "f1\(testsBasepath)")
        let t1 = try SFTPConnection(path: "t1\(testsBasepath)", host: "t1\(SFTPServer.host)", port: (SFTPServer.port ?? 0) + 1, user: "t1\(SFTPServer.user)", authentication: .key(path: "t1\(SFTPServer.keypath)"))
        
        let f2 = try SFTPConnection(path: "f2\(testsBasepath)", host: "f2\(SFTPServer.host)", port: (SFTPServer.port ?? 0) + 2, user: "f2\(SFTPServer.user)", authentication: .key(path: "f2\(SFTPServer.keypath)"))
        let t2 = try SFTPConnection(path: "t2\(testsBasepath)", host: "t2\(SFTPServer.host)", port: (SFTPServer.port ?? 0) + 3, user: "t2\(SFTPServer.user)", authentication: .key(path: "t2\(SFTPServer.keypath)"))
        
        let f3 = try SFTPConnection(path: "f3\(testsBasepath)", host: "f3\(SFTPServer.host)", port: (SFTPServer.port ?? 0) + 4, user: "f3\(SFTPServer.user)", authentication: .key(path: "f3\(SFTPServer.keypath)"))
        let t3 = LocalConnection(path: "t3\(testsBasepath)")
        
        let c1 = Configuration(from: f1, to: t1)
        let c2 = Configuration(from: f2, to: t2)
        let c3 = Configuration(from: f3, to: t3)
        
        // Save to user defaults
        try PreferencesManager.save(configurations: [c1, c2, c3])
        
        // Remove all configurations
        let countBeforeRemove = try PreferencesManager.loadAll()?.count
        PreferencesManager.removeAll()
        let countAfterRemove = try PreferencesManager.loadAll()?.count
        
        XCTAssertEqual(countBeforeRemove, 3)
        XCTAssertEqual(countAfterRemove, nil)
    }

}

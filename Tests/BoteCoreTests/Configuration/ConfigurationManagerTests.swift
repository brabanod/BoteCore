//
//  ConfigurationManagerTests.swift
//  bote-core-tests
//
//  Created by Pascal Braband on 29.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import XCTest
@testable import BoteCore

class ConfigurationManagerTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        PreferencesManager.removeAll()
        do {
            try KeychainGuard.removeItem(user: SFTPServer.user, server: SFTPServer.host)
            try KeychainGuard.removeItem(user: "n\(SFTPServer.user)", server: "n\(SFTPServer.host)")
        } catch _ {
            print("NOTE: There was no keychain item to be deleted in tearDown.")
        }
    }
    
    func testInitEmpty() throws {
        guard let cm = ConfigurationManager(()) else { XCTFail("Failed to initialize ConfigurationManager."); return }
        XCTAssertEqual(cm.configurations.count, 0)
    }
    
    func testInitPreLoaded() throws {
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
        
        guard let cm = ConfigurationManager(()) else { XCTFail("Failed to initialize ConfigurationManager."); return }
        XCTAssertEqual(cm.configurations.count, 3)
        
        let loadedConfs = cm.configurations
        
        var loadedC1: Configuration!
        var loadedC2: Configuration!
        var loadedC3: Configuration!
        for conf in loadedConfs {
            if conf.id == c1.id {
                loadedC1 = conf
            } else if conf.id == c2.id {
                loadedC2 = conf
            } else if conf.id == c3.id {
                loadedC3 = conf
            }
        }
        
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
        
        // Test c3
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

    func testAdd() throws {
        // Generate data
        let f = LocalConnection(path: testsBasepath)
        let t = try SFTPConnection(path: testsBasepath, host: SFTPServer.host, port: SFTPServer.port, user: SFTPServer.user, authentication: .key(path: SFTPServer.keypath))
        let conf = Configuration(from: f, to: t)
        
        // Add via Configuration Manager
        guard let cm = ConfigurationManager(()) else { XCTFail("Failed to initialize ConfigurationManager."); return }
        try cm.add(conf)
        
        XCTAssertEqual(cm.configurations.count, 1)
        
        // Check if configuration is the same as user defaults
        guard let all = try PreferencesManager.loadAll() else { XCTFail("Couldn't load from UserDefaults."); return }
        XCTAssertEqual(compare(dict: all, to: cm.configurations), true)
        
        // Load configuration and compare to data
        let loadedConf = cm.configurations[0]
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
    
    func testUpdate() throws {
        // Generate data
        let f = LocalConnection(path: testsBasepath)
        let t = try SFTPConnection(path: testsBasepath, host: SFTPServer.host, port: SFTPServer.port, user: SFTPServer.user, authentication: .key(path: SFTPServer.keypath))
        let conf = Configuration(from: f, to: t)
        
        // Add via Configuration Manager
        guard let cm = ConfigurationManager(()) else { XCTFail("Failed to initialize ConfigurationManager."); return }
        try cm.add(conf)
        
        // Create updated configuration
        var newConf = Configuration(from: LocalConnection(path: "new\(testsBasepath)"), to: try SFTPConnection(path: "neww\(testsBasepath)", host: SFTPServer.host, port: SFTPServer.port, user: "new\(SFTPServer.user)", authentication: .key(path: SFTPServer.keypath)))
        
        // Check before update
        let cmConfBeforePersist = cm.configurations[0]
        XCTAssertEqual(cmConfBeforePersist.id, conf.id)
        XCTAssertEqual(cmConfBeforePersist.from.path, testsBasepath)
        XCTAssertEqual((cmConfBeforePersist.to as! SFTPConnection).user, SFTPServer.user)
        XCTAssertEqual(cmConfBeforePersist.to.path, testsBasepath)
        
        guard let udConfBeforePersist = try PreferencesManager.load(for: conf.id) else { XCTFail("Couldn't load configuration from UserDefaults."); return }
        XCTAssertEqual(udConfBeforePersist.id, conf.id)
        XCTAssertEqual(udConfBeforePersist.from.path, testsBasepath)
        XCTAssertEqual((udConfBeforePersist.to as! SFTPConnection).user, SFTPServer.user)
        XCTAssertEqual(udConfBeforePersist.to.path, testsBasepath)
        
        // Update in UserDefaults
        try cm.update(&newConf, for: conf.id)
        
        // Check after update
        let cmConfAfterPersist = cm.configurations[0]
        XCTAssertEqual(cmConfAfterPersist.id, conf.id)
        XCTAssertEqual(cmConfAfterPersist.from.path, "new\(testsBasepath)")
        XCTAssertEqual((cmConfAfterPersist.to as! SFTPConnection).user, "new\(SFTPServer.user)")
        XCTAssertEqual(cmConfAfterPersist.to.path, "neww\(testsBasepath)")
        
        guard let udConfAfterPersist = try PreferencesManager.load(for: conf.id) else { XCTFail("Couldn't load configuration from UserDefaults."); return }
        XCTAssertEqual(udConfAfterPersist.id, conf.id)
        XCTAssertEqual(udConfAfterPersist.from.path, "new\(testsBasepath)")
        XCTAssertEqual((udConfAfterPersist.to as! SFTPConnection).user, "new\(SFTPServer.user)")
        XCTAssertEqual(udConfAfterPersist.to.path, "neww\(testsBasepath)")
    }
    
    func testUpdateWithReplacing() throws {
        // Instead of just chaning the configuration, override it with a new one
        // Generate data
        let f = LocalConnection(path: testsBasepath)
        let t = try SFTPConnection(path: testsBasepath, host: SFTPServer.host, port: SFTPServer.port, user: SFTPServer.user, authentication: .password(value: SFTPServer.password))
        let conf = Configuration(from: f, to: t)
        
        // Add via Configuration Manager
        guard let cm = ConfigurationManager(()) else { XCTFail("Failed to initialize ConfigurationManager."); return }
        try cm.add(conf)
        
        
        // Check before update
        let cmConfBeforePersist = cm.configurations[0]
        XCTAssertEqual(cmConfBeforePersist.id, conf.id)
        XCTAssertEqual(cmConfBeforePersist.from.path, testsBasepath)
        XCTAssertEqual((cmConfBeforePersist.to as! SFTPConnection).user, SFTPServer.user)
        XCTAssertEqual(cmConfBeforePersist.to.path, testsBasepath)
        
        guard let udConfBeforePersist = try PreferencesManager.load(for: conf.id) else { XCTFail("Couldn't load configuration from UserDefaults."); return }
        XCTAssertEqual(udConfBeforePersist.id, conf.id)
        XCTAssertEqual(udConfBeforePersist.from.path, testsBasepath)
        XCTAssertEqual((udConfBeforePersist.to as! SFTPConnection).user, SFTPServer.user)
        XCTAssertEqual(udConfBeforePersist.to.path, testsBasepath)
        
        // Check if correct keychain items are stored
        XCTAssertEqual(SFTPServer.password, try KeychainGuard.getItem(user: SFTPServer.user, server: SFTPServer.host))
        XCTAssertEqual(nil, try? KeychainGuard.getItem(user: "n\(SFTPServer.user)", server: "n\(SFTPServer.host)"))
        
        
        // Create updated Configuration to override
        let fNew = LocalConnection(path: "n\(testsBasepath)")
        let tNew = try SFTPConnection(path: "n\(testsBasepath)", host: "n\(SFTPServer.host)", port: SFTPServer.port, user: "n\(SFTPServer.user)", authentication: .password(value: "n\(SFTPServer.password)"))
        var confNew = Configuration(from: fNew, to: tNew)
        
        // Update in UserDefaults
        try cm.update(&confNew, for: conf.id)
        
        // Check after update
        let cmConfAfterPersist = cm.configurations[0]
        XCTAssertEqual(cmConfAfterPersist.id, conf.id)
        XCTAssertEqual(cmConfAfterPersist.from.path, "n\(testsBasepath)")
        XCTAssertEqual((cmConfAfterPersist.to as! SFTPConnection).user, "n\(SFTPServer.user)")
        XCTAssertEqual((cmConfAfterPersist.to as! SFTPConnection).host, "n\(SFTPServer.host)")
        XCTAssertEqual(cmConfAfterPersist.to.path, "n\(testsBasepath)")
        
        guard let udConfAfterPersist = try PreferencesManager.load(for: conf.id) else { XCTFail("Couldn't load configuration from UserDefaults."); return }
        XCTAssertEqual(udConfAfterPersist.id, conf.id)
        XCTAssertEqual(udConfAfterPersist.from.path, "n\(testsBasepath)")
        XCTAssertEqual((udConfAfterPersist.to as! SFTPConnection).user, "n\(SFTPServer.user)")
        XCTAssertEqual((udConfAfterPersist.to as! SFTPConnection).host, "n\(SFTPServer.host)")
        XCTAssertEqual(udConfAfterPersist.to.path, "n\(testsBasepath)")
        
        // Check if correct keychain items are stored
        // A new keychain item is stored and the old is kept
        // Thats updating a configuration this way should NOT happen
        XCTAssertEqual(SFTPServer.password, try? KeychainGuard.getItem(user: SFTPServer.user, server: SFTPServer.host))
        XCTAssertEqual("n\(SFTPServer.password)", try KeychainGuard.getItem(user: "n\(SFTPServer.user)", server: "n\(SFTPServer.host)"))
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
        
        // Add via Configuration Manager
        guard let cm = ConfigurationManager(()) else { XCTFail("Failed to initialize ConfigurationManager."); return }
        try cm.add(c1)
        try cm.add(c2)
        try cm.add(c3)
        
        XCTAssertEqual(cm.configurations.count, 3)
        
        // Remove one configuration
        try cm.remove(id: c2.id)
        
        XCTAssertEqual(cm.configurations.count, 2)
        XCTAssertEqual([cm.configurations[0].id, cm.configurations[1].id].sorted(), [c1.id, c3.id].sorted())
    }
    
    func testLoad() throws {
        // Implicitly tested in testInitPreLoaded()
    }
    
    func compare(dict: [String: Configuration], to array: [Configuration]) -> Bool {
        for (_, value) in dict {
            if array.contains(where: { (conf) -> Bool in
                return conf.id == value.id
                    && conf.fromType == value.fromType
                    && conf.toType == value.toType
                    && conf.from.path == value.from.path
                    && conf.to.path == value.to.path
            }) {
                continue
            } else {
                return false
            }
        }
        return true
    }
}

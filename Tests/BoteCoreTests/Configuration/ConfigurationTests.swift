//
//  ConfigurationTests.swift
//  bote-core-tests
//
//  Created by Pascal Braband on 23.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import XCTest
@testable import BoteCore

class ConfigurationTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testFromToType() throws {
        let a = LocalConnection(path: testsBasepath)
        let b = try SFTPConnection(path: testsBasepath, host: SFTPServer.host, port: SFTPServer.port, user: SFTPServer.user, authentication: .key(path: SFTPServer.keypath))
        
        let conf1 = Configuration(from: a, to: b)
        let conf2 = Configuration(from: b, to: a)
        
        XCTAssertEqual(conf1.fromType, ConnectionType.local)
        XCTAssertEqual(conf1.toType, ConnectionType.sftp)
        XCTAssertEqual(conf2.fromType, ConnectionType.sftp)
        XCTAssertEqual(conf2.toType, ConnectionType.local)
    }

    func testEncodeDecodeDifferentConnectionTypes() throws {
        let f = LocalConnection(path: testsBasepath)
        let t = try SFTPConnection(path: testsBasepath, host: SFTPServer.host, port: SFTPServer.port, user: SFTPServer.user, authentication: .key(path: SFTPServer.keypath))

        let conf = Configuration(from: f, to: t, name: "ConfNameDemo")
        
        let encodedConf = try PropertyListEncoder().encode(conf)
        let decodedConf = try PropertyListDecoder().decode(Configuration.self, from: encodedConf)

        let decodedF = decodedConf.from as! LocalConnection
        let decodedT = decodedConf.to as! SFTPConnection
        
        XCTAssertEqual(decodedConf.fromType, ConnectionType.local)
        XCTAssertEqual(decodedConf.toType, ConnectionType.sftp)
        XCTAssertEqual(decodedConf.id, conf.id)
        XCTAssertEqual(decodedConf.name, conf.name)
        
        XCTAssertEqual(decodedF.type, ConnectionType.local)
        XCTAssertEqual(decodedF.path, testsBasepath)
        
        XCTAssertEqual(decodedT.type, ConnectionType.sftp)
        XCTAssertEqual(decodedT.path, testsBasepath)
        XCTAssertEqual(decodedT.host, SFTPServer.host)
        XCTAssertEqual(decodedT.port, SFTPServer.port)
        XCTAssertEqual(decodedT.user, SFTPServer.user)
        XCTAssertEqual(decodedT.authentication, SFTPAuthentication.key(path: SFTPServer.keypath))
    }
    
    func testEncodeDecodeSameConnectionTypes() throws {
        let f = try SFTPConnection(path: "from\(testsBasepath)", host: "from\(SFTPServer.host)", port: (SFTPServer.port ?? 0) + 1, user: "from\(SFTPServer.user)", authentication: .key(path: "from\(SFTPServer.keypath)"))
        let t = try SFTPConnection(path: "to\(testsBasepath)", host: "to\(SFTPServer.host)", port: (SFTPServer.port ?? 0) + 2, user: "to\(SFTPServer.user)", authentication: .key(path: "to\(SFTPServer.keypath)"))

        let conf = Configuration(from: f, to: t, name: "ConfNameDemo")
        
        let encodedConf = try PropertyListEncoder().encode(conf)
        let decodedConf = try PropertyListDecoder().decode(Configuration.self, from: encodedConf)

        let decodedF = decodedConf.from as! SFTPConnection
        let decodedT = decodedConf.to as! SFTPConnection
        
        XCTAssertEqual(decodedConf.fromType, ConnectionType.sftp)
        XCTAssertEqual(decodedConf.toType, ConnectionType.sftp)
        XCTAssertEqual(decodedConf.id, conf.id)
        XCTAssertEqual(decodedConf.name, conf.name)
        
        XCTAssertEqual(decodedF.type, ConnectionType.sftp)
        XCTAssertEqual(decodedF.path, "from\(testsBasepath)")
        XCTAssertEqual(decodedF.host, "from\(SFTPServer.host)")
        XCTAssertEqual(decodedF.port, (SFTPServer.port ?? 0) + 1)
        XCTAssertEqual(decodedF.user, "from\(SFTPServer.user)")
        XCTAssertEqual(decodedF.authentication, SFTPAuthentication.key(path: "from\(SFTPServer.keypath)"))
        
        XCTAssertEqual(decodedT.type, ConnectionType.sftp)
        XCTAssertEqual(decodedT.path, "to\(testsBasepath)")
        XCTAssertEqual(decodedT.host, "to\(SFTPServer.host)")
        XCTAssertEqual(decodedT.port, (SFTPServer.port ?? 0) + 2)
        XCTAssertEqual(decodedT.user, "to\(SFTPServer.user)")
        XCTAssertEqual(decodedT.authentication, SFTPAuthentication.key(path: "to\(SFTPServer.keypath)"))
    }
    
    func testIdExplicit() throws {
        // Tests if id is explicit and always the same on one object
        // Already done in encoding/decoding tests
    }
    
    func testEquatable() throws {
        let f1 = LocalConnection(path: "f1\(testsBasepath)")
        let t1 = try SFTPConnection(path: "t1\(testsBasepath)", host: "t1\(SFTPServer.host)", port: (SFTPServer.port ?? 0) + 1, user: "t1\(SFTPServer.user)", authentication: .key(path: "t1\(SFTPServer.keypath)"))
        
        let f2 = try SFTPConnection(path: "f2\(testsBasepath)", host: "f2\(SFTPServer.host)", port: (SFTPServer.port ?? 0) + 2, user: "f2\(SFTPServer.user)", authentication: .key(path: "f2\(SFTPServer.keypath)"))
        let t2 = try SFTPConnection(path: "t2\(testsBasepath)", host: "t2\(SFTPServer.host)", port: (SFTPServer.port ?? 0) + 3, user: "t2\(SFTPServer.user)", authentication: .key(path: "t2\(SFTPServer.keypath)"))
        
        let base = Configuration(from: f1, to: t1, name: "nameA")
        let same = Configuration(from: f1, to: t1, name: "nameA")
        let otherName = Configuration(from: f1, to: t1, name: "nameB")
        let otherTo = Configuration(from: f1, to: t2, name: "nameA")
        let otherFrom = Configuration(from: f2, to: t1, name: "nameA")
        let other = Configuration(from: f2, to: t2, name: "nameA")
        
        XCTAssertTrue(base == same)
        XCTAssertTrue(same == base)
        XCTAssertFalse(base == otherName)
        XCTAssertFalse(base == otherTo)
        XCTAssertFalse(base == otherFrom)
        XCTAssertFalse(base == other)
    }
}

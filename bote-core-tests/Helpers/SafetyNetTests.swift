//
//  SafetyNetTests.swift
//  bote-core-tests
//
//  Created by Pascal Braband on 02.01.20.
//  Copyright © 2020 Pascal Braband. All rights reserved.
//

import XCTest

class SafetyNetTests: XCTestCase {
    
    let basePath = "test/path/for/safety/net"
    let basePathLess = "test/path/for/safety"
    let sf: SafetyNet = SafetyNet(basePath: "test/path/for/safety/net")

    override func setUp() {
        
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testBasePath() {
        // Test basePath itself
        let t = basePath
        do {
            try sf.intercept(path: t)
        } catch {
            XCTFail("intercept() should not fire.\nTested path: \(t)")
        }
    }
    
    func testBasePathWithInitializedSlash() {
        // Test basePath with initialized slash
        let newBasePath = "test/path/for/safety/net/"
        let sfTest = SafetyNet(basePath: newBasePath)
        let t = newBasePath + "some/path"
        do {
            try sfTest.intercept(path: t)
        } catch {
            XCTFail("intercept() should not fire.\nTested path: \(t)")
        }
    }
    
    func testBasePathWithAdditionalSlash() {
        // Test basePath with slash
        let t = basePath + "/"
        do {
            try sf.intercept(path: t)
        } catch {
            XCTFail("intercept() should not fire.\nTested path: \(t)")
        }
    }
    
    func testBasePathWithTwoAdditionalSlashes() {
        // Test basePath with two slashes
        let t = basePath + "//"
        do {
            try sf.intercept(path: t)
        } catch {
            XCTFail("intercept() should not fire.\nTested path: \(t)")
        }
    }
    
    func testBasePathParentDir() {
        // Test basePath on parent directory
        let t = basePathLess
        do {
            try sf.intercept(path: t)
            XCTFail("intercept() should fire.\nTested path: \(t)")
        } catch { }
    }
    
    func testBasePathPlusPathWithoutSlashInbetween() {
        // Test basePath with something after it, WITHOUT extra slash between them
        let t = basePath + "some/path/to/some/file"
        do {
            try sf.intercept(path: t)
            XCTFail("intercept() should fire.\nTested path: \(t)")
        } catch { }
    }
    
    func testBasePathPlusPathWithSlashInbetween() {
        // Test basePath with something after it, WITH extra slash between them
        let t = basePath + "/some/path/to/some/file"
        do {
            try sf.intercept(path: t)
        } catch {
            XCTFail("intercept() should not fire.\nTested path: \(t)")
        }
    }
    
    func testBasePathWithAccessingParentDirectory() {
        // Test basePath with a combination of ".." to access parent directory
        let t = basePath + "/some/../../../"
        do {
            try sf.intercept(path: t)
            XCTFail("intercept() should fire.\nTested path: \(t)")
        } catch { }
    }
}

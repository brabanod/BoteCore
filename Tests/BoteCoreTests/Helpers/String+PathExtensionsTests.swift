//
//  String+PathExtensionsTests.swift
//  bote-core-tests
//
//  Created by Pascal Braband on 02.01.20.
//  Copyright © 2020 Pascal Braband. All rights reserved.
//

import XCTest
@testable import BoteCore

class String_PathExtensionsTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDeletePrefix() {
        // delete ex1
        XCTAssertEqual("this/is/a/test/string".deletingPrefix("this/is/"), "a/test/string")
        
        // delete ex2
        XCTAssertEqual("hellomynameistest".deletingPrefix("hello"), "mynameistest")
        
        // delete same character
        XCTAssertEqual("aaaaaa".deletingPrefix("aa"), "aaaa")
        
        // delete repeating pattern
        XCTAssertEqual("testtesttest".deletingPrefix("test"), "testtest")
        
        // delete non existing characters
        XCTAssertEqual("testtesttest".deletingPrefix("some"), "testtesttest")
        
        // delete word, which is in word, but not as prefix
        XCTAssertEqual("hellomynameistest".deletingPrefix("myname"), "hellomynameistest")
        
        // delete non existing space
        XCTAssertEqual("testtesttest".deletingPrefix(" "), "testtesttest")
    }

    func testDeleteSuffix() {
        // delete ex1
        XCTAssertEqual("this/is/a/test/string".deletingSuffix("test/string"), "this/is/a/")
        
        // delete ex2
        XCTAssertEqual("hellomynameistest".deletingSuffix("istest"), "hellomyname")
        
        // delete same character
        XCTAssertEqual("aaaaaa".deletingSuffix("aa"), "aaaa")
        
        // delete repeating pattern
        XCTAssertEqual("testtesttest".deletingSuffix("test"), "testtest")
        
        // delete non existing characters
        XCTAssertEqual("testtesttest".deletingSuffix("some"), "testtesttest")
        
        // delete word, which is in word, but not as suffix
        XCTAssertEqual("hellomynameistest".deletingSuffix("hello"), "hellomynameistest")
        
        // delete non existing space
        XCTAssertEqual("testtesttest".deletingSuffix(" "), "testtesttest")
    }
    
    func testEscapeSpaces() {
        XCTAssertEqual("this is a test".escapeSpaces(), #"this\ is\ a\ test"#)
        XCTAssertEqual("this is".escapeSpaces(), #"this\ is"#)
    }
    
    func testDeleteReplacePath() {
        let localBasepath = "/local/base/path"
        let remoteBasepath = "/remote/some/foo"
        
        // replacement normal
        XCTAssertEqual("/local/base/path/with/extensions".replace(localBasePath: localBasepath, with: remoteBasepath), "/remote/some/foo/with/extensions")
        
        // replacement empty
        XCTAssertEqual(localBasepath.replace(localBasePath: localBasepath, with: remoteBasepath), remoteBasepath + "/")
        
        // replacement spaces
        XCTAssertEqual("/local/base/path/with/space extension".replace(localBasePath: localBasepath, with: remoteBasepath), #"/remote/some/foo/with/space\ extension"#)
    }
}

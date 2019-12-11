//
//  DirectoryCrawlerTests.swift
//  bote-core-tests
//
//  Created by Pascal Braband on 11.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import XCTest

class DirectoryCrawlerTests: XCTestCase {

    let testDir = testsBasepath + "/"

    override func setUp() {
        createDir(at: testDir)
    }

    override func tearDown() {
        removeDir(at: testDir)
    }

    func testCrawler() {
        
        /*
         testDir
         |__dirA
         |  |__dirAA
         |  |__dirAB
         |  |  |__fileABA
         |  |  |__fileABB
         |  |__fileAA
         |__dirB
         |  |__fileBA
         |  |__fileBB
         |  |__fileBC
         |__dirC
         |  |__dirCA
         |  |__fileCA
         |__fileA
         |__fileB
         */
        
        // Level 1, base: testDir/
        let dirA = testDir + "dirA"
        let dirB = testDir + "dirB"
        let dirC = testDir + "dirC"
        let fileA = testDir + "fileA"
        let fileB = testDir + "fileB"
        
        // Level 2A, base testDir/dirA
        let dirAA = dirA + "dirAA"
        let dirAB = dirA + "dirAB"
        let fileAA = dirA + "fileAA"
        
        // Level 2B, base testDir/dirB
        let fileBA = dirB + "fileBA"
        let fileBB = dirB + "fileBB"
        let fileBC = dirB + "fileBC"
        
        // Level 2C, base testDir/dirC
        let dirCA = dirC + "dirCA"
        let fileCA = dirC + "fileCA"
        
        // Level 3AB, base testDir/dirA/dirAB
        let fileABA = dirAB + "fileABA"
        let fileABB = dirAB + "fileABB"
        
        
        // Create files and dirs
        createDir(at: dirA)
        createDir(at: dirB)
        createDir(at: dirC)
        createFile(at: fileA)
        createFile(at: fileB)
        
        createDir(at: dirAA)
        createDir(at: dirAB)
        createFile(at: fileAA)
        
        createFile(at: fileBA)
        createFile(at: fileBB)
        createFile(at: fileBC)
        
        createDir(at: dirCA)
        createFile(at: fileCA)
        
        createFile(at: fileABA)
        createFile(at: fileABB)
        
        
        // Crawl
        let crawlResult = DirectoryCrawler.crawl(path: testDir)
        XCTAssertEqual(crawlResult.count, 15)
        
        XCTAssert(contains(crawlResult, (dirAA, true)))
        XCTAssert(contains(crawlResult, (dirAB, true)))
        XCTAssert(contains(crawlResult, (fileAA, false)))
        
        XCTAssert(contains(crawlResult, (fileBA, false)))
        XCTAssert(contains(crawlResult, (fileBB, false)))
        XCTAssert(contains(crawlResult, (fileBC, false)))
        
        XCTAssert(contains(crawlResult, (dirCA, true)))
        XCTAssert(contains(crawlResult, (fileCA, false)))
        
        XCTAssert(contains(crawlResult, (fileABA, false)))
        XCTAssert(contains(crawlResult, (fileABB, false)))
    }
    
    
    
    
    // MARK: - Helpers
    
    func contains(_ array:[(String, Bool)], _ value:(String, Bool)) -> Bool {
      let (c1, c2) = value
      for (v1, v2) in array { if v1 == c1 && v2 == c2 { return true } }
      return false
    }
}

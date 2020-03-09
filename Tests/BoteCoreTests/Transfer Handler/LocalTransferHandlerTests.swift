//
//  LocalTransferHandlerTests.swift
//  bote-core-tests
//
//  Created by Pascal Braband on 09.03.20.
//  Copyright © 2020 Pascal Braband. All rights reserved.
//

import XCTest
@testable import BoteCore
import Shout

class LocalTransferHandlerTests: XCTestCase {
    
    let fileA = testsBasepath + "/test_file_a"
    let fileB = testsBasepath + "/test_file_b"
    let dirA = testsBasepath + "/test_dir_a"
    let dirB = testsBasepath + "/test_dir_b"
    
    let fileAA = testsBasepath + "/test_dir_a/test_file_aa"
    let fileAB = testsBasepath + "/test_dir_a/test_file_ab"
    let dirAA = testsBasepath + "/test_dir_a/test_dir_aa"
    
    let fileAAA = testsBasepath + "/test_dir_a/test_dir_aa/test_file_aaa"
    let fileAAB = testsBasepath + "/test_dir_a/test_dir_aa/test_file_aab"
    
    var defaultTransferHandler: SFTPTransferHandler?

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
        
        // Create transfer test directory
        createDir(at: LocalServer.path)
    }

    override func tearDown() {
        // Remove local test directory
        removeDir(at: testsBasepath)
        
        // Remove remote test directory
        removeDir(at: LocalServer.path)
    }
    
    
    func testUpload() throws {
        let th = getTransferHandler()
        
        // Upload complete test directory
        let dirCrawl = DirectoryCrawler.crawl(path: testsBasepath)
        for (item, isDir) in dirCrawl {
            try th.upload(path: item, isDir: isDir)
        }
        
        // Check if everything was uploaded correctly
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: testsBasepath), isDir: true), "Failed for \(testsBasepath)")
        
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: fileA), isDir: false), "Failed for \(fileA)")
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: fileB), isDir: false), "Failed for \(fileB)")
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: dirA), isDir: true), "Failed for \(dirA)")
        
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: fileAA), isDir: false), "Failed for \(fileAA)")
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: fileAB), isDir: false), "Failed for \(fileAB)")
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: dirAA), isDir: true), "Failed for \(dirAA)")
        
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: fileAAA), isDir: false), "Failed for \(fileAAA)")
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: fileAAB), isDir: false), "Failed for \(fileAAB)")
    }
    
    func testUploadExistingDirectory() throws {
        let th = getTransferHandler()
        
        // Upload same directory twice
        do {
            try th.upload(path: dirA, isDir: true)
            try th.upload(path: dirA, isDir: true)
        } catch let error {
            XCTFail("Should not throw an error. Creating a directory which already exists should be prevented by upload() function. Failed with error: \(error)")
        }
        
        // Check if everything was uploaded correctly
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: testsBasepath), isDir: true), "Failed for \(testsBasepath)")
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: dirA), isDir: true), "Failed for \(dirA)")
    }
    
    func testOverrideExistingFile() throws {
        let th = getTransferHandler()
        
        // Write test string to file and upload
        let firstContent = "test_v1"
        try firstContent.write(to: URL(fileURLWithPath: fileA), atomically: true, encoding: .utf8)
        try th.upload(path: fileA, isDir: false)
        
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: testsBasepath), isDir: true), "Failed for \(testsBasepath)")
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: fileA), isDir: false), "Failed for \(fileA)")
        XCTAssertEqual(try getFileContents(for: fileA), firstContent)
        
        // Update file an reupload
        let secondContent = "test_v2"
        try secondContent.write(to: URL(fileURLWithPath: fileA), atomically: true, encoding: .utf8)
        do {
            try th.upload(path: fileA, isDir: false)
        } catch let error {
            XCTFail("Should not throw an error. Creating a directory which already exists should be prevented by upload() function. Failed with error: \(error)")
        }
        
        // Check if everything was updated correctly
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: testsBasepath), isDir: true), "Failed for \(testsBasepath)")
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: fileA), isDir: false), "Failed for \(fileA)")
        XCTAssertEqual(try getFileContents(for: fileA), secondContent)
    }
    
    func testRemoveFile() throws {
        let th = getTransferHandler()
        
        // Upload File
        try th.upload(path: fileA, isDir: false)
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: fileA), isDir: false), "Failed for \(fileA)")
        
        // Remove File
        try th.remove(path: fileA, isDir: false)
        XCTAssertTrue(try checkIfNotExists(path: getTransferPath(from: fileA), isDir: false), "Failed for \(fileA)")
    }
    
    func testRemoveDirectoryRecursive() throws {
        let th = getTransferHandler()
        
        // Upload complete test directory
        let dirCrawl = DirectoryCrawler.crawl(path: testsBasepath)
        for (item, isDir) in dirCrawl {
            try th.upload(path: item, isDir: isDir)
        }
        
        // Check if everything was uploaded correctly
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: testsBasepath), isDir: true), "Failed for \(testsBasepath)")
        
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: fileA), isDir: false), "Failed for \(fileA)")
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: fileB), isDir: false), "Failed for \(fileB)")
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: dirA), isDir: true), "Failed for \(dirA)")
        
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: fileAA), isDir: false), "Failed for \(fileAA)")
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: fileAB), isDir: false), "Failed for \(fileAB)")
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: dirAA), isDir: true), "Failed for \(dirAA)")
        
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: fileAAA), isDir: false), "Failed for \(fileAAA)")
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: fileAAB), isDir: false), "Failed for \(fileAAB)")
        
        // Remove everything
        try th.remove(path: testsBasepath, isDir: true)
        
        // Check if everything was removed
        XCTAssertTrue(try checkIfNotExists(path: getTransferPath(from: testsBasepath), isDir: true), "Failed for \(testsBasepath)")
    }
    
    func testRemoveNonExistingDirectory() throws {
        let th = getTransferHandler()
        
        // Try to remove non existing directory
        XCTAssertTrue(try checkIfNotExists(path: getTransferPath(from: dirA), isDir: true), "Failed for \(dirA)")
        try th.remove(path: dirA, isDir: true)
        XCTAssertTrue(try checkIfNotExists(path: getTransferPath(from: dirA), isDir: true), "Failed for \(dirA)")
    }
    
    func testRenameFile() throws {
        let th = getTransferHandler()
        
        // Upload File
        try th.upload(path: fileA, isDir: false)
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: fileA), isDir: false), "Failed for \(fileA)")
        
        // Rename File
        try th.rename(src: fileA, dst: fileB)
        XCTAssertTrue(try checkIfNotExists(path: getTransferPath(from: fileA), isDir: false), "Failed for \(fileA)")
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: fileB), isDir: false), "Failed for \(fileB)")
    }
    
    func testRenameDirectory() throws {
        let th = getTransferHandler()
        
        // Create Directory with contents
        try th.upload(path: dirA, isDir: true)
        try th.upload(path: fileAA, isDir: false)
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: dirA), isDir: true), "Failed for \(dirA)")
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: fileAA), isDir: false), "Failed for \(fileAA)")
        
        // Rename Directory
        try th.rename(src: dirA, dst: dirB)
        let newFileAA = fileAA.replace(localBasePath: dirA, with: dirB)
        XCTAssertTrue(try checkIfNotExists(path: getTransferPath(from: dirA), isDir: true), "Failed for \(dirA)")
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: dirB), isDir: true), "Failed for \(dirB)")
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: newFileAA), isDir: false), "Failed for \(newFileAA)")
    }
    
    func testMoveDirectory() throws {
        let th = getTransferHandler()
        
        // Create Directory with Sub-Directories
        try th.upload(path: dirA, isDir: true)
        try th.upload(path: dirAA, isDir: true)
        try th.upload(path: dirB, isDir: true)
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: dirA), isDir: true), "Failed for \(dirA)")
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: dirAA), isDir: true), "Failed for \(dirAA)")
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: dirB), isDir: true), "Failed for \(dirB)")
        
        // Rename Directory
        let newDirAA = dirAA.replace(localBasePath: dirA, with: dirB)
        try th.rename(src: dirAA, dst: newDirAA)
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: dirA), isDir: true), "Failed for \(dirA)")
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: dirB), isDir: true), "Failed for \(dirB)")
        XCTAssertTrue(try checkIfNotExists(path: getTransferPath(from: dirAA), isDir: true), "Failed for \(dirAA)")
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: newDirAA), isDir: true), "Failed for \(newDirAA)")
    }
    
    func testMoveFile() throws {
        createDir(at: dirB)
        let th = getTransferHandler()
        
        // Create Directory with Sub-Directories
        try th.upload(path: dirA, isDir: true)
        try th.upload(path: dirB, isDir: true)
        try th.upload(path: fileAA, isDir: false)
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: dirA), isDir: true), "Failed for \(dirA)")
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: dirB), isDir: true), "Failed for \(dirB)")
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: fileAA), isDir: false), "Failed for \(fileAA)")
        
        // Rename File
        let newFileAA = fileAA.replace(localBasePath: dirA, with: dirB)
        try th.rename(src: fileAA, dst: newFileAA)
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: dirA), isDir: true), "Failed for \(dirA)")
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: dirB), isDir: true), "Failed for \(dirB)")
        XCTAssertTrue(try checkIfNotExists(path: getTransferPath(from: fileAA), isDir: false), "Failed for \(fileAA)")
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: newFileAA), isDir: false), "Failed for \(newFileAA)")
    }
    
    func testReconnecting() throws {
        let th = getTransferHandler()
        
        // Should automallicaly reconnect after terminating the connection
        th.terminate()
        try th.upload(path: testsBasepath, isDir: true)
        try th.upload(path: fileA, isDir: false)
        
        XCTAssertTrue(try checkIfExists(path: getTransferPath(from: testsBasepath), isDir: true), "Failed for \(testsBasepath)")
            XCTAssertTrue(try checkIfExists(path: getTransferPath(from: fileA), isDir: false), "Failed for \(fileA)")
    }
    
    func testStatus() throws {
        let th = getTransferHandler()
        XCTAssertEqual(th.status, .disconnected)
        
        // Connect
        try th.connect()
        XCTAssertEqual(th.status, .connected)
        
        // Disconnect
        th.terminate()
        XCTAssertEqual(th.status, .disconnected)
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
        let option = isDir ? "-d" : "-f"
        let result = shell("if test \(option) \(path); then echo \"exists\"; fi")
        if result.components(separatedBy: "\n")[0] == "exists" {
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
        let option = isDir ? "-d" : "-f"
        let result = shell("if test ! \(option) \(path); then echo \"removed\"; fi")
        if result.components(separatedBy: "\n")[0] == "removed" {
            return true
        } else {
            return false
        }
    }
    

    /**
     - returns:
     The contents of a file on the transfer path.
     
     - parameters:
        - path: The path, for which the file contents should be read.
     */
    func getFileContents(for path: String) throws -> String {
        let transferPath = getTransferPath(from: path)
        return shell("cat \(path)")
    }

    
    /**
     - returns:
     Creates an instance of `SFTPTransferHandler` returns it
     */
    func getTransferHandler() -> LocalTransferHandler {
        // Create transfer handler
        do {
            let f = LocalConnection(path: testsBasepath)
            let t = LocalConnection(path: LocalServer.path)
            return try LocalTransferHandler(from: f, to: t)
        } catch let error {
            fatalError("Couldn't create LocalTransferHandler.\nERROR: \(error)")
        }
    }
    

    /**
     - returns:
     The tranfer path for a given local path.
     
     - parameters:
        - localPath: The path which should be transformed into the transfer path.
     */
    func getTransferPath(from localPath: String) -> String {
        localPath.replace(localBasePath: testsBasepath, with: LocalServer.path)
    }
}

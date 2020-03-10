//
//  SFTPTransferHandlerTests.swift
//  bote-core-tests
//
//  Created by Pascal Braband on 02.01.20.
//  Copyright © 2020 Pascal Braband. All rights reserved.
//

import XCTest
@testable import BoteCore
import Shout

class SFTPTransferHandlerTests: XCTestCase {
    
    let fileA = testsBasepath + "/test file a"
    let fileB = testsBasepath + "/test file b"
    let dirA = testsBasepath + "/test dir a"
    let dirB = testsBasepath + "/test dir b"
    
    let fileAA = testsBasepath + "/test dir a/test file aa"
    let fileAB = testsBasepath + "/test dir a/test file ab"
    let dirAA = testsBasepath + "/test dir a/test dir aa"
    
    let fileAAA = testsBasepath + "/test dir a/test dir aa/test file aaa"
    let fileAAB = testsBasepath + "/test dir a/test dir aa/test file aab"
    
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
        
        // Create remote test directory
        do {
            let f = LocalConnection(path: testsBasepath)
            let t = try SFTPConnection(path: SFTPServer.path, host: SFTPServer.host, port: SFTPServer.port, user: SFTPServer.user, authentication: .password(value: SFTPServer.password))
            defaultTransferHandler = try SFTPTransferHandler.init(from: f, to: t)
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
        // Remove local test directory
        removeDir(at: testsBasepath)
        
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
    
    func testConnectWithKey() throws {
        // Remove other connection, would lead to errors otherwise
        defaultTransferHandler?.terminate()
        defaultTransferHandler = nil
        
        // Create transfer handler with password
        let f = LocalConnection(path: testsBasepath)
        let t = try SFTPConnection(path: SFTPServer.path, host: SFTPServer.host, port: SFTPServer.port, user: SFTPServer.user, authentication: .key(path: "/Users/pascal/.ssh/id_rsa"))
        let sh = try SFTPTransferHandler.init(from: f, to: t)
        
        do {
            try sh.connect()
        } catch let error {
            XCTFail("Failed with message: \(String(describing: error.self))")
        }
    }

    func testConnectWithPassword() throws {
        // Create transfer handler with password
        let f = LocalConnection(path: testsBasepath)
        let t = try SFTPConnection(path: SFTPServer.path, host: SFTPServer.host, port: SFTPServer.port, user: SFTPServer.user, authentication: .password(value: SFTPServer.password))
        let sh = try SFTPTransferHandler.init(from: f, to: t)
        
        try sh.connect()
    }
    
    func testUpload() throws {
        let th = getTransferHandler()
        
        // Upload complete test directory
        let dirCrawl = DirectoryCrawler.crawl(path: testsBasepath)
        for (item, isDir) in dirCrawl {
            try th.upload(path: item, isDir: isDir)
        }
        
        // Check if everything was uploaded correctly
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: testsBasepath), isDir: true), "Failed for \(testsBasepath)")
        
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: fileA), isDir: false), "Failed for \(fileA)")
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: fileB), isDir: false), "Failed for \(fileB)")
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: dirA), isDir: true), "Failed for \(dirA)")
        
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: fileAA), isDir: false), "Failed for \(fileAA)")
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: fileAB), isDir: false), "Failed for \(fileAB)")
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: dirAA), isDir: true), "Failed for \(dirAA)")
        
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: fileAAA), isDir: false), "Failed for \(fileAAA)")
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: fileAAB), isDir: false), "Failed for \(fileAAB)")
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
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: testsBasepath), isDir: true), "Failed for \(testsBasepath)")
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: dirA), isDir: true), "Failed for \(dirA)")
    }
    
    func testOverrideExistingFile() throws {
        let th = getTransferHandler()
        
        // Write test string to file and upload
        let firstContent = "test_v1"
        try firstContent.write(to: URL(fileURLWithPath: fileA), atomically: true, encoding: .utf8)
        try th.upload(path: fileA, isDir: false)
        
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: testsBasepath), isDir: true), "Failed for \(testsBasepath)")
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: fileA), isDir: false), "Failed for \(fileA)")
        XCTAssertEqual(try getRemoteFileContents(for: fileA), firstContent)
        
        // Update file an reupload
        let secondContent = "test_v2"
        try secondContent.write(to: URL(fileURLWithPath: fileA), atomically: true, encoding: .utf8)
        do {
            try th.upload(path: fileA, isDir: false)
        } catch let error {
            XCTFail("Should not throw an error. Creating a directory which already exists should be prevented by upload() function. Failed with error: \(error)")
        }
        
        // Check if everything was updated correctly
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: testsBasepath), isDir: true), "Failed for \(testsBasepath)")
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: fileA), isDir: false), "Failed for \(fileA)")
        XCTAssertEqual(try getRemoteFileContents(for: fileA), secondContent)
    }
    
    func testRemoveFile() throws {
        let th = getTransferHandler()
        
        // Upload File
        try th.upload(path: fileA, isDir: false)
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: fileA), isDir: false), "Failed for \(fileA)")
        
        // Remove File
        try th.remove(path: fileA, isDir: false)
        XCTAssertTrue(try checkIfNotExists(path: getRemotePath(from: fileA), isDir: false), "Failed for \(fileA)")
    }
    
    func testRemoveDirectoryRecursive() throws {
        let th = getTransferHandler()
        
        // Upload complete test directory
        let dirCrawl = DirectoryCrawler.crawl(path: testsBasepath)
        for (item, isDir) in dirCrawl {
            try th.upload(path: item, isDir: isDir)
        }
        
        // Check if everything was uploaded correctly
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: testsBasepath), isDir: true), "Failed for \(testsBasepath)")
        
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: fileA), isDir: false), "Failed for \(fileA)")
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: fileB), isDir: false), "Failed for \(fileB)")
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: dirA), isDir: true), "Failed for \(dirA)")
        
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: fileAA), isDir: false), "Failed for \(fileAA)")
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: fileAB), isDir: false), "Failed for \(fileAB)")
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: dirAA), isDir: true), "Failed for \(dirAA)")
        
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: fileAAA), isDir: false), "Failed for \(fileAAA)")
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: fileAAB), isDir: false), "Failed for \(fileAAB)")
        
        // Remove everything
        try th.remove(path: testsBasepath, isDir: true)
        
        // Check if everything was removed
        XCTAssertTrue(try checkIfNotExists(path: getRemotePath(from: testsBasepath), isDir: true), "Failed for \(testsBasepath)")
    }
    
    func testRemoveNonExistingDirectory() throws {
        let th = getTransferHandler()
        
        // Try to remove non existing directory
        XCTAssertTrue(try checkIfNotExists(path: getRemotePath(from: dirA), isDir: true), "Failed for \(dirA)")
        try th.remove(path: dirA, isDir: true)
        XCTAssertTrue(try checkIfNotExists(path: getRemotePath(from: dirA), isDir: true), "Failed for \(dirA)")
    }
    
    func testRenameFile() throws {
        let th = getTransferHandler()
        
        // Upload File
        try th.upload(path: fileA, isDir: false)
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: fileA), isDir: false), "Failed for \(fileA)")
        
        // Rename File
        try th.rename(src: fileA, dst: fileB)
        XCTAssertTrue(try checkIfNotExists(path: getRemotePath(from: fileA), isDir: false), "Failed for \(fileA)")
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: fileB), isDir: false), "Failed for \(fileB)")
    }
    
    func testRenameDirectory() throws {
        let th = getTransferHandler()
        
        // Create Directory with contents
        try th.upload(path: dirA, isDir: true)
        try th.upload(path: fileAA, isDir: false)
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: dirA), isDir: true), "Failed for \(dirA)")
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: fileAA), isDir: false), "Failed for \(fileAA)")
        
        // Rename Directory
        try th.rename(src: dirA, dst: dirB)
        let newFileAA = fileAA.replace(localBasePath: dirA, with: dirB)
        XCTAssertTrue(try checkIfNotExists(path: getRemotePath(from: dirA), isDir: true), "Failed for \(dirA)")
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: dirB), isDir: true), "Failed for \(dirB)")
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: newFileAA), isDir: false), "Failed for \(newFileAA)")
    }
    
    func testMoveDirectory() throws {
        let th = getTransferHandler()
        
        // Create Directory with Sub-Directories
        try th.upload(path: dirA, isDir: true)
        try th.upload(path: dirAA, isDir: true)
        try th.upload(path: dirB, isDir: true)
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: dirA), isDir: true), "Failed for \(dirA)")
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: dirAA), isDir: true), "Failed for \(dirAA)")
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: dirB), isDir: true), "Failed for \(dirB)")
        
        // Rename Directory
        let newDirAA = dirAA.replace(localBasePath: dirA, with: dirB)
        try th.rename(src: dirAA, dst: newDirAA)
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: dirA), isDir: true), "Failed for \(dirA)")
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: dirB), isDir: true), "Failed for \(dirB)")
        XCTAssertTrue(try checkIfNotExists(path: getRemotePath(from: dirAA), isDir: true), "Failed for \(dirAA)")
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: newDirAA), isDir: true), "Failed for \(newDirAA)")
    }
    
    func testMoveFile() throws {
        let th = getTransferHandler()
        
        // Create Directory with Sub-Directories
        try th.upload(path: dirA, isDir: true)
        try th.upload(path: dirB, isDir: true)
        try th.upload(path: fileAA, isDir: false)
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: dirA), isDir: true), "Failed for \(dirA)")
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: dirB), isDir: true), "Failed for \(dirB)")
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: fileAA), isDir: false), "Failed for \(fileAA)")
        
        // Rename File
        let newFileAA = fileAA.replace(localBasePath: dirA, with: dirB)
        try th.rename(src: fileAA, dst: newFileAA)
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: dirA), isDir: true), "Failed for \(dirA)")
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: dirB), isDir: true), "Failed for \(dirB)")
        XCTAssertTrue(try checkIfNotExists(path: getRemotePath(from: fileAA), isDir: false), "Failed for \(fileAA)")
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: newFileAA), isDir: false), "Failed for \(newFileAA)")
    }
    
    func testReconnecting() throws {
        let th = getTransferHandler()
        
        // Should automallicaly reconnect after terminating the connection
        th.terminate()
        try th.upload(path: testsBasepath, isDir: true)
        try th.upload(path: fileA, isDir: false)
        
        XCTAssertTrue(try checkIfExists(path: getRemotePath(from: testsBasepath), isDir: true), "Failed for \(testsBasepath)")
            XCTAssertTrue(try checkIfExists(path: getRemotePath(from: fileA), isDir: false), "Failed for \(fileA)")
    }
    
    func testTimer() throws {
        let th = getTransferHandler()
        
        // Setup connectionTime and wait for it to fire
        th.setConnectionTime(seconds: 1)
        try th.connect()
        XCTAssertNotNil(th.sshSession)
        XCTAssertNotNil(th.sftpSession)
        
        let expectation = XCTestExpectation(description: "Transfer Handler connection should be terminated.")
        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
            if th.sshSession == nil, th.sftpSession == nil {
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 3.0)
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
        let ssh = defaultTransferHandler!.sshSession!
        let option = isDir ? "-d" : "-f"
        let (status, contents) = try ssh.capture("if test \(option) \(path.escapeSpaces()); then echo \"exists\"; fi")
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
        let (status, contents) = try ssh.capture("if test ! \(option) \(path.escapeSpaces()); then echo \"removed\"; fi")
        if status == 0, contents.components(separatedBy: "\n")[0] == "removed" {
            return true
        } else {
            return false
        }
    }
    
    /**
     - returns:
     The contents of a file on the SFTP server.
     
     - parameters:
        - path: The path, for which the file contents should be read.
     */
    func getRemoteFileContents(for path: String) throws -> String {
        let remotePath = getRemotePath(from: path)
        let ssh = defaultTransferHandler!.sshSession!
        let (_, contents) = try ssh.capture("cat \(remotePath.escapeSpaces())")
        return contents
    }
    
    /**
     - returns:
     Creates an instance of `SFTPTransferHandler` returns it
     */
    func getTransferHandler() -> SFTPTransferHandler {
        // Create transfer handler
        do {
            let f = LocalConnection(path: testsBasepath)
            let t = try SFTPConnection(path: SFTPServer.path, host: SFTPServer.host, port: SFTPServer.port, user: SFTPServer.user, authentication: .password(value: SFTPServer.password))
            return try SFTPTransferHandler.init(from: f, to: t)
        } catch let error {
            if error is KeychainError {
                fatalError("Couldn't create SFTPConnection object.\nERROR: \(error)")
            } else {
                fatalError("Couldn't upload remote test directory at path \'\(SFTPServer.path)\'.\nERROR: \(error)")
            }
        }
    }
    
    /**
     - returns:
     The remote path for a given local path.
     
     - parameters:
        - localPath: The path which should be transformed into the remote path.
     */
    func getRemotePath(from localPath: String) -> String {
        localPath.replace(localBasePath: testsBasepath, with: SFTPServer.path)
    }
}

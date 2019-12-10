//
//  LocalFileWatcherTests.swift
//  bote-core-tests
//
//  Created by Pascal Braband on 10.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import XCTest
import Combine

class LocalFileWatcherTests: XCTestCase {
    
    let filemanager = FileManager.default
    let watchPath = "/private/tmp/bote-core-tests"
    //let watchPath = "/Users/pascal/Desktop/watchDir"
    var subscriber: AnyCancellable?

    override func setUp() {
        createDir(at: watchPath)
    }

    override func tearDown() {
        removeDir(at: watchPath)
        subscriber?.cancel()
    }

    func testCreatedFile() {
        let filepath = watchPath + "/created_file_test"
        let expectation = XCTestExpectation(description: "Register \(FileEvent.createdFile(path: filepath).self)")
        
        subscriber = LocalFileWatcher.init(watchPath: watchPath).sink(receiveCompletion: { (completion) in
            switch completion {
            case .finished:
                XCTFail("Publisher unexpectedly finished.")
            case .failure(let error):
                XCTFail("Publisher unexpectedly failed. \(error)")
            }
        }) { (event: FileEvent) in
            print("##### EVENT: \(event)")
            if case .createdFile(path: let path) = event {
                XCTAssertEqual(filepath, path)
                expectation.fulfill()
            }
        }
        
        createFile(at: filepath)
        wait(for: [expectation], timeout: 1.0)
    }
    
    
    func testRemovedFile() {
        let filepath = watchPath + "/removed_file_test"
        let expectation = XCTestExpectation(description: "Register \(FileEvent.removedFile(path: filepath).self)")
        
        createFile(at: filepath)
        subscriber = LocalFileWatcher.init(watchPath: watchPath).sink(receiveCompletion: { (completion) in
            switch completion {
            case .finished:
                XCTFail("Publisher unexpectedly finished.")
            case .failure(let error):
                XCTFail("Publisher unexpectedly failed. \(error)")
            }
        }) { (event: FileEvent) in
            if case .removedFile(path: let path) = event {
                XCTAssertEqual(filepath, path)
                expectation.fulfill()
            } else {
                XCTFail("Event was of type \(event.self)")
            }
        }

        removeDir(at: filepath)
        wait(for: [expectation], timeout: 2.0)
    }
    
    
    func testCreatedDirectory() {
        let dirpath = watchPath + "/created_dir_test"
        let expectation = XCTestExpectation(description: "Register \(FileEvent.createdDir(path: dirpath).self)")
        subscriber = LocalFileWatcher.init(watchPath: watchPath).sink(receiveCompletion: { (completion) in
            switch completion {
            case .finished:
                XCTFail("Publisher unexpectedly finished.")
            case .failure(let error):
                XCTFail("Publisher unexpectedly failed. \(error)")
            }
        }) { (event: FileEvent) in
            if case .createdDir(path: let path) = event {
                XCTAssertEqual(dirpath, path)
                expectation.fulfill()
            } else {
                XCTFail("Event was of type \(event.self)")
            }
        }

        createDir(at: dirpath)
        wait(for: [expectation], timeout: 1.0)
    }

    
    func testRemovedDirectory() {
        let dirpath = watchPath + "/removed_dir_test"
        let expectation = XCTestExpectation(description: "Register \(FileEvent.removedDir(path: dirpath).self)")
        
        createDir(at: dirpath)
        subscriber = LocalFileWatcher.init(watchPath: watchPath).sink(receiveCompletion: { (completion) in
            switch completion {
            case .finished:
                XCTFail("Publisher unexpectedly finished.")
            case .failure(let error):
                XCTFail("Publisher unexpectedly failed. \(error)")
            }
        }) { (event: FileEvent) in
            if case .removedDir(path: let path) = event {
                XCTAssertEqual(dirpath, path)
                expectation.fulfill()
            } else {
                XCTFail("Event was of type \(event.self)")
            }
        }

        removeDir(at: dirpath)
        wait(for: [expectation], timeout: 1.0)
    }
    
    
    
    
    // MARK: - File Managment
    
    func createFile(at path: String) {
        filemanager.createFile(atPath: path, contents: nil, attributes: nil)
    }
    
    
    func removeFile(at path: String) {
        do {
            try filemanager.removeItem(atPath: path)
        } catch let error {
            XCTFail("Unexpectedly failed while removing test directory. \(error)")
        }
    }
    
    
    func createDir(at path: String) {
        do {
            try filemanager.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
        } catch let error {
            XCTFail("Unexpectedly failed while creating test directory. \(error)")
        }
    }
    
    
    func removeDir(at path: String) {
        do {
            try filemanager.removeItem(atPath: path)
        } catch let error {
            XCTFail("Unexpectedly failed while removing test directory. \(error)")
        }
    }
}

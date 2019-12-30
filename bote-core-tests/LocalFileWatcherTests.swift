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
    
    let watchPath = testsBasepath
    var subscriber: AnyCancellable?

    override func setUp() {
        createDir(at: watchPath)
    }

    override func tearDown() {
        removeDir(at: watchPath)
        subscriber?.cancel()
    }

    
    // Tests, if creating a file is registered correctly
    func testCreatedFile() {
        let filepath = watchPath + "/created_file_test"
        let expectation = XCTestExpectation(description: "Register \(FileEvent.createdFile(path: filepath).self)")
        
        subscriber = LocalFileWatcher.init(watchPath: watchPath).sink(receiveCompletion: { (completion) in
            self.checkCompletion(completion: completion)
        }) { (event: FileEvent) in
            if case .createdFile(path: let path) = event {
                if path == filepath {
                    expectation.fulfill()
                }
            }
        }
        
        createFile(at: filepath)
        wait(for: [expectation], timeout: 1.0)
    }
    
    
    // Tests, if removing a file is registered correctly
    func testRemovedFile() {
        let filepath = watchPath + "/removed_file_test"
        createFile(at: filepath)
        
        let expectation = XCTestExpectation(description: "Register \(FileEvent.removedFile(path: filepath).self)")
        
        subscriber = LocalFileWatcher.init(watchPath: watchPath).sink(receiveCompletion: { (completion) in
            self.checkCompletion(completion: completion)
        }) { (event: FileEvent) in
            if case .removedFile(path: let path) = event {
                if path == filepath {
                    expectation.fulfill()
                }
            } else {
                XCTFail("Event was of type \(event.self)")
            }
        }

        removeDir(at: filepath)
        wait(for: [expectation], timeout: 2.0)
    }
    
    
    // Tests, if creating a directory is registered correctly
    func testCreatedDirectory() {
        let dirpath = watchPath + "/created_dir_test"
        let expectation = XCTestExpectation(description: "Register \(FileEvent.createdDir(path: dirpath).self)")
        
        subscriber = LocalFileWatcher.init(watchPath: watchPath).sink(receiveCompletion: { (completion) in
            self.checkCompletion(completion: completion)
        }) { (event: FileEvent) in
            if case .createdDir(path: let path) = event {
                if dirpath == path {
                    expectation.fulfill()
                }
            } else {
                XCTFail("Event was of type \(event.self)")
            }
        }

        createDir(at: dirpath)
        wait(for: [expectation], timeout: 1.0)
    }

    
    // Tests, if removing a directory is registered correctly
    func testRemovedDirectory() {
        let dirpath = watchPath + "/removed_dir_test"
        createDir(at: dirpath)
        
        let expectation = XCTestExpectation(description: "Register \(FileEvent.removedDir(path: dirpath).self)")
        
        subscriber = LocalFileWatcher.init(watchPath: watchPath).sink(receiveCompletion: { (completion) in
            self.checkCompletion(completion: completion)
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
    
    
    // Tests, if renaming a file is registered correctly
    func testRenamedFile() {
        let srcFilepath = watchPath + "/rename_test_A"
        let dstFilepath = watchPath + "/rename_test_B"
        createFile(at: srcFilepath)
        
        let expectation = XCTestExpectation(description: "Register \(FileEvent.renamed(src: srcFilepath, dst: dstFilepath).self)")
        
        subscriber = LocalFileWatcher.init(watchPath: watchPath).sink(receiveCompletion: { (completion) in
            self.checkCompletion(completion: completion)
        }) { (event: FileEvent) in
            if case .renamed(src: let from, dst: let to) = event {
                XCTAssertEqual(from, srcFilepath)
                XCTAssertEqual(to, dstFilepath)
                expectation.fulfill()
            } else {
                XCTFail("Event was of type \(event.self)")
            }
        }
        
        moveItem(from: srcFilepath, to: dstFilepath)
        wait(for: [expectation], timeout: 1.0)
    }
    
    
    // Tests, if moving a file inside the watched folder is registered correctly
    func testMoveFileInsideWatchedFolder() {
        // Create subdir
        let watchPathSub = watchPath + "/move_test"
        createDir(at: watchPathSub)
        
        let srcFilepath = watchPath + "/move_test_file"
        let dstFilepath = watchPathSub + "/move_test_file"
        
        createFile(at: srcFilepath)
        
        let expectation = XCTestExpectation(description: "Register \(FileEvent.renamed(src: srcFilepath, dst: dstFilepath).self)")
        
        subscriber = LocalFileWatcher.init(watchPath: watchPathSub).sink(receiveCompletion: { (completion) in
            self.checkCompletion(completion: completion)
        }) { (event: FileEvent) in
            if case .createdFile(path: let path) = event {
                XCTAssertEqual(path, dstFilepath)
                expectation.fulfill()
            } else {
                XCTFail("Event was of type \(event.self)")
            }
        }
        
        moveItem(from: srcFilepath, to: dstFilepath)
        wait(for: [expectation], timeout: 1.0)
    }
    
    
    // Tests, if moving a directory inside the watched folder is registered correctly
    // Also tests if all files inside the folder are registered correctly (DirectoryCrawler)
    func testMoveDirectoryInsideWatchedFolder() {
        // Create subdir
        let watchPathSub = watchPath + "/move_test"
        createDir(at: watchPathSub)
        
        let srcFilepath = watchPath + "/move_test_dir"
        let dstFilepath = watchPathSub + "/move_test_dir"
        
        let fileA = "/a.txt"
        let fileB = "/b.txt"
        let fileC = "/c.txt"
        
        createDir(at: srcFilepath)
        createFile(at: srcFilepath + fileA)
        createFile(at: srcFilepath + fileB)
        createFile(at: srcFilepath + fileC)
        
        let expectation = XCTestExpectation(description: "Register \(FileEvent.renamed(src: srcFilepath, dst: dstFilepath).self)")
        
        var registeredEvents: [FileEvent] = []
        subscriber = LocalFileWatcher.init(watchPath: watchPathSub).sink(receiveCompletion: { (completion) in
            self.checkCompletion(completion: completion)
        }) { (event: FileEvent) in
            registeredEvents.append(event)
        }
        
        moveItem(from: srcFilepath, to: dstFilepath)
        
        // Check if all events were registered
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            if registeredEvents.contains(FileEvent.createdDir(path: dstFilepath))
                && registeredEvents.contains(FileEvent.createdFile(path: dstFilepath + fileA))
                && registeredEvents.contains(FileEvent.createdFile(path: dstFilepath + fileB))
                && registeredEvents.contains(FileEvent.createdFile(path: dstFilepath + fileC)) {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    
    // Tests, if moving a file outside the watched folder is registered correctly
    func testMoveFileOutsideWatchedFolder() {
        // Create subdir
        let watchPathSub = watchPath + "/move_test"
        createDir(at: watchPathSub)
        
        let srcFilepath = watchPathSub + "/move_test_file"
        let dstFilepath = watchPath + "/move_test_file"
        createFile(at: srcFilepath)
        
        let expectation = XCTestExpectation(description: "Register \(FileEvent.renamed(src: srcFilepath, dst: dstFilepath).self)")
        
        subscriber = LocalFileWatcher.init(watchPath: watchPathSub).sink(receiveCompletion: { (completion) in
            self.checkCompletion(completion: completion)
        }) { (event: FileEvent) in
            if case .removedFile(path: let path) = event {
                XCTAssertEqual(path, srcFilepath)
                expectation.fulfill()
            } else {
                XCTFail("Event was of type \(event.self)")
            }
        }
        
        moveItem(from: srcFilepath, to: dstFilepath)
        wait(for: [expectation], timeout: 1.0)
    }
    
    
    // Tests, if moving a directory outside the watched folder is registered correctly
    func testMoveDirectoryOutsideWatchedFolder() {
        // Create subdir
        let watchPathSub = watchPath + "/move_test"
        createDir(at: watchPathSub)
        
        let srcFilepath = watchPathSub + "/move_test_dir"
        let dstFilepath = watchPath + "/move_test_dir"
        createDir(at: srcFilepath)
        
        let expectation = XCTestExpectation(description: "Register \(FileEvent.renamed(src: srcFilepath, dst: dstFilepath).self)")
        
        subscriber = LocalFileWatcher.init(watchPath: watchPathSub).sink(receiveCompletion: { (completion) in
            self.checkCompletion(completion: completion)
        }) { (event: FileEvent) in
            if case .removedDir(path: let path) = event {
                XCTAssertEqual(path, srcFilepath)
                expectation.fulfill()
            } else {
                XCTFail("Event was of type \(event.self)")
            }
        }
        
        moveItem(from: srcFilepath, to: dstFilepath)
        wait(for: [expectation], timeout: 1.0)
    }
    
    
    
    
    // MARK: - Common
    func checkCompletion(completion: Subscribers.Completion<LocalFileWatcher.Failure>) {
        switch completion {
        case .finished:
            XCTFail("Publisher unexpectedly finished.")
        case .failure(let error):
            XCTFail("Publisher unexpectedly failed. \(error)")
        }
    }
}

//
//  LocalFileWatcherSubscription.swift
//  bote-core
//
//  Created by Pascal Braband on 10.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import Foundation
import Combine
import EonilFSEvents

enum FileWatcherError: Error {
    case watchFailed(String)
}

final class LocalFileWatcherSubscription<SubscriberType: Subscriber>: Subscription where SubscriberType.Input == FileEvent, SubscriberType.Failure == FileWatcherError {
    
    private var subscriber: SubscriberType?
    private let watchPath: String
    private let watchIdentifier: NSObject
    private var renameQueue: [String:String]
    
    init(subscriber: SubscriberType, watchPath: String) {
        self.subscriber = subscriber
        self.watchPath = watchPath
        self.watchIdentifier = NSObject()
        self.renameQueue = [:]
        
        // start watching folder
        do {
            try startWatching(eventHandler: { (event) in
                _ = subscriber.receive(event)
            })
        } catch let error {
            // Convert EonilFSEventsError to FileSystemWatcherError
            if let eventError = error as? EonilFSEventsError {
                var codeMessage = ""
                switch eventError.code {
                case .cannotCreateStream:
                    codeMessage = "Cannot create stream"
                case .cannotStartStream:
                    codeMessage = "Cannot start stream"
                }
                subscriber.receive(completion: .failure(FileWatcherError.watchFailed("Watching Failed. \(codeMessage). \(eventError.message ?? "No additional error message")")))
            } else {
                print("Watching Failed: \(error)")
            }
        }
    }
    
    
    func request(_ demand: Subscribers.Demand) {
    }
    
    
    func cancel() {
        subscriber = nil
        stopWatching()
    }
    
    
    
    
    // MARK: - File Watching
    
    
    /**
     Starts watching a directory on the file system.
     
     - parameters:
        - eventHandler: Gets called, when an event on the watched directory happened. Receives a FileEvent.
     */
    private func startWatching(eventHandler: @escaping (FileEvent) -> ()) throws {
        let handler = { (event: EonilFSEventsEvent) in
            self.process(event: event) { (processedEvent) in
                eventHandler(processedEvent)
            }
        }
        
        try EonilFSEvents.startWatching(
            paths: [watchPath],
            for: ObjectIdentifier(watchIdentifier),
            with: handler)
    }
    
    
    /**
     Stops watching a directory on the file system.
     */
    private func stopWatching() {
        EonilFSEvents.stopWatching(for: ObjectIdentifier(watchIdentifier))
    }
    
    
    /**
     Converts an file system event into a more usable FileEvent.
     
     - parameters:
        - event: The raw file system event
        - completion: Gets called, when processing of the raw event finished. Receives a FileEvent.
     
     The function that handles .itemRename can be exposed to 3 situations:
     1. Move files within watched folder/Normal rename:
        - **Observation**: 2 FS Events: old filename, new filename
        - **Event**: renamed
     2. Move file from watched folder to outside:
        - **Observation**: 1 FS Event: old filename
        - **Event**: removed
     3. Move file from outside to watched folder:
        - **Observation**: 1 FS Event: new filename
        - **Event**: created
     */
    private func process(event: EonilFSEventsEvent, completion: @escaping (FileEvent) -> ()) {
        let filepath = event.path
        if let flags = event.flag {
            
            // Item RENAMED
            if flags.contains(.itemRenamed) {
                
                if FileManager.default.fileExists(atPath: filepath) {
                    if renameQueue.count > 0, let sourceFile = renameQueue.popFirst()?.value {
                        // Renamed, if file exists and there is a file path in the renameQueue
                        completion(.renamed(src: sourceFile, dst: filepath))
                    } else {
                        // Created (moved into folder), if file exists and there is no (old) file path in the renameQueue
                        // Distinguish between dir and file
                        if isDir(flags: flags) {
                            completion(.createdDir(path: filepath))
                            // Crawl through directory, to catch the other new files, that were moved into folder
                            crawl(path: filepath, completion: completion)
                            
                        } else {
                            completion(.createdFile(path: filepath))
                        }
                    }
                } else {
                    // Save filepath to renameQueue with unique id (uuid)
                    let queueID = NSUUID().uuidString
                    renameQueue[queueID] = filepath
                    
                    // After 200ms, check if item still in renameQueue
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.02) {
                        if self.renameQueue[queueID] != nil {
                            // If yes, then no one removed it from renameQueue -> no rename -> moved out of folder -> removed
                            self.renameQueue.removeValue(forKey: queueID)
                            // Distinguish between dir and file
                            if self.isDir(flags: flags) {
                                completion(.removedDir(path: filepath))
                            } else {
                                completion(.removedFile(path: filepath))
                            }
                        }
                    }
                }
            }
                
            // Item REMOVED
            else if flags.contains(.itemRemoved) {
                if isDir(flags: flags) {
                    completion(.removedDir(path: filepath))
                } else {
                    completion(.removedFile(path: filepath))
                }
            }
                
            // Item CREATED or MODIFIED
            else if flags.contains(.itemCreated) || flags.contains(.itemModified) {
                if isDir(flags: flags) {
                    completion(.createdDir(path: filepath))
                } else {
                    completion(.createdFile(path: filepath))
                }
            }
        }
    }
    
    
    /**
     Checks whether the given flags indicate a file or directory.
     
     - returns:
     A bollean value, indicating if item is a directory or not.
     
     - parameters:
        - flags: The flags, which should be processed in the decission.
     */
    private func isDir(flags: EonilFSEventsEventFlags) -> Bool {
        if flags.contains(.itemIsDir) {
            return true
        } else {
            // itemIsFile, itemIsSymlink, itemIsHardlink or itemIsLastHardlink
            return false
        }
    }
    
    
    /**
     Crawls through a given directory and evaluates it's content.
     
     - parameters:
        - path: The directory, thorugh which should be crawled.
        - completion: The completion which gets called for every item that is found in the directory.
     */
    private func crawl(path: String, completion: @escaping (FileEvent) -> ()) {
        for item in DirectoryCrawler.crawl(path: path) {
            let path = item.0
            let isDir = item.1
            if isDir {
                completion(.createdDir(path: path))
            } else {
                completion(.createdFile(path: path))
            }
        }
    }
    
}




// .itemRenamed logic ...
// File exists?
//    yes -> check if any file is in Queue
//       yes -> rename file, source: Queue, dest: filename
//       no -> upload file
//    no -> add filepath to queue with unique id
//       -  start timer (200 ms)
//             finished -> is element with id still in queue?
//                yes -> delete file
//                no -> do nothing


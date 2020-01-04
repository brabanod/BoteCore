//
//  SyncOrchestrator.swift
//  bote-core
//
//  Created by Pascal Braband on 10.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import Foundation
import Combine

struct SyncItem {
    let configuration: Configuration
    let fileWatcher: FileWatcher
    let fileWatcherSubscription: AnyCancellable
    let syncHandler: SyncHandler
    var id: String { return self.configuration.id }
}

enum SyncOrchestratorError: Error {
    case SyncHandlerInitFailure(String)
    case FileWatcherInitFailure(String)
}

enum SyncStatus {
    case connected, active, failed, inactive
}

class SyncOrchestrator {
    
    var configurations: [SyncItem]
    
    init(configurations: [Configuration]) throws {
        self.configurations = [SyncItem]()
        for configuration in configurations {
            try startSynchronizing(with: configuration)
        }
    }
    
    
    /**
     Starts synchronization for a given configuration. Adds the resulting `SyncItem` to the `configurations` property.
     
     - parameters:
        - configuration: The configuration, for which a synchronization should be started.
     */
    public func startSynchronizing(with configuration: Configuration) throws {
        // Setup synchronizing with the given configuration
        
        // Setup SyncHandler for configuration.to
        guard let syncHandler: SyncHandler = SyncHandlerOrganizer.getSyncHandler(for: configuration) else { throw SyncOrchestratorError.SyncHandlerInitFailure("Initialization of SyncHandler failed and returned nil. Unsupported Connection type possible.")}
        
        // Setup FileWatcher for configuration.from (user SyncHandler in receive from Publisher)
        guard let fileWatcher = FileWatcherOrganizer.getFileWatcher(for: configuration.from) else { throw SyncOrchestratorError.FileWatcherInitFailure("Initialization of FileWatcher failed. and returned nil. Unsupported Connection type possible.")}
        let fileWatcherSubscription = fileWatcher.sink(receiveCompletion: { (completion) in
            switch completion {
            case .finished:
                print("Finished watching")
            case .failure(let error):
                print("Error watching: \(error)")
            }
        }) { (event) in
            print(event)
        }
        
        // Save both in a data structure
        configurations.append(SyncItem(configuration: configuration, fileWatcher: fileWatcher, fileWatcherSubscription: fileWatcherSubscription, syncHandler: syncHandler))
    }
    
    
    /**
     Stops the synchronization for an item.
     
     - parameters:
        - item: The `SyncItem` for which the synchronization should be stopped.
     */
    public func stopSynchronizing(for item: SyncItem) {
        
    }
    // alternative
    // func stopSynchronizing(for id: String) { }
}

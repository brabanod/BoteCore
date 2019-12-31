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
//    let fileWatcherSubscription: AnyCancellable
//    let syncHandler: SyncHandler
    var id: String { return self.configuration.id }
}

class SyncOrchestrator {
    
    var configurations: [SyncItem]
    
    init(configurations: [Configuration]) {
        self.configurations = [SyncItem]()
        for configuration in configurations {
            startSynchronizing(with: configuration)
        }
    }
    
    
    /**
     Starts synchronization for a given configuration. Adds the resulting `SyncItem` to the `configurations` property.
     
     - parameters:
        - configuration: The configuration, for which a synchronization should be started.
     */
    func startSynchronizing(with configuration: Configuration) {
        // Setup synchronizing with the given configuration
        
        // Setup SyncHandler for configuration.to
        //let syncHandler: SyncHandler = SyncHandlerOrganizer.get(for: configuration) --> gives corresponding sync handler for protocol (e.g. SFTPSyncHandler instance)
        
        // Setup FileWatcher for configuration.from (user SyncHandler in receive from Publisher)
        let fileWatcher = FileWatcherOrganizer.getFileManager(for: configuration.from)
        // let fileWatcherSubscription: AnyCancelable = watcher.sink(receiveCompletion: {...}) {...}
        
        // Save both in a data structure
        configurations.append(SyncItem(configuration: configuration, fileWatcher: fileWatcher))
    }
    
    
    /**
     Stops the synchronization for an item.
     
     - parameters:
        - item: The `SyncItem` for which the synchronization should be stopped.
     */
    func stopSynchronizing(for item: SyncItem) {
        
    }
    // alternative
    // func stopSynchronizing(for id: String) { }
}

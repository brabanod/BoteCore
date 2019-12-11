//
//  SyncOrchestrator.swift
//  bote-core
//
//  Created by Pascal Braband on 10.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import Foundation

struct SyncItem {
    let configuration: Configuration
    let fileWatcher: FileWatcher
//    let syncHandler: SyncHandler
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
     Starts synchronization for a given configuration.
     
     - parameters:
        - configuration: The configuration, for which a synchronization should be started.
     */
    func startSynchronizing(with configuration: Configuration) {
        let localWatcher = LocalFileWatcher.init(watchPath: "path/")
        let watcher = FileWatcher.local(watcher: localWatcher)
        //let syncHandler = SFTPSyncHandler()
        configurations.append(SyncItem(configuration: configuration, fileWatcher: watcher))
        
        // Setup synchronizing with the given configuration
        // Setup FileWatcher for configuration.from
        // Setup SyncHandler for configuration.to
        // Save both in a data structure
    }
}

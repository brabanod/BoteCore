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
        // let remoteWatcher = RemoteFileWatcher.get(for: configuration, watchPath: "/") --> gives corresponding file watcher for protocol (e.g. SFTPFileWatcher instance)
        let watcher = FileWatcher.local(watcher: localWatcher)
        //let syncHandler: SyncHandler = SyncHandlerOrganizer.get(for: configuration) --> gives corresponding sync handler for protocol (e.g. SFTPSyncHandler instance)
        configurations.append(SyncItem(configuration: configuration, fileWatcher: watcher))
        
        // Setup synchronizing with the given configuration
        // Setup FileWatcher for configuration.from
        // Setup SyncHandler for configuration.to
        // Save both in a data structure
        
        //let a = try SFTPConfiguration(path: "a", host: "s", port: nil, authentication: .key(path: "asd"), user: "pi", password: "")
        //let path = a.authentication
    }
}

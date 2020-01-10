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
    let transferHandler: TransferHandler
    var id: String { return self.configuration.id }
}

enum SyncOrchestratorError: Error {
    case TransferHandlerInitFailure(String)
    case FileWatcherInitFailure(String)
    case ConfigurationDuplicate
}

enum SyncStatus {
    case connected, active, failed, inactive
}

class SyncOrchestrator {
    
    var configurations: [SyncItem]
    
    init(configurations: [Configuration], errorHandler: @escaping(Configuration, Error) -> ()) throws {
        self.configurations = [SyncItem]()
        for configuration in configurations {
            try startSynchronizing(with: configuration, errorHandler: errorHandler)
        }
    }
    
    
    /**
     Starts synchronization for a given configuration. Adds the resulting `SyncItem` to the `configurations` property.
     
     - parameters:
        - configuration: The configuration, for which a synchronization should be started.
     */
    public func startSynchronizing(with configuration: Configuration, errorHandler: @escaping (Configuration, Error) -> ()) throws {
        // Only ONE SyncItem per Configuration is allowed. Check if SyncItem already exists for this Configuration
        if existsSyncItem(for: configuration) {
            throw SyncOrchestratorError.ConfigurationDuplicate
        }
        
        // Setup synchronizing with the given configuration
        
        // Setup TransferHandler for configuration.to
        guard let transferHandler: TransferHandler = TransferHandlerOrganizer.getTransferHandler(for: configuration)
            else { throw SyncOrchestratorError.TransferHandlerInitFailure("Initialization of TransferHandler failed and returned nil. Unsupported Connection type possible.") }
        
        // Setup FileWatcher for configuration.from (use TransferHandler in receive from Publisher)
        guard let fileWatcher = FileWatcherOrganizer.getFileWatcher(for: configuration.from)
            else { throw SyncOrchestratorError.FileWatcherInitFailure("Initialization of FileWatcher failed. and returned nil. Unsupported Connection type possible.") }
        let fileWatcherSubscription = fileWatcher.sink(receiveCompletion: { (completion) in
            switch completion {
            case .finished:
                print("Finished watching")
                let error = FileWatcherError.watchFailed("File watcher unexpectedly finished publishing file events.")
                errorHandler(configuration, error)
            case .failure(let error):
                print("Error watching: \(error)")
                errorHandler(configuration, error)
            }
        }) { (event) in
            // call transferHandler method for given events
            do {
                switch event {
                case .createdFile(path: let path):
                    try transferHandler.upload(path: path, isDir: false)
                case .createdDir(path: let path):
                    try transferHandler.upload(path: path, isDir: true)
                case .renamed(src: let from, dst: let to):
                    try transferHandler.rename(src: from, dst: to)
                case .removedFile(path: let path):
                    try transferHandler.remove(path: path, isDir: false)
                case .removedDir(path: let path):
                    try transferHandler.remove(path: path, isDir: true)
                }
            } catch let error {
                // submit error to external errorHandler
                errorHandler(configuration, error)
            }
        }
        
        // Save both in a data structure
        configurations.append(SyncItem(configuration: configuration, fileWatcher: fileWatcher, fileWatcherSubscription: fileWatcherSubscription, transferHandler: transferHandler))
    }
    
    
    /**
     Stops the synchronization for an item.
     
     - parameters:
        - item: The `SyncItem` for which the synchronization should be stopped.
     */
    public func stopSynchronizing(for item: SyncItem) {
        stopSynchronizing(for: item.configuration.id)
    }
    
    
    /**
    Stops the synchronization for an item.
    
    - parameters:
       - id: The id of the `Configuration` object, related to the `SyncItem`, for which the synchronization should be stopped.
    */
    public func stopSynchronizing(for id: String) {
        // Determine SyncItem in list by Configuration.id
        if let index = configurations.firstIndex(where: { $0.configuration.id == id }) {
            configurations[index].fileWatcherSubscription.cancel()
            configurations.remove(at: index)
        }
    }
    
    
    /**
    Stops the synchronization for an item.
    
    - parameters:
       - index: The index of the `SyncItem` for which the synchronization should be stopped.
    */
    public func stopSynchronizing(for index: Int) {
        // Determine SyncItem in list by index
        configurations[0].fileWatcherSubscription.cancel()
        configurations.remove(at: index)
    }
    
    
    private func existsSyncItem(for configuration: Configuration) -> Bool {
        if let index = configurations.firstIndex(where: { $0.configuration.id = configuration.id }) {
            return true
        } else {
            return false
        }
    }
}

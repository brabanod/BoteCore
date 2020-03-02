//
//  SyncOrchestrator.swift
//  bote-core
//
//  Created by Pascal Braband on 10.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import Foundation
import Combine

public class SyncItem {
    public var configuration: Configuration
    var fileWatcher: FileWatcher?
    var transferHandler: TransferHandler?
    public var id: String { return self.configuration.id }
    @Published public internal(set) var status: SyncStatus
    
    @Published public internal(set) var lastSynced: Date?
    
    var fileWatcherSubscription: AnyCancellable?
    var statusSubscription: AnyCancellable?
    
    
    init(configuration: Configuration, status: SyncStatus) {
        self.configuration = configuration
        self.status = status
    }
    
    
    init(configuration: Configuration, fileWatcher: FileWatcher?, transferHandler: TransferHandler?, status: SyncStatus, fileWatcherSubscription: AnyCancellable?, statusSubscription: AnyCancellable?) {
        self.configuration = configuration
        self.fileWatcher = fileWatcher
        self.transferHandler = transferHandler
        self.status = status
        
        self.fileWatcherSubscription = fileWatcherSubscription
        self.statusSubscription = statusSubscription
    }
}

public enum SyncOrchestratorError: Error {
    case TransferHandlerInitFailure(String)
    case FileWatcherInitFailure(String)
    case ConfigurationDuplicate
}

public enum SyncStatus: Int, Comparable {
    case connected, active, failed, inactive
    
    public static func < (a: SyncStatus, b: SyncStatus) -> Bool {
        return a.rawValue > b.rawValue
    }
}


/**
 Usage:
 Register new configurations with the `register` method. This loads a new configuration into the SyncOrchestrator. Syncornization for loaded configurations can be started and stoppen using `startSynchronization` and `stopSynchronization`.*/
public class SyncOrchestrator {
    
    public private(set) var syncItems: [SyncItem]
    
    public init() {
        syncItems = [SyncItem]()
    }
    
    public init(configurations: [Configuration], errorHandler: @escaping(SyncItem, Error) -> ()) throws {
        self.syncItems = [SyncItem]()
        for configuration in configurations {
            let item = try register(configuration: configuration)
            try startSynchronizing(for: item, errorHandler: errorHandler)
        }
    }
    
    
    /**
     Load a new configuration into the `SyncOrchestrator`, a new `SyncItem` will be created. The status of new items is always `.inactive`.
     
     - parameters:
        - configuration: The `Configuration` object, which should be loaded.
     */
    public func register(configuration: Configuration) throws -> SyncItem {
        if existsSyncItem(for: configuration) {
            throw SyncOrchestratorError.ConfigurationDuplicate
        }
        let item = SyncItem(configuration: configuration, status: .inactive)
        syncItems.append(item)
        return item
    }
    
    
    /**
     Remove a configuration from the `SyncOrchestrator`.
     
     - parameters:
        - configuration: The `Configuration` object, which should be removed.
     */
    public func unregister(configuration: Configuration) {
        if let index = findIndex(for: configuration) {
            syncItems.remove(at: index)
        }
    }
    
    
    /**
     Starts synchronization for a given configuration. Adds the resulting `SyncItem` to the `configurations` property.
     
     - parameters:
        - configuration: The configuration, for which a synchronization should be started.
     */
    public func startSynchronizing(for item: SyncItem, errorHandler: @escaping (SyncItem, Error) -> ()) throws {
        let configuration = item.configuration
        
        // Setup synchronizing with the given configuration
        
        // Setup TransferHandler for configuration.to
        guard let transferHandler: TransferHandler = TransferHandlerOrganizer.getTransferHandler(for: configuration)
            else { item.status = .failed
                throw SyncOrchestratorError.TransferHandlerInitFailure("Initialization of TransferHandler failed and returned nil. Unsupported Connection type possible.") }
        
        // Setup FileWatcher for configuration.from (use TransferHandler in receive from Publisher)
        guard let fileWatcher = FileWatcherOrganizer.getFileWatcher(for: configuration.from)
            else { item.status = .failed
                throw SyncOrchestratorError.FileWatcherInitFailure("Initialization of FileWatcher failed. and returned nil. Unsupported Connection type possible.") }
        
        // Subscribe to FileWatcher
        let fileWatcherSubscription = fileWatcher.sink(receiveCompletion: { (completion) in
            switch completion {
            case .finished:
                let error = FileWatcherError.watchFailed("File watcher unexpectedly finished publishing file events.")
                errorHandler(item, error)
                item.status = .failed
            case .failure(let error):
                errorHandler(item, error)
                item.status = .failed
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
                item.lastSynced = Date.init()
            } catch let error {
                // submit error to external errorHandler
                errorHandler(item, error)
                item.status = .failed
            }
        }
        
        // Save TransferHandler, FileWatcher and FileWatcherSubscription in SyncItem. Update status
        item.transferHandler = transferHandler
        item.fileWatcher = fileWatcher
        item.fileWatcherSubscription = fileWatcherSubscription
        item.status = .active
        
        // Receive status from TransferHandler
        item.statusSubscription = transferHandler.statusPublisher.sink { (status) in
            switch status {
            case .connected:
                item.status = .connected
            case .disconnected:
                switch item.status {
                case .connected:
                    item.status = .active
                case .active:
                    item.status = .active
                case .inactive:
                    item.status = .inactive
                case .failed:
                    item.status = .failed
                }
            }
        }
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
        if let index = findIndex(for: id) {
            deactivate(syncItem: syncItems[index])
        }
    }
    
    
    /**
    Stops the synchronization for an item.
    
    - parameters:
       - index: The index of the `SyncItem` for which the synchronization should be stopped.
    */
    public func stopSynchronizing(for index: Int) {
        // Determine SyncItem in list by index
        deactivate(syncItem: syncItems[index])
    }
    
    
    /**
     Deactivates all neccessary components of a `SyncItem`, in order to stop the synchronization.
     
     - parameters:
        - item: The `SyncItem` for which the synchronization should be stopped.
     */
    private func deactivate(syncItem item: SyncItem) {
        item.fileWatcherSubscription?.cancel()
        item.status = .inactive
    }
    
    
    private func existsSyncItem(for configuration: Configuration) -> Bool {
        if let _ = syncItems.firstIndex(where: { $0.configuration.id == configuration.id }) {
            return true
        } else {
            return false
        }
    }
    
    
    private func findIndex(for configuration: Configuration) -> Int? {
        return syncItems.firstIndex(where: { $0.configuration.id == configuration.id })
    }
    
    
    private func findIndex(for id: String) -> Int? {
        return syncItems.firstIndex(where: { $0.configuration.id == id })
    }
}

//
//  ConfigurationManager.swift
//  bote-core
//
//  Created by Pascal Braband on 14.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import Foundation

public class ConfigurationManager {
    
    private (set) var configurations: [Configuration]
    
    
    /**
     - returns:
        - _Default_: New `ConfigurationManager` object.
        - _Failure_: If the configurations couldn't be loaded from the UserDefaults, the initializer returns `nil`.
    */
    public init?(_: Void) {
        self.configurations = [Configuration]()
        
        do {
            self.configurations = try load()
        } catch _ {
            return nil
        }
    }
    
    
    /**
     Adds a new `Configuration` object to the UserDefaults.
     
     - parameters:
        - configuration: The `Configuration` object which should be saved.
    */
    public func add(_ configuration: Configuration) throws {
        try PreferencesManager.save(configuration: configuration)
        try reloadList()
    }
    
    
    /**
     Saves the given `Configuration` object for in the UserDefaults for a given id.
     
     - parameters:
        - configuration: The `Configuration` object which should be saved. Must be given as a reference.
        - id: The id of the `Configuration` object in the UserDefaults, which should be updated.
    */
    public func update(_ configuration: inout Configuration, for id: String) throws {
        // Set correct id for given configuration. Then update in Preferences
        configuration.setId(id)
        try PreferencesManager.save(configuration: configuration)
        try reloadList()
    }
    
    
    /**
     Removes a `Configuration` object from the UserDefaults, identified by its id.
     
     - parameters:
        - id: The id of the `Configuration` object in the UserDefaults, which should be removed.
    */
    public func remove(id: String) throws {
        // Call custom remove method for on the Configuration, then remove Configuration itself
        try PreferencesManager.load(for: id)?.remove()
        PreferencesManager.remove(for: id)
        try reloadList()
    }
    
    
    /**
     - returns:
     An array of the `Configuration` objects, which are stored in the UserDefaults.
     */
    private func load() throws -> [Configuration] {
        var configurations = [Configuration]()
        guard let loaded = try PreferencesManager.loadAll() else { return configurations }
        for (_, value) in loaded {
            configurations.append(value)
        }
        return configurations
    }
    
    
    /**
     Updates the `configurations` cache with the current values saved in the UserDefaults.
     */
    private func reloadList() throws {
        self.configurations = try load()
    }
}

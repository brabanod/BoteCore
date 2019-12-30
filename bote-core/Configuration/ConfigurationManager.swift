//
//  ConfigurationManager.swift
//  bote-core
//
//  Created by Pascal Braband on 14.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import Foundation

class ConfigurationManager: NSObject {
    
    var configurations: [Configuration]
    
    init?(_: Void) {
        self.configurations = [Configuration]()
        super.init()
        
        do {
            self.configurations = try load()
        } catch _ {
            return nil
        }
    }
    
    
    func add(_ configuration: Configuration) throws {
        try PreferencesManager.save(configuration: configuration)
        try reloadList()
    }
    
    
    func remove(id: String) throws {
        // FIXME: Also remove keychain item if present
        //PreferencesManager.load(for: id)?.remove()
        PreferencesManager.remove(for: id)
        try reloadList()
    }
    
    
    /**
     Saves the changes, that are cached in `configurations`, to UserDefaults.
     */
    func persist() throws {
        try reloadList()
        try PreferencesManager.write(configurations)
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

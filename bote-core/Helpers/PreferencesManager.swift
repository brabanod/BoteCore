//
//  PreferencesManager.swift
//  bote-core
//
//  Created by Pascal Braband on 12.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import Foundation


class PreferencesManager: NSObject {
    
    private static let configurationsSuiteName = (Bundle.main.bundleIdentifier ?? "de.pascalbraband.bote-core") + ".configurations"
    private static let defaults = UserDefaults.init(suiteName: PreferencesManager.configurationsSuiteName)!
    private static let configurationsKey = "BoteConfigurations"
    
    
    /**
     - returns:
     A configuration dictionary. If a dictionary exists in the User Defaults, then return it. Else create a new entry for the dictionary in User Defaults and return the empty dictionary to work with.
     */
    private static func getConfigurations() -> [String: Data] {
        if let saved = defaults.object(forKey: configurationsKey) as? [String: Data] {
            return saved
        } else {
            let new = [String: Data]()
            save(new)
            return new
        }
    }
    
    
    /**
     Saves the given configurations dictionary in the UserDefaults. Needs to be called at the end of every operation on the configurations dictionary.
     
     - parameters:
        - configurations: The dictionary, which should be saved to the UserDefaults.
     */
    private static func save(_ configurations: [String: Data]) {
        defaults.set(configurations, forKey: configurationsKey)
        defaults.synchronize()
    }
    
    
    /**
     Creates or updates a configuration item in the preferences.
     
     - parameters:
        - configurations: The `Configuration` object, which should be created or updated.
     */
    public static func save(configuration: Configuration) throws {
        // Encode data
        let configurationData = try PropertyListEncoder().encode(configuration)
        let key = configuration.id
        
        // Save to defaults dictionary
        var all = getConfigurations()
        all[key] = configurationData
        save(all)
    }
    
    
    /**
     Creates or updates multiple items in the preferences.
     
     - parameters:
        - configurations: An array of `Configuration` objects, which should be created or updated.
     */
    public static func save(configurations: [Configuration]) throws {
        for configuration in configurations {
            try save(configuration: configuration)
        }
    }
    
    
    /**
     - returns:
     A configuration stored in the preferences, for a given key.
     
     - parameters:
        - id: The id for the configuration object, that should be deleted.
     */
    public static func load(for id: String) throws -> Configuration? {
        // Load from UserDefaults
        let all = getConfigurations()
        guard let configurationData = all[id] else { return nil }
        
        // Decode
        guard let configuration = try? PropertyListDecoder().decode(Configuration.self, from: configurationData) else { return nil }
        return configuration
    }
    
    
    /**
     - returns:
     A dictionary with all keys and values, stored in the preferences.
     */
    public static func loadAll() throws -> [String: Configuration]? {
        guard let configurationsData = defaults.object(forKey: configurationsKey) as? [String: Data] else { return nil }
        var configurations = [String: Configuration]()
        for (key, configurationData) in configurationsData {
            guard let configuration = try? PropertyListDecoder().decode(Configuration.self, from: configurationData) else { return nil }
            configurations[key] = configuration
        }
        
        if configurations.isEmpty {
            return nil
        } else {
            return configurations
        }
    }
    
    
    /**
     Removes an object from User Defaults with the given key.
     
     - parameters:
        - key: The key for the object, which should be removed.
     */
    public static func remove(for id: String) {
        var all = getConfigurations()
        all.removeValue(forKey: id)
        save(all)
    }
    
    
    /**
     Removes multiple objects from User Defaults with the given keys.
     
     - parameters:
        - key: An array of keys, which are for the objects, that should be removed.
     */
    public static func remove(for ids: [String]) {
        for id in ids {
            remove(for: id)
        }
    }
    
    
    /**
     Removes all configurations saved in the User Defaults.
     */
    public static func removeAll() {
        print(configurationsSuiteName)
        defaults.removePersistentDomain(forName: configurationsSuiteName)
        defaults.synchronize()
    }
}

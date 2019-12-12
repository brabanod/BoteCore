//
//  PreferencesManager.swift
//  bote-core
//
//  Created by Pascal Braband on 12.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import Foundation


class PreferencesManager: NSObject {
    
    private static let defaults = UserDefaults.standard
    
    
    /**
     Creates or updates a configuration item in the preferences
     */
    public static func save(configuration: Configuration) throws {
        // Encode data
        let configurationData = try PropertyListEncoder().encode(configuration)
        //let key = Config-\(configuration.id)
        defaults.set(configurationData, forKey: "key")
    }
    
    
    /**
     - returns:
     A configuration stored in the preferences, for a given key
     */
    public static func load(for key: String) throws -> Configuration? {
        // Load from UserDefaults
        guard let configurationData = defaults.object(forKey: key) as? Data else {
            return nil
        }
        
        // Decode
        guard let configuration = try? PropertyListDecoder().decode(Configuration.self, from: configurationData) else {
            return nil
        }
        
        return configuration
    }
    
    
    /**
     - returns:
     A dictionary with all keys and values, stored in the preferences.
     */
    public static func loadAll() throws -> [String: Configuration]? {
        guard let all = defaults.dictionaryRepresentation() as? [String: Configuration] else {
            return nil
        }
        return all
    }
}

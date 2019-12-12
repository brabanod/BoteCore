//
//  KeychainGuard.swift
//  bote-core
//
//  Created by Pascal Braband on 11.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import Foundation
import Security

enum KeychainError: Error, Equatable {
    case itemNotFound
    case unexpectedPasswordData
    case unhandledError(status: OSStatus)
}


class KeychainGuard: NSObject {
    
    /**
     Add an item to the keychain.
     
     - parameters:
        - user: The username, which will be stored in the keychain item.
        - password: The password, which will be stored encrypted in the keychain item.
        - server: The server, which will be stored in the keychain item.
        - type: A description for the type of connection, this item is intended for.
     
     - throws:
        - `KeychainError.unhandledError(status: OSStatus)`
     */
    public static func addItem(user: String, password: String, server: String, type: String) throws {
        // Query with parameters for new item
        let addQuery: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                       kSecAttrLabel as String: Bundle.main.bundleIdentifier ?? "de.pascalbraband.zynced",
                                       kSecAttrDescription as String: "Zynced Connection",
                                       kSecAttrComment as String: "Credentials for \(type) Connection",
                                       kSecAttrAccount as String: user,
                                       kSecAttrServer as String: server,
                                       kSecValueData as String: password.data(using: .utf8)!]

        // Add item to keychain
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
    }
    
    
    /**
     Gets the password for a keychain item.
     
     - parameters:
        - user: The username associated to the keychain item.
        - server: The server associated to the keychain item.
     
     - returns:
     The password from the keychain item, which is identified by `user` and `server`.
     
     - throws:
        - `KeychainError.itemNotFound`
        - `KeychainError.unexpectedPasswordData`
        - `KeychainError.unhandledError(status: OSStatus)`
     */
    public static func getItem(user: String, server: String) throws -> String  {
        // Query with parameters for searching the item
        let searchQuery: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                             kSecAttrServer as String: server,
                                             kSecAttrAccount as String: user,
                                             kSecMatchLimit as String: kSecMatchLimitOne,
                                             kSecReturnAttributes as String: true,
                                             kSecReturnData as String: true]

        // Get item from keychain
        var item: CFTypeRef?
        let searchStatus = SecItemCopyMatching(searchQuery as CFDictionary, &item)
        guard searchStatus != errSecItemNotFound else { throw KeychainError.itemNotFound }
        guard searchStatus == errSecSuccess else { throw KeychainError.unhandledError(status: searchStatus) }

        // Extract password from item
        guard let existingItem = item as? [String : Any],
            let passwordData = existingItem[kSecValueData as String] as? Data,
            let password = String(data: passwordData, encoding: .utf8)
            else {
                throw KeychainError.unexpectedPasswordData
        }
        return password
    }
    
    
    /**
     Updates an item in the keychain.
     
     - parameters:
        - user: The username to find the keychain item.
        - server: The server to find the keychain item.
        - newUser: _(optional)_ New value for the username.
        - newPassword: _(optional)_ New value for the password.
        - newServer: _(optional)_ New value for the server.
     
     - returns:
     The password from the keychain item, which is identified by `user` and `server`.
     
     - throws:
        - `KeychainError.itemNotFound`
        - `KeychainError.unhandledError(status: OSStatus)`
     */
    public static func updateItem(user: String, server: String, newUser: String?, newPassword: String?, newServer: String?) throws  {
        // Query with parameters for searching the item to be modified
        let searchQuery: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                          kSecAttrServer as String: server,
                                          kSecAttrAccount as String: user]
        
        // Create updated attributes array
        var attributes: [String: Any] = [String: Any]()
        
        if newUser != nil {
            attributes[kSecAttrAccount as String] = newUser!
        }
        if newPassword != nil {
            attributes[kSecValueData as String] = newPassword!.data(using: .utf8)
        }
        if newServer != nil {
            attributes[kSecAttrServer as String] = newServer!
        }
        
        // Update if attributes were given
        if attributes.count > 0 {
            let status = SecItemUpdate(searchQuery as CFDictionary, attributes as CFDictionary)
            guard status != errSecItemNotFound else { throw KeychainError.itemNotFound }
            guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
        }
    }
    
    
    /**
     Removes an item from the keychain.
     
     - parameters:
        - user: The username associated to the keychain item.
        - server: The server associated to the keychain item.
     
     - returns:
     The password from the keychain item, which is identified by `user` and `server`.
     
     - throws:
        - `KeychainError.unhandledError(status: OSStatus)`
     */
    public static func removeItem(user: String, server: String) throws  {
        // Query with parameters for searching the item to be removed
        let searchQuery: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
        kSecAttrServer as String: server,
        kSecAttrAccount as String: user]
        
        // Remove the item from the keychain
        let status = SecItemDelete(searchQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw KeychainError.unhandledError(status: status) }
    }
}

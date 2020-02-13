//
//  SFTPConnection.swift
//  bote-core
//
//  Created by Pascal Braband on 10.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import Foundation

public enum SFTPAuthentication: Equatable {
    case password(value: String)
    case key(path: String)
}


/**
 - important:
 `.password(value: String)` in `authentication` is will not be saved and is only for initializing.
 If you want to access the password
 */
public struct SFTPConnection: Connection {
    public let type: ConnectionType = ConnectionType.sftp
    
    public var path: String
    var port: Int?
    public private(set) var host: String
    public private(set) var authentication: SFTPAuthentication
    public private(set) var user: String
    
    
    /**
     Use this initializer, to create a new configuration, with a new password.
     If a keychain item already exists for this configuration, the password will be overriden.
     */
    public init(path: String, host: String, port: Int?, user: String, authentication: SFTPAuthentication) throws {
        self.path = path
        self.host = host
        self.port = port
        self.user = user
        
        // type = .password -> set authentication and save in keychain
        // type = .key -> set authentication
        // The same as setAuthentication, but cannot be called, since object not yet initialized
        switch authentication {
        case .password(value: let newPassword):
            self.authentication = .password(value: newPassword)
            try savePassword(newPassword)
        case .key(path: let path):
            self.authentication = .key(path: path)
        }
    }
    
    
    /**
     Use this initializer, when a password for this configuration is already saved in keychain.
     This initializer will try to get it and initialize the configuration with the saved password.
     */
    public init(path: String, host: String, port: Int?, user: String) throws {
        self.path = path
        self.host = host
        self.port = port
        self.user = user
        self.authentication = .password(value: "")
        
        // Try getting keychain item for the specified configuration
        let password = try getPassword()
        self.authentication = .password(value: password)
    }
    
    
    
    
    // MARK: - Getters
    
    /**
     - returns:
     The password from the keychain item, associated to `self`'s parameters.
     
     - throws:
        - `KeychainError.itemNotFound`
        - `KeychainError.unexpectedPasswordData`
        - `KeychainError.unhandledError(status: OSStatus)`
     */
    func getPassword() throws -> String {
        return try KeychainGuard.getItem(user: user, server: host)
    }
    
    
    /**
     - returns:
        - The path for the SSH key, saved in the configuration
        - `nil` if authentication method is not `.key`
    */
    func getKeyPath() -> String? {
        switch self.authentication {
        case .key(path: let path):
            return path
        default:
            return nil
        }
    }
    
    
    
    
    // MARK: - Setters
    
    /**
     Sets the authentication for the configuration.
     
     - parameters:
        - newAuthentication: the new value for authentication.
            - case `.key(path:)`: updates authentication with `.key` and new path.
            - case `.password(value:)`: updates authentication with `.password` and updates password value in keychain item.
     
     - throws:
        - `KeychainError.itemNotFound`
        - `KeychainError.unhandledError(status: OSStatus)`
     */
    mutating func setAuthentication(_ newAuthentication: SFTPAuthentication) throws {
        switch newAuthentication {
        case .password(value: let password):
            // Update password in keychain item
            try savePassword(password)
            self.authentication = .password(value: password)
        case .key(path: let path):
            // Remove keychain item and update authentication
            removePassword()
            self.authentication = .key(path: path)
        }
    }
    
    
    /**
     Sets the user for the configuration.
     
     - parameters:
        - newUser: the new value for user.
     
     - throws:
        - `KeychainError.itemNotFound`
        - `KeychainError.unhandledError(status: OSStatus)`
     */
    mutating func setUser(_ newUser: String) throws {
        if case .password = authentication {
            try KeychainGuard.updateItem(user: user, server: host, newUser: newUser, newPassword: nil, newServer: nil)
        }
        self.user = newUser
    }
    
    
    /**
     Sets the host for the configuration.
     
     - parameters:
        - newHost: the new value for host.
     
     - throws:
        - `KeychainError.itemNotFound`
        - `KeychainError.unhandledError(status: OSStatus)`
     */
    mutating func setHost(_ newHost: String) throws {
        if case .password = authentication {
            try KeychainGuard.updateItem(user: user, server: host, newUser: nil, newPassword: nil, newServer: newHost)
        }
        self.host = newHost
    }
    
    
    
    
    // MARK: - Keychain
    
    /**
     Updates the password for the associated keychain item.
     Creates a new keychain item with given password, if keychain item doesn't exist.
     
     - parameters:
        - password: The password, which should be saved in the keychain item.
        - user: The user associated with the keychain item.
        - host: The host associated with the keychain item.
     
     - throws:
        - `KeychainError.itemNotFound`
        - `KeychainError.unhandledError(status: OSStatus)`
     */
    private func savePassword(_ password: String) throws {
        do {
            // Update password, if item already exists
            let _ = try getPassword()
            try KeychainGuard.updateItem(user: user, server: host, newUser: nil, newPassword: password, newServer: nil)
        } catch _ {
            // Create item, if it doesn't exist
            try KeychainGuard.addItem(user: user, password: password, server: host, type: "SFTP")
        }
    }
    
    
    /**
     Remove the keychain item associated with this configuration
     */
    private func removePassword() {
        do {
            try KeychainGuard.removeItem(user: user, server: host)
        } catch { }
    }
    
    
    
    
    // MARK: - Remove
    
    public func remove() {
        removePassword()
    }
}




// MARK: -

extension SFTPAuthentication: Codable {
    
    enum CodingKeys: String, CodingKey {
        case type, string
    }
    
    
    private enum SFTPAuthenticationType: String, Codable {
        case password
        case key
    }
    
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let type = try container.decode(SFTPAuthenticationType.self, forKey: .type)
        
        switch type {
        case .password:
            // Password is not stored in UserDefaults
            let value = ""
            self = .password(value: value)
        case .key:
            let path = try container.decode(String.self, forKey: .string)
            self = .key(path: path)
        }
    }
    
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .password(value: _):
            try container.encode(SFTPAuthenticationType.password, forKey: .type)
            // dont save password in preferences
        case .key(path: let path):
            try container.encode(SFTPAuthenticationType.key, forKey: .type)
            try container.encode(path, forKey: .string)
        }
    }
}

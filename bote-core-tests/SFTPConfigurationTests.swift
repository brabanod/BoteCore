//
//  SFTPConfigurationTests.swift
//  bote-core-tests
//
//  Created by Pascal Braband on 12.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import XCTest

class SFTPConfigurationTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        do {
            try KeychainGuard.removeItem(user: SFTPServer.user, server: SFTPServer.host)
        } catch _ {
            print("NOTE: There was no keychain item to be deleted in teadDown.")
        }
    }
    
    
    
    
    // MARK: - Initializers

    func testInitWithPassword() throws {
        let conf = try SFTPConfiguration(path: testsBasepath, host: SFTPServer.host, port: SFTPServer.port, authentication: .password(value: SFTPServer.password), user: SFTPServer.user)
        
        // Check password
        XCTAssertEqual(SFTPServer.password, try conf.getPassword())
        
        // Check other properties
        XCTAssertEqual(conf.path, testsBasepath)
        XCTAssertEqual(conf.host, SFTPServer.host)
        XCTAssertEqual(conf.port, SFTPServer.port)
        XCTAssertEqual(conf.user, SFTPServer.user)
        XCTAssertEqual(conf.authentication, SFTPAuthentication.password(value: SFTPServer.password))
    }
    
    
    func testInitWithSavedPassword() throws {
        let savedPass = "saved_pass"
        try KeychainGuard.addItem(user: SFTPServer.user, password: savedPass, server: SFTPServer.host, type: "SFTP_Test")
        let conf = try SFTPConfiguration(path: testsBasepath, host: SFTPServer.host, port: SFTPServer.port, user: SFTPServer.user)
        
        // Check password
        XCTAssertEqual(savedPass, try conf.getPassword())
        
        // Check other properties
        XCTAssertEqual(conf.path, testsBasepath)
        XCTAssertEqual(conf.host, SFTPServer.host)
        XCTAssertEqual(conf.port, SFTPServer.port)
        XCTAssertEqual(conf.user, SFTPServer.user)
        XCTAssertEqual(conf.authentication, SFTPAuthentication.password(value: savedPass))
    }
    
    
    func testWithSavedPasswordOverride() throws {
        let savedPass = "saved_pass"
        try KeychainGuard.addItem(user: SFTPServer.user, password: savedPass, server: SFTPServer.host, type: "SFTP_Test")
        let conf = try SFTPConfiguration(path: testsBasepath, host: SFTPServer.host, port: SFTPServer.port, authentication: .password(value: SFTPServer.password), user: SFTPServer.user)
        
        // Check password
        XCTAssertEqual(SFTPServer.password, try conf.getPassword())
        
        // Check other properties
        XCTAssertEqual(conf.path, testsBasepath)
        XCTAssertEqual(conf.host, SFTPServer.host)
        XCTAssertEqual(conf.port, SFTPServer.port)
        XCTAssertEqual(conf.user, SFTPServer.user)
        XCTAssertEqual(conf.authentication, SFTPAuthentication.password(value: SFTPServer.password))
    }
    
    
    func testInitWithoutPassword() throws {
        // Should throw error
        do {
            let _ = try SFTPConfiguration(path: testsBasepath, host: SFTPServer.host, port: SFTPServer.port, user: SFTPServer.user)
        } catch let error {
            guard let keychainError = error as? KeychainError else {
                XCTFail("Error was not of type KeychainError.")
                return
            }
            guard keychainError == .itemNotFound else {
                XCTFail("Error was not of type KeychainError.itemNotFound.")
                return
            }
        }
    }
    
    
    func testInitWithKey() throws {
        let conf = try SFTPConfiguration(path: testsBasepath, host: SFTPServer.host, port: SFTPServer.port, authentication: .key(path: SFTPServer.keypath), user: SFTPServer.user)
        
        // Check properties
        XCTAssertEqual(conf.path, testsBasepath)
        XCTAssertEqual(conf.host, SFTPServer.host)
        XCTAssertEqual(conf.port, SFTPServer.port)
        XCTAssertEqual(conf.user, SFTPServer.user)
        XCTAssertEqual(conf.authentication, SFTPAuthentication.key(path: SFTPServer.keypath))
    }
    
    
    
    
    // MARK: - Getters
    
    func testGetPassword() throws {
        let conf = try SFTPConfiguration(path: testsBasepath, host: SFTPServer.host, port: SFTPServer.port, authentication: .password(value: SFTPServer.password), user: SFTPServer.user)
        XCTAssertEqual(SFTPServer.password, try conf.getPassword())
    }
    
    
    func testGetKeyPath() throws {
        let conf = try SFTPConfiguration(path: testsBasepath, host: SFTPServer.host, port: SFTPServer.port, authentication: .key(path: SFTPServer.keypath), user: SFTPServer.user)
        XCTAssertEqual(SFTPServer.keypath, conf.getKeyPath())
    }
    
    
    
    
    // MARK: - Setters
    
    func testSetAuthenticationNewPassword() throws {
        var conf = try SFTPConfiguration(path: testsBasepath, host: SFTPServer.host, port: SFTPServer.port, authentication: .password(value: SFTPServer.password), user: SFTPServer.user)
        XCTAssertEqual(SFTPServer.password, try conf.getPassword())
        XCTAssertEqual(SFTPServer.password, try KeychainGuard.getItem(user: SFTPServer.user, server: SFTPServer.host))
        
        // Update password
        let newPass = "new_pass"
        try conf.setAuthentication(.password(value: newPass))
        XCTAssertEqual(newPass, try conf.getPassword())
        XCTAssertEqual(newPass, try KeychainGuard.getItem(user: SFTPServer.user, server: SFTPServer.host))
    }
    
    
    func testSetUser() throws {
        var conf = try SFTPConfiguration(path: testsBasepath, host: SFTPServer.host, port: SFTPServer.port, authentication: .password(value: SFTPServer.password), user: SFTPServer.user)
        XCTAssertEqual(SFTPServer.user, conf.user)
        XCTAssertEqual(SFTPServer.password, try KeychainGuard.getItem(user: SFTPServer.user, server: SFTPServer.host))
        
        // Update user
        let newUser = "new_user"
        try conf.setUser(newUser)
        XCTAssertEqual(newUser, conf.user)
        
        // Check if keychain item was updated.
        // Know that it is updated, when you can get the password for the new credentials
        XCTAssertEqual(SFTPServer.password, try KeychainGuard.getItem(user: SFTPServer.user, server: SFTPServer.host))
    }
    
    
    func testSetHost() throws {
        var conf = try SFTPConfiguration(path: testsBasepath, host: SFTPServer.host, port: SFTPServer.port, authentication: .password(value: SFTPServer.password), user: SFTPServer.user)
        XCTAssertEqual(SFTPServer.user, conf.user)
        XCTAssertEqual(SFTPServer.password, try KeychainGuard.getItem(user: SFTPServer.user, server: SFTPServer.host))
        
        // Update user
        let newHost = "new_host"
        try conf.setUser(newHost)
        XCTAssertEqual(newHost, conf.user)
        
        // Check if keychain item was updated.
        // Know that it is updated, when you can get the password for the new credentials
        XCTAssertEqual(SFTPServer.password, try KeychainGuard.getItem(user: SFTPServer.user, server: SFTPServer.host))
    }
    
    
    
    
    // MARK: - Encoding/Decoding
    
    func testEncodeDecodePassword() throws {
        let conf = try SFTPConfiguration(path: testsBasepath, host: SFTPServer.host, port: SFTPServer.port, authentication: .password(value: SFTPServer.password), user: SFTPServer.user)
        
        // Encode configuration
        let encodedConf = try PropertyListEncoder().encode(conf)
        //try encodedConf.write(to: URL(fileURLWithPath: "\(testsBasepath)/sftp_conf.plist"))
        
        // Decode configuration and check if all properties are set correct
        let decodedConf = try PropertyListDecoder().decode(SFTPConfiguration.self, from: encodedConf)
        XCTAssertEqual(decodedConf.path, testsBasepath)
        XCTAssertEqual(decodedConf.host, SFTPServer.host)
        XCTAssertEqual(decodedConf.port, SFTPServer.port)
        XCTAssertEqual(decodedConf.user, SFTPServer.user)
        XCTAssertEqual(decodedConf.authentication, SFTPAuthentication.password(value: ""))
    }
    
    func testEncodingKeypath() throws {
        let conf = try SFTPConfiguration(path: testsBasepath, host: SFTPServer.host, port: SFTPServer.port, authentication: .key(path: SFTPServer.keypath), user: SFTPServer.user)
        
        // Encode configuration
        let encodedConf = try PropertyListEncoder().encode(conf)
        
        // Decode configuration and check if all properties are set correct
        let decodedConf = try PropertyListDecoder().decode(SFTPConfiguration.self, from: encodedConf)
        XCTAssertEqual(decodedConf.path, testsBasepath)
        XCTAssertEqual(decodedConf.host, SFTPServer.host)
        XCTAssertEqual(decodedConf.port, SFTPServer.port)
        XCTAssertEqual(decodedConf.user, SFTPServer.user)
        XCTAssertEqual(decodedConf.authentication, SFTPAuthentication.key(path: SFTPServer.keypath))
        
    }

    // FIXME: Implement Encoding/Decoding tests
    // Check, that all values are correctly stored and load
    // Check, that password isn't stored in UserDefaults

}

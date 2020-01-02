//
//  SFTPSyncHandler.swift
//  bote-core
//
//  Created by Pascal Braband on 31.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import Foundation
import Shout

enum SFTPError: Error {
    case authenticationPasswordFailure, authenticationKeyFailure, connectionFailure, executionFailure, invalidPath
}


class SFTPSyncHandler: SyncHandler {    
    
    var status: SyncHandlerStatus
    
    // Timer
    var timer: Timer? = nil
    let connectionTime: TimeInterval = 5*60     // disconnect after 5 minutes of inactivity
    
    // Connection information
    private let remoteHost: String
    private let remoteUser: String
    
    private var sshSession: SSH?
    private var sftpSession: SFTP?
    
    private let from: Connection
    private let to: SFTPConnection
    
    // Paths
    private let localBasePath: String
    private let remoteBasePath: String
    
    private let safetyNet: SafetyNet
    
    
    required init(from: Connection, to: SFTPConnection) {
        self.status = .connected
        
        self.remoteHost = to.host
        self.remoteUser = to.user
        self.localBasePath = from.path
        self.remoteBasePath = to.path
        
        self.from = from
        self.to = to
        
        self.safetyNet = SafetyNet(basePath: self.remoteBasePath)
        
        restartConnectionTimer()
    }
    
    
    func upload(path: String, isDir: Bool) throws {
        try connect()
        
        if isDir {
            try uploadDir(path: path)
        } else {
            try uploadFile(path: path)
        }
    }
    
    
    private func uploadFile(path: String) throws {
        let destination = path.replace(localBasePath: localBasePath, with: remoteBasePath)
        let source = URL(fileURLWithPath: path)
        try safetyNet.intercept(path: destination)
        
        do {
            try sftpSession!.upload(localURL: source, remotePath: destination, permissions: .default)
        } catch {
            throw SFTPError.executionFailure
        }
    }
    
    
    private func uploadDir(path: String) throws {
        let directoryPath = path.replace(localBasePath: localBasePath, with: remoteBasePath)
        try safetyNet.intercept(path: directoryPath)
        
        do {
            try sftpSession!.createDirectory(directoryPath)
        } catch {
            throw SFTPError.executionFailure
        }
    }
    
    
    func remove(path: String, isDir: Bool) throws {
        try connect()
        
        if isDir {
            try removeFile(path: path)
        } else {
            try removeDir(path: path)
        }
    }
    
    
    private func removeFile(path: String) throws {
        let removePath = path.replace(localBasePath: localBasePath, with: remoteBasePath)
        try safetyNet.intercept(path: removePath)
        
        do {
            try sftpSession!.removeFile(removePath)
        } catch {
            throw SFTPError.executionFailure
        }
    }
    
    
    private func removeDir(path: String) throws {
        let removePath = path.replace(localBasePath: localBasePath, with: remoteBasePath)
        try safetyNet.intercept(path: removePath)
        
        do {
            try sshSession!.execute("rm -rf \(removePath)")
        } catch {
            throw SFTPError.executionFailure
        }
    }
    
    
    func rename(src: String, dst: String) throws {
        try connect()
        
        let source = src.replace(localBasePath: localBasePath, with: remoteBasePath)
        let destination = dst.replace(localBasePath: localBasePath, with: remoteBasePath)
        try safetyNet.intercept(path: source, destination)
               
        do {
            try sftpSession!.rename(src: source, dest: destination, override: true)
        } catch {
            throw SFTPError.executionFailure
        }
    }
    
    
    func connect() throws {
        restartConnectionTimer()
        
        // Check if connecting is required
        if !isConnected() {
            do {
                sshSession = try SSH(host: remoteHost)
                do {
                    // Use key
                    if case .key = to.authentication, let keypath = to.getKeyPath() {
                        try sshSession!.authenticate(username: remoteUser, privateKey: keypath)
                    }
                    // Use password
                    else{
                        try sshSession!.authenticate(username: remoteUser, password: to.getPassword())
                    }
                    
                    do {
                        sftpSession = try sshSession!.openSftp()
                    } catch {
                        throw SFTPError.connectionFailure
                    }
                } catch _ {
                    throw SFTPError.authenticationKeyFailure
                }
            } catch _ {
                throw SFTPError.connectionFailure
            }
        }
        status = .connected
    }
    
    
    func terminate() {
        // Deinit sshSession and sftpSession
        sshSession = nil
        sftpSession = nil
        status = .disconnected
    }
    
    
    /**
     - returns
        - `true`: if SSH/SFTP is connected
        - `false`: if SSH/SFTP is disconnected
     */
    private func isConnected() -> Bool {
        var isConnected = true
        
        if sshSession == nil || sftpSession == nil {
            isConnected = false
        } else {
            do {
                try sshSession!.execute("echo 'Checking SFTP connection'")
            } catch {
                isConnected = false
            }
        }
        return isConnected
    }
    
    
    /**
     Restarts the connection timer. Therefore creates a new timer, which terminates the connection after `connectionTime` seconds.
     */
    private func restartConnectionTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: connectionTime, repeats: false, block: { (timer) in
            self.terminate()
        })
    }
}

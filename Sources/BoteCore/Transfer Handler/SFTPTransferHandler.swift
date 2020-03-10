//
//  SFTPTransferHandler.swift
//  bote-core
//
//  Created by Pascal Braband on 31.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import Foundation
import Shout
import Combine

enum SFTPError: Error {
    case authenticationPasswordFailure(String)
    case authenticationKeyFailure(String)
    case connectionFailure(String)
    case executionFailure(String)
    case invalidPath(String)
}


class SFTPTransferHandler: TransferHandler {
    
    @Published var status: TransferHandlerStatus
    var statusPublisher: Published<TransferHandlerStatus>.Publisher { $status }
    
    // Timer
    private var timer: Timer? = nil
    private var connectionTime: TimeInterval = 5*60     // disconnect after 5 minutes of inactivity
    
    // Connection information
    private let remoteHost: String
    private let remoteUser: String
    
    var sshSession: SSH?
    var sftpSession: SFTP?
    
    private let from: Connection
    private let to: SFTPConnection
    
    // Paths
    private let localBasePath: String
    private let remoteBasePath: String
    
    private let safetyNet: SafetyNet
    
    
    required init(from: Connection, to: Connection) throws {
        if let toSFTP = to as? SFTPConnection {
            self.status = .disconnected
            self.remoteHost = toSFTP.host
            self.remoteUser = toSFTP.user
            self.localBasePath = from.path
            self.remoteBasePath = toSFTP.path
            
            self.from = from
            self.to = toSFTP
            
            self.safetyNet = SafetyNet(basePath: self.remoteBasePath)
        } else {
            throw TransferHandlerError.failedInitialization("Given to Connection should be of type \(ConnectionType.sftp) but was \(to.type).")
        }
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
        } catch let error {
            throw SFTPError.executionFailure(error.localizedDescription)
        }
    }
    
    
    private func uploadDir(path: String) throws {
        let directoryPath = path.replace(localBasePath: localBasePath, with: remoteBasePath)
        try safetyNet.intercept(path: directoryPath)
        
        do {
            // Only create directory if it doesn't already exists
            if try !directoryExists(at: directoryPath) {
                try sftpSession!.createDirectory(directoryPath)
            }
        } catch let error {
            throw SFTPError.executionFailure(error.localizedDescription)
        }
    }
    
    
    func remove(path: String, isDir: Bool) throws {
        try connect()
        
        if isDir {
            try removeDir(path: path)
        } else {
            try removeFile(path: path)
        }
    }
    
    
    private func removeFile(path: String) throws {
        let removePath = path.replace(localBasePath: localBasePath, with: remoteBasePath)
        try safetyNet.intercept(path: removePath)
        
        do {
            try sftpSession!.removeFile(removePath)
        } catch let error {
            throw SFTPError.executionFailure(error.localizedDescription)
        }
    }
    
    
    private func removeDir(path: String) throws {
        let removePath = path.replace(localBasePath: localBasePath, with: remoteBasePath).escapeSpaces()
        try safetyNet.intercept(path: removePath)
        
        do {
            try sshSession!.execute("rm -rf \(removePath)")
        } catch let error {
            throw SFTPError.executionFailure(error.localizedDescription)
        }
    }
    
    
    func rename(src: String, dst: String) throws {
        try connect()
        
        let source = src.replace(localBasePath: localBasePath, with: remoteBasePath)
        let destination = dst.replace(localBasePath: localBasePath, with: remoteBasePath)
        try safetyNet.intercept(path: source, destination)
               
        do {
            try sftpSession!.rename(src: source, dest: destination, override: true)
        } catch let error {
            throw SFTPError.executionFailure(error.localizedDescription)
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
                    } catch let error {
                        throw SFTPError.connectionFailure("Failed to establish SFTP connection. \(error.localizedDescription)")
                    }
                } catch let error {
                    throw SFTPError.authenticationKeyFailure(error.localizedDescription)
                }
            } catch let error {
                throw SFTPError.connectionFailure("Failed to establish SSH connection. \(error.localizedDescription)")
            }
        }
        status = .connected
    }
    
    
    func terminate() {
        // Deinit sshSession and sftpSession
        sftpSession = nil
        sshSession = nil
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
                let _ = try sshSession!.capture("echo 'Checking SFTP connection'")
            } catch {
                isConnected = false
            }
        }
        return isConnected
    }
    
    
    /**
     Checks whether a direcotry exists on the SFTP server.
     
     - parameters:
        - path: The path to the directory, which should be checked for existance.
     
     - returns:
     A boolean value, indicating whether the requested directory exists on the SFTP server or not.
     */
    private func directoryExists(at path: String) throws -> Bool {
        do {
            let (status, contents) = try sshSession!.capture("if test -d \(path.escapeSpaces()); then echo \"exists\"; fi")
            if status == 0, contents.components(separatedBy: "\n")[0] == "exists" {
                return true
            } else {
                return false
            }
        } catch let error {
            throw SFTPError.executionFailure(error.localizedDescription)
        }
    }
    
    
    /**
     Restarts the connection timer. Therefore creates a new timer, which terminates the connection after `connectionTime` seconds.
     */
    private func restartConnectionTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: connectionTime, repeats: false, block: { (timer) in
            self.terminate()
        })
    }
    
    
    public func setConnectionTime(minutes: Int) {
        self.connectionTime = Double(minutes) * 60.0
    }
    
    
    public func setConnectionTime(seconds: Int) {
        self.connectionTime = Double(seconds)
    }
}

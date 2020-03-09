//
//  LocalTransferHandler.swift
//  bote-core
//
//  Created by Pascal Braband on 09.03.20.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import Foundation
import Shout
import Combine

enum LocalError: Error {
    case executionFailure(String)
    case invalidPath(String)
}


class LocalTransferHandler: TransferHandler {
    
    @Published var status: TransferHandlerStatus
    var statusPublisher: Published<TransferHandlerStatus>.Publisher { $status }
    
    // Connection information
    private let from: Connection
    private let to: LocalConnection
    
    // Paths
    private let localBasePath: String
    private let toBasePath: String
    
    private let safetyNet: SafetyNet
    
    
    required init(from: Connection, to: Connection) throws {
        if let toLocal = to as? LocalConnection {
            self.status = .disconnected
            self.from = from
            self.to = toLocal
            self.localBasePath = from.path
            self.toBasePath = to.path
            
            self.safetyNet = SafetyNet(basePath: self.toBasePath)
        } else {
            throw TransferHandlerError.failedInitialization("Given to Connection should be of type \(ConnectionType.local) but was \(to.type).")
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
    
    
    func uploadDir(path: String) throws {
        let destination = path.replace(localBasePath: localBasePath, with: toBasePath)
        //let source = URL(fileURLWithPath: path)
        try safetyNet.intercept(path: destination)
        
        shell("cp -r \(path) \(destination)")
    }
    
    
    func uploadFile(path: String) throws {
        let destination = path.replace(localBasePath: localBasePath, with: toBasePath)
        try safetyNet.intercept(path: destination)
        
        shell("cp \(path) \(destination)")
    }
    
    
    func remove(path: String, isDir: Bool) throws {
        try connect()
        
        if isDir {
            try removeDir(path: path)
        } else {
            try removeFile(path: path)
        }
    }
    
    
    func removeDir(path: String) throws {
        let destination = path.replace(localBasePath: localBasePath, with: toBasePath)
        try safetyNet.intercept(path: destination)
        
        shell("rm -rf \(destination)")
    }
    
    
    func removeFile(path: String) throws {
        let destination = path.replace(localBasePath: localBasePath, with: toBasePath)
        try safetyNet.intercept(path: destination)
        
        shell("rm \(destination)")
    }
    
    
    func rename(src: String, dst: String) throws {
        try connect()
        
        let source = src.replace(localBasePath: localBasePath, with: toBasePath)
        let destination = dst.replace(localBasePath: localBasePath, with: toBasePath)
        try safetyNet.intercept(path: source, destination)
        
        shell("mv \(source) \(destination)")
    }
    
    
    func connect() throws {
        self.status = .connected
    }
    
    
    func terminate() {
        self.status = .disconnected
    }


    /**
     Calling this method with a shell instruction will execute it on the shell.
     
     - parameters:
        - command: The instruction, that should be executed on the shell.
     */
    @discardableResult
    func shell(_ command: String) -> String {
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = ["-c", command]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String

        return output
    }

}

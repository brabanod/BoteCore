//
//  TransferHandler.swift
//  bote-core
//
//  Created by Pascal Braband on 11.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//
// Interesting library: https://github.com/amosavian/FileProvider (WebDAV, FTP, Dropbox, OneDrive)

import Foundation

enum TransferHandlerStatus {
    case connected, disconnected
}


protocol TransferHandler {
    
    var status: TransferHandlerStatus { get }
    
    /**
     Initializes the `TransferHandler`.
     
     - parameters:
        - from: The `Connection` object, from which files should be transferred.
        - to: The `Connection` object, to which files should be transferred.
     */
    init(from: Connection, to: SFTPConnection)
    
    
    /**
     Uploads an item to the server.
     
     - parameters:
        - path: The path, to which the item should be uploaded.
        - isDir: Boolean value indicating, whether the item is a directory.
     */
    func upload(path: String, isDir: Bool) throws
    
    
    /**
     Removes an item from the server.
     
     - parameters:
        - path: The path, where the item to be removed is located.
        - isDir: Boolean value indicating, whether the item is a directory.
     */
    func remove(path: String, isDir: Bool) throws
    
    
    /**
     Renames an item on the server.
     
     - parameters:
        - src: The original name of the item.
        - dst: The new name of the item.
     */
    func rename(src: String, dst: String) throws
    
    /**
     Connects to the given remote.
     */
    func connect() throws
    
    
    /**
     Terminates the connection to the remote.
     */
    func terminate()
}




class TransferHandlerOrganizer {
    
    /**
     Returns the correct `TransferHandler` for a given `Connection`.
     
     - parameters:
        - connection: The `Connection`, for which the `TransferHandler` should be configured.
     */
    static func getTransferHandler(for configuration: Configuration) -> TransferHandler? {
        switch configuration.to.type {
//        case .local:
//            return LocalTransferHandler.init(connection: connection)
        case .sftp:
            if configuration.to is SFTPConnection {
                return SFTPTransferHandler(from: configuration.from, to: (configuration.to as! SFTPConnection))
            } else {
                return nil
            }
        default:
            return nil
        }
    }
}

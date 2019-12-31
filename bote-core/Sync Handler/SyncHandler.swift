//
//  SyncHandler.swift
//  bote-core
//
//  Created by Pascal Braband on 11.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//
// Interesting library: https://github.com/amosavian/FileProvider (WebDAV, FTP, Dropbox, OneDrive)

import Foundation

protocol SyncHandler {
    init(connection: Connection)
    func uploadFile(path: String)
    func removeFile(path: String)
    func renameFile(src: String, dst: String)
    
    // SyncHandlers should connect automatically, just a convenience function
    func connect()
    func terminate()
}


class SyncHandlerOrganizer {
    
    /**
     Returns the correct `SyncHandler` for a given `Connection`.
     
     - parameters:
        - connection: The `Connection`, for which the `SyncHandler` should be configured.
     */
    static func getSyncHandler(for connection: Connection) -> SyncHandler? {
        switch connection.type {
//        case .local:
//            return LocalSyncHandler.init(connection: connection)
        case .sftp:
            return SFTPSyncHandler(connection: connection)
        default:
            return nil
        }
    }
}

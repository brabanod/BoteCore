//
//  FileWatcher.swift
//  bote-core
//
//  Created by Pascal Braband on 10.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import Foundation
import Combine


typealias FileWatcher = AnyPublisher<FileEvent, FileWatcherError>


class FileWatcherOrganizer {
    
    /**
     Returns the correct `FileWatcher` for a given `Connection`.
     
     - parameters:
        - connection: The `Connection`, for which the `FileWatcher` should be configured.
     */
    static func getFileManager(for connection: Connection) -> FileWatcher {
        switch connection.type {
        case .local:
            return LocalFileWatcher.init(watchPath: connection.path).eraseToAnyPublisher()
//        case .sftp:
//            return SFTPFileWatcher.init(...)
        default:
            return LocalFileWatcher.init(watchPath: connection.path).eraseToAnyPublisher()
        }
    }
}

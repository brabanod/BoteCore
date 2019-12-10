//
//  FileWatcher.swift
//  bote-core
//
//  Created by Pascal Braband on 10.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import Foundation
import Combine

enum FileWatcher {
    case local(watcher: LocalFileWatcher)
    //case remote(watcher: RemoveFileWatcher)
}

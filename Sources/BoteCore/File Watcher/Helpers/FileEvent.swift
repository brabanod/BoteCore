//
//  FileEvent.swift
//  bote-core
//
//  Created by Pascal Braband on 10.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import Foundation

public enum FileEvent: Equatable {
    case createdFile(path: String)
    case createdDir(path: String)
    case renamed(src: String, dst: String)
    case removedFile(path: String)
    case removedDir(path: String)
}

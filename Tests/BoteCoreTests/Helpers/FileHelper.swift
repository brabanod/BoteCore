//
//  FileHelper.swift
//  bote-core-tests
//
//  Created by Pascal Braband on 11.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import Foundation
@testable import BoteCore


func createFile(at path: String) {
    safetyNet(path: path) {
        shell("touch \(path)")
    }
}


func removeFile(at path: String) {
    safetyNet(path: path) {
        shell("rm \(path)")
    }
}


func createDir(at path: String) {
    safetyNet(path: path) {
        shell("mkdir \(path)")
    }
}


func removeDir(at path: String) {
    safetyNet(path: path) {
        shell("rm -rf \(path)")
    }
    
}


func moveItem(from src: String, to dst: String) {
    safetyNet(path: src, dst) {
        shell("mv \(src) \(dst)")
    }
}


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


func safetyNet(path: String..., completion: () -> ()) {
    // Should prevent accidently operating on wrong path in file system
    if path.allSatisfy({ $0.hasPrefix("/private/tmp/") }) {
        completion()
    } else {
        fatalError("Operating on unauthorized path: \(path).")
    }
}

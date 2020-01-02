//
//  main.swift
//  bote-core
//
//  Created by Pascal Braband on 10.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import Foundation


let watchPath = "\(NSHomeDirectory())/Desktop/watchDir"


//let watchSubscriber = LocalFileWatcher.init(watchPath: watchPath).sink(receiveCompletion: { (completion) in
//    switch completion {
//    case .finished:
//        print("Finished watching")
//    case .failure(let error):
//        print("Error watching: \(error)")
//    }
//}) { (event) in
//    print(event)
//}

//FileManager.default.createFile(atPath: watchPath+"/myfile.txt", contents: "hello".data(using: .utf8), attributes: nil)

//let f = LocalConnection(path: "/Users/pascal/watchDir/")
//let t = try SFTPConnection(path: testsBasepath, host: SFTPServer.host, port: SFTPServer.port, user: SFTPServer.user, authentication: .password(value: SFTPServer.password))
//
//let syncHandler = SFTPSyncHandler.init(from: f, to: t)
//try syncHandler.upload(path: "/Users/pascal/watchDir/asdf.txt" , isDir: true)

//RunLoop.main.run()
print("finished")

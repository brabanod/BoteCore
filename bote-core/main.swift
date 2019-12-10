//
//  main.swift
//  bote-core
//
//  Created by Pascal Braband on 10.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import Foundation


let watchPath = "\(NSHomeDirectory())/Desktop/watchDir"


let watchSubscriber = LocalFileWatcher.init(watchPath: watchPath).sink(receiveCompletion: { (completion) in
    switch completion {
    case .finished:
        print("Finished watching")
    case .failure(let error):
        print("Error watching: \(error)")
    }
}) { (event) in
    print(event)
}

//FileManager.default.createFile(atPath: watchPath+"/myfile.txt", contents: "hello".data(using: .utf8), attributes: nil)


RunLoop.main.run()


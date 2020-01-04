//
//  LocalFileWatcher.swift
//  bote-core
//
//  Created by Pascal Braband on 10.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import Foundation
import Combine
import EonilFSEvents

struct LocalFileWatcher: Publisher {
    typealias Output = FileEvent
    typealias Failure = FileWatcherError
    
    let watchPath: String
    
    init(watchPath: String) {
        self.watchPath = watchPath
    }
    
    func receive<S>(subscriber: S) where S: Subscriber, LocalFileWatcher.Failure == S.Failure, LocalFileWatcher.Output == S.Input {
        let subscription = LocalFileWatcherSubscription(subscriber: subscriber, watchPath: watchPath)
        subscriber.receive(subscription: subscription)
    }
}

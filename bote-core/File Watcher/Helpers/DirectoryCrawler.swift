//
//  DirectoryCrawler.swift
//  bote-core
//
//  Created by Pascal Braband on 10.12.19.
//  Copyright © 2019 Pascal Braband. All rights reserved.
//

import Foundation

class DirectoryCrawler {
    
    /**
     Crawls through a given directory and returns all files in it and it's subdirectories
     
     - returns:
     A tuple `(String, Bool)`. The `String` indicates the item, the `Bool` indicates, whether item is direcotry
     
     - parameters:
        - path: The path, which should be crawled
     */
    public static func crawl(path: String) -> [(String, Bool)] {
        var result = [(String, Bool)]()
        do {
            let resourceKeys : [URLResourceKey] = [.creationDateKey, .isDirectoryKey]
            let baseURL = URL(fileURLWithPath: path)
            let enumerator = FileManager.default.enumerator(at: baseURL,
                                    includingPropertiesForKeys: resourceKeys,
                                                       options: [.skipsHiddenFiles], errorHandler: { (url, error) -> Bool in
                                                                print("directoryEnumerator error at \(url): ", error)
                                                                return true
            })!

            for case let fileURL as URL in enumerator {
                let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                // resourceValues.creationDate!
                //print(fileURL.path, "       isDir: ", resourceValues.isDirectory!)
                result.append((fileURL.path, resourceValues.isDirectory!))
            }
        } catch {
            print(error)
        }
        return result
    }
}

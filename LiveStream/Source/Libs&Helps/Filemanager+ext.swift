//
//  Filemanager+ext.swift
//  LiveStream
//
//  Created by htv on 17/08/2022.
//

import UIKit

extension FileManager {
    func getUrls(in path: String? = nil, for directory: FileManager.SearchPathDirectory, skipsHiddenFiles: Bool = true) -> [URL]? {
        let documentsURL = path == nil ? urls(for: directory, in: .userDomainMask)[0] : urls(for: directory, in: .userDomainMask)[0].appendingPathComponent(path!)
        let fileURLs = try? contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: skipsHiddenFiles ? .skipsHiddenFiles : [] )
        return fileURLs
    }
}

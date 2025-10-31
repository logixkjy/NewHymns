//
//  BundleDBCopier.swift
//  OldHymns
//
//  Created by JooYoung Kim on 9/25/25.
//

import Foundation

public enum BundleDBCopier {
    public static func installIfNeeded(dbFileName: String = "hymn.db") throws -> String {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dst = docs.appendingPathComponent(dbFileName)
        if fm.fileExists(atPath: dst.path) { return dst.path }
        guard let src = Bundle.main.url(forResource: "hymn", withExtension: "db") else {
            throw NSError(domain: "BundleDBCopier", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bundle DB not found: hymn.db"])
        }
        try fm.copyItem(at: src, to: dst)
        return dst.path
    }
}

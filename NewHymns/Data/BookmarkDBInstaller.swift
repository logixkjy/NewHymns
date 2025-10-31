//
//  BookmarkDBInstaller.swift
//  OldHymns
//
//  Created by JooYoung Kim on 9/25/25.
//

// BookmarkDBInstaller.swift
import Foundation

enum BookmarkDBInstaller {
    static func path(dbFileName: String = "bookmark.db") throws -> String {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dst = docs.appendingPathComponent(dbFileName)
        if !fm.fileExists(atPath: dst.path) {
            fm.createFile(atPath: dst.path, contents: nil)
        }
        return dst.path
    }
}

// BookmarkDBMigrator.swift
import Foundation

enum BookmarkDBMigrator {
    static func run(on db: DBClient) throws {
        try db.execute("""
      CREATE TABLE IF NOT EXISTS TBL_BOOKMARK (
        _id    INTEGER PRIMARY KEY AUTOINCREMENT,
        number INTEGER NOT NULL,
        title  TEXT    NOT NULL
      );
    """, [])
        try db.execute("""
      CREATE TABLE IF NOT EXISTS TBL_HISTORY (
        _id    INTEGER PRIMARY KEY AUTOINCREMENT,
        number INTEGER NOT NULL,
        title  TEXT    NOT NULL,
        date   TEXT    NOT NULL
      );
    """, [])
        try? db.execute("CREATE INDEX IF NOT EXISTS idx_bm_number ON TBL_BOOKMARK(number);", [])
        try? db.execute("CREATE INDEX IF NOT EXISTS idx_hist_number ON TBL_HISTORY(number);", [])
    }
}

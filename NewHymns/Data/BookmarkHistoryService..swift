//
//  BookmarkHistoryService..swift
//  OldHymns
//
//  Created by JooYoung Kim on 9/25/25.
//

import Foundation

public struct BookmarkHistoryService {
    let db: DBClient
    public init(db: DBClient) { self.db = db }
    
    public func bookmarkedSet() throws -> Set<Int> {
        let rows = try db.query("SELECT number FROM TBL_BOOKMARK", [])
        return Set(rows.compactMap { ( $0.columns["NUMBER"] as? NSNumber)?.intValue })
    }
    
    public func isBookmarked(_ number: Int) throws -> Bool {
        let rs = try db.query("SELECT 1 FROM TBL_BOOKMARK WHERE number = ? LIMIT 1", [number])
        return rs.first != nil
    }
    
    public func setBookmark(number: Int, title: String, on: Bool) throws {
        if on {
            try db.execute("INSERT INTO TBL_BOOKMARK(number, title) VALUES(?, ?)", [number, title])
        } else {
            try db.execute("DELETE FROM TBL_BOOKMARK WHERE number = ?", [number])
        }
    }
    
    public func bookmarkDeleteAll() throws {
        try db.execute("DELETE FROM TBL_BOOKMARK", [])
        try db.execute("VACUUM", [])
    }
    
    public func historyDeleteAll() throws {
        try db.execute("DELETE FROM TBL_HISTORY", [])
        try db.execute("VACUUM", [])
    }
    
    public func upsertHistory(number: Int, title: String, iso: String) throws {
        print ("test log upsertHistory \(number)")
        try db.execute("DELETE FROM TBL_HISTORY WHERE number = ?", [number])
        try db.execute("INSERT INTO TBL_HISTORY(number, title, date) VALUES(?, ?, ?)", [number, title, iso])
    }
}

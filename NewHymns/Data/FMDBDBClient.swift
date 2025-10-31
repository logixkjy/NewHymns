//
//  FMDBDBClient.swift
//  OldHymns
//
//  Created by JooYoung Kim on 9/25/25.
//

import Foundation
import FMDB
import ComposableArchitecture

public struct SQLRow: Equatable, Sendable {
    public let columns: [String: AnyHashable]
    public init(_ c: [String: AnyHashable]) { self.columns = c }
}

public struct DBClient: Sendable {
    public var open: @Sendable (_ path: String) throws -> Void
    public var close: @Sendable () -> Void
    public var query: @Sendable (_ sql: String, _ args: [any CVarArg]) throws -> [SQLRow]
    public var execute: @Sendable (_ sql: String, _ args: [any CVarArg]) throws -> Void
}

private enum DBKey: DependencyKey {
    // 기본값은 필요 시 다른 곳에서 교체해 사용
    static let liveValue: DBClient = FMDBDBClient.live()
    static let testValue: DBClient = .init(open: { _ in }, close: {}, query: {_,_ in []}, execute: {_,_ in})
}
public extension DependencyValues {
    var db: DBClient { get { self[DBKey.self] } set { self[DBKey.self] = newValue } }
}

final class FMDBHandle: @unchecked Sendable {
    var queue: FMDatabaseQueue?
    deinit { queue?.close() }
}

public enum FMDBDBClient {
    public static func live() -> DBClient {
        let handle = FMDBHandle()
        
        let open: @Sendable (String) throws -> Void = { path in
            guard let q = FMDatabaseQueue(path: path) else {
                throw NSError(domain: "FMDBDBClient", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot open \(path)"])
            }
            handle.queue = q
            q.inDatabase { db in
                try? db.executeUpdate("PRAGMA journal_mode=WAL;", values: nil)
                try? db.executeUpdate("PRAGMA synchronous=NORMAL;", values: nil)
            }
        }
        let close: @Sendable () -> Void = { handle.queue?.close(); handle.queue = nil }
        
        let query: @Sendable (String, [any CVarArg]) throws -> [SQLRow] = { sql, args in
            guard let q = handle.queue else { return [] }
            var out: [SQLRow] = []; var thrown: Error?
            q.inDatabase { db in
                do {
                    let rs = try db.executeQuery(sql, values: args)
                    let count = Int(rs.columnCount)
                    while rs.next() {
                        var dict: [String: AnyHashable] = [:]
                        for i in 0..<count {
                            let name = (rs.columnName(for: Int32(i)) ?? "COL\(i)").uppercased()
                            if let obj = rs.object(forColumnIndex: Int32(i)) {
                                switch obj {
                                case let n as NSNumber: dict[name] = n
                                case let s as NSString: dict[name] = String(s)
                                default: dict[name] = "\(obj)"
                                }
                            } else { dict[name] = "" }
                        }
                        out.append(SQLRow(dict))
                    }
                    rs.close()
                } catch { thrown = error }
            }
            if let e = thrown { throw e }
            return out
        }
        
        let execute: @Sendable (String, [any CVarArg]) throws -> Void = { sql, args in
            guard let q = handle.queue else { return }
            var thrown: Error?
            q.inDatabase { db in
                do { try db.executeUpdate(sql, values: args) } catch { thrown = error }
            }
            if let e = thrown { throw e }
        }
        
        return DBClient(open: open, close: close, query: query, execute: execute)
    }
}

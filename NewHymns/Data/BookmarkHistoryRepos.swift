//
//  BookmarkHistoryRepos.swift
//  OldHymns
//
//  Created by JooYoung Kim on 10/2/25.
//

// Data/BookmarkHistoryRepos.swift
import Foundation
import ComposableArchitecture

struct HistoryItem: Equatable, Identifiable, Sendable {
    var id: Int { number }
    let number: Int
    let title: String
    let date: String
}

struct BookmarkRepo: Sendable {
    var list: @Sendable () async throws -> [Hymn]
    var add:  @Sendable (_ number: Int, _ title: String) async throws -> Void
    var remove: @Sendable (_ number: Int) async throws -> Void
    var removeAll: @Sendable () async throws -> Void
    var isBookmarked: @Sendable (_ number: Int) async throws -> Bool
}
struct HistoryRepo: Sendable {
    var list: @Sendable () async throws -> [HistoryItem]     // 최근 순
    var add:  @Sendable (_ number: Int, _ title: String) async throws -> Void
    var remove: @Sendable (_ number: Int) async throws -> Void
    var removeAll: @Sendable () async throws -> Void
}

enum BookmarkRepoKey: DependencyKey {
    static let liveValue = BookmarkRepo(
        list: { [] },
        add: { _, _ in },
        remove: { _ in },
        removeAll: {},
        isBookmarked: { _ in false }
    )
}
enum HistoryRepoKey: DependencyKey {
    static let liveValue = HistoryRepo(
        list: { [] },
        add: { _, _ in },
        remove: { _ in },
        removeAll: {}
    )
}

extension DependencyValues {
    var bookmarkRepo: BookmarkRepo {
        get { self[BookmarkRepoKey.self] }
        set { self[BookmarkRepoKey.self] = newValue }
    }
    var historyRepo: HistoryRepo {
        get { self[HistoryRepoKey.self] }
        set { self[HistoryRepoKey.self] = newValue }
    }
}

//
//  HymnRepository.swift
//  OldHymns
//
//  Created by JooYoung Kim on 9/25/25.
//

import Foundation
import ComposableArchitecture

public struct HymnRepository: Sendable {
    public var search: @Sendable (_ query: String) throws -> [Hymn]
    public var byNumber: @Sendable (_ number: Int) throws -> Hymn?
    public var toggleBookmark: @Sendable (_ id: Int, _ newValue: Bool) throws -> Hymn
    public var addHistory: @Sendable (_ number: Int, _ title: String) throws -> Void
    
    public init(
        search: @escaping @Sendable (String) throws -> [Hymn],
        byNumber: @escaping @Sendable (Int) throws -> Hymn?,
        toggleBookmark: @escaping @Sendable (Int, Bool) throws -> Hymn,
        addHistory: @escaping @Sendable (Int, String) throws -> Void
    ) { self.search = search; self.byNumber = byNumber; self.toggleBookmark = toggleBookmark; self.addHistory = addHistory }
}

private enum HymnRepoKey: DependencyKey {
    static let liveValue = HymnRepository(
        search: { _ in [] }, byNumber: { _ in nil },
        toggleBookmark: { id,_ in Hymn(number: id, title: "", words: "", bookmark: false, img: "", youtubeId: 0) },
        addHistory: { _,_ in }
    )
    static let testValue = liveValue
}
public extension DependencyValues {
    var hymnRepo: HymnRepository {
        get { self[HymnRepoKey.self] }
        set { self[HymnRepoKey.self] = newValue }
    }
}

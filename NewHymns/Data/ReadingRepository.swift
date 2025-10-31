//
//  ReadingRepository.swift
//  OldHymns
//
//  Created by JooYoung Kim on 9/25/25.
//

import Foundation
import ComposableArchitecture

public struct ReadingRepository: Sendable {
    public var search: @Sendable (_ query: String) throws -> [Reading]
    public var byNumber: @Sendable (_ number: Int) throws -> Reading?
    
    public init(
        search: @escaping @Sendable (String) throws -> [Reading],
        byNumber: @escaping @Sendable (Int) throws -> Reading?
    ) { self.search = search; self.byNumber = byNumber }
}

private enum ReadingRepoKey: DependencyKey {
    static let liveValue = ReadingRepository(search: { _ in [] }, byNumber: { _ in nil })
    static let testValue = liveValue
}
public extension DependencyValues {
    var readingRepo: ReadingRepository {
        get { self[ReadingRepoKey.self] }
        set { self[ReadingRepoKey.self] = newValue }
    }
}

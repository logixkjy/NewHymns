//
//  Hymn.swift
//  OldHymns
//
//  Created by JooYoung Kim on 9/25/25.
//

// Models/Hymn.swift
import Foundation
public struct Hymn: Equatable, Identifiable, Sendable, Hashable {
    public var id: Int { number }
    public let number: Int
    public let title: String
    public let words: String
    public var bookmark: Bool
    public var img: String
    public var youtubeId: Int
    public init(number: Int, title: String, words: String, bookmark: Bool, img: String, youtubeId: Int) {
        self.number = number; self.title = title; self.words = words; self.bookmark = bookmark; self.img = img; self.youtubeId = youtubeId
    }
}

// Models/Reading.swift
import Foundation
public struct Reading: Equatable, Identifiable, Sendable {
    public var id: Int { number }
    public let number: Int
    public let title: String
    public let words: String
    public init(number: Int, title: String, words: String) {
        self.number = number; self.title = title; self.words = words
    }
}

enum Mode: Int, Equatable { case score = 1, lyrics = 0 }

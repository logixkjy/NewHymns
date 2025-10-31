//
//  HymnsYouTubeIndex.swift
//  OldHymns
//
//  Created by JooYoung Kim on 10/13/25.
//

// Data/HymnsYouTubeIndex.swift
import Foundation

struct HymnLink: Decodable {
    let index: Int
    let youtube: String
}
struct HymnJSON: Decodable {
    let ver: Int
    let list: [HymnLink]
}

enum HymnsYouTubeIndex {
    // 프로세스 내 캐시
    private static var cache: [Int: String]?
    
    /// JSON을 로드해 번호→YouTubeID 딕셔너리 리턴
    static func load() throws -> [Int: String] {
        if let c = cache { return c }
        guard let url = Bundle.main.url(forResource: "newHymns", withExtension: "json") else {
            throw NSError(domain: "OldHymnsYouTubeIndex", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "newHymns.json not found in bundle"])
        }
        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode(HymnJSON.self, from: data)
        
        // 일부 항목에 "=-xxx" 같은 오염이 있을 수 있어 정제
        var dict: [Int: String] = [:]
        for item in decoded.list {
            let id = sanitizeYouTubeID(item.youtube)
            guard !id.isEmpty else { continue }
            // 중복 index가 있으면 "마지막 값이 이긴다"
            dict[item.index] = id
        }
        cache = dict
        return dict
    }
    
    /// 번호로 YouTube ID 조회
    static func youtubeID(for number: Int) -> String? {
        (try? load())?[number]
    }
    
    /// YouTube ID 정제: [A-Za-z0-9-_]만 허용
    private static func sanitizeYouTubeID(_ raw: String) -> String {
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_")
        return String(raw.unicodeScalars.filter { allowed.contains($0) })
    }
}

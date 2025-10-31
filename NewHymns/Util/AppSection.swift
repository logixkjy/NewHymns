//
//  AppSection.swift
//  OldHymns
//
//  Created by JooYoung Kim on 10/2/25.
//

// AppSection.swift
// AppSection.swift
import Foundation

enum AppSection: Equatable, Hashable, CaseIterable {
    case hymns          // 찬송가
    case bookmarks      // 북마크
    case history        // 히스토리
    case readings       // 교독문
    case lordsPrayer    // 주기도문
    case apostlesCreed  // 사도신경
    case tenCommandments// 십계명
    case settings       // 설정
    
    var title: String {
        switch self {
        case .hymns: return "찬송가"
        case .bookmarks: return "북마크"
        case .history: return "히스토리"
        case .readings: return "교독문"
        case .lordsPrayer: return "주기도문"
        case .apostlesCreed: return "사도신경"
        case .tenCommandments: return "십계명"
        case .settings: return "설정"
        }
    }
    
    var systemImage: String {
        switch self {
        case .hymns: return "music.note.list"
        case .bookmarks: return "bookmark"
        case .history: return "clock"
        case .readings: return "text.book.closed"
        case .lordsPrayer: return "hands.sparkles"
        case .apostlesCreed: return "cross"
        case .tenCommandments: return "list.number"
        case .settings: return "gearshape"
        }
    }
}

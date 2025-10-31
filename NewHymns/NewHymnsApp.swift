//
//  NewHymnsApp.swift
//  NewHymns
//
//  Created by JooYoung Kim on 10/31/25.
//

import SwiftUI
import ComposableArchitecture
import GoogleMobileAds

@main
struct NewHymnsApp: App {
    // AppDelegate를 SwiftUI에서 사용하기 위한 설정
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    private var adManager = AppOpenAdManager.shared
    
    var body: some Scene {
        WindowGroup {
            RootView(
                store: Store(initialState: RootFeature.State()) {
                    RootFeature()
                } withDependencies: { dep in
                    // 1) hymn.db / bookmark.db 열기
                    let hymnPath = try! BundleDBCopier.installIfNeeded(dbFileName: "hymn.db")
                    let hymnDB = FMDBDBClient.live()
                    try? hymnDB.open(hymnPath)
                    
                    let markPath = try! BookmarkDBInstaller.path()
                    let markDB = FMDBDBClient.live()
                    try? markDB.open(markPath)
                    try? BookmarkDBMigrator.run(on: markDB)
                    
                    // 2) 서비스 & 테이블명 감지 → 클로저 밖 로컬 상수로 보관 (dep 캡처 금지)
                    let markService = BookmarkHistoryService(db: markDB)
                    
                    func resolveReadingTable(_ db: DBClient) -> String {
                        if let r = try? db.query("SELECT name FROM sqlite_master WHERE type='table' AND name='NEW_DOCTRINAL' LIMIT 1", []), !r.isEmpty { return "NEW_DOCTRINAL" }
                        if let r = try? db.query("SELECT name FROM sqlite_master WHERE type='table' AND name='RESPONSIVE' LIMIT 1", []), !r.isEmpty { return "RESPONSIVE" }
                        return "NEW_DOCTRINAL"
                    }
                    let readingTable = resolveReadingTable(hymnDB)
                    
                    // 3) 여기서부터 dep 를 캡처하지 않는 리포지토리 생성
                    dep.hymnRepo = HymnRepository(
                        search: { q in
                            let query = q.trimmingCharacters(in: .whitespacesAndNewlines)
                            let bookmarked = try markService.bookmarkedSet()
                            
                            // 1) 숫자: number 부분 일치
                            if KoreanSearch.isNumeric(query) {
                                let like = "%\(query)%"
                                let rows = try hymnDB.query("""
                            SELECT number, title, words, img, youtubeId
                            FROM NEW_HYMN
                            WHERE CAST(number AS TEXT) LIKE ?
                            ORDER BY number
                          """, [like])
                                
                                return rows.map { r in
                                    let num = (r.columns["NUMBER"] as! NSNumber).intValue
                                    return Hymn(
                                        number: num,
                                        title:  r.columns["TITLE"] as! String,
                                        words:  r.columns["WORDS"] as! String,
                                        bookmark: bookmarked.contains(num),
                                        img: r.columns["IMG"] as! String,
                                        youtubeId: (r.columns["YOUTUBEID"] as? NSNumber)?.intValue ?? 0
                                    )
                                }
                            }
                            
                            // 2) 초성: 전적으로 클라이언트에서 매칭 (LIKE 선필터로 누락되는 문제 방지)
                            if KoreanSearch.isInitialsQuery(query) {
                                // 1) 전체(또는 상한) 로딩
                                let rows = try hymnDB.query("""
                                SELECT number, title, words, img, youtubeId
                                FROM NEW_HYMN
                                ORDER BY number
                              """, [])
                                
                                // 2) 공백 처리:
                                // - 쿼리에 공백이 **없으면**: 공백 무시 매칭 (ㄱㄴㄷ → ㄱㄴㄷ 검색)
                                // - 쿼리에 공백이 **있으면**: 단어 경계 매칭 (ㄱ ㄴ → '첫 단어 ㄱ, 다음 단어 ㄴ')
                                let hasSpaceInQuery = query.contains { $0.isWhitespace }
                                let filtered: [SQLRow]
                                
                                if hasSpaceInQuery {
                                    // 단어 경계(공백 의미 존중)
                                    filtered = rows.filter { r in
                                        let words = (r.columns["WORDS"] as! String)
                                        return KoreanSearch.matchesInitialTokens(query: query, inWords: words)
                                    }
                                } else {
                                    // 공백 무시(유연)
                                    let needle = KoreanSearch.removeAllSpaces(KoreanSearch.initialsWithSpaces(of: query))
                                    filtered = rows.filter { r in
                                        let words = (r.columns["WORDS"] as! String)
                                        let hay = KoreanSearch.compactInitials(of: words) // 모든 공백 제거
                                        return hay.localizedCaseInsensitiveContains(needle)
                                    }
                                }
                                
                                return filtered.map { r in
                                    let num = (r.columns["NUMBER"] as! NSNumber).intValue
                                    return Hymn(
                                        number: num,
                                        title:  r.columns["TITLE"] as! String,
                                        words:  r.columns["WORDS"] as! String,
                                        bookmark: bookmarked.contains(num),
                                        img: r.columns["IMG"] as! String,
                                        youtubeId: (r.columns["YOUTUBEID"] as? NSNumber)?.intValue ?? 0
                                    )
                                }
                            }
                            
                            // 3) 일반 텍스트: title/words LIKE
                            let like = "%\(query)%"
                            let rows = try hymnDB.query("""
                          SELECT number, title, words, img, youtubeId
                          FROM NEW_HYMN
                          WHERE title LIKE ? OR words LIKE ?
                          ORDER BY number
                        """, [like, like])
                            
                            return rows.map { r in
                                let num = (r.columns["NUMBER"] as! NSNumber).intValue
                                return Hymn(
                                    number: num,
                                    title:  r.columns["TITLE"] as! String,
                                    words:  r.columns["WORDS"] as! String,
                                    bookmark: bookmarked.contains(num),
                                    img: r.columns["IMG"] as! String,
                                    youtubeId: (r.columns["YOUTUBEID"] as? NSNumber)?.intValue ?? 0
                                )
                            }
                        },
                        byNumber: { n in
                            guard let row = try hymnDB.query("""
                          SELECT number, title, words, img, youtubeId
                          FROM NEW_HYMN
                          WHERE number = ?
                        """, [n]).first else { return nil }
                            let num = (row.columns["NUMBER"] as! NSNumber).intValue
                            let isBM = try markService.isBookmarked(num)
                            return Hymn(
                                number: num,
                                title:  row.columns["TITLE"] as! String,
                                words:  row.columns["WORDS"] as! String,
                                bookmark: isBM,
                                img: row.columns["IMG"] as! String,
                                youtubeId: (row.columns["YOUTUBEID"] as? NSNumber)?.intValue ?? 0
                            )
                        },
                        toggleBookmark: { id, newValue in
                            // dep 를 쓰지 말고 hymnDB/markService 로 처리
                            guard let row = try hymnDB.query(
                                "SELECT number, title, words, img, youtubeId FROM NEW_HYMN WHERE number = ?",
                                [id]
                            ).first else {
                                // 없는 번호면 그대로 반환(또는 throw)
                                return Hymn(number: id, title: "", words: "", bookmark: false, img: "", youtubeId: 0)
                            }
                            
                            let title = row.columns["TITLE"] as! String
                            try markService.setBookmark(number: id, title: title, on: newValue)
                            
                            // 최신 상태 재조회 (자기 자신 dep.hymnRepo 호출 금지)
                            let isBM = try markService.isBookmarked(id)
                            return Hymn(
                                number: (row.columns["NUMBER"] as! NSNumber).intValue,
                                title:  title,
                                words:  row.columns["WORDS"] as! String,
                                bookmark: isBM,
                                img: row.columns["IMG"] as! String,
                                youtubeId: (row.columns["YOUTUBEID"] as? NSNumber)?.intValue ?? 0
                            )
                        },
                        addHistory: { number, title in
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd"
                            formatter.timeZone = .current     // ✅ 시스템 타임존 (기존 NSDateFormatter와 동일)
                            formatter.locale = Locale.current // ✅ 로케일도 시스템 기준
                            let iso = formatter.string(from: Date())
//                            let iso = ISO8601DateFormatter().string(from: Date())
                            try markService.upsertHistory(number: number, title: title, iso: iso)
                        }
                    )
                    
                    // 교독문 리포지토리도 동일 원칙으로 dep 미캡처
                    dep.readingRepo = ReadingRepository(
                        search: { q in
                            let query = q.trimmingCharacters(in: .whitespacesAndNewlines)
//                            print("query = \(query)")
                            // 2) 초성: 전적으로 클라이언트에서 매칭 (LIKE 선필터로 누락되는 문제 방지)
                            if KoreanSearch.isInitialsQuery(query) {
                                let rows = try hymnDB.query("""
                                SELECT number, title, words
                                FROM \(readingTable)
                                ORDER BY number
                              """, [])
                                
                                let hasSpaceInQuery = query.contains { $0.isWhitespace }
                                
                                // 공통 헬퍼: 제목→본문 순으로 검사, 그리고 rank(0:title, 1:words)
                                func matchRank(title: String, words: String) -> Int? {
                                    if hasSpaceInQuery {
                                        if KoreanSearch.matchesInitialTokens(query: query, inWords: title) { return 0 }
                                        if KoreanSearch.matchesInitialTokens(query: query, inWords: words) { return 1 }
                                    } else {
                                        let needle = KoreanSearch.removeAllSpaces(KoreanSearch.initialsWithSpaces(of: query))
                                        // 제목 먼저
                                        let titleHay = KoreanSearch.compactInitials(of: title)
                                        if titleHay.localizedCaseInsensitiveContains(needle) { return 0 }
                                        // 없으면 본문
                                        let wordsHay = KoreanSearch.compactInitials(of: words)
                                        if wordsHay.localizedCaseInsensitiveContains(needle) { return 1 }
                                    }
                                    return nil
                                }
                                
                                // 제목/본문 매칭 + rank 부여
                                let matched: [(row: SQLRow, rank: Int)] = rows.compactMap { r in
                                    let title = r.columns["TITLE"] as! String
                                    let words = r.columns["WORDS"] as! String
                                    if let rank = matchRank(title: title, words: words) {
                                        return (r, rank)
                                    }
                                    return nil
                                }
                                
                                // 제목에서 매칭된 것(rank 0)을 우선 노출, 그 다음 번호순
                                let sorted = matched.sorted {
                                    if $0.rank != $1.rank { return $0.rank < $1.rank }
                                    let n0 = ( $0.row.columns["NUMBER"] as! NSNumber ).intValue
                                    let n1 = ( $1.row.columns["NUMBER"] as! NSNumber ).intValue
                                    return n0 < n1
                                }
                                
                                return sorted.map { payload in
                                    let r = payload.row
                                    let num = (r.columns["NUMBER"] as! NSNumber).intValue
                                    return Reading (
                                        number: num,
                                        title:  r.columns["TITLE"] as! String,
                                        words:  r.columns["WORDS"] as! String
                                    )
                                }
                            }
                            
                            // 3) 일반 텍스트: title/words LIKE
                            let like = "%\(query)%"
                            let rows = try hymnDB.query("""
                        SELECT number, title, words 
                        FROM \(readingTable)
                          WHERE title LIKE ? OR words LIKE ?
                          ORDER BY number
                        """, [like, like])
                            
                            return rows.map { r in
                                let num = (r.columns["NUMBER"] as! NSNumber).intValue
                                return Reading(
                                    number: num,
                                    title:  r.columns["TITLE"] as! String,
                                    words:  r.columns["WORDS"] as! String
                                )
                            }
                        },
                        byNumber: { n in
                            try hymnDB.query("""
                          SELECT number, title, words FROM \(readingTable)
                          WHERE number = ?
                        """, [n]).compactMap { r in
                                Reading(
                                    number: (r.columns["NUMBER"] as! NSNumber).intValue,
                                    title:  r.columns["TITLE"] as! String,
                                    words:  r.columns["WORDS"] as! String
                                )
                            }.first
                        }
                    )
                    
                    // ❶ BookmarkRepo: bookmark.db → HYMN 조인(제목/가사 포함) 후 Hymn으로 반환
                    dep.bookmarkRepo = BookmarkRepo(
                        list: {
                            // ✅ 메인 액터 격리 메서드 안전 호출
                            let nums: Set<Int> = try await MainActor.run {
                                try markService.bookmarkedSet()
                            }
                            guard !nums.isEmpty else { return [] }
                            
                            // IN (?,?,?) 플레이스홀더 구성
                            let placeholders = Array(repeating: "?", count: nums.count).joined(separator: ",")
                            let rows = try hymnDB.query("""
                          SELECT number, title, words, img, youtubeId FROM NEW_HYMN
                          WHERE number IN (\(placeholders))
                          ORDER BY number
                        """, Array(nums) )
                            
                            return rows.map { r in
                                let num = (r.columns["NUMBER"] as! NSNumber).intValue
                                return Hymn(
                                    number: num,
                                    title:  r.columns["TITLE"] as! String,
                                    words:  r.columns["WORDS"] as! String,
                                    bookmark: true,
                                    img:    r.columns["IMG"] as! String,
                                    youtubeId: (r.columns["YOUTUBEID"] as? NSNumber)?.intValue ?? 0
                                )
                            }
                        },
                        
                        add: { number, title in
                            // ✅ 기존 서비스 DB 규약 그대로 사용
                            try await MainActor.run {
                                try markService.setBookmark(number: number, title: title, on: true)
                            }
                        },
                        
                        remove: { number in
                            try await MainActor.run {
                                try markService.setBookmark(number: number, title: "", on: false)
                            }
                        },
                        
                        removeAll: {
                            try await MainActor.run {
                                try markService.bookmarkDeleteAll()
                            }
                        },
                        
                        isBookmarked: { number in
                            let s: Set<Int> = try await MainActor.run {
                                try markService.bookmarkedSet()
                            }
                            return s.contains(number)
                        }
                    )
                    
                    // ❷ HistoryRepo: TBL_HISTORY → 최근순으로 반환
                    dep.historyRepo = HistoryRepo(
                        list: {
                            let rows = try await MainActor.run {
                                try markService.db.query("""
                              SELECT number, title, date
                              FROM TBL_HISTORY
                              ORDER BY date DESC, _id DESC
                            """, [])
                            }
                            return rows.map { r in
                                HistoryItem(
                                    number: (r.columns["NUMBER"] as! NSNumber).intValue,
                                    title:  r.columns["TITLE"] as! String,
                                    date:   r.columns["DATE"] as! String
                                )
                            }
                        },
                        
                        add: { number, title in
                            // 중복 방지: 있으면 지우고 최신으로 삽입(스키마에 UNIQUE가 없으므로)
                            let now: String = {
                                let f = ISO8601DateFormatter()
                                f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                                return f.string(from: Date())
                            }()
                            
                            try await MainActor.run {
                                try markService.db.execute("DELETE FROM TBL_HISTORY WHERE number = ?", [number])
                                try markService.db.execute("INSERT INTO TBL_HISTORY (number, title, date) VALUES (?,?,?)",
                                                           [number, title, now])
                            }
                        },
                        
                        remove: { number in
                            try await MainActor.run {
                                try markService.db.execute("DELETE FROM TBL_HISTORY WHERE number = ?", [number])
                            }
                        },
                        
                        removeAll: {
                            try await MainActor.run {
                                try markService.historyDeleteAll()
                            }
                        }
                    )
                }
            )
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                AttAuthentication.requestIfNeeded()
            }
        }
    }
    
    func dateFromLocalString(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current  // ✅ 저장 시점과 동일하게 로컬 기준
        return formatter.date(from: string)
    }
}

//
//  BookmarksFeature.swift
//  OldHymns
//
//  Created by JooYoung Kim on 10/2/25.
//

// Features/BookmarksFeature.swift
import Foundation
import SwiftUI
import ComposableArchitecture

private let audioTimerID: String = "Bookmarks.audioTimerID"
private let bookmarkSortModeKey: String = "Bookmarks.sortMode"
private let bookmarkCustomOrderKey: String = "Bookmarks.customOrder"

@Reducer
struct BookmarksFeature {
    enum SortMode: String, CaseIterable, Equatable {
        case numberAsc
        case numberDesc
        case custom
    }

    @ObservableState
    struct State: Equatable {
        var items: [Hymn] = []
        var sortMode: SortMode = .numberAsc
        var customOrder: [Int] = []
        
        // 상세 화면
        var hymn: Hymn = Hymn(number: 0, title: "", words: "", bookmark: false, img: "", youtubeId: 0)
        var mode: Mode = .score
        var scoreImage: UIImage?
        
        // 🔹 줌 파라미터
        var minFloorFactor: CGFloat = 0.8
        var maxZoom: CGFloat = 3.0
        
        // 🔹 오디오
        var audioAvailable = false
        var isPlaying = false
        var duration: TimeInterval = 0
        var current: TimeInterval = 0

        // 🔹 새로 추가
        var isFullscreenScore = false         // 풀사이즈 악보
        var isAudioPanelPresented = false     // 오디오 패널 시트
        // 🔹 자동 스크롤
        var isAutoScrollEnabled: Bool = false // 자동 스크롤 ON/OFF
        var autoScrollSpeed: Double = 4.5     // 1-8 = 스크롤 속도
    }
    
    enum Action: Equatable {
        case onAppear
        case refresh
        case loaded([Hymn])
        case setSortMode(SortMode)
        case move(IndexSet, Int)
        case delete(IndexSet)
        case open(Hymn)
        
        case select(Hymn)
        
        // 상세
        case onAppearDetail
        case setMode(Mode)
        case toggleBookmark
        case openYouTube
        case nextHymn
        case prevHymn
        // 오디오
        case playPause
        case stop
        case tick                          // 현재/길이/재생상태 동기화 요청
        // ✅ 내부 상태 갱신용 (unsafeBitCast 제거)
        case _internalUpdate(current: TimeInterval, duration: TimeInterval, playing: Bool)
        
        // 타이머 제어
        case startTicker
        case cancelTicker
        
        // 🔹 새로 추가
        case toggleFullscreenScore(Bool)      // true=켜기/false=끄기
        case setAudioPanel(Bool)              // 하단 시트 표시/해제
        
        // 🔹 자동 스크롤
        case toggleAutoScroll                 // 자동 스크롤 ON/OFF
        case setAutoScrollSpeed(Double)       // 스크롤 속도 설정
        
        // 로딩
        case loadedAssets(score: UIImage?, hasAudio: Bool, duration: TimeInterval)
        
        // 상위 동기화
        case updated(Hymn)
    }
    @Dependency(\.bookmarkRepo) var bookmarkRepo
    @Dependency(\.hymnRepo) var hymnRepo
    @Dependency(\.audio) var audio
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                if let raw = UserDefaults.standard.string(forKey: bookmarkSortModeKey),
                   let saved = SortMode(rawValue: raw) {
                    state.sortMode = saved
                }
                state.customOrder = UserDefaults.standard.array(forKey: bookmarkCustomOrderKey) as? [Int] ?? []
                return .run { send in
                    let list = try await bookmarkRepo.list()
                    await send(.loaded(list))
                }
            case .refresh:
                return .run { send in
                    let list = try await bookmarkRepo.list()
                    await send(.loaded(list))
                }
            case .loaded(let hymns):
                state.items = Self.applySort(items: hymns, mode: state.sortMode, customOrder: state.customOrder)
                state.customOrder = state.items.map(\.number)
                UserDefaults.standard.set(state.customOrder, forKey: bookmarkCustomOrderKey)
                return .none
            case .setSortMode(let mode):
                state.sortMode = mode
                state.items = Self.applySort(items: state.items, mode: mode, customOrder: state.customOrder)
                state.customOrder = state.items.map(\.number)
                UserDefaults.standard.set(mode.rawValue, forKey: bookmarkSortModeKey)
                UserDefaults.standard.set(state.customOrder, forKey: bookmarkCustomOrderKey)
                return .none
            case .move(let source, let destination):
                state.items.move(fromOffsets: source, toOffset: destination)
                state.sortMode = .custom
                state.customOrder = state.items.map(\.number)
                UserDefaults.standard.set(SortMode.custom.rawValue, forKey: bookmarkSortModeKey)
                UserDefaults.standard.set(state.customOrder, forKey: bookmarkCustomOrderKey)
                return .none
            case .delete(let idxSet):
              let toDelete = idxSet.map { state.items[$0].number }
              state.items.remove(atOffsets: idxSet)
              state.customOrder.removeAll { toDelete.contains($0) }
              UserDefaults.standard.set(state.customOrder, forKey: bookmarkCustomOrderKey)

              return .run { send in
                await withTaskGroup(of: Void.self) { group in
                  for n in toDelete {
                    group.addTask {
                      try? await bookmarkRepo.remove(n)   // ✅ 병렬 실행
                    }
                  }
                  await group.waitForAll()
                }
                await send(.refresh)
              }
            case .open:
                return .none
                
                
                
            case .select(let h):
//                state.selection = HymnDetailFeature.State(hymn: h)
                state.hymn = h
                return .none
                
            case .onAppearDetail:
                do {
                    try hymnRepo.addHistory(state.hymn.number, state.hymn.title)
                } catch { }
                let imgName = state.hymn.img
                return .run { [num = state.hymn.number] send in
                    let img = imgName.isEmpty ? nil : UIImage(named: imgName)
                    let has = await audio.preload(num)
                    let dur = await audio.duration()
                    await send(.loadedAssets(score: img, hasAudio: has, duration: dur))
                    if await audio.isPlaying() { await send(.startTicker) }
                    await send(.tick)
                }
//                return .none
                
            case .loadedAssets(let score, let hasAudio, let dur):
                state.scoreImage = score
                state.audioAvailable = hasAudio
                state.duration = dur
                return .none
                
                // MARK: 모드
            case .setMode(let m):
                state.mode = m
                return .none
                
                // MARK: 북마크
            case .toggleBookmark:
                do {
                    let upd = try hymnRepo.toggleBookmark(state.hymn.id, !state.hymn.bookmark)
                    state.hymn = upd
                    return .send(.updated(upd))
                } catch { return .none }
                
                // MARK: 곡 이동
            case .nextHymn:
                guard let idx = state.items.firstIndex(where: { $0.number == state.hymn.number }), idx < state.items.count - 1 else {
                    return .none
                }
                let h = state.items[idx + 1]
                state.hymn = h
                do {
                    try hymnRepo.addHistory(state.hymn.number, state.hymn.title)
                } catch { }
                let img = h.img.isEmpty ? nil : UIImage(named: h.img)
                return .run { [n = h.number] send in
                    let has = await audio.preload(n)
                    let dur = await audio.duration()
                    await send(.loadedAssets(score: img, hasAudio: has, duration: dur))
                    await send(.tick)
                }
                
            case .prevHymn:
                guard let idx = state.items.firstIndex(where: { $0.number == state.hymn.number }), idx > 0 else {
                    return .none
                }
                let h = state.items[idx - 1]
                state.hymn = h
                do {
                    try hymnRepo.addHistory(state.hymn.number, state.hymn.title)
                } catch { }
                let img = h.img.isEmpty ? nil : UIImage(named: h.img)
                return .run { [n = h.number] send in
                    let has = await audio.preload(n)
                    let dur = await audio.duration()
                    await send(.loadedAssets(score: img, hasAudio: has, duration: dur))
                    await send(.tick)
                }
                
                // MARK: 재생/정지 + 타이머
            case .playPause:
                return .run { [num = state.hymn.number, ready = state.audioAvailable] send in
                    if await audio.isPlaying() {
                        await audio.pause()
                        await send(.tick); await send(.cancelTicker)
                    } else {
                        var ready = ready
                        if !ready { ready = await audio.preload(num) }
                        guard ready else { return }
                        await audio.play()
                        await send(.tick)
                        try? await Task.sleep(nanoseconds: 50_000_000)
                        await send(.tick)
                        await send(.startTicker)
                    }
                }
//                return .none
                
            case .stop:
                return .run { send in
                    await audio.stop()
                    await send(.tick)
                    await send(.cancelTicker)
                }
                
            case .startTicker:
                return .run { send in
                    while !Task.isCancelled {
                        try await Task.sleep(nanoseconds: 500_000_000)
                        await send(.tick)
                    }
                }
                .cancellable(id: audioTimerID, cancelInFlight: true)
//                return .none
                
            case .cancelTicker:
                return .cancel(id: audioTimerID)
                
            case .tick:
                return .run { send in
                    let cur = await audio.currentTime()
                    let dur = await audio.duration()
                    let playing = await audio.isPlaying()

                    await send(._internalUpdate(current: cur, duration: dur, playing: playing))
                }
//                return .none

            case ._internalUpdate(let cur, let dur, let playing):
                state.current = cur
                state.duration = dur
                state.isPlaying = playing
                return .none
                
                // MARK: 유튜브
            case .openYouTube:
                if let id = HymnsYouTubeIndex.youtubeID(for: state.hymn.number),
                   let url = URL(string: "https://www.youtube.com/watch?v=\(id)") {
                    UIApplication.shared.open(url)
                } else {
                    // 매핑이 없으면 검색으로 폴백
                    let q = "찬송가 \(state.hymn.number)장 \(state.hymn.title) 악보"
                    if let url = URL(string:
                                        "https://www.youtube.com/results?search_query=\(q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
                    ) {
                        UIApplication.shared.open(url)
                    }
                }
                return .none
                
            case .updated:
                return .none
                
                // 🔹 토글 분기만 추가
            case .toggleFullscreenScore(let on):
                state.isFullscreenScore = on
                return .none
                
            case .setAudioPanel(let on):
                state.isAudioPanelPresented = on
                return .none
                
                // 🔹 자동 스크롤
            case .toggleAutoScroll:
                state.isAutoScrollEnabled.toggle()
                return .none
                
            case .setAutoScrollSpeed(let speed):
                state.autoScrollSpeed = speed
                return .none
            }
        }
    }
}

private extension BookmarksFeature {
    static func applySort(items: [Hymn], mode: SortMode, customOrder: [Int]) -> [Hymn] {
        switch mode {
        case .numberAsc:
            return items.sorted { $0.number < $1.number }
        case .numberDesc:
            return items.sorted { $0.number > $1.number }
        case .custom:
            let orderIndex = Dictionary(uniqueKeysWithValues: customOrder.enumerated().map { ($1, $0) })
            return items.sorted { lhs, rhs in
                let l = orderIndex[lhs.number] ?? Int.max
                let r = orderIndex[rhs.number] ?? Int.max
                if l != r { return l < r }
                return lhs.number < rhs.number
            }
        }
    }
}

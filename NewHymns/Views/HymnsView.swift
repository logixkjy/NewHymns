//
//  HymnsView.swift
//  OldHymns
//
//  Created by JooYoung Kim on 9/25/25.
//

// Features/HymnsView.swift
import SwiftUI
import ComposableArchitecture

// 회전 감지용 도우미: size 변경을 관찰해 가로/세로 상태를 바인딩으로 반영
private struct OrientationReader: View {
    @Binding var isLandscape: Bool
    var body: some View {
        GeometryReader { geo in
            Color.clear
                .onAppear {
                    isLandscape = geo.size.width > geo.size.height
                }
                .onChange(of: geo.size) { newSize in
                    isLandscape = newSize.width > newSize.height
                }
        }
    }
}

struct HymnsView: View {
    let store: StoreOf<HymnsFeature>
    init(store: StoreOf<HymnsFeature>) { self.store = store }
    
    // 섹션 모델
    struct SectionInfo: Identifiable, Hashable {
        let id: Int
        let title: String        // "1~50" 등
        let items: [Hymn]
        var anchorID: String { "section-\(id)" }
    }
    
    // results를 50개씩 잘라 섹션을 만든다
    private func makeSections(_ items: [Hymn], size: Int = 50) -> [SectionInfo] {
        let sorted = items.sorted { $0.number < $1.number }
        guard !sorted.isEmpty else { return [] }
        var out: [SectionInfo] = []; var offset = 0; var sid = 0
        while offset < sorted.count {
            let end = min(offset + size, sorted.count)
            out.append(.init(id: sid, title: "\(offset+1)~\(end)", items: Array(sorted[offset..<end])))
            sid += 1; offset = end
        }
        return out
    }
    
    @FocusState private var searchFocused: Bool
    @State private var isLandscape = false
    @Environment(\.horizontalSizeClass) private var hClass
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { vs in
            WithPerceptionTracking {
                let rebuildKey = vs.isLandscape ? "land" : "port"
                let isSearching = !vs.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                
                VStack(spacing: 0) {
                    // 회전 감지 (최상단에 배치)
                    OrientationReader(isLandscape: $isLandscape)
                        .frame(height: 0)
                    
                    // 상단 고정 검색바
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                        TextField("번호(123) 또는 가사/초성(ㄱㄴㄷ) 검색",
                                  text: vs.binding(get: \.query, send: HymnsFeature.Action.setQuery))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($searchFocused)
                        .submitLabel(.search)
                        .onSubmit { store.send(.search) }
                        if !vs.query.isEmpty {
                            Button {
                                vs.send(.binding(.set(\.query, "")))
                                store.send(.search)
                            } label: {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(.ultraThinMaterial)
                    
                    Divider()
                    
                    // 본문: 검색 중이면 평면 리스트, 아니면 섹션+인덱스
                    if isSearching {
                        FlatList(store: store, results: vs.results, hClass: hClass)
                        // 회전 시 강제 재빌드 (캐시 레이아웃 제거)
                            .id(isLandscape ? "flat-land" : "flat-port")
                            .transition(.opacity)
                    } else {
                        let sections = makeSections(vs.results, size: 50)
                        SectionedListWithIndex(
                            store: store,
                            sections: sections,
                            hClass: hClass,
                            isLandscape: isLandscape
                        )
                        .id(isLandscape ? "sec-land" : "sec-port")
                        .transition(.opacity)
                    }
                    
                    // 하단 광고(있다면)
                    BannerSlot()
                }
                .id(rebuildKey)
                .onAppear {
                    store.send(.startObserveOrientation)
                    store.send(.search)
                }
                .onDisappear {
                  store.send(.stopObserveOrientation)
                }
                .refreshable { store.send(.search) }
                .animation(.easeInOut, value: isSearching)
            }
        }
    }
}

// MARK: - Cell 재사용
private struct HymnCell: View {
    let store: StoreOf<HymnsFeature>
    let h: Hymn
    @Environment(\.horizontalSizeClass) private var hClass
    
    var body: some View {
        NavigationLink {
            HymnDetailView(store: store, hymn: h)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(h.number)").monospaced()
                    Text(h.title).font(hClass == .regular ? .title3 : .headline)
                    if h.bookmark {
                        Image(systemName: "bookmark.fill").foregroundStyle(.yellow)
                    }
                }
                Text(h.words.replacingOccurrences(of: ":", with: " "))
                    .lineLimit(1)                 // 한 줄 고정
                    .truncationMode(.tail)        // 말줄임 위치
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading) // 좌측 정렬 고정
            .contentShape(Rectangle()) // 탭 범위 확대
        }
    }
}

// MARK: - 검색 중: 섹션/인덱스 없음
private struct FlatList: View {
    let store: StoreOf<HymnsFeature>
    let results: [Hymn]
    let hClass: UserInterfaceSizeClass?
    
    var body: some View {
        List {
            ForEach(results) { h in HymnCell(store: store, h: h) }
        }
        .listStyle(.plain)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }
}

// MARK: - 기본: 섹션 + 인덱스 바
private struct SectionedListWithIndex: View {
    let store: StoreOf<HymnsFeature>
    let sections: [HymnsView.SectionInfo]
    let hClass: UserInterfaceSizeClass?
    let isLandscape: Bool
    
    var body: some View {
        ScrollViewReader { proxy in
            WithPerceptionTracking {
                ZStack(alignment: .trailing) {
                    List {
                        ForEach(sections) { section in
                            Section(
                                header:
                                    Text(section.title)
                                    .font(.headline)
                                    .textCase(nil)           // iPad에서 자동 대문자화 방지
                                    .id(section.anchorID)    // 헤더에 앵커
                            ) {
                                ForEach(section.items) { h in HymnCell(store: store, h: h) }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    // 회전 시 스크롤리더도 리셋
                    .id(isLandscape ? "reader-land" : "reader-port")
                    
                    if sections.count > 1 {
                        VStack(spacing: 6) {
                            ForEach(sections, id: \.id) { section in
                                Button {
                                    let anchor = section.anchorID
                                    DispatchQueue.main.async {
                                        withAnimation(.easeInOut) { proxy.scrollTo(anchor, anchor: .top) }
                                    }
                                } label: {
                                    Text(section.title.split(separator: "~").first.map(String.init) ?? section.title)
                                        .font(.caption2)
                                        .padding(.vertical, 2).padding(.horizontal, 6)
                                        .background(.ultraThinMaterial, in: Capsule())
                                }
                            }
                        }
                        .padding(.trailing, 6)
                    }
                }
            }
        }
    }
}

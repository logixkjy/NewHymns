//
//  ReadingsView.swift
//  OldHymns
//
//  Created by JooYoung Kim on 9/25/25.
//

// Features/ReadingsView.swift
import SwiftUI
import ComposableArchitecture

struct ReadingsView: View {
    let store: StoreOf<ReadingsFeature>
    init(store: StoreOf<ReadingsFeature>) { self.store = store }
    
    @FocusState private var searchFocused: Bool
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { vs in
            VStack(spacing: 0) {
                // 상단 고정 검색바
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                    TextField("제목/내용 초성(ㄱㄴㄷ) 검색", text: vs.binding(get: \.query, send: ReadingsFeature.Action.setQuery))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($searchFocused)
                        .submitLabel(.search)
                        .onSubmit { store.send(.search) }
                    if !vs.query.isEmpty {
                        Button {
                            vs.send(.binding(.set(\.query, "")))
                            store.send(.search)
                        } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                    }
                }
                .padding(12)
                .background(.ultraThinMaterial)
                
                List {
                    ForEach(vs.results) { h in
                        NavigationLink {
                            NavWrapped(
                                title: "\(h.title)",
                                mode: .detail() // 기본은 dismiss()
                            ) {
                                // ✅ 상세로 이동: 원본 html 전달 (목록 셀 미리보기는 '<' 이전만 보여주고 있음)
                                ReadingsDetailView(
                                    store: Store(
                                        initialState: ReadingsDetailFeature.State(
                                            reading: h
                                        )
                                    ) {
                                        ReadingsDetailFeature()
                                    }
                                )
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack { Text("\(h.number)").monospaced(); Text(h.title).font(.headline) }
                                Text(h.words.split(separator: "<").first.map(String.init) ?? h.words) // 미리보기만 태그 제거
                                    .lineLimit(1)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                
                BannerSlot()
            }
            .onAppear {
                store.send(.search)
                if InterstitialAdManager.shared.recordEventAndCheckShow() {
                    InterstitialAdManager.shared.showIfAvailable()
                }
            }
            .refreshable { store.send(.search) }
        }
    }
}

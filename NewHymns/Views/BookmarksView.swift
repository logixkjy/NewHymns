//
//  BookmarksView.swift
//  OldHymns
//
//  Created by JooYoung Kim on 10/2/25.
//

// Features/BookmarksView.swift
import SwiftUI
import ComposableArchitecture

struct BookmarksView: View {
    let store: StoreOf<BookmarksFeature>
    var body: some View {
        WithViewStore(store, observe: { $0 }) { vs in
            VStack(spacing: 0) {
                List {
                    ForEach(vs.items) { h in BookmarkHymnCell(store: store, h: h) }
                        .onDelete { vs.send(.delete($0)) }
                }
                .listStyle(.plain)
                
                BannerSlot()
            }
            .onAppear {
                vs.send(.onAppear)
                if InterstitialAdManager.shared.recordEventAndCheckShow() {
                    InterstitialAdManager.shared.showIfAvailable()
                }
            }
            .refreshable { vs.send(.refresh) }
        }
    }
}

// MARK: - Cell 재사용
private struct BookmarkHymnCell: View {
    let store: StoreOf<BookmarksFeature>
    let h: Hymn
    var body: some View {
        NavigationLink {
            BookmarksDetailView(
                store: store,
                hymn: h
            )
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(h.number)").monospaced()
                    Text(h.title).font(.headline)
                }
                Text(h.words.replacingOccurrences(of: ":", with: " "))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

//
//  HistoryView.swift
//  OldHymns
//
//  Created by JooYoung Kim on 10/2/25.
//

// Features/HistoryView.swift
import SwiftUI
import ComposableArchitecture

struct HistoryView: View {
    let store: StoreOf<HistoryFeature>
    var body: some View {
        WithViewStore(store, observe: { $0 }) { vs in
            VStack(spacing: 0) {
                List {
                    ForEach(vs.items) { h in
                        HistoryHymnCell(store: store, h: h)
                    }
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
private struct HistoryHymnCell: View {
    let store: StoreOf<HistoryFeature>
    let h: HistoryItem
    var body: some View {
        NavigationLink {
            HistoryDetailView(
                store: store,
                hymn: h
            )
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(h.number)").monospaced()
                    Text(h.title).font(.headline)
                }
                Text(h.date).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

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
    @State private var editMode: EditMode = .inactive

    var body: some View {
        VStack(spacing: 0) {
            List {
                ForEach(store.items) { h in BookmarkHymnCell(store: store, h: h) }
                    .onDelete { store.send(.delete($0)) }
                    .onMove { from, to in
                        store.send(.move(from, to))
                    }
            }
            .listStyle(.plain)
            
            BannerSlot()
        }
        .onAppear {
            store.send(.onAppear)
        }
        .refreshable { store.send(.refresh) }
        .environment(\.editMode, $editMode)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("번호 오름차순") { store.send(.setSortMode(.numberAsc)) }
                    Button("번호 내림차순") { store.send(.setSortMode(.numberDesc)) }
                    Button("직접 정렬") { store.send(.setSortMode(.custom)) }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if store.sortMode == .custom {
                    EditButton()
                }
            }
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

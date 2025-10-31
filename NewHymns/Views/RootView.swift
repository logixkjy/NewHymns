//
//  RootView.swift
//  OldHymns
//
//  Created by JooYoung Kim on 9/25/25.
//

// Views/RootView.swift  (슬라이드 컨테이너)
import SwiftUI
import ComposableArchitecture

struct RootView: View {
    @State private var isSplash: Bool = true
    
    @Environment(\.scenePhase) private var scenePhase
    
    let store: StoreOf<RootFeature>
    init(store: StoreOf<RootFeature>) { self.store = store }
    private let menuWidth: CGFloat = 280
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { vs in
            ZStack(alignment: .leading) {
                if isSplash {
                    SplashView(isSplash: $isSplash)
                        .preferredColorScheme(.dark)
                } else {
                    ContentHost(
                        selection: vs.selection,
                        hymns: store.scope(state: \.hymns, action: RootFeature.Action.hymns),
                        bookmarks: store.scope(state: \.bookmarks, action: RootFeature.Action.bookmarks),
                        history: store.scope(state: \.history, action: RootFeature.Action.history),
                        readings: store.scope(state: \.readings, action: RootFeature.Action.readings),
                        lordsPrayer: store.scope(state: \.lordsPrayer, action: RootFeature.Action.lordsPrayer),
                        apostlesCreed: store.scope(state: \.apostlesCreed, action: RootFeature.Action.apostlesCreed),
                        tenCommandments: store.scope(state: \.tenCommandments, action: RootFeature.Action.tenCommandments),
                        settings: store.scope(state: \.settings, action: RootFeature.Action.settings),
                        onTapMenu: { vs.send(.toggleMenu(nil)) }
                    )
                    .disabled(vs.menuOpen)
                    .offset(x: vs.menuOpen ? menuWidth * 0.4 : 0)
                    .animation(.easeInOut(duration: 0.2), value: vs.menuOpen)
                    .onChange(of: scenePhase) { newPhase in
                        switch newPhase {
                        case .active:
//                            print("AppOpenAd did become active.")
                            AppOpenAdManager.shared.showAdIfAvailable()
                        case .background:
//                            print("AppOpenAd moved to background. Pre-loading next ad...")
                            Task {
                                await AppOpenAdManager.shared.loadAd()
                            }
                            break
                        case .inactive:
                            break
                        @unknown default:
                            break
                        }
                    }
                    
                    if vs.menuOpen {
                        Color.black.opacity(0.25).ignoresSafeArea()
                            .onTapGesture { vs.send(.toggleMenu(false)) }
                            .transition(.opacity)
                    }
                    
                    SideMenuView(selection: vs.selection) { sec in
                        vs.send(.select(sec))
                    }
                    .frame(width: menuWidth)
                    .offset(x: vs.menuOpen ? 0 : -menuWidth)
                    .animation(.easeInOut(duration: 0.2), value: vs.menuOpen)
                }
            }
            .gesture(
                DragGesture().onEnded { value in
                    let x = value.translation.width
                    if !vs.menuOpen, x > 80 { vs.send(.toggleMenu(true)) }
                    if vs.menuOpen, x < -80 { vs.send(.toggleMenu(false)) }
                }
            )
                
        }
    }
}

// Views/RootView.swift (ContentHost 부분만 교체/수정)
private struct ContentHost: View {
    let selection: AppSection
    let hymns: StoreOf<HymnsFeature>
    let bookmarks: StoreOf<BookmarksFeature>
    let history: StoreOf<HistoryFeature>
    let readings: StoreOf<ReadingsFeature>
    let lordsPrayer: StoreOf<StaticPageFeature>
    let apostlesCreed: StoreOf<StaticPageFeature>
    let tenCommandments: StoreOf<StaticPageFeature>
    let settings: StoreOf<SettingsFeature>
    let onTapMenu: () -> Void
    
    var body: some View {
        Group {
            switch selection {
            case .hymns:
                NavWrapped(title: "찬송가", mode: .main(onMenu: onTapMenu)) {
                    HymnsView(store: hymns)
                }
            case .bookmarks:
                NavWrapped(title: "북마크", mode: .main(onMenu: onTapMenu)) {
                    BookmarksView(store: bookmarks)
                }
            case .history:
                NavWrapped(title: "히스토리", mode: .main(onMenu: onTapMenu)) {
                    HistoryView(store: history)
                }
            case .readings:
                NavWrapped(title: "교독문", mode: .main(onMenu: onTapMenu)) {
                    ReadingsView(store: readings)
                }
            case .lordsPrayer:
                NavWrapped(title: "주기도문", mode: .main(onMenu: onTapMenu)) {
                    StaticPageView(store: lordsPrayer)
                }
            case .apostlesCreed:
                NavWrapped(title: "사도신경", mode: .main(onMenu: onTapMenu)) {
                    StaticPageView(store: apostlesCreed)
                }
            case .tenCommandments:
                NavWrapped(title: "십계명", mode: .main(onMenu: onTapMenu)) {
                    StaticPageView(store: tenCommandments)
                }
            case .settings:
                NavWrapped(title: "설정", mode: .main(onMenu: onTapMenu)) {
                    SettingsView(store: settings)
                }
            }
        }
    }
}

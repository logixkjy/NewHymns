//
//  RootFeature.swift
//  OldHymns
//
//  Created by JooYoung Kim on 9/25/25.
//

// Features/RootFeature.swift
import Foundation
import ComposableArchitecture

@Reducer
struct RootFeature {
    @ObservableState
    struct State: Equatable {
        var hymns = HymnsFeature.State()
        var readings = ReadingsFeature.State()
        var bookmarks = BookmarksFeature.State()
        var history = HistoryFeature.State()
        var lordsPrayer = StaticPageFeature.State(title: "주기도문", text: StaticTexts.lordsPrayer)
        var apostlesCreed = StaticPageFeature.State(title: "사도신경", text: StaticTexts.apostlesCreed)
        var tenCommandments = StaticPageFeature.State(title: "십계명", text: StaticTexts.tenCommandments)
        var settings = SettingsFeature.State()
        
        var menuOpen = false
        var selection: AppSection = .hymns
    }
    
    enum Action: Equatable {
        case toggleMenu(Bool?)
        case select(AppSection)
        case hymns(HymnsFeature.Action)
        case readings(ReadingsFeature.Action)
        case bookmarks(BookmarksFeature.Action)
        case history(HistoryFeature.Action)
        case lordsPrayer(StaticPageFeature.Action)
        case apostlesCreed(StaticPageFeature.Action)
        case tenCommandments(StaticPageFeature.Action)
        case settings(SettingsFeature.Action)
    }
    
    var body: some Reducer<State, Action> {
        Scope(state: \.hymns, action: /Action.hymns) { HymnsFeature() }
        Scope(state: \.readings, action: /Action.readings) { ReadingsFeature() }
        Scope(state: \.bookmarks, action: /Action.bookmarks) { BookmarksFeature() }
        Scope(state: \.history, action: /Action.history) { HistoryFeature() }
        Scope(state: \.lordsPrayer, action: /Action.lordsPrayer) { StaticPageFeature() }
        Scope(state: \.apostlesCreed, action: /Action.apostlesCreed) { StaticPageFeature() }
        Scope(state: \.tenCommandments, action: /Action.tenCommandments) { StaticPageFeature() }
        Scope(state: \.settings, action: /Action.settings) { SettingsFeature() }
        
        Reduce { state, action in
            switch action {
            case .toggleMenu(let v):
                state.menuOpen = v ?? !state.menuOpen
                return .none
            case .select(let sec):
                state.selection = sec
                state.menuOpen = false
                return .none
            case .hymns, .readings, .bookmarks, .history, .lordsPrayer, .apostlesCreed, .tenCommandments, .settings:
                return .none
            }
        }
    }
}

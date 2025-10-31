//
//  SettingsFeature.swift
//  OldHymns
//
//  Created by JooYoung Kim on 10/20/25.
//

import Foundation
import ComposableArchitecture
import SwiftUI

@Reducer
struct SettingsFeature: Reducer {
    @ObservableState
    struct State: Equatable {
        var preventAutoLock = false
        var autoPlayMusic: Bool = false
        var appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.0.0"
        var showResetAlert: Bool = false
        var resetTarget: ResetTarget? = nil
        
        enum ResetTarget: String, Equatable {
            case bookmark = "북마크"
            case history = "히스토리"
        }
    }
    
    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case togglePreventAutoLock(Bool)
        case toggleAutoPlayMusic(Bool)
        case resetButtonTapped(State.ResetTarget)
        case confirmReset(State.ResetTarget)
        case setShowResetAlert(Bool)
        case cancelReset
    }
    
    @Dependency(\.continuousClock) var clock
    @Dependency(\.historyRepo) var historyRepo
    @Dependency(\.bookmarkRepo) var bookmarkRepo
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(_):
                return .none
                
            case .togglePreventAutoLock(let value):
                state.preventAutoLock = value
                UIApplication.shared.isIdleTimerDisabled = value
                return .none
                
            case .toggleAutoPlayMusic(let value):
                state.autoPlayMusic = value
                return .none
                
            case .resetButtonTapped(let target):
                state.resetTarget = target
                state.showResetAlert = true
                return .none
                
            case .confirmReset(let target):
                return .run  { send in
                    if target == .history {
                        try? await historyRepo.removeAll()
                    } else {
                        try? await bookmarkRepo.removeAll()
                    }
                    await send(.cancelReset)
                }
                
            case .setShowResetAlert(let alert):
                state.showResetAlert = alert
                return .none
                
            case .cancelReset:
                state.showResetAlert = false
                state.resetTarget = nil
                return .none
                
            }
        }
    }
}

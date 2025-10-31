//
//  StaticPageFeature.swift
//  OldHymns
//
//  Created by JooYoung Kim on 10/2/25.
//

// Features/StaticPageFeature.swift
import Foundation
import ComposableArchitecture

@Reducer
struct StaticPageFeature {
    @ObservableState
    struct State: Equatable {
        var title: String
        var text: String
        var fontSize: Double = 17   // ✅ 기본 폰트 크기
    }
    
    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)   // ✅ 슬라이더 바인딩용
        case setFontSize(Double)
    }
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
                
            case .binding(_):
                return .none
                
            case .setFontSize(let value):
                state.fontSize = value
                return .none
                
            }
        }
    }
}

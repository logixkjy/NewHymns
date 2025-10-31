//
//  ReadingsFeature.swift
//  OldHymns
//
//  Created by JooYoung Kim on 9/25/25.
//

// Features/ReadingsFeature.swift
import Foundation
import ComposableArchitecture

@Reducer
struct ReadingsFeature {
    @ObservableState
    public struct State: Equatable {
        public var query: String = ""
        public var results: [Reading] = []
        public var selection: ReadingsDetailFeature.State?
    }
    
    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case setQuery(String)
        case search
        case select(Reading)
        case setNavigation(ReadingsDetailFeature.State?)
        case detail(ReadingsDetailFeature.Action)
    }
    @Dependency(\.readingRepo) var readingRepo
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .setQuery(let value):
                state.query = value
                return .run { send in
                    try await Task.sleep(nanoseconds: 200_000_000)
                    await send(.search)
                }
                
            case .binding(_):
                return .none
                
            case .search:
                do {
                    state.results = try readingRepo.search(state.query)
                } catch {
                    state.results = []
                }
                return .none
                
            case .select(let r):
                state.selection = ReadingsDetailFeature.State(reading: r)
                return .none
                
            case .setNavigation(let v):
                state.selection = v
                return .none
                
            case .detail:
                return .none
            }
        }
        .ifLet(\.selection, action: /Action.detail) { ReadingsDetailFeature() }
    }
}

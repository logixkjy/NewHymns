//
//  ReadingsDetailFeature.swift
//  OldHymns
//
//  Created by JooYoung Kim on 9/25/25.
//

// Features/ReadingDetailFeature.swift
import Foundation
import ComposableArchitecture

@Reducer
struct ReadingsDetailFeature {
    @ObservableState
    struct State: Equatable {
        public var reading: Reading
    }
    
    enum Action: Equatable {
        case onAppear
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .none
            }
        }
    }
}

//
//  SettingsView.swift
//  OldHymns
//
//  Created by JooYoung Kim on 10/20/25.
//

import SwiftUI
import ComposableArchitecture

struct SettingsView: View {
    let store: StoreOf<SettingsFeature>
    @Environment(\.colorScheme) private var scheme
    
    @AppStorage("Settings.autoPlayMusic") private var storedAutoPlay = false
    @AppStorage("Settings.preventAutoLock") private var storedPreventLock = false
    
    var body: some View {
        Form {
            Section("일반 설정") {
                HStack {
                    Toggle(
                        "자동 잠금 차단",
                        isOn: Binding(
                            get: { store.preventAutoLock },
                            set: { store.send(.togglePreventAutoLock($0)) }
                        )
                    )
                    .onChange(of: store.preventAutoLock) { _, newValue in
                        storedPreventLock = newValue
                    }
                }
            }
            Section("재생 설정") {
                HStack {
                    Toggle(
                        "음악 자동 재생",
                        isOn: Binding(
                            get: { store.autoPlayMusic },
                            set: { store.send(.toggleAutoPlayMusic($0)) }
                        )
                    )
                    .onChange(of: store.autoPlayMusic) { _, newValue in
                        storedAutoPlay = newValue
                    }
                }
            }
            Section("어플리케이션 정보") {
                HStack {
                    Text("현재 버전 정보")
                    Spacer()
                    Text(store.appVersion)
                        .foregroundStyle(.secondary)
                }
            }
            Section("북마크/히스토리 설정") {
                HStack {
                    Text("북마크 초기화")
                    Spacer()
                    Button("초기화") {
                        store.send(.resetButtonTapped(.bookmark))
                    }
                }
                HStack {
                    Text("히스토리 초기화")
                    Spacer()
                    Button("초기화") {
                        store.send(.resetButtonTapped(.history))
                    }
                }
            }
        }
        .appTintedLightOnly(scheme)
        .navigationBarTitleDisplayMode(.inline)
        
        .alert(
            store.resetTarget?.rawValue ?? "",
            isPresented: Binding(
                get: { store.showResetAlert },
                set: { store.send(.setShowResetAlert($0)) }
            ),
            actions: {
                Button("취소", role: .cancel) { store.send(.cancelReset) }
                Button("초기화", role: .destructive) {
                    if let target = store.resetTarget {
                        store.send(.confirmReset(target))
                    }
                }
            },
            message: { Text("\(store.resetTarget?.rawValue ?? "") 데이터를 초기화하시겠습니까?") }
        )
        .task {
            store.send(.toggleAutoPlayMusic(storedAutoPlay))
            store.send(.togglePreventAutoLock(storedPreventLock))
        }
    }
}

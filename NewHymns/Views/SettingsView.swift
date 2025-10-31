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
        WithViewStore(store, observe: { $0 }) { vs in
            Form {
                Section("일반 설정") {
                    HStack {
                        Toggle("자동 잠금 차단", isOn: vs.binding(get: \.preventAutoLock,
                                                            send: SettingsFeature.Action.togglePreventAutoLock))
                            .onChange(of: vs.preventAutoLock) { newValue in
                                storedPreventLock = newValue
                            }
                    }
                }
                Section("재생 설정") {
                    HStack {
                        Toggle("음악 자동 재생", isOn: vs.binding(get: \.autoPlayMusic,
                                                            send: SettingsFeature.Action.toggleAutoPlayMusic))
                            .onChange(of: vs.autoPlayMusic) { newValue in
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
                            vs.send(.resetButtonTapped(.bookmark))
                        }
                    }
                    HStack {
                        Text("히스토리 초기화")
                        Spacer()
                        Button("초기화") {
                            vs.send(.resetButtonTapped(.history))
                        }
                    }
                }
            }
            .appTintedLightOnly(scheme)
            .navigationBarTitleDisplayMode(.inline)
            
            .alert(
                vs.resetTarget?.rawValue ?? "",
                isPresented: vs.binding(get: \.showResetAlert,
                                        send: SettingsFeature.Action.setShowResetAlert),
                actions: {
                    Button("취소", role: .cancel) { vs.send(.cancelReset) }
                    Button("초기화", role: .destructive) {
                        if let target = vs.resetTarget {
                            vs.send(.confirmReset(target))
                        }
                    }
                },
                message: { Text("\(vs.resetTarget?.rawValue ?? "") 데이터를 초기화하시겠습니까?") }
            )
            .task {
                vs.send(.toggleAutoPlayMusic(storedAutoPlay))
                vs.send(.togglePreventAutoLock(storedPreventLock))
            }
        }
    }
}

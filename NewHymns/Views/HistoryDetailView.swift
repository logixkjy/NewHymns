//
//  HistoryDetailView.swift
//  OldHymns
//
//  Created by JooYoung Kim on 10/15/25.
//

import SwiftUI
import ComposableArchitecture

private func fmt(_ t: TimeInterval) -> String {
    guard t.isFinite else { return "--:--" }
    let s = Int(t.rounded())
    return String(format: "%d:%02d", s/60, s%60)
}

struct HistoryDetailView: View {
    
    let store: StoreOf<HistoryFeature>
    let hymn: HistoryItem
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    
    @State private var didFirstAppear = false
    
    @AppStorage("StaticPage.fontSize") private var fontSize: Double = 17
    @AppStorage("HymnDetail.lastMode") private var savedMode: Int = Mode.score.rawValue
    
    init(store: StoreOf<HistoryFeature>, hymn: HistoryItem) {
        self.store = store
        self.hymn = hymn
    }
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { vs in
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                // MARK: - 본문
                Group {
                    if vs.mode == .score {
                        ZStack {
                            // 악보(줌)
                            if let img = vs.scoreImage {
                                GeometryReader { geo in
                                    ZoomableImage(image: img, containerSize: geo.size)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                }
                            } else {
                                VStack { Spacer(); Text("악보 이미지가 없습니다.").foregroundStyle(.secondary); Spacer() }
                            }
                        }
                    } else {
                        // 가사
                        ScrollView {
                            Text(vs.hymn.words.replacingOccurrences(of: ":", with: "\n"))
                                .font(.system(size: CGFloat(fontSize)))
                                .lineSpacing(6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                        }
                    }
                }
//                .navigationTitle("\(vs.hymn.number). \(vs.hymn.title)")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)   // ✅ 디테일일 때 기본 백버튼 숨김
                .appNavBarStyledLightOnly(scheme)
                .toolbar {
                    // 좌측
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                            }
                        }
                        .foregroundStyle(.white)
                    }
                    
                    // 중앙 타이틀
                    ToolbarItem(placement: .principal) {
                        Text("\(vs.hymn.number). \(vs.hymn.title)").font(.title3).bold()
                            .foregroundStyle(.white)
                    }
                    
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button(action: { vs.send(.openYouTube) }) {
                            Image(systemName: "play.rectangle.on.rectangle")
                        }
                        .foregroundStyle(.white)
                        .accessibilityLabel("YouTube")
                        
                        Button(action: { vs.send(.toggleBookmark) }) {
                            Image(systemName: vs.hymn.bookmark ? "bookmark.fill" : "bookmark")
                        }
                        .foregroundStyle(.white)
                        .accessibilityLabel("Bookmark")
                    }
                }
            }
            // 공통 하단 인셋: 미니플레이어 + 컨트롤바 + (가사모드 전용) 폰트 슬라이더
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    // ❸ 가사 모드일 때만 폰트 슬라이더 (컨트롤바 ‘아래’에 표시)
                    if vs.mode == .lyrics {
                        HStack(spacing: 10) {
                            Image(systemName: "textformat.size.smaller")
                            Slider(value: $fontSize, in: 12...60, step: 1)
                            Image(systemName: "textformat.size.larger")
                            Text("\(Int(fontSize))pt").font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 16)
                        .appTintedLightOnly(scheme)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                    
                    // ❷ 고정 높이 컨트롤 바 (항상 같은 레이아웃 → 요동 없음)
                    HStack {
                        CircleIconButton(systemName: "chevron.left") { vs.send(.prevHymn) }
                        Spacer(minLength: 12)
                        
                        // 🔹 악보/가사 토글 버튼
                        SelectableCircleButton(systemName: "music.note.list",
                                               isSelected: vs.mode == .score) {
                            vs.send(.setMode(.score))
                            savedMode = Mode.score.rawValue
                        }
                        
                        SelectableCircleButton(systemName: "text.book.closed",
                                               isSelected: vs.mode == .lyrics) {
                            vs.send(.setMode(.lyrics))
                            savedMode = Mode.lyrics.rawValue
                        }
                        
                        Divider().frame(height: 18)
                        
                        // 풀스크린: 항상 자리 차지 → 가사 모드시 숨김(레이아웃 고정)
                        CircleIconButton(systemName: "arrow.up.left.and.arrow.down.right") {
                            vs.send(.toggleFullscreenScore(true))
                        }
                        .opacity(vs.mode == .score ? 1 : 0)
                        .allowsHitTesting(vs.mode == .score)
                        
                        // 오디오 패널
                        CircleIconButton(systemName: "headphones") { vs.send(.setAudioPanel(true)) }
                        
                        Spacer(minLength: 12)
                        CircleIconButton(systemName: "chevron.right") { vs.send(.nextHymn) }
                    }
                    .padding(.horizontal, 24)
                    .frame(height: 56) // ✅ 고정 높이로 “자리 흔들림” 방지
                    .appTintedLightOnly(scheme)
                }
                .padding(.vertical, 8)
                .background(Color.clear) // 인셋 배경은 투명
            }
//            .animation(.easeInOut, value: vs.isPlaying)
//            .animation(.easeInOut, value: vs.mode)
            .onAppear {
                guard !didFirstAppear else { return }   // ← 다시 나타날 때는 초기화 금지
                didFirstAppear = true
                
                vs.send(.select(self.hymn))
                let m = Mode(rawValue: savedMode) ?? .score
                vs.send(.setMode(m))
                vs.send(.onAppearDetail)
            }
            // 🔹 풀사이즈 악보
            .fullScreenCover(isPresented: vs.binding(get: \.isFullscreenScore,
                                                     send: HistoryFeature.Action.toggleFullscreenScore)
            ) {
                FullscreenScoreView(
                    image: vs.scoreImage,
                    minFloorFactor: vs.minFloorFactor,
                    maxScale: vs.maxZoom,
                    onClose: { vs.send(.toggleFullscreenScore(false)) },
                    onPrev:  { vs.send(.prevHymn) },
                    onNext:  { vs.send(.nextHymn) }
                )
                .ignoresSafeArea()
            }
            // 🔹 오디오 패널(하단 시트)
            .sheet(isPresented: vs.binding(get: \.isAudioPanelPresented,
                                           send: HistoryFeature.Action.setAudioPanel)) {
                HistoryAudioBottomSheetView(store: store)
                    .presentationDetents([.height(140), .medium]) // 필요에 따라 조절
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

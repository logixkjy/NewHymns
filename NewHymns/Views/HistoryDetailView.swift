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
    @AppStorage("HymnDetail.autoScrollEnabled") private var savedScrollEnabled: Bool = false
    @AppStorage("HymnDetail.autoScrollSpeed") private var savedScrollSpeed: Double = 1.0
    
    // 자동 스크롤
    @State private var scrollOffset: CGFloat = 0
    @State private var autoScrollTimer: Timer?
    
    init(store: StoreOf<HistoryFeature>, hymn: HistoryItem) {
        self.store = store
        self.hymn = hymn
    }
    
    // 자동 스크롤 시작 (위치 리셋)
    private func startAutoScroll(speed: Double, resetPosition: Bool = true) {
        // 기존 타이머 정지
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
        
        // 위치 리셋이 필요한 경우만 (토글 ON/OFF, 모드 전환 등)
        if resetPosition {
            scrollOffset = 0
        }
        
        // 속도가 유효한 범위인지 확인
        guard speed >= 1 && speed <= 3 else {
            return
        }
        
        // 타이머 시작 (속도에 따라 스크롤 오프셋 증가)
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 0.07, repeats: true) { _ in
            scrollOffset += CGFloat(speed) * 0.0007
            if scrollOffset > 1.0 {
                scrollOffset = 1.0
                autoScrollTimer?.invalidate()
                autoScrollTimer = nil
            }
        }
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
                        ScrollViewReader { proxy in
                            ScrollView {
                                VStack(spacing: 0) {
                                    Text(vs.hymn.words.replacingOccurrences(of: ":", with: "\n"))
                                        .font(.system(size: CGFloat(fontSize)))
                                        .lineSpacing(6)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(16)
                                        .id("lyricsContent")
                                    
                                    // 자동 스크롤을 위한 투명한 스페이서
                                    Color.clear
                                        .frame(height: 1000)
                                        .id("scrollBottom")
                                }
                            }
                            .onChange(of: scrollOffset) { _, newValue in
                                withAnimation(.linear(duration: 0.1)) {
                                    proxy.scrollTo("lyricsContent", anchor: .init(x: 0.5, y: newValue))
                                }
                            }
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
            // 공통 하단 인셋: 미니플레이어 + 컨트롤바 + (가사모드 전용) 폰트 슬라이더 + 자동 스크롤 슬라이더
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    // ❸ 가사 모드일 때만 폰트 슬라이더 + 자동 스크롤 슬라이더
                    if vs.mode == .lyrics {
                        VStack(spacing: 12) {
                            // 폰트 크기 슬라이더
                            HStack(spacing: 10) {
                                Image(systemName: "textformat.size.smaller")
                                    .foregroundStyle(.primary)
                                Slider(value: $fontSize, in: 12...60, step: 1)
                                Image(systemName: "textformat.size.larger")
                                    .foregroundStyle(.primary)
                                Text("\(Int(fontSize))pt")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 40)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))
                            
                            // 자동 스크롤 컨트롤
                            HStack(spacing: 10) {
                                // 자동 스크롤 ON/OFF 토글 (아이콘만)
                                Toggle(isOn: Binding(
                                    get: { vs.isAutoScrollEnabled },
                                    set: { newValue in
                                        vs.send(.toggleAutoScroll)
                                        savedScrollEnabled = newValue
                                        if newValue {
                                            startAutoScroll(speed: vs.autoScrollSpeed)
                                        } else {
                                            autoScrollTimer?.invalidate()
                                            autoScrollTimer = nil
                                            scrollOffset = 0
                                        }
                                    }
                                )) {
                                    Image(systemName: "scroll")
                                        .foregroundStyle(.primary)
                                }
                                .toggleStyle(.switch)
                                .fixedSize()
                                
                                // 속도 조절 슬라이더 (활성화 시에만)
                                if vs.isAutoScrollEnabled {
                                    HStack(spacing: 8) {
                                        Image(systemName: "gauge.with.dots.needle.0percent")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Slider(value: Binding(
                                            get: { vs.autoScrollSpeed },
                                            set: { newValue in
                                                vs.send(.setAutoScrollSpeed(newValue))
                                                savedScrollSpeed = newValue
                                                if vs.isAutoScrollEnabled {
                                                    startAutoScroll(speed: newValue, resetPosition: false)
                                                }
                                            }
                                        ), in: 1...3, step: 0.3)
                                        Image(systemName: "gauge.with.dots.needle.100percent")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .transition(.opacity.combined(with: .scale))
                                } else {
                                    // OFF일 때 안내 텍스트
                                    Text("자동 스크롤")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))
                        }
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
                            // 악보 모드로 전환시 자동 스크롤 중지
                            autoScrollTimer?.invalidate()
                            autoScrollTimer = nil
                            scrollOffset = 0
                        }
                        
                        SelectableCircleButton(systemName: "text.book.closed",
                                               isSelected: vs.mode == .lyrics) {
                            vs.send(.setMode(.lyrics))
                            savedMode = Mode.lyrics.rawValue
                            // 가사 모드로 전환시 자동 스크롤이 활성화되어 있으면 시작
                            scrollOffset = 0
                            if vs.isAutoScrollEnabled {
                                startAutoScroll(speed: vs.autoScrollSpeed)
                            }
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
                    .frame(height: 56) // ✅ 고정 높이로 "자리 흔들림" 방지
                    .appTintedLightOnly(scheme)
                }
                .padding(.vertical, 8)
                .background(Color(.systemBackground).opacity(0.95)) // ✅ 불투명한 배경으로 변경
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
                
                // 저장된 자동 스크롤 설정 복원
                if savedScrollEnabled {
                    vs.send(.toggleAutoScroll)
                }
                vs.send(.setAutoScrollSpeed(savedScrollSpeed))
                
                // 가사 모드이고 자동 스크롤이 활성화되어 있으면 시작
                if m == .lyrics && savedScrollEnabled {
                    startAutoScroll(speed: savedScrollSpeed)
                }
            }
            .onDisappear {
                // 화면 사라질 때 타이머 정리
                autoScrollTimer?.invalidate()
                autoScrollTimer = nil
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

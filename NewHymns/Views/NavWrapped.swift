//
//  NavWrapped.swift
//  OldHymns
//
//  Created by JooYoung Kim on 10/2/25.
//

// Views/NavWrapped.swift
import SwiftUI

struct NavWrapped<Content: View>: View {
    
    @Environment(\.colorScheme) private var scheme
    
    let title: String
    let mode: Mode
    let trailing: Trailing
    let content: () -> Content
    
    // 메인/상세 모드
    enum Mode {
        case main(onMenu: () -> Void)        // 좌측: 햄버거
        case detail(onBack: (() -> Void)? = nil) // 좌측: < 뒤로(없으면 시스템 dismiss)
        var isDetail: Bool { if case .detail = self { true } else { false } }
    }
    
    // 우측 액션 구성(필요한 것만 true/클로저 제공)
    struct Trailing {
        var showBookmark = false
        var bookmarked = false
        var onToggleBookmark: (() -> Void)? = nil
        
        var showYouTube = false
        var onOpenYouTube: (() -> Void)? = nil
        
        // 필요 시 더 추가 가능(공유, 검색 등)
        var extraItems: [AnyView] = []
    }
    
    init(
        title: String,
        mode: Mode,
        trailing: Trailing = .init(),
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.mode = mode
        self.trailing = trailing
        self.content = content
    }
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            content()
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(mode.isDetail)   // ✅ 디테일일 때 기본 백버튼 숨김
                .appNavBarStyledLightOnly(scheme)
                .toolbar {
                    // 좌측
                    ToolbarItem(placement: .topBarLeading) {
                        switch mode {
                        case .main(let onMenu):
                            Button(action: onMenu) {
                                Image(systemName: "line.3.horizontal")
                            }
                            .foregroundStyle(.white)
                        case .detail(let onBack):
                            Button {
                                if let onBack { onBack() } else { dismiss() }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                }
                            }
                            .foregroundStyle(.white)
                        }
                    }
                    
                    // 중앙 타이틀
                    ToolbarItem(placement: .principal) {
                        Text(title).font((self.mode.isDetail ? .title3 : .title)).bold()
                            .foregroundStyle(.white)
                    }
                    
                    // 우측(여러 개 가능)
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        if trailing.showYouTube, let onOpenYouTube = trailing.onOpenYouTube {
                            Button(action: onOpenYouTube) {
                                Image(systemName: "play.rectangle.on.rectangle")
                            }
                            .accessibilityLabel("YouTube")
                            .foregroundStyle(.white)
                        }
                        
                        if trailing.showBookmark, let onToggleBookmark = trailing.onToggleBookmark {
                            Button(action: onToggleBookmark) {
                                Image(systemName: trailing.bookmarked ? "bookmark.fill" : "bookmark")
                            }
                            .accessibilityLabel("Bookmark")
                            .foregroundStyle(.white)
                        }
                        
                        ForEach(Array(trailing.extraItems.enumerated()), id: \.offset) { _, v in
                            v
                        }
                    }
                }
        }
    }
}

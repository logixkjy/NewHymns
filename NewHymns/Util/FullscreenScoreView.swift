//
//  FullscreenScoreView.swift
//  OldHymns
//
//  Created by JooYoung Kim on 10/15/25.
//

import SwiftUI

struct FullscreenScoreView: View {
    let image: UIImage?
    let minFloorFactor: CGFloat
    let maxScale: CGFloat
    let onClose: () -> Void
    let onPrev:  () -> Void   // 필요 없으면 제거 가능
    let onNext:  () -> Void
    
    // 튜닝
    private let closePaddingTopExtra: CGFloat = 8
    private let closePaddingTrailing: CGFloat = 12
    private let closeSize: CGFloat = 44
    
    var body: some View {
        let topInset = topSafeAreaInset()
        
        ZStack {
            // 배경만 전체 화면
            Color(.systemBackground).ignoresSafeArea()
            
            // ── 상태바 영역(topInset)만큼 '비우고' 그 아래부터 콘텐츠 시작 ──
            VStack(spacing: 0) {
                // 상단 상태바 영역은 비워둔다 (여기엔 아무것도 놓지 않음)
                Color.clear.frame(height: topInset)
                
                // 실제 콘텐츠 영역: 상태바 아래부터 화면 끝까지
                ZStack {
                    // 악보
                    if let img = image {
                        GeometryReader { geo in
                            ZoomableImage(image: img, containerSize: geo.size)
                                .frame(width: geo.size.width, height: geo.size.height)
                        }
                    } else {
                        VStack { Spacer(); Text("악보 이미지가 없습니다.").foregroundStyle(.white); Spacer() }
                    }
                    
                    // 닫기 플로팅 버튼 (상태바 아래 영역 내에서만 배치)
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: closeSize, height: closeSize)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().stroke(.white.opacity(0.35), lineWidth: 0.5))
                            .shadow(color: .black.opacity(0.45), radius: 8, y: 3)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.top, closePaddingTopExtra)        // 상태바 아래에서 살짝 내려오도록
                    .padding(.trailing, closePaddingTrailing)
                    .accessibilityLabel("닫기")
                    .accessibilityAddTraits(.isButton)
                }
            }
        }
        // 상태바는 숨기지 않음(겹침 방지). 숨기고 싶다면 아래 주석 해제:
        // .statusBarHidden(true)
    }
}

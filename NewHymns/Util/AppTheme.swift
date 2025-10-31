//
//  AppTheme.swift
//  OldHymns
//
//  Created by JooYoung Kim on 10/12/25.
//

// UI/Theme.swift
import SwiftUI

enum AppTheme {
    /// 자산에서 "AppPrimary"가 있으면 그걸 쓰고, 없으면 임시로 teal
    static var primary: Color {
        Color("AppPrimary", bundle: .main)
    }
    static var background: Color {
        Color("background", bundle: .main)
    }
    
    /// 버튼/칩 등 반투명 배경에 얹을 때
    static var primaryTranslucent: Color { primary.opacity(0.12) }
    static var primaryStroke: Color { primary.opacity(0.35) }
    
    /// 네비게이션 바 배경
    static var navBar: Color { primary.opacity(0.90) }
    
    /// 진행 바/슬라이더/토글 등 틴트
    static var tint: Color { primary }
    
    /// 상·하단 그라디언트 (시야 안정)
    static var topGradient: LinearGradient {
        LinearGradient(colors: [.black.opacity(0.22), .clear],
                       startPoint: .top, endPoint: .center)
    }
}

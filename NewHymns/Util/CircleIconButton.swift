//
//  CircleIconButton.swift
//  OldHymns
//
//  Created by JooYoung Kim on 10/15/25.
//

import SwiftUI

// 둥근 플로팅 버튼
struct CircleIconButton: View {
    let systemName: String
    let action: () -> Void
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title3.bold())
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
            // ✅ 테두리: 라이트는 테마 스트로크, 다크는 연한 화이트
                .overlay {
                    Circle().stroke(scheme == .light ? AppTheme.primaryStroke : .white.opacity(0.15), lineWidth: 1)
                }
                .foregroundStyle(scheme == .light ? AppTheme.primary : .white)
                .shadow(color: .black.opacity(0.25), radius: 6, y: 2)
        }
    }
}

struct SelectableCircleButton: View {
    let systemName: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title3.bold())
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(
                    Circle().stroke(
                        isSelected
                        ? (scheme == .light ? Color.teal : .white.opacity(0.5))
                        : (scheme == .light ? Color.teal.opacity(0.3) : .white.opacity(0.15)),
                        lineWidth: isSelected ? 2 : 1
                    )
                )
                .foregroundStyle(scheme == .light ? AppTheme.primary : .white)
                .shadow(color: .black.opacity(0.25), radius: 6, y: 2)
                .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
    }
}

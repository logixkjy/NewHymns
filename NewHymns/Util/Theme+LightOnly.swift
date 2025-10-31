//
//  Theme+LightOnly.swift
//  OldHymns
//
//  Created by JooYoung Kim on 10/12/25.
//

// UI/Theme+LightOnly.swift
import SwiftUI

struct NavBarTealOnLightModifier: ViewModifier {
    let isLight: Bool
    let background: Color   // ex) AppTheme.navBar (청록)
    let foreground: UIColor // ex) .white
    
    func body(content: Content) -> some View {
        content
            .toolbarBackground(isLight ? background : .clear, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .tint(isLight ? Color(foreground) : .accentColor)   // 우측 아이콘 흰색
        
            .onAppear {
                guard isLight else { return }
                let ap = UINavigationBarAppearance()
                ap.configureWithOpaqueBackground()
                ap.backgroundEffect = nil
                ap.backgroundColor = UIColor(background)
                ap.shadowColor = nil
                ap.titleTextAttributes = [.foregroundColor: foreground]
                ap.largeTitleTextAttributes = [.foregroundColor: foreground]
                
                let btn = UIBarButtonItemAppearance(style: .plain)
                btn.normal.titleTextAttributes = [.foregroundColor: foreground]
                ap.buttonAppearance = btn
                ap.backButtonAppearance = btn
                
                let nav = UINavigationBar.appearance()
                nav.standardAppearance = ap
                nav.scrollEdgeAppearance = ap
                nav.compactAppearance = ap
                nav.isTranslucent = false
                nav.tintColor = foreground          // ← back indicator/바 버튼 심볼도 흰색
            }
    }
}

extension View {
    /// 라이트 모드에서만: 배경 청록 고정 + 글자/아이콘 흰색
    func tealNavBarLightOnly(scheme: ColorScheme, background: Color) -> some View {
        self.modifier(NavBarTealOnLightModifier(isLight: scheme == .light,
                                                background: background,
                                                foreground: .white))
    }
}

extension View {
    /// 조건부 적용 헬퍼
    @ViewBuilder
    func applyIf<Content: View>(_ condition: Bool, _ transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
    
    /// 네비게이션 바 테마를 **라이트 모드에서만** 적용
    func appNavBarStyledLightOnly(_ scheme: ColorScheme) -> some View {
        self.applyIf(scheme == .light) {
            $0.toolbarBackground(AppTheme.navBar, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .accentColor(.white)
        }
    }
    
    /// 틴트(세그먼트/슬라이더/프로그레스 등)를 **라이트 모드에서만** 적용
    func appTintedLightOnly(_ scheme: ColorScheme) -> some View {
        self.applyIf(scheme == .light) { $0.tint(AppTheme.primary) }
    }
    
    /// 테마 배경(칩/둥근 버튼 등)을 **라이트 모드에서만** 적용
    func themedBackgroundLightOnly(_ scheme: ColorScheme, shape: some InsettableShape) -> some View {
        self.background(
            Group {
                if scheme == .light {
                    AnyView(ShapeView(shape: shape, fill: AppTheme.primaryTranslucent, stroke: AppTheme.primaryStroke))
                } else {
                    AnyView(EmptyView())
                }
            }
        )
    }
}

/// 내부 도우미 뷰
private struct ShapeView<S: InsettableShape>: View {
    let shape: S
    let fill: Color
    let stroke: Color
    var body: some View {
        shape.fill(fill)
            .overlay(shape.stroke(stroke, lineWidth: 1))
    }
}

extension View {
    /// 네비 바를 앱 테마로 칠함
    func appNavBarStyled() -> some View {
        self
            .toolbarBackground(AppTheme.navBar, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar) // 청록 위에서 가독성↑
    }
}

/// 둥근 플로팅 버튼(테마 색)
struct ThemedCircleButton: View {
    let systemName: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title3.bold())
                .foregroundStyle(.primary) // 시스템에 맡김
                .frame(width: 44, height: 44)
                .background(AppTheme.primaryTranslucent, in: Circle())
                .overlay(Circle().stroke(AppTheme.primaryStroke, lineWidth: 1))
                .shadow(color: .black.opacity(0.25), radius: 6, y: 2)
        }
    }
}

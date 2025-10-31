//
//  topSafeAreaInset.swift
//  OldHymns
//
//  Created by JooYoung Kim on 10/15/25.
//

import UIKit

// MARK: - 풀사이즈 악보 전용 화면
// iOS 13+ 키 윈도우의 상단 안전영역 값
func topSafeAreaInset() -> CGFloat {
    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = scene.windows.first(where: { $0.isKeyWindow }) else { return 0 }
    return window.safeAreaInsets.top
}

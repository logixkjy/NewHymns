//
//  AdThrottle.swift
//  OldHymns
//
//  Created by JooYoung Kim on 10/20/25.
//

import Foundation

enum AdKind: String { case appOpen, interstitial }

actor AdThrottle {
    static let shared = AdThrottle()

    // 마지막 노출 시각
    private var lastShown: [AdKind: Date] = [:]
    // 글로벌 쿨다운 (둘 다 막는 잠금시간)
    var globalCooldown: TimeInterval = 180   // 3분
    // 타입별 최소 간격(선택)
    var perTypeCooldown: [AdKind: TimeInterval] = [
        .appOpen: 90,        // 앱 오프닝 띄운 직후 90초간 동일 타입 금지
        .interstitial: 120   // 전면 띄운 직후 120초간 동일 타입 금지
    ]

    // 민감 화면 억제(예: 악보/성경 상세)시 true
    var suppressed: Bool = false

    func canShow(_ kind: AdKind) -> Bool {
        if suppressed { return false }

        let now = Date()
        // 1) 글로벌 쿨다운: 최근 어떤 타입이든 globalCooldown 이내면 금지
        if let lastAny = lastShown.values.max(), now.timeIntervalSince(lastAny) < globalCooldown {
            return false
        }
        // 2) 타입별 쿨다운(선택)
        if let lastThis = lastShown[kind],
           let minGap = perTypeCooldown[kind],
           now.timeIntervalSince(lastThis) < minGap {
            return false
        }
        return true
    }

    func markShown(_ kind: AdKind) {
        lastShown[kind] = Date()
    }
}

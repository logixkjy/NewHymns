//
//  ATTConsent.swift
//  OldHymns
//
//  Created by JooYoung Kim on 10/29/25.
//

import Foundation
import AppTrackingTransparency
import AdSupport

enum AttAuthentication {
    static func requestIfNeeded() {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            ATTrackingManager.requestTrackingAuthorization() {
                _ in
            }
        }
    }
}

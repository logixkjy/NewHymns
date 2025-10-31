//
//  FixedBannerView.swift
//  OldHymns
//
//  Created by JooYoung Kim on 10/22/25.
//

import SwiftUI
import GoogleMobileAds

/// 항상 320x50 크기의 고정 배너.
/// 회전해도 reload 되지 않으며, 가운데 정렬로 표시.
struct FixedBannerView: UIViewRepresentable {
    let adUnitID = "ca-app-pub-2746869735313650/2526983323"
    
    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner) // ✅ 320x50 고정
        banner.adUnitID = adUnitID
        banner.rootViewController = UIApplication.shared.firstKeyWindowRootViewController()
        banner.delegate = context.coordinator
        banner.load(Request())
        return banner
    }
    
    func updateUIView(_ uiView: BannerView, context: Context) {
        // 고정 크기이므로 회전해도 reload 필요 없음
    }
    
    func makeCoordinator() -> Coordinator { Coordinator() }
    
    final class Coordinator: NSObject, BannerViewDelegate {
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
//            print("✅ FixedBannerView: banner loaded")
        }
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: any Error) {
            print("❌ FixedBannerView: failed - \(error.localizedDescription)")
        }
    }
}

private extension UIApplication {
    func firstKeyWindowRootViewController() -> UIViewController? {
        connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?.rootViewController
    }
}
private extension UIWindowScene {
    var keyWindow: UIWindow? { windows.first(where: \.isKeyWindow) }
}

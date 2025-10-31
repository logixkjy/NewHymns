//
//  BannerAdView.swift
//  OldHymns
//
//  Created by JooYoung Kim on 10/17/25.
//

// BannerAdView.swift
import SwiftUI
import GoogleMobileAds

struct BannerAdView: View {
    let adUnitID: String = "ca-app-pub-2746869735313650/6621740922"
    
    var body: some View {
        GeometryReader { geo in
            InnerBannerView(adUnitID: adUnitID, width: geo.size.width)
                .frame(width: geo.size.width, height: 64, alignment: .center) // 임시 높이; 실제는 SDK가 결정
        }
        // 배너 높이를 안정시키고 레이아웃 점프 방지 (50~100 사이가 일반적)
        .frame(height: 64)
    }
}


private struct InnerBannerView: UIViewRepresentable {
    let adUnitID: String
    let width: CGFloat

    func makeUIView(context: Context) -> BannerView {
        let initialSize = AdSizeBanner
//        print("rotation Log width \(width)  adSize(\(initialSize))")
        let banner = BannerView(adSize: initialSize)
        banner.adUnitID = adUnitID
        banner.delegate = context.coordinator
        banner.rootViewController = UIApplication.shared.firstKeyWindowRootViewController()
        banner.load(Request())
        return banner
    }

    func updateUIView(_ view: BannerView, context: Context) {
        let newSize = AdSizeBanner
//        print("rotation Log width \(width)  newSize(\(newSize))")
        if !CGSizeEqualToSize(view.adSize.size, newSize.size) {
            view.adSize = newSize
            view.load(Request())
             print("rotation Log 🔄 Banner reloaded with size: \(newSize.size)")
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, BannerViewDelegate {
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
//             print("rotation Log ✅ Banner Loaded: \(bannerView.adSize.size)")
        }
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: any Error) {
            print("rotation Log ❌ Banner Failed: \(error.localizedDescription)")
        }
    }
}


private extension UIApplication {
    func firstKeyWindowRootViewController() -> UIViewController? {
        connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?
            .rootViewController
    }
}
private extension UIWindowScene {
    var keyWindow: UIWindow? { windows.first(where:  { $0.isKeyWindow })}
}

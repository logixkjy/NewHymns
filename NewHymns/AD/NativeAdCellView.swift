//
//  NativeAdCellView.swift
//  OldHymns
//
//  Created by JooYoung Kim on 10/17/25.
//

// NativeAdCellView.swift
import SwiftUI
import GoogleMobileAds

struct NativeAdCellView: View {
    let adUnitID: String
    
    var body: some View {
        NativeAdContainer(adUnitID: adUnitID)
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 16)
    }
}

/// UIViewRepresentable로 GADNativeAdView를 감쌉니다.
struct NativeAdContainer: UIViewRepresentable {
    let adUnitID: String
    
    func makeUIView(context: Context) -> NativeAdHostingView {
        let v = NativeAdHostingView()
        v.load(adUnitID: adUnitID)
        return v
    }
    
    func updateUIView(_ uiView: NativeAdHostingView, context: Context) {}
}

/// 실제 GADNativeAdView 구성 & 로딩
final class NativeAdHostingView: UIView, NativeAdLoaderDelegate, NativeAdDelegate {
    private var adLoader: AdLoader?
    private var nativeAdView: NativeAdView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    required init?(coder: NSCoder) { fatalError() }
    
    func load(adUnitID: String) {
        let videoOptions = VideoOptions()
//        videoOptions.startMuted = true
        
        adLoader = AdLoader(
            adUnitID: adUnitID,
            rootViewController: Self.topVC(),
            adTypes: [.native],
            options: [videoOptions]
        )
        adLoader?.delegate = self
        adLoader?.load(Request())
    }
    
    // MARK: - Loader Delegate
    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        // 실패 시 빈 뷰 유지 (리스트 레이아웃 깨지지 않게)
        print("Native load fail:", error.localizedDescription)
    }
    
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        nativeAd.delegate = self
        
        // 이전 뷰 제거
        nativeAdView?.removeFromSuperview()
        
        // 간단한 카드 레이아웃 (제목/본문/CTA/미디어)
        let adView = NativeAdView(frame: .zero)
        
        // 미디어
        let mediaView = MediaView()
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        adView.mediaView = mediaView
        
        // 헤드라인
        let headline = UILabel()
        headline.font = .preferredFont(forTextStyle: .headline)
        headline.numberOfLines = 2
        headline.translatesAutoresizingMaskIntoConstraints = false
        adView.headlineView = headline
        
        // 바디
        let body = UILabel()
        body.font = .preferredFont(forTextStyle: .subheadline)
        body.textColor = .secondaryLabel
        body.numberOfLines = 3
        body.translatesAutoresizingMaskIntoConstraints = false
        adView.bodyView = body
        
        // CTA
        let cta = UIButton(type: .system)
        cta.titleLabel?.font = .preferredFont(forTextStyle: .callout).bold()
        cta.translatesAutoresizingMaskIntoConstraints = false
        adView.callToActionView = cta
        
        // 아이콘(선택)
        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        adView.iconView = iconView
        
        // 계층 구성
        let vstack = UIStackView(arrangedSubviews: [mediaView, headline, body, cta])
        vstack.axis = .vertical
        vstack.spacing = 8
        vstack.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(vstack)
        
        NSLayoutConstraint.activate([
            vstack.topAnchor.constraint(equalTo: adView.topAnchor, constant: 12),
            vstack.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 12),
            vstack.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -12),
            vstack.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -12),
            mediaView.heightAnchor.constraint(equalToConstant: 180)
        ])
        
        // 데이터 바인딩
        (adView.headlineView as? UILabel)?.text = nativeAd.headline
        (adView.bodyView as? UILabel)?.text = nativeAd.body
        (adView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
        (adView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        
        adView.mediaView?.mediaContent = nativeAd.mediaContent
        adView.nativeAd = nativeAd
        
        addSubview(adView)
        adView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            adView.topAnchor.constraint(equalTo: topAnchor),
            adView.leadingAnchor.constraint(equalTo: leadingAnchor),
            adView.trailingAnchor.constraint(equalTo: trailingAnchor),
            adView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        nativeAdView = adView
    }
    
    // MARK: - Native Delegate
    func nativeAdDidRecordImpression(_ nativeAd: NativeAd) {
        // 로그/분석 등
    }
    func nativeAdDidRecordClick(_ nativeAd: NativeAd) {}
    func nativeAdWillPresentScreen(_ nativeAd: NativeAd) {}
    func nativeAdWillDismissScreen(_ nativeAd: NativeAd) {}
    func nativeAdDidDismissScreen(_ nativeAd: NativeAd) {}
    
    static func topVC(_ base: UIViewController? = UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.keyWindow }
        .first?.rootViewController) -> UIViewController? {
            if let nav = base as? UINavigationController { return topVC(nav.visibleViewController) }
            if let tab = base as? UITabBarController { return topVC(tab.selectedViewController) }
            if let presented = base?.presentedViewController { return topVC(presented) }
            return base
        }
}

private extension UIFont {
    func bold() -> UIFont { UIFont(descriptor: fontDescriptor.withSymbolicTraits(.traitBold)!, size: pointSize) }
}

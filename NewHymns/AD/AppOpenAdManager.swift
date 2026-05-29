import GoogleMobileAds
import UIKit

protocol AppOpenAdManagerDelegate: AnyObject {
    func appOpenAdDidFinish()
}

enum AppOpenAdPlacement {
    case splash
    case resume
    
    var adUnitID: String {
        switch self {
        case .splash:
            return "ca-app-pub-2746869735313650/6386332804"
        case .resume:
            return "ca-app-pub-2746869735313650/6891626845"
        }
    }
}

final class AppOpenAdManager: NSObject {
    static let shared = AppOpenAdManager()
    
    private var appOpenAds: [AppOpenAdPlacement: AppOpenAd] = [:]
    private var loadDates: [AppOpenAdPlacement: Date] = [:]
    private var isShowingAd = false
    private var showingPlacement: AppOpenAdPlacement?
    weak var delegate: AppOpenAdManagerDelegate?

    // 너무 잦은 노출 방지 (원하면 조정)
    private var lastShownAt: [AppOpenAdPlacement: Date] = [:]
    private let minInterval: TimeInterval = 60 * 3 // 3분

    // MARK: - Public
    func startSDKIfNeeded() {
        // 중복 호출 안전
        MobileAds.shared.start()
    }
    
    func loadAd(for placement: AppOpenAdPlacement = .splash) async {
//        print("AppOpenAd loadAd")
        // 4시간 만료 체크
        if let loadDate = loadDates[placement],
           Date().timeIntervalSince(loadDate) < 60*60*4,
           appOpenAds[placement] != nil {
            return
        }
        
        do {
            let ad = try await AppOpenAd.load(
                with: placement.adUnitID, request: Request())
            appOpenAds[placement] = ad
            loadDates[placement] = Date()
            ad.fullScreenContentDelegate = self
//            print("AppOpenAd loaded")
        } catch {
            print("App open ad failed to load with error: \(error.localizedDescription)")
            appOpenAds[placement] = nil
            loadDates[placement] = nil
        }
    }
        
    /// 스플래시 종료 시점 등에서 호출
    func showAdIfAvailable(
        for placement: AppOpenAdPlacement = .splash,
        or onNoAd: (() -> Void)? = nil
    ) {
        // 빈도 제한
        if let lastShownAt = lastShownAt[placement],
           Date().timeIntervalSince(lastShownAt) < minInterval {
            onNoAd?()
            return
        }
        guard !isShowingAd else { return }
        guard let ad = appOpenAds[placement] else {
            onNoAd?()
            return
        }
        isShowingAd = true
        showingPlacement = placement
        DispatchQueue.main.async {
            ad.present(from: nil)
        }
    }

    // MARK: - Utilities
    private static func topViewController(
        _ base: UIViewController? = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?.rootViewController
    ) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return topViewController(tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return topViewController(presented)
        }
        return base
    }
}

extension AppOpenAdManager: FullScreenContentDelegate {
    func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
//        print("AppOpenAd did present")
    }
    
    func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        print("AppOpenAd fail to present:", error.localizedDescription)
        isShowingAd = false
        let placement = showingPlacement ?? .splash
        appOpenAds[placement] = nil
        loadDates[placement] = nil
        showingPlacement = nil
        Task {
            await loadAd(for: placement)
        }
        // 광고 실패 → 바로 진행
        delegate?.appOpenAdDidFinish()
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
//        print("AppOpenAd did dismiss")
        isShowingAd = false
        let placement = showingPlacement ?? .splash
        lastShownAt[placement] = Date()
        appOpenAds[placement] = nil
        loadDates[placement] = nil
        showingPlacement = nil
        Task {
            await loadAd(for: placement) // 다음 번을 위해 미리 로드
        }
        delegate?.appOpenAdDidFinish()
    }
}

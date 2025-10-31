import GoogleMobileAds
import UIKit

protocol AppOpenAdManagerDelegate: AnyObject {
    func appOpenAdDidFinish()
}

final class AppOpenAdManager: NSObject {
    static let shared = AppOpenAdManager()

    // ⚠️ 실제 운영 adUnitID로 교체 (지금은 테스트 단위)
    private let adUnitID = "ca-app-pub-2746869735313650/6386332804"

    private var appOpenAd: AppOpenAd?
    private var loadDate: Date?
    private var isShowingAd = false
    weak var delegate: AppOpenAdManagerDelegate?

    // 너무 잦은 노출 방지 (원하면 조정)
    private var lastShownAt: Date?
    private let minInterval: TimeInterval = 60 * 3 // 3분

    // MARK: - Public
    func startSDKIfNeeded() {
        // 중복 호출 안전
        MobileAds.shared.start()
    }
    
    func loadAd() async {
//        print("AppOpenAd loadAd")
        // 4시간 만료 체크
        if let loadDate, Date().timeIntervalSince(loadDate) < 60*60*4, appOpenAd != nil { return }
        
        do {
            appOpenAd = try await AppOpenAd.load(
                with: adUnitID, request: Request())
            loadDate = Date()
            appOpenAd?.fullScreenContentDelegate = self
//            print("AppOpenAd loaded")
        } catch {
            print("App open ad failed to load with error: \(error.localizedDescription)")
            appOpenAd = nil
            loadDate = nil
        }
    }
        
    /// 스플래시 종료 시점 등에서 호출
    func showAdIfAvailable(or onNoAd: (() -> Void)? = nil) {
        // 빈도 제한
        if let lastShownAt, Date().timeIntervalSince(lastShownAt) < minInterval {
            onNoAd?()
            return
        }
        guard !isShowingAd else { return }
        guard let ad = appOpenAd else {
            onNoAd?()
            return
        }
        isShowingAd = true
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
        appOpenAd = nil
        Task {
            await loadAd()
        }
        // 광고 실패 → 바로 진행
        delegate?.appOpenAdDidFinish()
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
//        print("AppOpenAd did dismiss")
        isShowingAd = false
        lastShownAt = Date()
        appOpenAd = nil
        Task {
            await loadAd() // 다음 번을 위해 미리 로드
        }
        delegate?.appOpenAdDidFinish()
    }
}

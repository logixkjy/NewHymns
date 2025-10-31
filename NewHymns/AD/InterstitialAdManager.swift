//
//  InterstitialAdManager.swift
//  OldHymns
//
//  Created by JooYoung Kim on 10/19/25.
//

import SwiftUI
import GoogleMobileAds
import Combine
import Foundation

final class InterstitialAdManager: NSObject, ObservableObject, FullScreenContentDelegate {
    static let shared = InterstitialAdManager()
    private let adUnitID = "ca-app-pub-2746869735313650/7958873328"
    
    private var interstitial: InterstitialAd?
    
    private var loadTime: Date?
    
    private(set) var viewCount = 0
    private let threshold: Int = 5
    private let cooldown: TimeInterval = 300
    
    private var isStarted = false
    
    func recordEventAndCheckShow() -> Bool {
        // 최초 한번은 무조건 광고가 표시되어야 한다.
        if !isStarted {
            isStarted.toggle()
            return true
        }
        viewCount += 1
        guard viewCount >= threshold else { return false }
        viewCount = 0

        if let last = loadTime, Date().timeIntervalSince(last) < cooldown {
            return false // 최근에 이미 노출됨
        }
        loadTime = Date()
        return true
    }
    
    func showIfAvailable() {
        if let _ = interstitial {
            present()
        } else {
            Task {
                await load(comp: {
                    present()
                })
            }
        }
    }
    
    func load(comp: () -> Void) async {
        do {
            interstitial = try await InterstitialAd.load(with: adUnitID, request: Request())
            interstitial?.fullScreenContentDelegate = self
//            print("interstitial has loaded")
            comp()
        } catch {
            print( "interstitial Failed to load \(error)")
        }
    }
    
    func present() {
        guard let root = UIApplication.shared.firstKeyWindowRootViewController() else { return }
        guard let interstitial else {
            print("interstitial Not ready! loading now"); Task { await load(comp: {}) }; return
        }
        interstitial.present(from: root)
     }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
//        print("interstitial Dismissed loading next")
        self.interstitial = nil
        Task {
            await load(comp: {})
        }
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("interstitial Failed To Present \(error)")
        self.interstitial = nil
        Task {
            await load(comp: {})
        }
    }
    
    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
//      print("interstitial \(#function) called")
    }

    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
//      print("interstitial \(#function) called")
    }
    
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
//      print("interstitial \(#function) called")
    }

    func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
//      print("interstitial \(#function) called")
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


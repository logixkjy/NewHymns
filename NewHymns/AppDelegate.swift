//
//  AppDelegate.swift
//  OldHymns
//
//  Created by JooYoung Kim on 10/15/25.
//

// AppDelegate.swift
import UIKit
import GoogleMobileAds

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        MobileAds.shared.start()
        
        return true
    }
}

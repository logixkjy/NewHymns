//
//  OrientationClient.swift
//  OldHymns
//
//  Created by JooYoung Kim on 10/22/25.
//

// Data/OrientationClient.swift
import SwiftUI
import ComposableArchitecture

public struct OrientationClient: Sendable {
    /// true = landscape, false = portrait
    public var changes: @Sendable () -> AsyncStream<Bool>
}

private func currentIsLandscape() -> Bool {
    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
        return scene.interfaceOrientation.isLandscape
    }
    // 폴백
    let b = UIScreen.main.bounds
    return b.width > b.height
}

@MainActor
private func currentIsLandscapeOnMain() -> Bool {
    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
        return scene.interfaceOrientation.isLandscape
    }
    let b = UIScreen.main.bounds
    return b.width > b.height
}

extension OrientationClient: DependencyKey {
    public static let liveValue: OrientationClient = .init(
        changes: {
            AsyncStream { cont in
                // 초기값을 MainActor에서 읽어 전달
                Task { @MainActor in
                    cont.yield(currentIsLandscapeOnMain())
                }
                
                let center = NotificationCenter.default
                let id = center.addObserver(
                    forName: UIDevice.orientationDidChangeNotification,
                    object: nil,
                    queue: .main // 노티 콜백을 메인 큐로 받기
                ) { _ in
                    Task { @MainActor in
                        // 유효한 인터페이스 방향일 때만 갱신
                        if UIDevice.current.orientation.isValidInterfaceOrientation {
                            cont.yield(currentIsLandscapeOnMain())
                        }
                    }
                }
                
                cont.onTermination = { _ in
                    center.removeObserver(id)
                }
            }
        }
    )
}

public extension DependencyValues {
    var orientation: OrientationClient {
        get { self[OrientationClient.self] }
        set { self[OrientationClient.self] = newValue }
    }
}

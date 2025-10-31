//
//  AudioPlayerClient.swift
//  OldHymns
//
//  Created by JooYoung Kim on 10/11/25.
//

// Data/AudioPlayerClient.swift
import AVFoundation
import ComposableArchitecture


public struct AudioPlayerClient: Sendable {
    public var preload:     @Sendable (_ hymnNumber: Int) async -> Bool
    public var play:        @Sendable () async -> Void
    public var pause:       @Sendable () async -> Void
    public var stop:        @Sendable () async -> Void
    public var isPlaying:   @Sendable () async -> Bool
    public var duration:    @Sendable () async -> TimeInterval
    public var currentTime: @Sendable () async -> TimeInterval
    public var seek:        @Sendable (_ time: TimeInterval) async -> Void
}

public extension AudioPlayerClient {
    // 기존 live() 대신 shared()를 제공
    static func shared(bundle: Bundle = .main) -> AudioPlayerClient {
        // 전역 공유 엔진
        struct Holder { static let engine = AudioEngine() }
        let engine = Holder.engine
        return .init(
            preload:     { n in await engine.preload(hymnNumber: n, bundle: bundle) },
            play:        { await engine.play() },
            pause:       { await engine.pause() },
            stop:        { await engine.stop() },
            isPlaying:   { await engine.isPlaying() },
            duration:    { await engine.duration() },
            currentTime: { await engine.currentTime() },
            seek:        { t in await engine.seek(to: t) }
        )
    }
}

private enum AudioClientKey: DependencyKey {
  // 🔒 반드시 "공유 엔진"을 사용해서 모든 곳이 같은 인스턴스를 보게 한다
  static let liveValue: AudioPlayerClient = .shared()  // <- 아래 구현 참고
  static let testValue: AudioPlayerClient = .init(
    preload: { _ in false }, play: {}, pause: {}, stop: {},
    isPlaying: { false }, duration: { 0 }, currentTime: { 0 }, seek: { _ in }
  )
}

public extension DependencyValues {
  var audio: AudioPlayerClient {
    get { self[AudioClientKey.self] }
    set { self[AudioClientKey.self] = newValue }
  }
}

actor AudioEngine {
    private var player: AVAudioPlayer?
    private var sessionConfigured = false
    
    private func ensureSession() async {
        guard !sessionConfigured else { return }
        await MainActor.run {
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.playback, mode: .default, options: [])
            try? session.setActive(true, options: [])
        }
        sessionConfigured = true
    }
    
    func preload(hymnNumber: Int, bundle: Bundle = .main) async -> Bool {
        await ensureSession()
        
        let candidates = ["\(hymnNumber).mp3", "\(hymnNumber).m4a", "\(hymnNumber).aac"]
        for name in candidates {
            let base = (name as NSString).deletingPathExtension
            let ext  = (name as NSString).pathExtension
            guard let url = bundle.url(forResource: base, withExtension: ext) else { continue }
            
            do {
                // 파일 IO: actor 내부(백그라운드 스레드에서 실행됨)
                let data = try Data(contentsOf: url)
                // ⬇️ AVAudioPlayer 생성/준비도 actor 내부에서!
                let p = try AVAudioPlayer(data: data)
                p.prepareToPlay()
                self.player = p
//                print("audio log preload player load!!! \(self.player == nil ? "nil" : "ok")")
                return true
            } catch {
                continue
            }
        }
        
        self.player = nil
//        print("audio log preload player nil!!!")
        return false
    }
    
    func play()  async {
        if let player = player {
            player.play()
        } else {
            print("audio log play player nil!!!")
        }
    }
    func pause() async { player?.pause() }
    func stop()  async { player?.stop(); player?.currentTime = 0 }
    func isPlaying() async -> Bool { player?.isPlaying ?? false }
    func duration()  async -> TimeInterval { player?.duration ?? 0 }
    func currentTime() async -> TimeInterval { player?.currentTime ?? 0 }
    func seek(to t: TimeInterval) async {
        guard let d = player?.duration else { return }
        player?.currentTime = max(0, min(t, d))
    }
}

public extension AudioPlayerClient {
    static func live(bundle: Bundle = .main) -> AudioPlayerClient {
        let engine = AudioEngine()
        return .init(
            preload:     { n in await engine.preload(hymnNumber: n, bundle: bundle) },
            play:        { await engine.play() },
            pause:       { await engine.pause() },
            stop:        { await engine.stop() },
            isPlaying:   { await engine.isPlaying() },
            duration:    { await engine.duration() },
            currentTime: { await engine.currentTime() },
            seek:        { t in await engine.seek(to: t) }
        )
    }
}

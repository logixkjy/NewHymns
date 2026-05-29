//
//  AudioBottomSheetView.swift
//  OldHymns
//
//  Created by JooYoung Kim on 10/12/25.
//

// Features/AudioBottomSheetView.swift
import SwiftUI
import ComposableArchitecture

private func fmt(_ t: TimeInterval) -> String {
    guard t.isFinite else { return "--:--" }
    let s = Int(t.rounded())
    return String(format: "%d:%02d", s/60, s%60)
}

struct AudioBottomSheetView: View {
    let store: StoreOf<HymnsFeature>
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { vs in
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("\(vs.hymn.number) \(vs.hymn.title)")
                        .font(.headline)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                    }
                    .accessibilityLabel("닫기")
                }
                
                HStack(spacing: 12) {
                    Button { vs.send(.playPause) } label: {
                        Image(systemName: vs.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 36))
                    }
                    .disabled(!vs.audioAvailable && !vs.isPlaying)
                    
                    let dur = max(vs.duration, 0.001)
                    VStack(spacing: 6) {
                        Slider(
                            value: Binding(
                                get: { min(max(vs.current, 0), dur) },
                                set: { newVal in Task { await AudioPlayerClient.live().seek(newVal) } }
                            ),
                            in: 0...dur
                        )
                        HStack {
                            Text(fmt(vs.current)).font(.caption.monospacedDigit())
                            Spacer()
                            Text("-" + fmt(max(vs.duration - vs.current, 0))).font(.caption.monospacedDigit())
                        }
                    }
                    
                    Button { vs.send(.stop) } label: {
                        Image(systemName: "stop.circle")
                            .font(.system(size: 36))
                    }
                }
            }
            .padding(16)
        }
    }
}

struct BookmarkAudioBottomSheetView: View {
    let store: StoreOf<BookmarksFeature>
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { vs in
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("\(vs.hymn.number) \(vs.hymn.title)")
                        .font(.headline)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                    }
                    .accessibilityLabel("닫기")
                }
                
                HStack(spacing: 12) {
                    Button { vs.send(.playPause) } label: {
                        Image(systemName: vs.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 36))
                    }
                    .disabled(!vs.audioAvailable && !vs.isPlaying)
                    
                    let dur = max(vs.duration, 0.001)
                    VStack(spacing: 6) {
                        Slider(
                            value: Binding(
                                get: { min(max(vs.current, 0), dur) },
                                set: { newVal in Task { await AudioPlayerClient.live().seek(newVal) } }
                            ),
                            in: 0...dur
                        )
                        HStack {
                            Text(fmt(vs.current)).font(.caption.monospacedDigit())
                            Spacer()
                            Text("-" + fmt(max(vs.duration - vs.current, 0))).font(.caption.monospacedDigit())
                        }
                    }
                    
                    Button { vs.send(.stop) } label: {
                        Image(systemName: "stop.circle")
                            .font(.system(size: 24))
                    }
                }
            }
            .padding(16)
        }
    }
}

struct HistoryAudioBottomSheetView: View {
    let store: StoreOf<HistoryFeature>
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { vs in
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("\(vs.hymn.number) \(vs.hymn.title)")
                        .font(.headline)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                    }
                    .accessibilityLabel("닫기")
                }
                
                HStack(spacing: 12) {
                    Button { vs.send(.playPause) } label: {
                        Image(systemName: vs.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 36))
                    }
                    .disabled(!vs.audioAvailable && !vs.isPlaying)
                    
                    let dur = max(vs.duration, 0.001)
                    VStack(spacing: 6) {
                        Slider(
                            value: Binding(
                                get: { min(max(vs.current, 0), dur) },
                                set: { newVal in Task { await AudioPlayerClient.live().seek(newVal) } }
                            ),
                            in: 0...dur
                        )
                        HStack {
                            Text(fmt(vs.current)).font(.caption.monospacedDigit())
                            Spacer()
                            Text("-" + fmt(max(vs.duration - vs.current, 0))).font(.caption.monospacedDigit())
                        }
                    }
                    
                    Button { vs.send(.stop) } label: {
                        Image(systemName: "stop.circle")
                            .font(.system(size: 24))
                    }
                }
            }
            .padding(16)
        }
    }
}

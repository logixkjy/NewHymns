//
//  ReadingsDetailView.swift
//  OldHymns
//
//  Created by JooYoung Kim on 9/25/25.
//

// Features/ReadingsDetailView.swift
import SwiftUI
import ComposableArchitecture

struct ReadingsDetailView: View {
    let store: StoreOf<ReadingsDetailFeature>
    @Environment(\.colorScheme) private var scheme
    
    @AppStorage("StaticPage.fontSize") private var storedFontSize: Double = 17
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { vs in
            WithPerceptionTracking {                // ✅ perceptible state 추적 보장
                let html = HTMLBuilder.styledHTML(
                    body: vs.reading.words,
                    fontSize: storedFontSize
                )
                
                VStack(spacing: 0) {
                    // 헤더
//                    HStack {
//                        Text("\(vs.reading.number)  \(vs.reading.title)")
//                            .font(.headline)
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                        Spacer()
//                    }
//                    .padding(.horizontal, 16)
//                    .padding(.top, 12)
                    
                    // 본문: 웹뷰가 나머지 공간을 모두 차지하도록
                    GeometryReader { geo in
                        WithPerceptionTracking {           // ✅ escaping 클로저 내부도 추적
                            HTMLWebView(html: html)
                                .frame(width: geo.size.width, height: geo.size.height)
                        }
                    }
                    
                    Divider()
                    
                    // 하단 슬라이더 바 (고정)
                    HStack(spacing: 12) {
                        Image(systemName: "textformat.size.smaller")
                        Slider(value: $storedFontSize, in: 12...60, step: 1)
                        Image(systemName: "textformat.size.larger")
                        Text("\(Int(storedFontSize))pt")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .appTintedLightOnly(scheme)
                }
//                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

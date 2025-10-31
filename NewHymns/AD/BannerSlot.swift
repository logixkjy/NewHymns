//
//  BannerSlot.swift
//  OldHymns
//
//  Created by JooYoung Kim on 10/22/25.
//

import SwiftUI

/// 부모 폭에 따라 가운데 정렬되는 320x50 고정 배너 슬롯
struct BannerSlot: View {
    var body: some View {
        HStack {
            Spacer()
            FixedBannerView()
                .frame(width: 320, height: 50)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(.ultraThinMaterial)
    }
}

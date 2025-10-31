//
//  SideMenuView.swift
//  OldHymns
//
//  Created by JooYoung Kim on 10/2/25.
//

// Views/SideMenuView.swift
import SwiftUI

struct SideMenuView: View {
    let selection: AppSection
    let onSelect: (AppSection) -> Void
    
    private let order: [AppSection] = [
        .hymns, .bookmarks, .history, .readings, .lordsPrayer, .apostlesCreed, .tenCommandments, .settings
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "leaf")
                Text("새찬송가").font(.title3).bold()
            }
            .padding(.vertical, 24).padding(.horizontal, 16)
            
            ForEach(order, id: \.self) { sec in
                Button {
                    onSelect(sec)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: sec.systemImage)
                        Text(sec.title)
                        Spacer()
                        if selection == sec { Image(systemName: "checkmark") }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(selection == sec ? Color.secondary.opacity(0.1) : .clear,
                                in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .systemBackground))
    }
}

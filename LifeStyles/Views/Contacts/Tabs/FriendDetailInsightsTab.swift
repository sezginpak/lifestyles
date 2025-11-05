//
//  FriendDetailInsightsTab.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Extracted from FriendDetailTabs.swift - Insights Tab Content
//

import SwiftUI

/// Insights tab içeriği - İletişim analitiği ve istatistikleri
struct FriendDetailInsightsTab: View {
    @Bindable var friend: Friend

    var body: some View {
        ModernInsightsView(friend: friend)
    }
}

#Preview {
    FriendDetailInsightsTab(friend: .preview)
        .modelContainer(for: Friend.self)
}

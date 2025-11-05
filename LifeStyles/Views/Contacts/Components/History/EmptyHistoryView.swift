//
//  EmptyHistoryView.swift
//  LifeStyles
//
//  Extracted from FriendDetailTabs.swift - Phase 5
//  Empty state view for when there's no contact history yet
//

import SwiftUI

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text(String(localized: "friend.no.history.yet", comment: "No history yet"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

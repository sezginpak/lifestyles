//
//  NextContactCard.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Extracted from FriendDetailTabs.swift - Next Contact Card Component
//

import SwiftUI

/// Sonraki iletişim zamanı kartı
struct NextContactCard: View {
    let friend: Friend

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: friend.needsContact ? [.red.opacity(0.2), .orange.opacity(0.2)] : [.green.opacity(0.2), .mint.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Image(systemName: friend.needsContact ? "exclamationmark.triangle.fill" : "calendar.badge.clock")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: friend.needsContact ? [.red, .orange] : [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.needsContact ? "İletişim Gerekiyor!" : "Sonraki İletişim")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(friend.needsContact ? "\(friend.daysOverdue) gün gecikti" : "\(friend.daysRemaining) gün içinde")
                    .font(.subheadline)
                    .foregroundStyle(friend.needsContact ? .red : .green)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    friend.needsContact ? Color.red.opacity(0.3) : Color.green.opacity(0.3),
                    lineWidth: 2
                )
        )
    }
}

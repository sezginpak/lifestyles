//
//  HeroStatsCard.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Extracted from FriendDetailTabs.swift - Hero Stats Component
//

import SwiftUI

/// Hero istatistik kartları - 2x2 grid (Friend Detail için)
struct FriendHeroStatsCard: View {
    let friend: Friend

    var body: some View {
        VStack(spacing: 12) {
            // İlk sıra - 2 büyük kart
            HStack(spacing: 12) {
                // İletişim Sayısı
                EnhancedStatCard(
                    icon: "phone.fill",
                    value: "\(friend.totalContactCount)",
                    label: "İletişim",
                    gradient: LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing),
                    accentColor: .blue
                )

                // İlişki Süresi
                EnhancedStatCard(
                    icon: "calendar",
                    value: "\(daysSinceCreation)",
                    label: "Gün",
                    gradient: LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing),
                    accentColor: .purple
                )
            }

            // İkinci sıra - Partner için özel veya 2 normal kart
            HStack(spacing: 12) {
                EnhancedStatCard(
                    icon: "clock.fill",
                    value: friend.frequency.displayName,
                    label: "Sıklık",
                    gradient: LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing),
                    accentColor: .orange
                )

                if friend.isPartner, let duration = friend.relationshipDuration {
                    let totalMonths = duration.years * 12 + duration.months
                    EnhancedStatCard(
                        icon: "heart.fill",
                        value: "\(totalMonths)",
                        label: "Ay Birlikte",
                        gradient: LinearGradient(colors: [.pink, .red], startPoint: .topLeading, endPoint: .bottomTrailing),
                        accentColor: .pink
                    )
                } else {
                    EnhancedStatCard(
                        icon: "message.fill",
                        value: "\(currentStreak)",
                        label: "Seri",
                        gradient: LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing),
                        accentColor: .green
                    )
                }
            }
        }
    }

    // MARK: - Helper Properties

    private var daysSinceCreation: Int {
        Calendar.current.dateComponents([.day], from: friend.createdAt, to: Date()).day ?? 0
    }

    private var currentStreak: Int {
        guard let history = friend.contactHistory, !history.isEmpty else { return 0 }

        let sorted = history.sorted(by: { $0.date > $1.date })
        var streak = 0
        var lastDate = Date()

        for item in sorted {
            let daysDiff = Calendar.current.dateComponents([.day], from: item.date, to: lastDate).day ?? 0
            if daysDiff <= friend.frequency.days + 1 {
                streak += 1
                lastDate = item.date
            } else {
                break
            }
        }

        return streak
    }
}

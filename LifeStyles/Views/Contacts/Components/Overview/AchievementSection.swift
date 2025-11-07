//
//  AchievementSection.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Extracted from FriendDetailTabs.swift - Achievement Section Component
//

import SwiftUI

/// Başarı rozetleri bölümü
struct AchievementSection: View {
    let friend: Friend

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "friend.achievements", comment: ""))
                .font(.headline)
                .foregroundStyle(.primary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(achievementBadges, id: \.title) { badge in
                        ModernAchievementBadge(badge: badge)
                    }
                }
            }
        }
    }

    // MARK: - Helper Properties

    private var achievementBadges: [FriendAchievement] {
        var badges: [FriendAchievement] = []

        if friend.totalContactCount >= 100 {
            badges.append(FriendAchievement(icon: "star.fill", title: "100 İletişim", color: .yellow))
        } else if friend.totalContactCount >= 50 {
            badges.append(FriendAchievement(icon: "star.fill", title: "50 İletişim", color: .orange))
        } else if friend.totalContactCount >= 10 {
            badges.append(FriendAchievement(icon: "star.fill", title: "10 İletişim", color: .blue))
        }

        if currentStreak >= 30 {
            badges.append(FriendAchievement(icon: "flame.fill", title: "30 Gün Seri", color: .red))
        } else if currentStreak >= 7 {
            badges.append(FriendAchievement(icon: "flame.fill", title: "7 Gün Seri", color: .orange))
        }

        if relationshipHealthScore >= 90 {
            badges.append(FriendAchievement(icon: "heart.fill", title: "Mükemmel İlişki", color: .pink))
        }

        if daysSinceCreation >= 365 {
            badges.append(FriendAchievement(icon: "calendar", title: "1 Yıl", color: .purple))
        }

        return badges
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

    private var relationshipHealthScore: Int {
        var score = 50

        // İletişim düzeni (+30)
        if !friend.needsContact {
            score += 30
        } else {
            score -= friend.daysOverdue * 2
        }

        // İletişim sıklığı (+20)
        if friend.totalContactCount > 10 {
            score += 20
        } else if friend.totalContactCount > 5 {
            score += 10
        }

        // Streak bonus (+20)
        if currentStreak > 7 {
            score += 20
        } else if currentStreak > 3 {
            score += 10
        }

        // Ruh hali ortalaması (+30)
        if let avgMood = averageMoodScore, avgMood > 0.7 {
            score += 30
        } else if let avgMood = averageMoodScore, avgMood > 0.5 {
            score += 15
        }

        return max(0, min(100, score))
    }

    private var averageMoodScore: Double? {
        guard let history = friend.contactHistory?.compactMap({ $0.mood }), !history.isEmpty else { return nil }

        let total = history.reduce(0.0) { sum, mood in
            switch mood {
            case .great: return sum + 1.0
            case .good: return sum + 0.75
            case .okay: return sum + 0.5
            case .notGreat: return sum + 0.25
            }
        }

        return total / Double(history.count)
    }

    private var daysSinceCreation: Int {
        Calendar.current.dateComponents([.day], from: friend.createdAt, to: Date()).day ?? 0
    }
}

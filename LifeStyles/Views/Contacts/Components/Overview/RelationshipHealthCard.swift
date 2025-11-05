//
//  RelationshipHealthCard.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Extracted from FriendDetailTabs.swift - Relationship Health Card Component
//

import SwiftUI

/// İlişki sağlığı kartı
struct RelationshipHealthCard: View {
    let friend: Friend

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("İlişki Sağlığı")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                Text("\(relationshipHealthScore)%")
                    .font(.title2.bold())
                    .foregroundStyle(
                        LinearGradient(
                            colors: healthGradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(height: 12)

                    // Progress
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: healthGradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(relationshipHealthScore) / 100, height: 12)
                }
            }
            .frame(height: 12)

            // Detaylar
            HStack(spacing: 20) {
                HealthIndicator(icon: "phone.fill", label: "İletişim", isGood: !friend.needsContact)
                HealthIndicator(icon: "flame.fill", label: "Seri", isGood: currentStreak > 3)
                HealthIndicator(icon: "heart.fill", label: "Ruh Hali", isGood: (averageMoodScore ?? 0) > 0.5)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: healthGradientColors.map { $0.opacity(0.3) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Helper Properties

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

    private var healthGradientColors: [Color] {
        switch relationshipHealthScore {
        case 80...100: return [.green, .mint]
        case 50..<80: return [.orange, .yellow]
        default: return [.red, .orange]
        }
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
}

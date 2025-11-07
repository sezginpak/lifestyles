//
//  MoodStreakWidget.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Mood tracking streak widget (Duolingo style)
//

import SwiftUI

struct MoodStreakWidget: View {
    let streakData: StreakData

    var body: some View {
        VStack(spacing: 16) {
            // Main streak display
            HStack(spacing: 20) {
                // Flame icon
                flameIcon

                // Streak counter
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(localized: "streak.current", defaultValue: "\(streakData.currentStreak)", comment: "Current streak"))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text(String(localized: "time.days", comment: "days"))
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    Text(streakData.isActive ? "Streak aktif!" : "Son kayıt: \(lastRecordText)")
                        .font(.caption)
                        .foregroundStyle(streakData.isActive ? .green : .secondary)
                }

                Spacer()
            }

            // Progress to next badge
            if let daysToNext = streakData.daysToNextBadge {
                nextBadgeProgress(daysRemaining: daysToNext)
            }

            // Best streak
            if streakData.longestStreak > streakData.currentStreak {
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(.yellow)
                    Text(String(format: NSLocalizedString("mood.streak.longest.format", comment: "Longest streak: X days"), streakData.longestStreak))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()
                }
            }

            // Earned badges (horizontal scroll)
            if !streakData.streakBadges.isEmpty {
                badgesSection
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.orange.opacity(0.1),
                            Color.red.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [.orange.opacity(0.3), .red.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Components

    private var flameIcon: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.orange.opacity(0.3), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 40
                    )
                )
                .frame(width: 80, height: 80)

            // Flame
            Text("🔥")
                .font(.system(size: streakData.isActive ? 56 : 48))
                .scaleEffect(streakData.isActive ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: streakData.isActive)
        }
    }

    private func nextBadgeProgress(daysRemaining: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(String(localized: "mood.next.badge", comment: "Next badge"))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Text(String(format: NSLocalizedString("common.days.remaining.format", comment: "X days remaining"), daysRemaining))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 6)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: progressWidth(total: geometry.size.width, remaining: daysRemaining), height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    private func progressWidth(total: CGFloat, remaining: Int) -> CGFloat {
        // Find next milestone
        let milestones = [7, 14, 30, 60, 100, 365]
        guard let nextMilestone = milestones.first(where: { streakData.currentStreak < $0 }) else {
            return total
        }

        let previousMilestone = milestones.last(where: { $0 < nextMilestone }) ?? 0
        let progress = Double(streakData.currentStreak - previousMilestone) / Double(nextMilestone - previousMilestone)

        return total * progress
    }

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "medal.fill")
                    .foregroundStyle(.yellow)
                Text(String(localized: "mood.streak.badges.earned", comment: "Earned badges"))
                    .font(.caption.weight(.medium))

                Spacer()

                Text(String(localized: "streak.badges.count", defaultValue: "\(streakData.streakBadges.count)", comment: "Streak badges"))
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.yellow))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(streakData.streakBadges.sorted(by: { $0.days < $1.days })) { badge in
                        BadgeCard(badge: badge)
                    }
                }
            }
        }
    }

    private var lastRecordText: String {
        guard let lastDate = streakData.lastMoodDate else { return "Yok" }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.localizedString(for: lastDate, relativeTo: Date())
    }
}

// MARK: - Badge Card

struct BadgeCard: View {
    let badge: StreakBadge

    var body: some View {
        VStack(spacing: 8) {
            // Badge emoji
            Text(badge.emoji)
                .font(.system(size: 36))

            // Days
            Text(String(localized: "badge.days", defaultValue: "\(badge.days)", comment: "Badge days"))
                .font(.caption.weight(.bold))

            Text(String(localized: "time.days", comment: "days"))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 70, height: 90)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [.yellow.opacity(0.2), .orange.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.yellow.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Compact Streak Display (for lists)

struct CompactStreakDisplay: View {
    let currentStreak: Int
    let isActive: Bool

    var body: some View {
        HStack(spacing: 6) {
            Text("🔥")
                .font(.title3)

            Text(String(localized: "streak.current", defaultValue: "\(currentStreak)", comment: "Current streak"))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.orange)

            if isActive {
                Circle()
                    .fill(.green)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.orange.opacity(0.1))
        )
    }
}

#Preview {
    VStack {
        MoodStreakWidget(
            streakData: StreakData(
                currentStreak: 12,
                longestStreak: 30,
                lastMoodDate: Date(),
                streakBadges: [
                    StreakBadge(days: 7, earnedDate: Date(), emoji: "🔥"),
                    StreakBadge(days: 14, earnedDate: Date(), emoji: "🔥🔥")
                ],
                isActive: true
            )
        )

        CompactStreakDisplay(currentStreak: 12, isActive: true)
    }
    .padding()
}

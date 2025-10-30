//
//  RelationshipTimelineWidget.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//

import SwiftUI

struct RelationshipTimelineWidget: View {
    let friend: Friend

    // Milestone'lar (günler)
    private let milestones: [(days: Int, title: String, emoji: String)] = [
        (100, "100 Gün", "💯"),
        (180, "6 Ay", "📆"),
        (365, "1 Yıl", "🎉"),
        (730, "2 Yıl", "🎊"),
        (1095, "3 Yıl", "💑"),
        (1825, "5 Yıl", "🏆"),
        (3650, "10 Yıl", "👑")
    ]

    var body: some View {
        VStack(spacing: 16) {
            Text(String(localized: "relationship.duration", comment: "Relationship Duration"))
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 20) {
                // Sol: Circular Progress
                circularProgress

                // Sağ: Detaylı Bilgi
                VStack(alignment: .leading, spacing: 12) {
                    // Toplam Süre
                    if let duration = friend.relationshipDuration {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(localized: "relationship.together", comment: "Together"))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 4) {
                                if duration.years > 0 {
                                    Text("\(duration.years)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Text(String(localized: "time.unit.year", comment: "year"))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                if duration.months > 0 {
                                    Text("\(duration.months)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Text(String(localized: "common.month", comment: "month"))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                if duration.days > 0 || (duration.years == 0 && duration.months == 0) {
                                    Text("\(duration.days)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Text(String(localized: "time.unit.day", comment: "day"))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    // Sonraki Milestone
                    if let nextMilestone = getNextMilestone() {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(localized: "relationship.next.goal", comment: "Next Goal"))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 6) {
                                Text(nextMilestone.emoji)
                                    .font(.body)
                                Text(nextMilestone.title)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }

                            Text(String(format: NSLocalizedString("relationship.days.left.format", comment: "Days left to milestone"), daysToNextMilestone()))
                                .font(.caption2)
                                .foregroundStyle(.pink)
                        }
                    }
                }
            }

            // Milestone Badge'leri
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(milestones, id: \.days) { milestone in
                        MilestoneBadge(
                            milestone: milestone,
                            isCompleted: isCompleted(milestone),
                            isCurrent: isCurrent(milestone)
                        )
                    }
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.pink.opacity(0.15), Color.red.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .pink.opacity(0.2), radius: 10, x: 0, y: 5)
    }

    // MARK: - Circular Progress

    private var circularProgress: some View {
        ZStack {
            // Background Circle
            Circle()
                .stroke(Color.pink.opacity(0.2), lineWidth: 12)

            // Progress Circle
            Circle()
                .trim(from: 0, to: progressToNextMilestone())
                .stroke(
                    LinearGradient(
                        colors: [.pink, .red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Center Content
            VStack(spacing: 4) {
                if let days = friend.relationshipDays {
                    Text("\(days)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.pink, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text(String(localized: "time.unit.day", comment: "day"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 120, height: 120)
    }

    // MARK: - Helper Functions

    private func getNextMilestone() -> (days: Int, title: String, emoji: String)? {
        guard let currentDays = friend.relationshipDays else { return nil }

        for milestone in milestones {
            if currentDays < milestone.days {
                return milestone
            }
        }

        return nil
    }

    private func daysToNextMilestone() -> Int {
        guard let currentDays = friend.relationshipDays,
              let next = getNextMilestone() else { return 0 }
        return next.days - currentDays
    }

    private func progressToNextMilestone() -> CGFloat {
        guard let currentDays = friend.relationshipDays,
              let next = getNextMilestone() else { return 0 }

        // Önceki milestone'u bul
        var previousDays = 0
        for milestone in milestones {
            if milestone.days >= next.days {
                break
            }
            previousDays = milestone.days
        }

        let totalRange = next.days - previousDays
        let currentProgress = currentDays - previousDays

        return CGFloat(currentProgress) / CGFloat(totalRange)
    }

    private func isCompleted(_ milestone: (days: Int, title: String, emoji: String)) -> Bool {
        guard let currentDays = friend.relationshipDays else { return false }
        return currentDays >= milestone.days
    }

    private func isCurrent(_ milestone: (days: Int, title: String, emoji: String)) -> Bool {
        return getNextMilestone()?.days == milestone.days
    }
}

// MARK: - Milestone Badge

struct MilestoneBadge: View {
    let milestone: (days: Int, title: String, emoji: String)
    let isCompleted: Bool
    let isCurrent: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(
                        isCompleted ?
                        LinearGradient(colors: [.pink, .red], startPoint: .topLeading, endPoint: .bottomTrailing) :
                        LinearGradient(colors: [Color(.systemGray5), Color(.systemGray6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 50, height: 50)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                } else {
                    Text(milestone.emoji)
                        .font(.title3)
                }

                if isCurrent {
                    Circle()
                        .stroke(Color.pink, lineWidth: 3)
                        .frame(width: 56, height: 56)
                }
            }

            Text(milestone.title)
                .font(.caption2)
                .fontWeight(isCurrent ? .semibold : .regular)
                .foregroundStyle(isCompleted || isCurrent ? .primary : .secondary)
        }
        .opacity(isCompleted || isCurrent ? 1.0 : 0.6)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            // 50 gün
            RelationshipTimelineWidget(
                friend: Friend(
                    name: "Partner 1",
                    relationshipStartDate: Calendar.current.date(byAdding: .day, value: -50, to: Date())
                )
            )
            .padding()

            // 200 gün
            RelationshipTimelineWidget(
                friend: Friend(
                    name: "Partner 2",
                    relationshipStartDate: Calendar.current.date(byAdding: .day, value: -200, to: Date())
                )
            )
            .padding()

            // 400 gün
            RelationshipTimelineWidget(
                friend: Friend(
                    name: "Partner 3",
                    relationshipStartDate: Calendar.current.date(byAdding: .day, value: -400, to: Date())
                )
            )
            .padding()
        }
    }
}

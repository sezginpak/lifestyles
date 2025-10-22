//
//  GoalRingCard.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Ring progress ile hedef kartı
//

import SwiftUI

struct GoalRingCard: View {
    let goal: Goal
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Ring Progress
            ZStack {
                // Background Ring
                Circle()
                    .stroke(
                        Color(hex: goal.category.ringColor).opacity(0.2),
                        lineWidth: 6
                    )
                    .frame(width: 60, height: 60)

                // Progress Ring
                Circle()
                    .trim(from: 0, to: goal.milestoneProgress)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(hex: goal.category.ringColor),
                                Color(hex: goal.category.ringColor).opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: goal.progress)

                // Emoji veya Kategori
                if let emoji = goal.emoji {
                    Text(emoji)
                        .font(.title2)
                } else {
                    Text(goal.category.emoji)
                        .font(.title3)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 6) {
                // Başlık
                Text(goal.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                // Badges Row
                HStack(spacing: 6) {
                    // Priority
                    if goal.priority != .medium {
                        HStack(spacing: 2) {
                            Text(goal.priority.emoji)
                                .font(.caption2)
                            Text(goal.priority.displayName)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                    }

                    // Days Remaining
                    HStack(spacing: 2) {
                        Image(systemName: goal.isOverdue ? "exclamationmark.triangle.fill" : "calendar")
                            .font(.caption2)
                        Text("\(abs(goal.daysRemaining)) \(String(localized: "time.days", comment: "days"))")
                            .font(.caption2)
                    }
                    .foregroundStyle(goal.isOverdue ? .red : .secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background((goal.isOverdue ? Color.red : Color.secondary).opacity(0.1))
                    .clipShape(Capsule())

                    // Progress %
                    HStack(spacing: 2) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.caption2)
                        Text("%\(goal.progressPercentage)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(Color(hex: goal.category.ringColor))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(hex: goal.category.ringColor).opacity(0.15))
                    .clipShape(Capsule())
                }

                // Milestones (varsa)
                if let milestones = goal.milestones, !milestones.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                        Text("\(goal.completedMilestonesCount)/\(goal.totalMilestonesCount) \(String(localized: "goal.steps", comment: "steps"))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Quick Complete Button
            if !goal.isCompleted {
                Button {
                    HapticFeedback.medium()
                    onComplete()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color(hex: goal.category.ringColor))
                }
                .buttonStyle(.plain)
            } else {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Preview

#Preview("Goal Ring Cards") {
    VStack(spacing: 12) {
        // Health goal
        GoalRingCard(
            goal: {
                let goal = Goal(
                    title: "Haftada 3 kez spor yap",
                    category: .health,
                    priority: .high,
                    targetDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
                    progress: 0.6
                )
                goal.emoji = "🏃"
                return goal
            }()
        ) {
            print("Complete tapped")
        }

        // Social goal with milestones
        GoalRingCard(
            goal: {
                let goal = Goal(
                    title: "5 arkadaşla görüş",
                    category: .social,
                    priority: .medium,
                    targetDate: Calendar.current.date(byAdding: .day, value: 10, to: Date())!,
                    progress: 0.4
                )
                let milestone1 = GoalMilestone(title: "İlk buluşma", isCompleted: true, order: 0)
                let milestone2 = GoalMilestone(title: "Grup aktivitesi", order: 1)
                milestone1.goal = goal
                milestone2.goal = goal
                goal.milestones = [milestone1, milestone2]
                return goal
            }()
        ) {
            print("Complete tapped")
        }

        // Overdue goal
        GoalRingCard(
            goal: Goal(
                title: "Kitap bitir",
                category: .personal,
                priority: .low,
                targetDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
                progress: 0.7,
                emoji: "📚"
            )
        ) {
            print("Complete tapped")
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

//
//  GoalsComponents.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Hedefler ekranı tüm component'leri - toplu dosya
//

import SwiftUI
import Charts

// MARK: - Habit Streak Card (Calendar Heatmap)

struct HabitStreakCard: View {
    let habit: Habit
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Circle()
                    .fill(Color(hex: habit.colorHex))
                    .frame(width: 12, height: 12)

                Text(habit.name)
                    .font(.headline)

                Spacer()

                // Current Streak Badge
                if habit.currentStreak > 0 {
                    HStack(spacing: 4) {
                        Text("🔥")
                        Text("\(habit.currentStreak)")
                            .font(.caption.bold())
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(Capsule())
                }

                // Quick Toggle
                Button {
                    HapticFeedback.light()
                    onToggle()
                } label: {
                    Image(systemName: habit.isCompletedToday() ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(habit.isCompletedToday() ? .green : .secondary)
                }
            }

            // Calendar Heatmap
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 10), spacing: 4) {
                ForEach(habit.getLast30DaysStatus().indices, id: \.self) { index in
                    let isCompleted = habit.getLast30DaysStatus()[index]
                    RoundedRectangle(cornerRadius: 3)
                        .fill(isCompleted ? Color(hex: habit.colorHex) : Color.secondary.opacity(0.15))
                        .frame(height: 20)
                }
            }

            // Stats
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                    Text(String(format: NSLocalizedString("goal.best.streak.format", comment: "Best streak"), habit.bestStreak))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "chart.bar.fill")
                        .font(.caption2)
                    Text("%\(Int(habit.weeklyCompletionRate * 100))")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
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

// MARK: - Weekly Stats Chart

struct WeeklyStatsChart: View {
    let weeklyStats: WeeklyGoalStats

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "goal.weekly.progress", comment: "Weekly progress"))
                    .font(.headline)

                Spacer()

                // Trend Indicator
                HStack(spacing: 4) {
                    Text(weeklyStats.trend.rawValue)
                    Text(weeklyStats.trend.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Mini Bar Chart
            Chart {
                ForEach(Array(weeklyStats.dailyCompletions.enumerated()), id: \.offset) { index, count in
                    BarMark(
                        x: .value("Gün", dayName(for: index)),
                        y: .value("Tamamlanan", count)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .frame(height: 100)
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisValueLabel {
                        if let day = value.as(String.self) {
                            Text(String(day.prefix(1)))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis(.hidden)

            // Best Day
            HStack {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
                Text(String(format: NSLocalizedString("goal.best.day.format", comment: "Best day"), weeklyStats.bestDay))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    private func dayName(for index: Int) -> String {
        let days = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"]
        return days[index]
    }
}

// MARK: - Monthly Progress Ring

struct MonthlyProgressRing: View {
    let monthlyStats: MonthlyGoalStats

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 12)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: monthlyStats.completionRate)
                    .stroke(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                Text("%\(monthlyStats.completionPercentage)")
                    .font(.headline.bold())
            }

            VStack(spacing: 4) {
                Text(String(localized: "goal.monthly", comment: "Monthly"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(String(format: NSLocalizedString("goal.completed.format", comment: "Completed"), monthlyStats.totalCompleted))
                    .font(.caption.bold())
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Achievement Badge Card

struct AchievementBadgeCard: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 8) {
            // Badge Circle
            ZStack {
                Circle()
                    .fill(
                        achievement.isEarned
                            ? Color(hex: achievement.colorHex).opacity(0.2)
                            : Color.secondary.opacity(0.1)
                    )
                    .frame(width: 60, height: 60)

                if achievement.isEarned {
                    Text(achievement.emoji)
                        .font(.largeTitle)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }

            // Title
            Text(achievement.title)
                .font(.caption.bold())
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundStyle(achievement.isEarned ? .primary : .secondary)

            // Progress (locked only)
            if !achievement.isEarned {
                ProgressView(value: Double(achievement.currentProgress), total: Double(achievement.requirement))
                    .tint(Color(hex: achievement.colorHex))
                    .scaleEffect(x: 1, y: 0.5)

                Text("\(achievement.currentProgress)/\(achievement.requirement)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 90)
        .padding(.vertical, 12)
    }
}

// MARK: - AI Coaching Card

@available(iOS 26.0, *)
struct AICoachingCard: View {
    let coaching: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text(String(localized: "goal.ai.coaching", comment: "AI coaching"))
                    .font(.headline)

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if isExpanded {
                Text(coaching)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [.purple.opacity(0.3), .pink.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Previews

#Preview("Habit Streak Card") {
    HabitStreakCard(
        habit: {
            let habit = Habit(name: "Sabah Koşusu", colorHex: "E74C3C")
            habit.currentStreak = 12
            habit.longestStreak = 15
            return habit
        }()
    ) {
        print("Toggle tapped")
    }
    .padding()
}

#Preview("Weekly Stats") {
    WeeklyStatsChart(
        weeklyStats: WeeklyGoalStats(
            completionRate: 0.85,
            completedCount: 6,
            totalCount: 7,
            dailyCompletions: [3, 4, 2, 5, 4, 3, 2],
            bestDay: "Perşembe",
            averageProgress: 0.75,
            streak: 7
        )
    )
    .padding()
}

#Preview("Monthly Ring") {
    MonthlyProgressRing(
        monthlyStats: MonthlyGoalStats(
            completionRate: 0.68,
            totalCompleted: 15,
            totalActive: 7,
            categoriesBreakdown: [:],
            averageProgress: 0.65,
            overdueCount: 2,
            weeklyTrend: []
        )
    )
    .padding()
}

#Preview("Achievement Badge") {
    HStack {
        AchievementBadgeCard(
            achievement: Achievement(
                id: "test1",
                title: "Hafta Savaşçısı",
                description: "7 gün seri",
                emoji: "🔥",
                category: .streak,
                requirement: 7,
                currentProgress: 7,
                isEarned: true,
                earnedAt: Date(),
                colorHex: "E74C3C"
            )
        )

        AchievementBadgeCard(
            achievement: Achievement(
                id: "test2",
                title: "Hedef Avcısı",
                description: "10 hedef",
                emoji: "💪",
                category: .goal,
                requirement: 10,
                currentProgress: 6,
                isEarned: false,
                earnedAt: nil,
                colorHex: "3498DB"
            )
        )
    }
    .padding()
}

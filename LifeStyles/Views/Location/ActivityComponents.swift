//
//  ActivityComponents.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Aktivite ekranı için zenginleştirilmiş componentler
//

import SwiftUI
import SwiftData

// MARK: - Enhanced Activity Card

struct EnhancedActivityCard: View {
    let activity: ActivitySuggestion
    let onComplete: () -> Void
    let onToggleFavorite: () -> Void
    let onTap: () -> Void

    @State private var isPressed = false
    @State private var showingDetails = false

    var body: some View {
        Button {
            HapticFeedback.light()
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Header Row
                HStack(spacing: 10) {
                    // Category Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: activity.isCompleted ?
                                        [Color.green, Color.mint] :
                                        [Color.brandPrimary, Color.purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)

                        Text(activity.type.emoji)
                            .font(.title3)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(activity.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        HStack(spacing: 6) {
                            // Time of Day
                            if !activity.timeOfDayEmoji.isEmpty {
                                Text(activity.timeOfDayEmoji)
                                    .font(.caption2)
                                Text(activity.timeOfDayDisplay)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            // Duration
                            if let duration = activity.estimatedDuration {
                                Text("•")
                                    .foregroundStyle(.secondary)
                                Image(systemName: "clock")
                                    .font(.caption2)
                                Text(duration)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Spacer()

                    // Favorite Button
                    Button {
                        HapticFeedback.light()
                        onToggleFavorite()
                    } label: {
                        Image(systemName: activity.isFavorite ? "star.fill" : "star")
                            .font(.title3)
                            .foregroundStyle(activity.isFavorite ? .yellow : .secondary)
                    }
                    .buttonStyle(.plain)
                }

                // Description
                Text(activity.activityDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                // Bottom Row - Metrics
                HStack(spacing: 12) {
                    // Difficulty
                    HStack(spacing: 4) {
                        Text(activity.difficultyEmoji)
                            .font(.caption2)
                        Text(activity.difficultyDisplayName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    // Points
                    HStack(spacing: 4) {
                        Image(systemName: "star.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text("\(activity.calculatedPoints) puan")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Complete Button
                    Button {
                        HapticFeedback.success()
                        onComplete()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: activity.isCompleted ? "checkmark.circle.fill" : "circle")
                            Text(activity.isCompleted ? "Tamamlandı" : "Tamamla")
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(activity.isCompleted ? .green : .brandPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(activity.isCompleted ? Color.green.opacity(0.15) : Color.brandPrimary.opacity(0.15))
                        )
                    }
                    .disabled(activity.isCompleted)
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: activity.isCompleted ?
                                        [Color.green.opacity(0.3), Color.mint.opacity(0.3)] :
                                        [Color.brandPrimary.opacity(0.2), Color.purple.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            .shadow(
                color: (activity.isCompleted ? Color.green : Color.brandPrimary).opacity(0.08),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1.0)
    }
}

// MARK: - Activity Stats Card

struct ActivityStatsCard: View {
    let stats: ActivityStats

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.brandPrimary)
                Text(String(localized: "activity.my.stats", comment: "My statistics"))
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }

            // Stats Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatItem(icon: "flame.fill", value: "\(stats.currentStreak)", label: "Streak", color: .orange)
                StatItem(icon: "star.fill", value: "\(stats.totalPoints)", label: "Puan", color: .yellow)
                StatItem(icon: "arrow.up.circle.fill", value: "Lv\(stats.currentLevel)", label: "Seviye", color: .purple)
            }

            // Level Progress
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Seviye \(stats.currentLevel)")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(String(format: NSLocalizedString("activity.points.remaining.format", comment: "X points remaining"), stats.pointsForNextLevel))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.purple.opacity(0.15))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [Color.purple, Color.pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, min(1, stats.levelProgress)) * geometry.size.width, height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.3), Color.pink.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .shadow(color: Color.purple.opacity(0.1), radius: 12, x: 0, y: 4)
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Category Filter Chips

struct CategoryFilterChips: View {
    @Binding var selectedCategory: ActivityType?

    let categories: [ActivityType] = ActivityType.allCases

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // All categories chip
                FilterChip(
                    icon: "sparkles",
                    label: "Tümü",
                    isSelected: selectedCategory == nil,
                    color: .brandPrimary
                ) {
                    selectedCategory = nil
                }

                ForEach(categories, id: \.self) { category in
                    FilterChip(
                        icon: category.emoji,
                        label: category.displayName,
                        isSelected: selectedCategory == category,
                        color: categoryColor(for: category)
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func categoryColor(for category: ActivityType) -> Color {
        switch category {
        case .outdoor: return .green
        case .exercise: return .orange
        case .social: return .blue
        case .learning: return .purple
        case .creative: return .pink
        case .relax: return .mint
        }
    }
}

struct FilterChip: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if icon.count == 1 {
                    // Emoji
                    Text(icon)
                        .font(.callout)
                } else {
                    // SF Symbol
                    Image(systemName: icon)
                        .font(.caption)
                }

                Text(label)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundStyle(isSelected ? .white : color)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? color : color.opacity(0.15))
            )
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Time Filter Chips

struct TimeFilterChips: View {
    @Binding var selectedTime: String?

    let times: [(String, String, String)] = [
        ("morning", "🌅", "Sabah"),
        ("afternoon", "☀️", "Öğle"),
        ("evening", "🌙", "Akşam"),
        ("night", "✨", "Gece")
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // All time chip
                FilterChip(
                    icon: "clock",
                    label: "Tüm Gün",
                    isSelected: selectedTime == nil,
                    color: .indigo
                ) {
                    selectedTime = nil
                }

                ForEach(times, id: \.0) { time in
                    FilterChip(
                        icon: time.1,
                        label: time.2,
                        isSelected: selectedTime == time.0,
                        color: .indigo
                    ) {
                        selectedTime = time.0
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Badge Showcase Card

struct BadgeShowcaseCard: View {
    let badges: [Badge]

    private var recentBadges: [Badge] {
        badges
            .filter { $0.isEarned }
            .sorted { $0.earnedAt ?? Date.distantPast > $1.earnedAt ?? Date.distantPast }
            .prefix(3)
            .map { $0 }
    }

    private var upcomingBadges: [Badge] {
        badges
            .filter { !$0.isEarned }
            .sorted { $0.progressPercentage > $1.progressPercentage }
            .prefix(2)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.yellow)
                Text("Rozetler")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text("\(badges.filter { $0.isEarned }.count)/\(badges.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !recentBadges.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "activity.badges.recent", comment: "Recently earned badges"))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        ForEach(recentBadges) { badge in
                            BadgeItem(badge: badge, size: .medium)
                        }
                        Spacer()
                    }
                }
            }

            if !upcomingBadges.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "activity.badges.upcoming", comment: "Upcoming badges"))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 8) {
                        ForEach(upcomingBadges) { badge in
                            UpcomingBadgeRow(badge: badge)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.yellow.opacity(0.3), Color.orange.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .shadow(color: Color.yellow.opacity(0.1), radius: 12, x: 0, y: 4)
    }
}

enum BadgeSize {
    case small, medium, large

    var dimension: CGFloat {
        switch self {
        case .small: return 40
        case .medium: return 60
        case .large: return 80
        }
    }

    var fontSize: Font {
        switch self {
        case .small: return .caption
        case .medium: return .title3
        case .large: return .title
        }
    }
}

struct BadgeItem: View {
    let badge: Badge
    let size: BadgeSize

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: badge.isEarned ?
                                [Color.yellow, Color.orange] :
                                [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size.dimension, height: size.dimension)

                Image(systemName: badge.iconName)
                    .font(size.fontSize)
                    .foregroundStyle(badge.isEarned ? .white : .gray)
            }

            if size != .small {
                Text(badge.title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: size.dimension + 20)
            }
        }
    }
}

struct UpcomingBadgeRow: View {
    let badge: Badge

    var body: some View {
        HStack(spacing: 12) {
            BadgeItem(badge: badge, size: .small)

            VStack(alignment: .leading, spacing: 4) {
                Text(badge.title)
                    .font(.caption)
                    .fontWeight(.semibold)

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.yellow)
                            .frame(width: max(0, min(1, badge.progressPercentage)) * geometry.size.width, height: 6)
                    }
                }
                .frame(height: 6)

                Text(badge.progressText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Streak Card

struct StreakCard: View {
    let currentStreak: Int

    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 16) {
            // Flame Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange, Color.red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .glowEffect(color: .orange, radius: 10)

                Text("🔥")
                    .font(.largeTitle)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: NSLocalizedString("activity.streak.days.format", comment: "X Day Streak!"), currentStreak))
                    .font(.title3)
                    .fontWeight(.bold)

                Text(streakMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.4), Color.red.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
        .shadow(color: Color.orange.opacity(0.15), radius: 12, x: 0, y: 4)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }

    private var streakMessage: String {
        if currentStreak == 0 {
            return "İlk aktivitenle başla!"
        } else if currentStreak < 7 {
            return "Harika gidiyorsun! Devam et!"
        } else if currentStreak < 30 {
            return "İnanılmaz! Streak'ini koru!"
        } else {
            return "Efsanesin! 🎉"
        }
    }
}

// MARK: - Extension for Glow Effect
// Not: glowEffect artık AppColors.swift içinde merkezi olarak tanımlı

// MARK: - ActivityType Extension

extension ActivityType: CaseIterable {
    static var allCases: [ActivityType] {
        return [.outdoor, .exercise, .social, .learning, .creative, .relax]
    }
}

//
//  GamificationView.swift
//  LifeStyles
//
//  Main gamification view showing badges, level, and stats
//  Created by Claude on 30.10.2025.
//

import SwiftUI
import SwiftData

struct GamificationView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProgressRecords: [UserProgress]
    @Query private var badges: [GamificationBadge]

    @State private var showingAllBadges = false
    @State private var selectedTab: GamificationTab = .overview

    enum GamificationTab {
        case overview
        case badges
        case stats
    }

    var userProgress: UserProgress {
        if let progress = userProgressRecords.first {
            return progress
        } else {
            // İlk kez açılıyorsa yeni progress oluştur
            let newProgress = UserProgress()
            modelContext.insert(newProgress)
            try? modelContext.save()
            return newProgress
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Tab selector
                    tabSelector

                    // Content based on selected tab
                    Group {
                        switch selectedTab {
                        case .overview:
                            overviewContent
                        case .badges:
                            badgesContent
                        case .stats:
                            statsContent
                        }
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTab)
                }
                .padding(.vertical, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Başarılar")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Tab Selector

    var tabSelector: some View {
        HStack(spacing: 12) {
            TabButton(
                title: "Genel",
                icon: "star.fill",
                isSelected: selectedTab == .overview,
                action: { selectedTab = .overview }
            )

            TabButton(
                title: "Rozetler",
                icon: "medal.fill",
                isSelected: selectedTab == .badges,
                action: { selectedTab = .badges }
            )

            TabButton(
                title: "İstatistik",
                icon: "chart.bar.fill",
                isSelected: selectedTab == .stats,
                action: { selectedTab = .stats }
            )
        }
        .padding(.horizontal)
    }

    // MARK: - Overview Content

    var overviewContent: some View {
        VStack(spacing: 20) {
            // Level progress
            LevelProgressView(userProgress: userProgress, showDetails: true)
                .padding(.horizontal)

            // Quick stats
            quickStatsGrid

            // Recent badges
            if !badges.isEmpty {
                recentBadgesSection
            }

            // Motivational quote
            motivationalCard
        }
    }

    // MARK: - Badges Content

    var badgesContent: some View {
        BadgeGridView(badges: badges)
    }

    // MARK: - Stats Content

    var statsContent: some View {
        VStack(spacing: 20) {
            GamificationStatsView(userProgress: userProgress)
                .padding(.horizontal)

            // Detailed stats
            detailedStatsSection
        }
    }

    // MARK: - Quick Stats Grid

    var quickStatsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing: 12
        ) {
            GamificationStatCard(
                icon: "📝",
                title: "Journal",
                value: "\(userProgress.journalCount)",
                color: .blue
            )

            GamificationStatCard(
                icon: "😊",
                title: "Mood",
                value: "\(userProgress.moodCount)",
                color: .purple
            )

            GamificationStatCard(
                icon: "🔥",
                title: "Streak",
                value: "\(userProgress.currentStreak)",
                color: .orange
            )

            GamificationStatCard(
                icon: "🏆",
                title: "Rozetler",
                value: "\(badges.count)",
                color: .green
            )
        }
        .padding(.horizontal)
    }

    // MARK: - Recent Badges Section

    var recentBadgesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Son Kazanılan Rozetler")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Button(action: {
                    selectedTab = .badges
                }) {
                    Text("Tümü")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(badges.prefix(5)) { badge in
                        BadgeView(
                            badgeType: badge.badgeType,
                            isEarned: true,
                            earnedDate: badge.earnedDate,
                            onTap: nil
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Motivational Card

    var motivationalCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 32))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(motivationalMessage)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Text(motivationalSubtext)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.yellow.opacity(0.1),
                            Color.orange.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    // MARK: - Detailed Stats Section

    var detailedStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detaylı İstatistikler")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 12) {
                GamificationStatRow(
                    icon: "📝",
                    title: "Toplam Journal",
                    value: "\(userProgress.journalCount)",
                    color: .blue
                )

                GamificationStatRow(
                    icon: "😊",
                    title: "Toplam Mood Kaydı",
                    value: "\(userProgress.moodCount)",
                    color: .purple
                )

                GamificationStatRow(
                    icon: "🔥",
                    title: "Güncel Streak",
                    value: "\(userProgress.currentStreak) gün",
                    color: .orange
                )

                GamificationStatRow(
                    icon: "⭐",
                    title: "En Uzun Streak",
                    value: "\(userProgress.longestStreak) gün",
                    color: .yellow
                )

                GamificationStatRow(
                    icon: "🏆",
                    title: "Kazanılan Rozetler",
                    value: "\(badges.count) / \(BadgeType.allCases.count)",
                    color: .green
                )

                GamificationStatRow(
                    icon: "⚡",
                    title: "Toplam XP",
                    value: "\(userProgress.totalXP)",
                    color: .cyan
                )
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Helpers

    var motivationalMessage: String {
        let level = userProgress.currentLevel
        let streak = userProgress.currentStreak

        if streak >= 7 {
            return "Harikasın! \(streak) gündür düzenli devam ediyorsun!"
        } else if level >= 10 {
            return "Level \(level)! Muhteşem bir ilerleme gösteriyorsun!"
        } else if badges.count >= 5 {
            return "Şimdiden \(badges.count) rozet kazandın! Devam et!"
        } else {
            return "Her gün bir adım daha yakınsın!"
        }
    }

    var motivationalSubtext: String {
        let nextBadge = nextAvailableBadge()
        return "Bir sonraki hedef: \(nextBadge?.displayName ?? "Devam et")"
    }

    func nextAvailableBadge() -> BadgeType? {
        let earnedTypes = badges.map { $0.badgeType }
        return BadgeType.allCases.first(where: { !earnedTypes.contains($0) })
    }
}

// MARK: - Tab Button

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(
                        isSelected ?
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [Color(.systemGray6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 8)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Gamification Stat Row

struct GamificationStatRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(icon)
                .font(.title2)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    GamificationView()
        .modelContainer(for: [UserProgress.self, GamificationBadge.self])
}

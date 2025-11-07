//
//  LevelProgressView.swift
//  LifeStyles
//
//  Level and XP progress display for gamification
//  Created by Claude on 30.10.2025.
//

import SwiftUI

struct LevelProgressView: View {
    let userProgress: UserProgress
    let showDetails: Bool

    @State private var animatedProgress: Double = 0.0

    init(userProgress: UserProgress, showDetails: Bool = true) {
        self.userProgress = userProgress
        self.showDetails = showDetails
    }

    var body: some View {
        VStack(spacing: showDetails ? 16 : 12) {
            // Level header
            HStack {
                // Level badge
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: levelGradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: showDetails ? 60 : 50, height: showDetails ? 60 : 50)
                        .shadow(color: levelColor.opacity(0.4), radius: 8)

                    VStack(spacing: 0) {
                        Text(String(localized: "gamification.level.abbr", comment: ""))
                            .font(.system(size: showDetails ? 10 : 8, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))

                        Text(String(localized: "text.userprogresscurrentlevel"))
                            .font(.system(size: showDetails ? 24 : 20, weight: .black))
                            .foregroundColor(.white)
                    }
                }

                if showDetails {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "text.level.userprogresscurrentlevel"))
                            .font(.title3)
                            .fontWeight(.bold)

                        Text(String(localized: "text.userprogresstotalxp.xp"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if showDetails {
                    // XP to next level
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(localized: "gamification.next.level", comment: ""))
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text(String(localized: "text.userprogressxpfornextlevel.userprogressxpincurrentlevel.xp"))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                }
            }

            // Progress bar
            progressBar
        }
        .padding(showDetails ? 20 : 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(levelColor.opacity(0.3), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.05), radius: 8)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
                animatedProgress = userProgress.levelProgress
            }
        }
    }

    // MARK: - Progress Bar

    var progressBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            if showDetails {
                // Progress text
                HStack {
                    Text(String(localized: "text.userprogressxpincurrentlevel.userprogressxpfornextlevel.xp"))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(String(localized: "text.intuserprogresslevelprogress.100"))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(levelColor)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: showDetails ? 8 : 6)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: showDetails ? 12 : 8)

                    // Progress fill
                    RoundedRectangle(cornerRadius: showDetails ? 8 : 6)
                        .fill(
                            LinearGradient(
                                colors: levelGradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * animatedProgress, height: showDetails ? 12 : 8)
                        .shadow(color: levelColor.opacity(0.5), radius: 4)
                }
            }
            .frame(height: showDetails ? 12 : 8)
        }
    }

    // MARK: - Helpers

    var levelColor: Color {
        switch userProgress.currentLevel {
        case 1...5:
            return .blue
        case 6...10:
            return .green
        case 11...20:
            return .purple
        case 21...30:
            return .orange
        default:
            return .pink
        }
    }

    var levelGradientColors: [Color] {
        switch userProgress.currentLevel {
        case 1...5:
            return [.blue, .cyan]
        case 6...10:
            return [.green, .teal]
        case 11...20:
            return [.purple, .pink]
        case 21...30:
            return [.orange, .red]
        default:
            return [.pink, .purple]
        }
    }
}

// MARK: - Compact Level Card

struct CompactLevelCard: View {
    let userProgress: UserProgress

    var body: some View {
        HStack(spacing: 12) {
            // Level icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)

                VStack(spacing: -2) {
                    Text(String(localized: "gamification.level.abbr", comment: ""))
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))

                    Text(String(localized: "text.userprogresscurrentlevel"))
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.white)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "text.level.userprogresscurrentlevel"))
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(String(localized: "text.userprogressxpincurrentleveluserprogressxpfornextlevel.xp"))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Mini progress
            CircularProgressView(
                progress: userProgress.levelProgress,
                size: 40,
                lineWidth: 4,
                colors: [.blue, .purple]
            )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Circular Progress View

struct CircularProgressView: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat
    let colors: [Color]

    @State private var animatedProgress: Double = 0.0

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)
                .frame(width: size, height: size)

            // Progress circle
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(
                        colors: colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))

            // Percentage
            Text(String(localized: "text.intanimatedprogress.100"))
                .font(.system(size: size * 0.25, weight: .bold))
                .foregroundColor(.primary)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1)) {
                animatedProgress = progress
            }
        }
    }
}

// MARK: - Stats Overview

struct GamificationStatsView: View {
    let userProgress: UserProgress

    var body: some View {
        VStack(spacing: 16) {
            // Level progress
            LevelProgressView(userProgress: userProgress, showDetails: true)

            // Stats grid
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
                    value: "\(userProgress.badges?.count ?? 0)",
                    color: .green
                )
            }
        }
    }
}

struct GamificationStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 32))

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            LevelProgressView(
                userProgress: UserProgress(
                    totalXP: 350,
                    currentLevel: 3,
                    journalCount: 25,
                    moodCount: 40,
                    currentStreak: 7,
                    longestStreak: 12
                ),
                showDetails: true
            )
            .padding()

            CompactLevelCard(
                userProgress: UserProgress(
                    totalXP: 150,
                    currentLevel: 2
                )
            )
            .padding()

            GamificationStatsView(
                userProgress: UserProgress(
                    totalXP: 350,
                    currentLevel: 3,
                    journalCount: 25,
                    moodCount: 40,
                    currentStreak: 7,
                    longestStreak: 12
                )
            )
            .padding()
        }
    }
}

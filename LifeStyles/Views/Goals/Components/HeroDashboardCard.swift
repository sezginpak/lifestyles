//
//  HeroDashboardCard.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Hedefler ekranı hero dashboard kartı
//

import SwiftUI

struct HeroDashboardCard: View {
    let combinedStats: CombinedStats

    var body: some View {
        VStack(spacing: 20) {
            // Bugünkü Progress Ring
            ZStack {
                // Background Ring
                Circle()
                    .stroke(
                        Color.white.opacity(0.2),
                        lineWidth: 16
                    )
                    .frame(width: 140, height: 140)

                // Progress Ring
                Circle()
                    .trim(from: 0, to: CGFloat(combinedStats.todayCompletionPercentage) / 100.0)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(hex: "2ECC71"),
                                Color(hex: "27AE60")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: combinedStats.todayCompletionPercentage)

                // Center Content
                VStack(spacing: 4) {
                    Text(String(localized: "stats.completed.today", defaultValue: "\(combinedStats.todayCompleted)", comment: "Completed today"))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(hex: "2ECC71"),
                                    Color(hex: "27AE60")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text(String(format: NSLocalizedString("goals.of.total", comment: "Of total goals"), combinedStats.todayTotal))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Stats Row
            HStack(spacing: 20) {
                // Streak
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Text("🔥")
                            .font(.title3)
                        Text(String(localized: "streak.current", defaultValue: "\(combinedStats.currentStreak)", comment: "Combined streak"))
                            .font(.title3.bold())
                            .foregroundStyle(.primary)
                    }
                    Text(String(localized: "goal.streak.days", comment: "Day streak"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Weekly %
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Text("📊")
                            .font(.title3)
                        Text(String(format: NSLocalizedString("goals.completion.rate", comment: "Completion rate percentage"), combinedStats.weeklyCompletionPercentage))
                            .font(.title3.bold())
                            .foregroundStyle(.primary)
                    }
                    Text(String(localized: "goal.weekly", comment: "Weekly"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Motivasyon Mesajı
            Text(combinedStats.motivationMessage)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(24)
        .background(
            ZStack {
                // Gradient Background
                LinearGradient(
                    colors: [
                        Color(hex: "667EEA"),
                        Color(hex: "764BA2")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Glassmorphism Overlay
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.2),
                        Color.clear,
                        Color.black.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color(hex: "667EEA").opacity(0.3), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Preview

#Preview("Hero Dashboard") {
    VStack {
        HeroDashboardCard(
            combinedStats: CombinedStats(
                todayCompleted: 3,
                todayTotal: 5,
                weeklyCompletionRate: 0.85,
                currentStreak: 7,
                motivationMessage: "Harika gidiyorsun! 7 gün seri! 🌟"
            )
        )
        .padding()

        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}

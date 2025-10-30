//
//  ModernHeroCard.swift
//  LifeStyles
//
//  Simple Hero Stats Card for Dashboard
//  Created by Claude on 25.10.2025.
//

import SwiftUI

struct ModernHeroStatsCard: View {
    let summary: DashboardSummary

    var body: some View {
        VStack(spacing: 16) {
            // Overall Score
            VStack(spacing: 8) {
                Text(String(format: NSLocalizedString("dashboard.score.percentage", comment: "Score percentage"), summary.overallScore))
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text(summary.motivationMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)

            // 4 Rings
            HStack(spacing: 20) {
                ringView(summary.goalsRing)
                ringView(summary.habitsRing)
                ringView(summary.socialRing)
                ringView(summary.activityRing)
            }
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    LinearGradient(
                        colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private func ringView(_ data: DashboardRingData) -> some View {
        VStack(spacing: 8) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                    .frame(width: 60, height: 60)

                // Progress circle
                Circle()
                    .trim(from: 0, to: data.progress)
                    .stroke(
                        Color(hex: data.color),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))

                // Icon
                Image(systemName: data.icon)
                    .font(.title3)
                    .foregroundStyle(Color(hex: data.color))
            }

            Text(data.label)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(String(format: NSLocalizedString("dashboard.score.percentage", comment: "Score percentage"), data.percentage))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    ModernHeroStatsCard(
        summary: DashboardSummary.empty()
    )
    .padding()
}

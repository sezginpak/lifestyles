//
//  OverviewSection.swift
//  LifeStyles
//
//  Created by Claude on 04.11.2025.
//

import SwiftUI

/// Genel bakış analytics section
struct OverviewSection: View {
    let data: OverviewAnalytics

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            Text(String(localized: "analytics.overview.title", defaultValue: "Genel Bakış", comment: "Overview section title"))
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)

            // Main wellness card
            LargeStatCard(
                title: String(localized: "analytics.overview.wellnessLevel", defaultValue: "Wellness Seviyeniz", comment: "Wellness level title"),
                value: "\(Int(data.wellnessScore))",
                progress: data.wellnessScore / 100.0,
                icon: "heart.circle.fill",
                color: wellnessColor,
                description: wellnessDescription
            )

            // Stats grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                AnalyticsStatCard(
                    title: String(localized: "analytics.overview.activeDays", defaultValue: "Aktif Günler", comment: "Active days title"),
                    value: "\(data.totalActiveDays)",
                    subtitle: String(localized: "analytics.overview.lastThirtyDays", defaultValue: "Son 30 günde", comment: "Last 30 days subtitle"),
                    icon: "calendar",
                    color: .blue,
                    trend: nil
                )

                AnalyticsStatCard(
                    title: String(localized: "analytics.overview.consistency", defaultValue: "Düzenlilik", comment: "Consistency title"),
                    value: "%\(Int(data.consistencyScore * 100))",
                    subtitle: consistencyLevel,
                    icon: "chart.line.uptrend.xyaxis",
                    color: .purple,
                    trend: nil
                )
            }

            // Trend card
            trendCard
        }
    }

    private var wellnessColor: Color {
        let score = data.wellnessScore
        switch score {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .yellow
        case 20..<40: return .orange
        default: return .red
        }
    }

    private var wellnessDescription: String {
        let score = data.wellnessScore
        switch score {
        case 80...100: return String(localized: "analytics.overview.wellness.excellent", defaultValue: "Harika gidiyorsunuz! Wellness seviyeniz mükemmel.", comment: "Excellent wellness description")
        case 60..<80: return String(localized: "analytics.overview.wellness.good", defaultValue: "İyi bir performans gösteriyorsunuz. Devam edin!", comment: "Good wellness description")
        case 40..<60: return String(localized: "analytics.overview.wellness.average", defaultValue: "Orta seviye. Bazı alanlarda iyileştirme yapabilirsiniz.", comment: "Average wellness description")
        case 20..<40: return String(localized: "analytics.overview.wellness.needsImprovement", defaultValue: "Geliştirilmesi gereken alanlar var.", comment: "Needs improvement wellness description")
        default: return String(localized: "analytics.overview.wellness.poor", defaultValue: "Kendinize daha fazla zaman ayırın.", comment: "Poor wellness description")
        }
    }

    private var consistencyLevel: String {
        let score = data.consistencyScore
        switch score {
        case 0.8...1.0: return String(localized: "analytics.overview.consistency.excellent", defaultValue: "Mükemmel", comment: "Excellent consistency level")
        case 0.6..<0.8: return String(localized: "analytics.overview.consistency.good", defaultValue: "İyi", comment: "Good consistency level")
        case 0.4..<0.6: return String(localized: "analytics.overview.consistency.average", defaultValue: "Orta", comment: "Average consistency level")
        default: return String(localized: "analytics.overview.consistency.needsImprovement", defaultValue: "Geliştirilmeli", comment: "Needs improvement consistency level")
        }
    }

    @ViewBuilder
    private var trendCard: some View {
        HStack(spacing: 16) {
            Image(systemName: trendIcon)
                .font(.system(size: 40))
                .foregroundStyle(trendColor)
                .frame(width: 60, height: 60)
                .background(trendColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "analytics.overview.trend.title", defaultValue: "Genel Trend", comment: "Overall trend title"))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)

                Text(trendText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var trendIcon: String {
        switch data.improvementTrend {
        case .improving: return "chart.line.uptrend.xyaxis"
        case .stable: return "chart.line.flattrend.xyaxis"
        case .declining: return "chart.line.downtrend.xyaxis"
        }
    }

    private var trendColor: Color {
        switch data.improvementTrend {
        case .improving: return .green
        case .stable: return .blue
        case .declining: return .orange
        }
    }

    private var trendText: String {
        switch data.improvementTrend {
        case .improving: return String(localized: "analytics.overview.trend.improving", defaultValue: "Son zamanlarda gelişme gösteriyorsunuz!", comment: "Improving trend description")
        case .stable: return String(localized: "analytics.overview.trend.stable", defaultValue: "Stabil bir performans sergiliyorsunuz.", comment: "Stable trend description")
        case .declining: return String(localized: "analytics.overview.trend.declining", defaultValue: "Son zamanlarda düşüş var. Dikkat edin!", comment: "Declining trend description")
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        OverviewSection(
            data: OverviewAnalytics(
                wellnessScore: 85,
                totalActiveDays: 24,
                consistencyScore: 0.80,
                improvementTrend: .improving
            )
        )
        .padding()
    }
}

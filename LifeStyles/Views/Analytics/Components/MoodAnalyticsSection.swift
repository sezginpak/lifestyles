//
//  MoodAnalyticsSection.swift
//  LifeStyles
//
//  Created by Claude on 04.11.2025.
//

import SwiftUI
import Charts

/// Ruh hali analytics section
struct MoodAnalyticsSection: View {
    let data: MoodAnalytics

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Image(systemName: "face.smiling")
                    .foregroundStyle(.orange)
                Text(String(localized: "analytics.mood.title", defaultValue: "Ruh Hali Analizleri", comment: "Mood analytics section title"))
                    .font(.title2.weight(.bold))
            }

            // Average mood card
            HStack(spacing: 16) {
                Image(systemName: moodIcon)
                    .font(.system(size: 40))
                    .foregroundStyle(moodColor)
                    .frame(width: 70, height: 70)
                    .background(moodColor.opacity(0.15))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "analytics.mood.averageMood", defaultValue: "Ortalama Ruh Hali", comment: "Average mood label"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", data.averageMood))
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .foregroundStyle(moodColor)

                        Text(String(localized: "analytics.mood.outOfFive", defaultValue: "/ 5", comment: "Out of 5 scale"))
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    Text(moodDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Stats
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                if let bestDay = data.bestDay {
                    AnalyticsMiniCard(
                        title: String(localized: "analytics.mood.bestDay", defaultValue: "En İyi Gün", comment: "Best day label"),
                        value: formattedDate(bestDay),
                        icon: "sun.max.fill",
                        color: .yellow
                    )
                }

                if let worstDay = data.worstDay {
                    AnalyticsMiniCard(
                        title: String(localized: "analytics.mood.worstDay", defaultValue: "Zor Gün", comment: "Worst day label"),
                        value: formattedDate(worstDay),
                        icon: "cloud.rain.fill",
                        color: .gray
                    )
                }

                AnalyticsMiniCard(
                    title: String(localized: "analytics.mood.consistency", defaultValue: "Düzenlilik", comment: "Consistency label"),
                    value: "%\(Int(data.consistencyRate * 100))",
                    icon: "calendar.badge.checkmark",
                    color: .purple
                )
            }

            // Mood trend
            if !data.moodTrend.isEmpty {
                let chartPoints = data.moodTrend.map {
                    TrendLineChart.ChartDataPoint(date: $0.date, value: $0.value)
                }

                TrendLineChart(
                    title: String(localized: "analytics.mood.thirtyDayTrend", defaultValue: "30 Günlük Ruh Hali Trendi", comment: "30-day mood trend chart title"),
                    dataPoints: chartPoints,
                    color: moodColor
                )
            }

            // Mood distribution
            if !data.moodDistribution.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(String(localized: "analytics.mood.distribution", defaultValue: "Ruh Hali Dağılımı", comment: "Mood distribution chart title"))
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Chart {
                        ForEach(Array(data.moodDistribution.sorted(by: { $0.key < $1.key })), id: \.key) { mood, count in
                            BarMark(
                                x: .value("Mood", moodLabel(mood)),
                                y: .value("Count", count)
                            )
                            .foregroundStyle(moodColorForValue(mood))
                            .cornerRadius(6)
                        }
                    }
                    .frame(height: 150)
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel()
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            // Top triggers
            if !data.topMoodTriggers.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(String(localized: "analytics.mood.triggers", defaultValue: "Ruh Halini Etkileyen Faktörler", comment: "Mood triggers title"))
                        .font(.headline)
                        .foregroundStyle(.primary)

                    ForEach(data.topMoodTriggers, id: \.self) { trigger in
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundStyle(.orange)
                            Text(trigger)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var moodIcon: String {
        switch data.averageMood {
        case 4.5...5: return "face.smiling.fill"
        case 3.5..<4.5: return "face.smiling"
        case 2.5..<3.5: return "face.dashed"
        case 1.5..<2.5: return "face.dashed.fill"
        default: return "cloud.rain.fill"
        }
    }

    private var moodColor: Color {
        switch data.averageMood {
        case 4.5...5: return .green
        case 3.5..<4.5: return .blue
        case 2.5..<3.5: return .yellow
        case 1.5..<2.5: return .orange
        default: return .red
        }
    }

    private var moodDescription: String {
        switch data.averageMood {
        case 4.5...5: return String(localized: "analytics.mood.description.excellent", defaultValue: "Harika! Ruh haliniz mükemmel", comment: "Excellent mood description")
        case 3.5..<4.5: return String(localized: "analytics.mood.description.good", defaultValue: "İyi bir dönemdesiniz", comment: "Good mood description")
        case 2.5..<3.5: return String(localized: "analytics.mood.description.average", defaultValue: "Orta seviye", comment: "Average mood description")
        case 1.5..<2.5: return String(localized: "analytics.mood.description.low", defaultValue: "Biraz düşük", comment: "Low mood description")
        default: return String(localized: "analytics.mood.description.veryLow", defaultValue: "Zorlu bir dönem", comment: "Very low mood description")
        }
    }

    private func moodLabel(_ value: Int) -> String {
        switch value {
        case 5: return "😊"
        case 4: return "🙂"
        case 3: return "😐"
        case 2: return "🙁"
        case 1: return "😢"
        default: return "\(value)"
        }
    }

    private func moodColorForValue(_ value: Int) -> Color {
        switch value {
        case 5: return .green
        case 4: return .blue
        case 3: return .yellow
        case 2: return .orange
        case 1: return .red
        default: return .gray
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        MoodAnalyticsSection(
            data: MoodAnalytics(
                averageMood: 4.2,
                moodDistribution: [5: 12, 4: 18, 3: 8, 2: 3, 1: 1],
                bestDay: Date(),
                worstDay: Date().addingTimeInterval(-7*86400),
                moodTrend: [
                    MoodAnalytics.MoodPoint(date: Date().addingTimeInterval(-6*86400), value: 3.5, intensity: 0.6),
                    MoodAnalytics.MoodPoint(date: Date().addingTimeInterval(-5*86400), value: 4.0, intensity: 0.7),
                    MoodAnalytics.MoodPoint(date: Date().addingTimeInterval(-4*86400), value: 3.8, intensity: 0.65),
                    MoodAnalytics.MoodPoint(date: Date().addingTimeInterval(-3*86400), value: 4.5, intensity: 0.8),
                    MoodAnalytics.MoodPoint(date: Date().addingTimeInterval(-2*86400), value: 4.2, intensity: 0.75),
                    MoodAnalytics.MoodPoint(date: Date().addingTimeInterval(-1*86400), value: 4.8, intensity: 0.85),
                    MoodAnalytics.MoodPoint(date: Date(), value: 4.0, intensity: 0.7)
                ],
                topMoodTriggers: ["Arkadaşlarla vakit geçirmek", "Açık havada olmak", "Hedef tamamlamak"],
                consistencyRate: 0.85
            )
        )
        .padding()
    }
}

//
//  AnalyticsComponents.swift
//  LifeStyles
//
//  Created by Claude on 31.10.2025.
//

import SwiftUI
import Charts

// MARK: - Circular Progress Gauge

struct CircularProgressGauge: View {
    let progress: Double // 0-1
    let lineWidth: CGFloat
    let size: CGFloat
    let color: Color

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)

            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Hourly Heatmap

struct HourlyHeatMap: View {
    let hourlyDistribution: [Int: Int]
    let maxCount: Int

    init(hourlyDistribution: [Int: Int]) {
        self.hourlyDistribution = hourlyDistribution
        self.maxCount = hourlyDistribution.values.max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Saat bloklarını 4'lü gruplar halinde göster
            ForEach(0..<6, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<4, id: \.self) { col in
                        let hour = row * 4 + col
                        let count = hourlyDistribution[hour] ?? 0
                        let intensity = maxCount > 0 ? Double(count) / Double(maxCount) : 0

                        VStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(intensityColor(for: intensity))
                                .frame(width: 40, height: 32)
                                .overlay(
                                    Text(String(localized: "component.count", defaultValue: "\(count)", comment: "Generic count")).font(.caption2)
                                        .foregroundStyle(intensity > 0.5 ? .white : .primary)
                                )

                            Text(String(format: "%02d", hour))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func intensityColor(for intensity: Double) -> Color {
        if intensity == 0 {
            return Color(.systemGray6)
        } else if intensity < 0.3 {
            return .blue.opacity(0.3)
        } else if intensity < 0.6 {
            return .blue.opacity(0.6)
        } else {
            return .blue
        }
    }
}

// MARK: - Milestone Progress Ring

struct MilestoneProgressRing: View {
    let milestone: FriendAnalyticsViewModel.Milestone
    let size: CGFloat

    var body: some View {
        ZStack {
            CircularProgressGauge(
                progress: milestone.progress,
                lineWidth: 6,
                size: size,
                color: milestone.color
            )

            VStack(spacing: 4) {
                Image(systemName: milestone.icon)
                    .font(.system(size: size * 0.25))
                    .foregroundStyle(milestone.color)

                if !milestone.isCompleted {
                    Text(String(localized: "analytics.milestone.remaining", defaultValue: "\(milestone.remaining)", comment: "Milestone remaining"))
                        .font(.system(size: size * 0.2, weight: .bold))
                        .foregroundStyle(.primary)
                } else {
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.2, weight: .bold))
                        .foregroundStyle(.green)
                }
            }
        }
    }
}

// MARK: - Simple Bar Chart

struct SimpleBarChart: View {
    let data: [(String, Double)] // Label, Value
    let maxValue: Double
    let color: Color

    init(data: [(String, Double)], color: Color = .blue) {
        self.data = data
        self.maxValue = data.map { $0.1 }.max() ?? 1
        self.color = color
    }

    var body: some View {
        VStack(spacing: 8) {
            ForEach(data, id: \.0) { item in
                HStack(spacing: 8) {
                    Text(item.0)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 60, alignment: .leading)

                    GeometryReader { geo in
                        HStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(color)
                                .frame(width: geo.size.width * (item.1 / maxValue))

                            Text(String(format: "%.0f", item.1))
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            Spacer()
                        }
                    }
                    .frame(height: 20)
                }
            }
        }
    }
}

// MARK: - Mood Timeline Chart

struct MoodTimelineChart: View {
    let timelineData: [FriendAnalyticsViewModel.MoodTimelinePoint]

    var body: some View {
        Chart {
            ForEach(timelineData) { point in
                LineMark(
                    x: .value("Tarih", point.date),
                    y: .value("Ruh Hali", point.score)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .blue, .orange, .red],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .lineStyle(StrokeStyle(lineWidth: 2))

                AreaMark(
                    x: .value("Tarih", point.date),
                    y: .value("Ruh Hali", point.score)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green.opacity(0.3), .blue.opacity(0.2), .orange.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .chartYScale(domain: 0...1)
        .chartYAxis {
            AxisMarks(values: [0, 0.25, 0.5, 0.75, 1.0]) { value in
                if let score = value.as(Double.self) {
                    AxisValueLabel {
                        Text(moodLabel(for: score))
                            .font(.caption2)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated))
                    .font(.caption2)
            }
        }
        .frame(height: 180)
    }

    private func moodLabel(for score: Double) -> String {
        if score >= 0.875 { return "😊" }
        else if score >= 0.625 { return "🙂" }
        else if score >= 0.375 { return "😐" }
        else { return "😔" }
    }
}

// MARK: - Stat Pill View

struct StatPillView: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - Analytics Card Container

struct AnalyticsCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()
            }

            // Content
            content()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - Weekday Distribution Chart

struct WeekdayMoodChart: View {
    let weekdayDistribution: [String: [ContactMood: Int]]

    private let weekdayOrder = ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(weekdayOrder, id: \.self) { day in
                if let moods = weekdayDistribution[day] {
                    WeekdayMoodRow(day: day, moods: moods)
                }
            }
        }
    }
}

struct WeekdayMoodRow: View {
    let day: String
    let moods: [ContactMood: Int]

    private var total: Int {
        moods.values.reduce(0, +)
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(day.prefix(3))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 30, alignment: .leading)

            GeometryReader { geo in
                HStack(spacing: 0) {
                    ForEach([ContactMood.great, .good, .okay, .notGreat], id: \.self) { mood in
                        if let count = moods[mood], count > 0 {
                            Rectangle()
                                .fill(moodColor(for: mood))
                                .frame(width: geo.size.width * (Double(count) / Double(total)))
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .frame(height: 24)

            Text(String(localized: "component.total", defaultValue: "\(total)", comment: "Total"))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 30)
        }
    }

    private func moodColor(for mood: ContactMood) -> Color {
        switch mood {
        case .great: return .green
        case .good: return .blue
        case .okay: return .orange
        case .notGreat: return .red
        }
    }
}

// MARK: - Stat Grid View

struct StatsGridView: View {
    let stats: [(String, String, String, Color)] // Icon, Label, Value, Color

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(stats.indices, id: \.self) { index in
                let stat = stats[index]
                StatGridItem(
                    icon: stat.0,
                    label: stat.1,
                    value: stat.2,
                    color: stat.3
                )
            }
        }
    }
}

struct StatGridItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Trend Indicator

struct TrendIndicator: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)

            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}

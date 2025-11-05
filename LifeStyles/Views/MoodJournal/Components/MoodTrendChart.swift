//
//  MoodTrendChart.swift
//  LifeStyles
//
//  Mood trend grafik gösterimi (SwiftUI Charts)
//  Created by Claude on 25.10.2025.
//

import SwiftUI
import Charts

// MARK: - Trend Data Model

struct MoodTrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let score: Double
    let moodType: MoodType
    let count: Int // Gün içindeki kayıt sayısı

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }

    var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
}

// MARK: - Time Range

enum TimeRange: String, CaseIterable {
    case week = "7 Gün"
    case twoWeeks = "14 Gün"
    case month = "30 Gün"

    var days: Int {
        switch self {
        case .week: return 7
        case .twoWeeks: return 14
        case .month: return 30
        }
    }

    var icon: String {
        switch self {
        case .week: return "calendar"
        case .twoWeeks: return "calendar.badge.clock"
        case .month: return "calendar.circle"
        }
    }
}

// MARK: - Mood Trend Chart

struct MoodTrendChart: View {
    let entries: [MoodEntry]
    @State private var selectedRange: TimeRange = .week
    @State private var selectedPoint: MoodTrendPoint?

    private var trendData: [MoodTrendPoint] {
        generateTrendData(range: selectedRange)
    }

    private var averageScore: Double {
        guard !trendData.isEmpty else { return 0 }
        return trendData.reduce(0.0) { $0 + $1.score } / Double(trendData.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // Header
            HStack {
                Text(String(localized: "mood.trend", comment: "Mood Trend"))
                    .cardTitle()

                Spacer()

                // Time range picker
                Picker("Zaman", selection: $selectedRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue)
                            .tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }

            // Chart
            if trendData.isEmpty {
                emptyState
            } else {
                chartView
            }
        }
        .padding(Spacing.large)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.relaxed, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .cardShadow()
    }

    // MARK: - Chart View

    private var chartView: some View {
        VStack(spacing: Spacing.small) {
            // Chart
            Chart {
                // Area gradient
                ForEach(trendData) { point in
                    AreaMark(
                        x: .value("Tarih", point.date),
                        y: .value("Skor", point.score)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [gradientColor(for: point.score).opacity(0.3), gradientColor(for: point.score).opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }

                // Line
                ForEach(trendData) { point in
                    LineMark(
                        x: .value("Tarih", point.date),
                        y: .value("Skor", point.score)
                    )
                    .foregroundStyle(gradientColor(for: point.score))
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
                }

                // Points
                ForEach(trendData) { point in
                    PointMark(
                        x: .value("Tarih", point.date),
                        y: .value("Skor", point.score)
                    )
                    .foregroundStyle(point.moodType.color)
                    .symbol {
                        Circle()
                            .fill(point.moodType.color)
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                }

                // Average line
                RuleMark(y: .value("Ortalama", averageScore))
                    .foregroundStyle(Color.gray.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Ort: \(String(format: "%.1f", averageScore))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color(.systemBackground))
                                    .shadow(radius: 2)
                            )
                    }

                // Selection overlay
                if let selectedPoint = selectedPoint {
                    RuleMark(x: .value("Seçili", selectedPoint.date))
                        .foregroundStyle(Color.gray.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1))
                }
            }
            .frame(height: 200)
            .chartYScale(domain: -2...2)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: selectedRange == .week ? 1 : 3)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            VStack(spacing: 2) {
                                Text(date.formatted(.dateTime.day()))
                                    .font(.caption2)
                                Text(date.formatted(.dateTime.weekday(.narrow)))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        AxisGridLine()
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: [-2, -1, 0, 1, 2]) { value in
                    AxisValueLabel {
                        if let score = value.as(Int.self) {
                            Text(scoreLabel(for: score))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    AxisGridLine()
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let location = value.location
                                    if let date: Date = proxy.value(atX: location.x) {
                                        // Find closest point
                                        selectedPoint = trendData.min(by: {
                                            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                                        })
                                    }
                                }
                                .onEnded { _ in
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation {
                                            selectedPoint = nil
                                        }
                                    }
                                }
                        )
                }
            }

            // Selected point info
            if let point = selectedPoint {
                selectedPointInfo(point)
                    .transition(.opacity)
            }

            // Stats summary
            statsRow
        }
    }

    private func selectedPointInfo(_ point: MoodTrendPoint) -> some View {
        HStack(spacing: Spacing.small) {
            Text(point.moodType.emoji)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(point.formattedDate)
                    .font(.caption)
                    .fontWeight(.semibold)

                Text("\(point.moodType.displayName) • Skor: \(String(format: "%.1f", point.score))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if point.count > 1 {
                Text(String(format: NSLocalizedString("mood.records.count", comment: "records count"), point.count))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.gray.opacity(0.1))
                    )
            }
        }
        .padding(Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.compact, style: .continuous)
                .fill(point.moodType.color.opacity(0.1))
        )
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: Spacing.medium) {
            statItem(icon: "arrow.up.right", label: "En İyi", value: String(format: "%.1f", maxScore), color: .green)
            statItem(icon: "arrow.down.right", label: "En Düşük", value: String(format: "%.1f", minScore), color: .red)
            statItem(icon: "chart.line.uptrend.xyaxis", label: "Değişim", value: trendIndicator, color: trendColor)
        }
    }

    private func statItem(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: Spacing.micro) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.medium) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text(String(localized: "mood.no.records.period", comment: "No mood records in this period"))
                .font(.callout)
                .foregroundStyle(.secondary)

            Text(String(localized: "mood.start.adding", comment: "Start adding moods to see trend"))
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func generateTrendData(range: TimeRange) -> [MoodTrendPoint] {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -range.days + 1, to: endDate) else {
            return []
        }

        var points: [MoodTrendPoint] = []

        for dayOffset in 0..<range.days {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else {
                continue
            }
            let dayEntries = entries.filter { calendar.isDate($0.date, inSameDayAs: date) }

            if !dayEntries.isEmpty {
                let avgScore = dayEntries.reduce(0.0) { $0 + $1.score } / Double(dayEntries.count)
                let dominantMood = dayEntries.max(by: { $0.intensity < $1.intensity })?.moodType ?? .neutral

                points.append(MoodTrendPoint(
                    date: date,
                    score: avgScore,
                    moodType: dominantMood,
                    count: dayEntries.count
                ))
            } else {
                // Boş günler için 0 skor
                points.append(MoodTrendPoint(
                    date: date,
                    score: 0,
                    moodType: .neutral,
                    count: 0
                ))
            }
        }

        return points
    }

    private func gradientColor(for score: Double) -> Color {
        if score > 0.5 {
            return .green
        } else if score < -0.5 {
            return .red
        } else {
            return .blue
        }
    }

    private func scoreLabel(for score: Int) -> String {
        switch score {
        case 2: return "😄"
        case 1: return "😊"
        case 0: return "😐"
        case -1: return "😔"
        case -2: return "😢"
        default: return ""
        }
    }

    private var maxScore: Double {
        trendData.map { $0.score }.max() ?? 0
    }

    private var minScore: Double {
        trendData.map { $0.score }.min() ?? 0
    }

    private var trendIndicator: String {
        guard trendData.count >= 2 else { return "—" }

        let firstHalf = trendData.prefix(trendData.count / 2)
        let secondHalf = trendData.suffix(trendData.count / 2)

        let firstAvg = firstHalf.reduce(0.0) { $0 + $1.score } / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0.0) { $0 + $1.score } / Double(secondHalf.count)

        let diff = secondAvg - firstAvg

        if diff > 0.3 {
            return "↑ Yükseliyor"
        } else if diff < -0.3 {
            return "↓ Düşüyor"
        } else {
            return "→ Stabil"
        }
    }

    private var trendColor: Color {
        let indicator = trendIndicator
        if indicator.contains("↑") {
            return .green
        } else if indicator.contains("↓") {
            return .red
        } else {
            return .blue
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        MoodTrendChart(entries: [
            MoodEntry(date: Date().addingTimeInterval(-6 * 86400), moodType: .happy, intensity: 4),
            MoodEntry(date: Date().addingTimeInterval(-5 * 86400), moodType: .veryHappy, intensity: 5),
            MoodEntry(date: Date().addingTimeInterval(-4 * 86400), moodType: .neutral, intensity: 3),
            MoodEntry(date: Date().addingTimeInterval(-3 * 86400), moodType: .sad, intensity: 2),
            MoodEntry(date: Date().addingTimeInterval(-2 * 86400), moodType: .happy, intensity: 4),
            MoodEntry(date: Date().addingTimeInterval(-1 * 86400), moodType: .excited, intensity: 5),
            MoodEntry(date: Date(), moodType: .grateful, intensity: 4)
        ])
        .padding()
    }
}

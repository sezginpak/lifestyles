//
//  InteractiveHeatmap.swift
//  LifeStyles
//
//  30 günlük interaktif mood heatmap
//  Created by Claude on 25.10.2025.
//

import SwiftUI

// MARK: - Heatmap Day Data

struct HeatmapDayData: Identifiable {
    let id = UUID()
    let date: Date
    let moodEntries: [MoodEntry]
    let averageScore: Double
    let intensity: Double // 0-1 (color intensity)

    var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var hasEntries: Bool {
        !moodEntries.isEmpty
    }

    var dominantMood: MoodType? {
        moodEntries.max(by: { $0.intensity < $1.intensity })?.moodType
    }
}

// MARK: - Interactive Heatmap

struct InteractiveHeatmap: View {
    let entries: [MoodEntry]
    @State private var selectedDay: HeatmapDayData?
    @State private var showDetailSheet = false
    @State private var showRouteOverlay = true
    @State private var showPaywall = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    init(entries: [MoodEntry]) {
        self.entries = entries
    }

    private var heatmapData: [HeatmapDayData] {
        generateHeatmapData()
    }

    // Premium kontrolü
    private var isPremium: Bool {
        PurchaseManager.shared.isPremium
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // Header
            HStack {
                Text(String(localized: "mood.30.day.heatmap", comment: "30-Day Mood Heatmap"))
                    .cardTitle()

                Spacer()

                // Toggle streak line
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        showRouteOverlay.toggle()
                    }
                }) {
                    Image(systemName: showRouteOverlay ? "chart.line.uptrend.xyaxis" : "chart.line.uptrend.xyaxis.circle")
                        .font(.callout)
                        .foregroundStyle(.purple)
                }
            }

            // Legend
            legend

            // Heatmap grid
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(heatmapData) { dayData in
                    heatmapCell(dayData)
                        .onTapGesture {
                            if dayData.hasEntries {
                                selectedDay = dayData
                                showDetailSheet = true
                            }
                        }
                }
            }

            // Stats
            statsRow
        }
        .padding(Spacing.large)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.relaxed, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .cardShadow()
        .overlay {
            if !isPremium {
                premiumOverlay
            }
        }
        .sheet(isPresented: $showDetailSheet) {
            if let day = selectedDay {
                DayDetailSheet(dayData: day)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PremiumPaywallView()
        }
    }

    // MARK: - Heatmap Cell

    private func heatmapCell(_ dayData: HeatmapDayData) -> some View {
        ZStack {
            // Background color based on mood
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(cellColor(for: dayData))

            // Day number
            Text(dayData.dayNumber)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(dayData.hasEntries ? .white : .secondary)

            // Today indicator
            if dayData.isToday {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Color.purple, lineWidth: 2)
            }

            // Streak indicator (optional)
            if showRouteOverlay && dayData.hasEntries {
                Circle()
                    .fill(Color.white)
                    .frame(width: 4, height: 4)
                    .offset(y: -12)
            }
        }
        .frame(height: 40)
        .contentShape(Rectangle())
    }

    private func cellColor(for dayData: HeatmapDayData) -> Color {
        guard dayData.hasEntries else {
            return Color.gray.opacity(0.1)
        }

        if let mood = dayData.dominantMood {
            return mood.color.opacity(0.5 + dayData.intensity * 0.5)
        }

        // Fallback: Score-based color
        let score = dayData.averageScore
        if score > 0.5 {
            return Color.green.opacity(0.5 + dayData.intensity * 0.5)
        } else if score < -0.5 {
            return Color.red.opacity(0.5 + dayData.intensity * 0.5)
        } else {
            return Color.blue.opacity(0.5 + dayData.intensity * 0.5)
        }
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: Spacing.small) {
            legendItem(color: .gray.opacity(0.1), label: "Kayıt yok")

            Spacer()

            Text(String(localized: "mood.label", comment: "Mood:"))
                .font(.caption2)
                .foregroundStyle(.secondary)

            legendItem(color: .red.opacity(0.7), label: "Düşük")
            legendItem(color: .blue.opacity(0.7), label: "Orta")
            legendItem(color: .green.opacity(0.7), label: "Yüksek")
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(color)
                .frame(width: 12, height: 12)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: Spacing.large) {
            statItem(
                icon: "checkmark.circle.fill",
                label: "Aktif Gün",
                value: "\(activeDaysCount)/30",
                color: .green
            )

            statItem(
                icon: "flame.fill",
                label: "Streak",
                value: "\(currentStreak) gün",
                color: .orange
            )

            statItem(
                icon: "chart.bar.fill",
                label: "Ortalama",
                value: String(format: "%.1f", averageScore),
                color: .purple
            )
        }
    }

    private func statItem(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.micro) {
            HStack(spacing: Spacing.micro) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)

                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.callout)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Premium Overlay

    private var premiumOverlay: some View {
        ZStack {
            // Blur background
            RoundedRectangle(cornerRadius: CornerRadius.relaxed, style: .continuous)
                .fill(.ultraThinMaterial)

            // Content
            VStack(spacing: Spacing.large) {
                // Crown icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.2), .blue.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)

                    Image(systemName: "crown.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                // Text
                VStack(spacing: Spacing.small) {
                    Text(String(localized: "common.premium.feature", comment: "Premium Feature"))
                        .font(.title3)
                        .fontWeight(.bold)

                    Text(String(localized: "mood.heatmap.premium.required", comment: "30-day heatmap requires Premium"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.large)
                }

                // CTA Button
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text(String(localized: "common.premium.upgrade", comment: "Upgrade to Premium"))
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, Spacing.large)
                    .padding(.vertical, Spacing.medium)
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
            }
            .padding(Spacing.large)
        }
    }

    // MARK: - Computed Properties

    private var activeDaysCount: Int {
        heatmapData.filter { $0.hasEntries }.count
    }

    private var currentStreak: Int {
        var streak = 0
        let sortedData = heatmapData.sorted(by: { $0.date > $1.date })

        for dayData in sortedData {
            if dayData.hasEntries {
                streak += 1
            } else {
                break
            }
        }

        return streak
    }

    private var averageScore: Double {
        let daysWithEntries = heatmapData.filter { $0.hasEntries }
        guard !daysWithEntries.isEmpty else { return 0 }

        let totalScore = daysWithEntries.reduce(0.0) { $0 + $1.averageScore }
        return totalScore / Double(daysWithEntries.count)
    }

    // MARK: - Data Generation

    private func generateHeatmapData() -> [HeatmapDayData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var data: [HeatmapDayData] = []

        for dayOffset in (0..<30).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                continue
            }

            let dayEntries = entries.filter { calendar.isDate($0.date, inSameDayAs: date) }

            let avgScore: Double
            let intensity: Double

            if !dayEntries.isEmpty {
                avgScore = dayEntries.reduce(0.0) { $0 + $1.score } / Double(dayEntries.count)
                let avgIntensity = dayEntries.reduce(0) { $0 + $1.intensity } / dayEntries.count
                intensity = Double(avgIntensity) / 5.0 // Normalize to 0-1
            } else {
                avgScore = 0
                intensity = 0
            }

            data.append(HeatmapDayData(
                date: date,
                moodEntries: dayEntries,
                averageScore: avgScore,
                intensity: intensity
            ))
        }

        return data
    }
}

// MARK: - Day Detail Sheet

struct DayDetailSheet: View {
    let dayData: HeatmapDayData
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.large) {
                    // Date header
                    VStack(spacing: Spacing.small) {
                        Text(formattedDate)
                            .font(.title2)
                            .fontWeight(.bold)

                        if dayData.isToday {
                            Text(String(localized: "mood.today", comment: "Today"))
                                .font(.caption)
                                .foregroundStyle(.purple)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.purple.opacity(0.1))
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.large)

                    // Mood entries
                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        Text(String(format: NSLocalizedString("mood.records.format", comment: "Mood Records"), dayData.moodEntries.count))
                            .font(.headline)

                        ForEach(dayData.moodEntries.sorted(by: { $0.date < $1.date })) { entry in
                            moodEntryRow(entry)
                        }
                    }

                    // Stats
                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        Text(String(localized: "mood.statistics", comment: "Statistics"))
                            .font(.headline)

                        statsGrid
                    }
                }
                .padding(Spacing.large)
            }
            .navigationTitle(String(localized: "journal.nav.day.detail", comment: "Day detail"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "button.close", comment: "Close button")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func moodEntryRow(_ entry: MoodEntry) -> some View {
        HStack(spacing: Spacing.medium) {
            // Time
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.date.formatted(.dateTime.hour().minute()))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(relativeTime(from: entry.date))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(width: 60, alignment: .leading)

            // Mood
            HStack(spacing: Spacing.small) {
                Text(entry.moodType.emoji)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.moodType.displayName)
                        .font(.callout)
                        .fontWeight(.medium)

                    HStack(spacing: 2) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < entry.intensity ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundStyle(index < entry.intensity ? .yellow : .gray)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.normal, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: Spacing.medium) {
            statCard(
                icon: "chart.line.uptrend.xyaxis",
                label: "Ortalama Skor",
                value: String(format: "%.1f", dayData.averageScore),
                color: .blue
            )

            statCard(
                icon: "star.fill",
                label: "Ortalama Yoğunluk",
                value: String(format: "%.1f/5", averageIntensity),
                color: .yellow
            )

            // Sadece entry varsa göster
            if let entry = entry {
                statCard(
                    icon: entry.moodType.isPositive ? "hand.thumbsup.fill" : "hand.thumbsdown.fill",
                    label: "Baskın Mood",
                    value: entry.moodType.displayName,
                    color: entry.moodType.color
                )
            }

            statCard(
                icon: "clock.fill",
                label: "Kayıt Sayısı",
                value: "\(dayData.moodEntries.count)",
                color: .purple
            )
        }
    }

    private func statCard(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.callout)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.normal, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: dayData.date)
    }

    private func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private var averageIntensity: Double {
        let total = dayData.moodEntries.reduce(0) { $0 + $1.intensity }
        return Double(total) / Double(dayData.moodEntries.count)
    }

    private var entry: MoodEntry? {
        if let dominantMood = dayData.dominantMood {
            return dayData.moodEntries.first(where: { $0.moodType == dominantMood })
        }
        return dayData.moodEntries.first
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        InteractiveHeatmap(entries: [
            MoodEntry(date: Date().addingTimeInterval(-1 * 86400), moodType: .happy, intensity: 4),
            MoodEntry(date: Date().addingTimeInterval(-2 * 86400), moodType: .veryHappy, intensity: 5),
            MoodEntry(date: Date().addingTimeInterval(-3 * 86400), moodType: .neutral, intensity: 3),
            MoodEntry(date: Date().addingTimeInterval(-4 * 86400), moodType: .sad, intensity: 2),
            MoodEntry(date: Date().addingTimeInterval(-5 * 86400), moodType: .happy, intensity: 4),
            MoodEntry(date: Date().addingTimeInterval(-6 * 86400), moodType: .excited, intensity: 5),
            MoodEntry(date: Date().addingTimeInterval(-7 * 86400), moodType: .grateful, intensity: 4),
            MoodEntry(date: Date().addingTimeInterval(-10 * 86400), moodType: .tired, intensity: 2),
            MoodEntry(date: Date().addingTimeInterval(-12 * 86400), moodType: .happy, intensity: 4),
            MoodEntry(date: Date(), moodType: .veryHappy, intensity: 5)
        ])
        .padding()
    }
}

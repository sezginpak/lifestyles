//
//  PatternRecognitionCard.swift
//  LifeStyles
//
//  Pattern detection ve görüntüleme
//  Created by Claude on 25.10.2025.
//

import SwiftUI

// MARK: - Pattern Recognition Card

struct PatternRecognitionCard: View {
    let entries: [MoodEntry]
    @State private var selectedPattern: PatternInsight?
    @State private var showDetailSheet = false

    private var patterns: [PatternInsight] {
        detectPatterns(from: entries)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // Header
            Text(String(localized: "mood.patterns.detected", comment: "Detected Patterns"))
                .cardTitle()

            if patterns.isEmpty {
                emptyState
            } else {
                patternsGrid
            }
        }
        .padding(Spacing.large)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.relaxed, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .cardShadow()
        .sheet(isPresented: $showDetailSheet) {
            if let pattern = selectedPattern {
                PatternDetailSheet(pattern: pattern, entries: entries)
            }
        }
    }

    // MARK: - Patterns Grid

    private var patternsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: Spacing.medium) {
            ForEach(patterns) { pattern in
                patternCard(pattern)
                    .onTapGesture {
                        selectedPattern = pattern
                        showDetailSheet = true
                    }
            }
        }
    }

    private func patternCard(_ pattern: PatternInsight) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            // Icon + Impact indicator
            HStack {
                Text(pattern.emoji)
                    .font(.title)

                Spacer()

                impactBadge(pattern.impact)
            }

            // Title
            Text(pattern.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)

            // Description
            Text(pattern.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            // Frequency
            HStack {
                Image(systemName: "clock")
                    .font(.caption2)

                Text(pattern.frequency)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                if pattern.confidence > 0.7 {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.normal, style: .continuous)
                .fill(pattern.backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.normal, style: .continuous)
                .strokeBorder(pattern.borderColor, lineWidth: 1)
        )
    }

    private func impactBadge(_ impact: PatternImpact) -> some View {
        Circle()
            .fill(impactColor(impact))
            .frame(width: 8, height: 8)
    }

    private func impactColor(_ impact: PatternImpact) -> Color {
        switch impact {
        case .positive: return .green
        case .negative: return .red
        case .neutral: return .gray
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.medium) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text(String(localized: "pattern.not.detected.yet", comment: "No patterns detected yet"))
                .font(.callout)
                .foregroundStyle(.secondary)

            Text(String(localized: "pattern.discover.more", comment: "Record more moods to discover patterns"))
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
    }

    // MARK: - Pattern Detection Logic

    private func detectPatterns(from entries: [MoodEntry]) -> [PatternInsight] {
        guard entries.count >= 7 else { return [] }

        var patterns: [PatternInsight] = []

        // Pattern 1: Best day of week
        if let bestDay = detectBestDayOfWeek(entries) {
            patterns.append(bestDay)
        }

        // Pattern 2: Time of day pattern
        if let timePattern = detectTimeOfDayPattern(entries) {
            patterns.append(timePattern)
        }

        // Pattern 3: Streak pattern
        if let streakPattern = detectStreakPattern(entries) {
            patterns.append(streakPattern)
        }

        // Pattern 4: Social correlation
        if let socialPattern = detectSocialCorrelation(entries) {
            patterns.append(socialPattern)
        }

        // Pattern 5: Weekend vs Weekday
        if let weekendPattern = detectWeekendPattern(entries) {
            patterns.append(weekendPattern)
        }

        return patterns
    }

    // Best day of week
    private func detectBestDayOfWeek(_ entries: [MoodEntry]) -> PatternInsight? {
        let byDay = Dictionary(grouping: entries) { entry -> Int in
            Calendar.current.component(.weekday, from: entry.date)
        }

        guard let (dayIndex, dayEntries) = byDay.max(by: { lhs, rhs in
            let lhsAvg = lhs.value.reduce(0.0) { $0 + $1.score } / Double(lhs.value.count)
            let rhsAvg = rhs.value.reduce(0.0) { $0 + $1.score } / Double(rhs.value.count)
            return lhsAvg < rhsAvg
        }) else {
            return nil
        }

        let avgScore = dayEntries.reduce(0.0) { $0 + $1.score } / Double(dayEntries.count)

        guard avgScore > 0.3 else { return nil }

        let dayNames = ["Pazar", "Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi"]
        let dayName = dayNames[dayIndex - 1]

        return PatternInsight(
            title: "En İyi Gün",
            description: "\(dayName) günleri daha mutlu hissediyorsunuz",
            frequency: "Haftalık",
            impact: .positive,
            emoji: "📅",
            confidence: min(1.0, abs(avgScore)),
            details: "\(dayName) günleri ortalama \(String(format: "%.1f", avgScore)) mood skoru",
            backgroundColor: Color.green.opacity(0.05),
            borderColor: Color.green.opacity(0.2)
        )
    }

    // Time of day pattern
    private func detectTimeOfDayPattern(_ entries: [MoodEntry]) -> PatternInsight? {
        let byTime = Dictionary(grouping: entries) { entry -> String in
            let hour = Calendar.current.component(.hour, from: entry.date)
            if hour < 12 { return "Sabah" }
            else if hour < 18 { return "Öğlen" }
            else { return "Akşam" }
        }

        guard let (time, timeEntries) = byTime.max(by: { lhs, rhs in
            let lhsAvg = lhs.value.reduce(0.0) { $0 + $1.score } / Double(lhs.value.count)
            let rhsAvg = rhs.value.reduce(0.0) { $0 + $1.score } / Double(rhs.value.count)
            return lhsAvg < rhsAvg
        }) else {
            return nil
        }

        let avgScore = timeEntries.reduce(0.0) { $0 + $1.score } / Double(timeEntries.count)

        guard avgScore > 0.2 else { return nil }

        return PatternInsight(
            title: "Günün Zamanı",
            description: "\(time) saatlerinde daha iyi hissediyorsunuz",
            frequency: "Günlük",
            impact: avgScore > 0.5 ? .positive : .neutral,
            emoji: time == "Sabah" ? "🌅" : (time == "Öğlen" ? "☀️" : "🌙"),
            confidence: min(1.0, abs(avgScore)),
            details: "\(time) ortalama \(String(format: "%.1f", avgScore)) mood skoru",
            backgroundColor: Color.blue.opacity(0.05),
            borderColor: Color.blue.opacity(0.2)
        )
    }

    // Streak pattern
    private func detectStreakPattern(_ entries: [MoodEntry]) -> PatternInsight? {
        let sortedEntries = entries.sorted(by: { $0.date < $1.date })
        var currentStreak = 0
        var maxStreak = 0
        var lastDate: Date?

        for entry in sortedEntries {
            if let last = lastDate {
                let daysDiff = Calendar.current.dateComponents([.day], from: last, to: entry.date).day ?? 0
                if daysDiff == 1 {
                    currentStreak += 1
                } else {
                    maxStreak = max(maxStreak, currentStreak)
                    currentStreak = 1
                }
            } else {
                currentStreak = 1
            }
            lastDate = entry.date
        }

        maxStreak = max(maxStreak, currentStreak)

        guard maxStreak >= 3 else { return nil }

        return PatternInsight(
            title: "Düzenli Takip",
            description: "\(maxStreak) gün üst üste mood kaydettiniz!",
            frequency: "Günlük",
            impact: .positive,
            emoji: "🔥",
            confidence: min(1.0, Double(maxStreak) / 7.0),
            details: "En uzun streak: \(maxStreak) gün",
            backgroundColor: Color.orange.opacity(0.05),
            borderColor: Color.orange.opacity(0.2)
        )
    }

    // Social correlation
    private func detectSocialCorrelation(_ entries: [MoodEntry]) -> PatternInsight? {
        let withFriends = entries.filter { !($0.relatedFriends?.isEmpty ?? true) }
        let withoutFriends = entries.filter { $0.relatedFriends?.isEmpty ?? true }

        guard withFriends.count >= 3, withoutFriends.count >= 3 else { return nil }

        let avgWithFriends = withFriends.reduce(0.0) { $0 + $1.score } / Double(withFriends.count)
        let avgWithoutFriends = withoutFriends.reduce(0.0) { $0 + $1.score } / Double(withoutFriends.count)

        let diff = avgWithFriends - avgWithoutFriends

        guard abs(diff) > 0.3 else { return nil }

        if diff > 0 {
            return PatternInsight(
                title: "Sosyal Bağlantı",
                description: "Arkadaşlarla görüştüğünüzde daha mutlu oluyorsunuz",
                frequency: "Haftalık",
                impact: .positive,
                emoji: "👥",
                confidence: min(1.0, abs(diff)),
                details: "Sosyal etkileşim +\(String(format: "%.1f", diff)) mood etkisi",
                backgroundColor: Color.pink.opacity(0.05),
                borderColor: Color.pink.opacity(0.2)
            )
        } else {
            return PatternInsight(
                title: "Me-Time",
                description: "Yalnız zamanlarınızda daha huzurlu hissediyorsunuz",
                frequency: "Haftalık",
                impact: .neutral,
                emoji: "🧘",
                confidence: min(1.0, abs(diff)),
                details: "Yalnız zaman +\(String(format: "%.1f", abs(diff))) mood etkisi",
                backgroundColor: Color.purple.opacity(0.05),
                borderColor: Color.purple.opacity(0.2)
            )
        }
    }

    // Weekend vs Weekday
    private func detectWeekendPattern(_ entries: [MoodEntry]) -> PatternInsight? {
        let weekendEntries = entries.filter { entry in
            let weekday = Calendar.current.component(.weekday, from: entry.date)
            return weekday == 1 || weekday == 7 // Pazar veya Cumartesi
        }

        let weekdayEntries = entries.filter { entry in
            let weekday = Calendar.current.component(.weekday, from: entry.date)
            return weekday != 1 && weekday != 7
        }

        guard weekendEntries.count >= 2, weekdayEntries.count >= 3 else { return nil }

        let avgWeekend = weekendEntries.reduce(0.0) { $0 + $1.score } / Double(weekendEntries.count)
        let avgWeekday = weekdayEntries.reduce(0.0) { $0 + $1.score } / Double(weekdayEntries.count)

        let diff = avgWeekend - avgWeekday

        guard abs(diff) > 0.3 else { return nil }

        if diff > 0 {
            return PatternInsight(
                title: "Hafta Sonu Etkisi",
                description: "Hafta sonları daha iyi hissediyorsunuz",
                frequency: "Haftalık",
                impact: .positive,
                emoji: "🎉",
                confidence: min(1.0, abs(diff)),
                details: "Hafta sonu +\(String(format: "%.1f", diff)) mood farkı",
                backgroundColor: Color.cyan.opacity(0.05),
                borderColor: Color.cyan.opacity(0.2)
            )
        } else {
            return PatternInsight(
                title: "Hafta İçi Performansı",
                description: "Hafta içi daha üretken ve mutlusunuz",
                frequency: "Haftalık",
                impact: .positive,
                emoji: "💼",
                confidence: min(1.0, abs(diff)),
                details: "Hafta içi +\(String(format: "%.1f", abs(diff))) mood farkı",
                backgroundColor: Color.indigo.opacity(0.05),
                borderColor: Color.indigo.opacity(0.2)
            )
        }
    }
}

// MARK: - Pattern Insight Model

enum PatternImpact {
    case positive
    case negative
    case neutral
}

struct PatternInsight: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let frequency: String
    let impact: PatternImpact
    let emoji: String
    let confidence: Double // 0-1
    let details: String
    let backgroundColor: Color
    let borderColor: Color
}

// MARK: - Pattern Detail Sheet

struct PatternDetailSheet: View {
    let pattern: PatternInsight
    let entries: [MoodEntry]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.large) {
                    // Hero
                    VStack(spacing: Spacing.medium) {
                        Text(pattern.emoji)
                            .font(.system(size: 60))

                        Text(pattern.title)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(pattern.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.large)

                    // Stats
                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        statRow(icon: "chart.bar.fill", label: "Güvenilirlik", value: "\(Int(pattern.confidence * 100))%")
                        statRow(icon: "clock", label: "Frekans", value: pattern.frequency)
                        statRow(icon: "info.circle", label: "Detay", value: pattern.details)
                    }
                    .padding(Spacing.large)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.normal, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )

                    // Tips
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text(String(localized: "pattern.what.to.do", comment: "What should you do"))
                            .font(.headline)

                        Text(recommendation(for: pattern))
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .padding(Spacing.large)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.normal, style: .continuous)
                            .fill(pattern.backgroundColor)
                    )
                }
                .padding(Spacing.large)
            }
            .navigationTitle("Pattern Detayı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func statRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            Text(label)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.semibold)
        }
    }

    private func recommendation(for pattern: PatternInsight) -> String {
        if pattern.title.contains("En İyi Gün") {
            return "Bu günleri iyi değerlendirin! Zor görevlerinizi bu güne planlayabilirsiniz."
        } else if pattern.title.contains("Günün Zamanı") {
            return "En üretken olduğunuz saatleri önemli işler için kullanın."
        } else if pattern.title.contains("Düzenli Takip") {
            return "Harika gidiyorsunuz! Mood takibine devam edin, pattern'ler daha net görünecek."
        } else if pattern.title.contains("Sosyal Bağlantı") {
            return "Sosyal etkileşimlerinizi artırın. Arkadaşlarınızla daha sık görüşmeye çalışın."
        } else if pattern.title.contains("Me-Time") {
            return "Kendinize zaman ayırmaktan çekinmeyin. Bu sizin için önemli."
        } else if pattern.title.contains("Hafta Sonu") {
            return "Hafta sonlarınızı iyi değerlendirin. Dinlenme ve keyif için kullanın."
        } else if pattern.title.contains("Hafta İçi") {
            return "İş/okul rutininiz size iyi geliyor. Bu dengeyi koruyun."
        }

        return "Pattern'inizi takip etmeye devam edin ve kendinizi daha iyi tanıyın."
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        PatternRecognitionCard(entries: [
            MoodEntry(date: Date().addingTimeInterval(-1 * 86400), moodType: .happy, intensity: 4),
            MoodEntry(date: Date().addingTimeInterval(-2 * 86400), moodType: .veryHappy, intensity: 5),
            MoodEntry(date: Date().addingTimeInterval(-3 * 86400), moodType: .neutral, intensity: 3),
            MoodEntry(date: Date().addingTimeInterval(-4 * 86400), moodType: .sad, intensity: 2),
            MoodEntry(date: Date().addingTimeInterval(-5 * 86400), moodType: .happy, intensity: 4),
            MoodEntry(date: Date().addingTimeInterval(-6 * 86400), moodType: .excited, intensity: 5),
            MoodEntry(date: Date().addingTimeInterval(-7 * 86400), moodType: .grateful, intensity: 4),
        ])
        .padding()
    }
}

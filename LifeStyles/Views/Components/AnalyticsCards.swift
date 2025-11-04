//
//  AnalyticsCards.swift
//  LifeStyles
//
//  Created by Claude on 31.10.2025.
//

import SwiftUI

// MARK: - Consistency Score Card

struct ConsistencyScoreCard: View {
    let metrics: FriendAnalyticsViewModel.ConsistencyMetrics

    var body: some View {
        AnalyticsCard(
            title: "Tutarlılık Skoru",
            icon: "chart.line.uptrend.xyaxis",
            color: metrics.category.color
        ) {
            VStack(spacing: 20) {
                // Circular gauge with score
                ZStack {
                    CircularProgressGauge(
                        progress: Double(metrics.score) / 100.0,
                        lineWidth: 20,
                        size: 140,
                        color: metrics.category.color
                    )

                    VStack(spacing: 4) {
                        Text("\(metrics.score)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(.primary)

                        Image(systemName: metrics.category.icon)
                            .font(.title3)
                            .foregroundStyle(metrics.category.color)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)

                // Category badge
                HStack {
                    Spacer()
                    TrendIndicator(
                        icon: metrics.category.icon,
                        label: metrics.category.rawValue,
                        color: metrics.category.color
                    )
                    Spacer()
                }

                Divider()

                // Stats
                StatsGridView(stats: [
                    ("target", "Hedef", "\(metrics.targetDays) gün", .blue),
                    ("calendar", "Ortalama", String(format: "%.1f gün", metrics.averageDays), .green),
                    ("chart.bar", "Sapma", String(format: "±%.1f gün", metrics.deviation), .orange),
                    ("checkmark.circle", "Tutarlı", metrics.score >= 70 ? "Evet" : "Hayır",
                     metrics.score >= 70 ? .green : .red)
                ])
            }
        }
    }
}

// MARK: - Timing Analytics Card

struct TimingAnalyticsCard: View {
    let analytics: FriendAnalyticsViewModel.TimingAnalytics

    @State private var selectedView: TimingView = .hourly

    enum TimingView {
        case hourly, weekday, summary
    }

    var body: some View {
        AnalyticsCard(
            title: "Zamanlama Analizi",
            icon: "clock.fill",
            color: .blue
        ) {
            VStack(spacing: 16) {
                // Segmented picker
                Picker("Görünüm", selection: $selectedView) {
                    Text("Saatlik").tag(TimingView.hourly)
                    Text("Günlük").tag(TimingView.weekday)
                    Text("Özet").tag(TimingView.summary)
                }
                .pickerStyle(.segmented)

                // Content based on selection
                switch selectedView {
                case .hourly:
                    hourlyView
                case .weekday:
                    weekdayView
                case .summary:
                    summaryView
                }
            }
        }
    }

    private var hourlyView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Saatlik Dağılım")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            ScrollView {
                HourlyHeatMap(hourlyDistribution: analytics.hourlyDistribution)
            }
            .frame(maxHeight: 300)

            if let mostActiveHour = analytics.mostActiveHour {
                HStack {
                    Spacer()
                    StatPillView(
                        icon: "star.fill",
                        label: "En Aktif Saat",
                        value: String(format: "%02d:00", mostActiveHour),
                        color: .blue
                    )
                    Spacer()
                }
            }
        }
    }

    private var weekdayView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Günlük Dağılım")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            let sortedWeekdays = analytics.weekdayDistribution.sorted { $0.value > $1.value }
            SimpleBarChart(
                data: sortedWeekdays.map { (dayName(for: $0.key), Double($0.value)) },
                color: .blue
            )

            if let mostActiveDay = analytics.mostActiveDay {
                HStack {
                    Spacer()
                    StatPillView(
                        icon: "star.fill",
                        label: "En Aktif Gün",
                        value: mostActiveDay,
                        color: .blue
                    )
                    Spacer()
                }
            }
        }
    }

    private var summaryView: some View {
        VStack(spacing: 16) {
            // Weekday vs Weekend
            HStack(spacing: 12) {
                VStack(spacing: 8) {
                    Image(systemName: "briefcase.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)

                    Text("\(analytics.weekdayCount)")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Hafta İçi")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(spacing: 8) {
                    Image(systemName: "sun.max.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)

                    Text("\(analytics.weekendCount)")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Hafta Sonu")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Divider()

            // Most active insights
            VStack(alignment: .leading, spacing: 8) {
                if let mostActiveHour = analytics.mostActiveHour {
                    InsightRow(
                        icon: "clock.fill",
                        label: "En aktif saat:",
                        value: String(format: "%02d:00", mostActiveHour),
                        color: .blue
                    )
                }

                if let mostActiveDay = analytics.mostActiveDay {
                    InsightRow(
                        icon: "calendar",
                        label: "En aktif gün:",
                        value: mostActiveDay,
                        color: .green
                    )
                }

                if let mostActiveMonth = analytics.mostActiveMonth {
                    InsightRow(
                        icon: "calendar.badge.clock",
                        label: "En aktif ay:",
                        value: mostActiveMonth,
                        color: .purple
                    )
                }
            }
        }
    }

    private func dayName(for weekday: Int) -> String {
        let days = ["", "Pazar", "Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi"]
        return days[min(max(weekday, 0), 7)]
    }
}

struct InsightRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Milestone Tracker Card

struct MilestoneTrackerCard: View {
    let milestones: [FriendAnalyticsViewModel.Milestone]

    var body: some View {
        AnalyticsCard(
            title: "Yaklaşan Başarılar",
            icon: "flag.checkered",
            color: .purple
        ) {
            if milestones.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.yellow)

                    Text("Tebrikler!")
                        .font(.headline)

                    Text("Tüm yakın başarıları tamamladınız")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 16) {
                    ForEach(Array(milestones.prefix(5).enumerated()), id: \.offset) { item in
                        MilestoneRow(milestone: item.element, rank: item.offset + 1)

                        if item.offset < min(milestones.count, 5) - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
    }
}

struct MilestoneRow: View {
    let milestone: FriendAnalyticsViewModel.Milestone
    let rank: Int

    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(milestone.color.opacity(0.2))
                    .frame(width: 32, height: 32)

                Text("\(rank)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(milestone.color)
            }

            // Progress ring
            MilestoneProgressRing(milestone: milestone, size: 50)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(milestone.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(milestone.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !milestone.isCompleted {
                    Text("\(milestone.remaining) kaldı")
                        .font(.caption2)
                        .foregroundStyle(milestone.color)
                        .fontWeight(.medium)
                }
            }

            Spacer()

            // Percentage
            if !milestone.isCompleted {
                Text(String(format: "%.0f%%", milestone.progress * 100))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(milestone.color)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
            }
        }
    }
}

// MARK: - Communication Depth Card

struct CommunicationDepthCard: View {
    let metrics: FriendAnalyticsViewModel.DepthMetrics

    var body: some View {
        AnalyticsCard(
            title: "İletişim Derinliği",
            icon: "text.bubble.fill",
            color: .indigo
        ) {
            VStack(spacing: 16) {
                // Stats grid
                StatsGridView(stats: [
                    ("note.text", "Toplam Not", "\(metrics.totalNotes)", .indigo),
                    ("percent", "Not Oranı", String(format: "%.0f%%", metrics.notesPercentage), .blue),
                    ("text.alignleft", "Ort. Uzunluk", String(format: "%.0f karakter", metrics.averageNoteLength), .green),
                    ("doc.text", "En Uzun", "\(metrics.longestNote) karakter", .purple)
                ])

                Divider()

                // Trend indicator
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundStyle(.secondary)

                    Text("Not Yazma Trendi:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    TrendIndicator(
                        icon: metrics.recentNotesTrend.icon,
                        label: metrics.recentNotesTrend.rawValue,
                        color: metrics.recentNotesTrend.color
                    )
                }

                // Insight text
                insightText
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var insightText: some View {
        Group {
            if metrics.notesPercentage >= 80 {
                Text("✨ Harika! Görüşmelerinizin çoğunda not tutuyorsunuz. Bu derin ve anlamlı iletişimin göstergesi.")
            } else if metrics.notesPercentage >= 50 {
                Text("👍 İyi gidiyorsunuz. Daha fazla not almak görüşmelerinizi daha anlamlı hale getirebilir.")
            } else if metrics.notesPercentage >= 25 {
                Text("💡 Görüşmeleriniz sırasında not almayı deneyin. Gelecekte değerli anılar olabilir.")
            } else {
                Text("📝 Not tutmaya başlamak için harika bir zaman! Küçük detaylar bile önemlidir.")
            }
        }
    }
}

// MARK: - Enhanced Mood Cards

struct FriendMoodTimelineCard: View {
    let analytics: FriendAnalyticsViewModel.MoodAnalytics

    var body: some View {
        AnalyticsCard(
            title: "Ruh Hali Trend Analizi",
            icon: "chart.xyaxis.line",
            color: .green
        ) {
            VStack(spacing: 16) {
                if analytics.timelineData.isEmpty {
                    emptyState
                } else {
                    // Timeline chart
                    MoodTimelineChart(timelineData: analytics.timelineData)

                    Divider()

                    // Overall trend
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundStyle(.secondary)

                        Text("Genel Eğilim:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        TrendIndicator(
                            icon: analytics.overallTrend.icon,
                            label: analytics.overallTrend.rawValue,
                            color: analytics.overallTrend.color
                        )
                    }

                    // Average mood score
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)

                        Text("Ortalama Ruh Hali:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(String(format: "%.0f%%", analytics.averageMoodScore * 100))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Henüz Ruh Hali Verisi Yok")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Görüşmelerinize ruh hali ekleyerek trend analizi oluşturabilirsiniz")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct MoodStreakCard: View {
    let analytics: FriendAnalyticsViewModel.MoodAnalytics

    var body: some View {
        AnalyticsCard(
            title: "Ruh Hali Serisi",
            icon: "flame.fill",
            color: .orange
        ) {
            if let streak = analytics.currentStreak {
                VStack(spacing: 16) {
                    // Streak display
                    VStack(spacing: 12) {
                        Text(streak.emoji)
                            .font(.system(size: 64))

                        Text("\(streak.count)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(streak.color)

                        Text(streak.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)

                    Divider()

                    // Start date
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundStyle(.secondary)

                        Text("Başlangıç:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(streak.startDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    // Encouragement message
                    encouragementMessage(for: streak)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(12)
                        .background(streak.color.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            } else {
                emptyState
            }
        }
    }

    private func encouragementMessage(for streak: FriendAnalyticsViewModel.MoodStreak) -> Text {
        switch streak.type {
        case .great:
            if streak.count >= 5 {
                return Text("🎉 Muhteşem! \(streak.count) harika görüşme serisi devam ediyor!")
            } else {
                return Text("✨ İyi gidiyorsunuz! \(streak.count) harika görüşme. Devam edin!")
            }
        case .good:
            return Text("👍 \(streak.count) iyi görüşme! İlişkiniz güzel seyrediyor.")
        case .okay:
            return Text("🤔 Son \(streak.count) görüşme normal geçti. Belki daha derin konuşmalar deneyebilirsiniz?")
        case .notGreat:
            return Text("💙 Son \(streak.count) görüşme zordu. Bu kişiyle konuşmak faydalı olabilir.")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Henüz Seri Yok")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Görüşmelerinize ruh hali ekleyerek seri oluşturabilirsiniz")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct WeekdayMoodDistributionCard: View {
    let analytics: FriendAnalyticsViewModel.MoodAnalytics

    var body: some View {
        AnalyticsCard(
            title: "Günlere Göre Ruh Hali",
            icon: "calendar.badge.clock",
            color: .blue
        ) {
            if analytics.weekdayDistribution.isEmpty {
                emptyState
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Hangi günler daha pozitif?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    WeekdayMoodChart(weekdayDistribution: analytics.weekdayDistribution)

                    // Legend
                    HStack(spacing: 12) {
                        ForEach([ContactMood.great, .good, .okay, .notGreat], id: \.self) { mood in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(moodColor(for: mood))
                                    .frame(width: 8, height: 8)

                                Text(moodLabel(for: mood))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Henüz Günlük Veri Yok")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func moodColor(for mood: ContactMood) -> Color {
        switch mood {
        case .great: return .green
        case .good: return .blue
        case .okay: return .orange
        case .notGreat: return .red
        }
    }

    private func moodLabel(for mood: ContactMood) -> String {
        switch mood {
        case .great: return "Harika"
        case .good: return "İyi"
        case .okay: return "Normal"
        case .notGreat: return "Zor"
        }
    }
}

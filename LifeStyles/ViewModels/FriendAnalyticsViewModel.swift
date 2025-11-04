//
//  FriendAnalyticsViewModel.swift
//  LifeStyles
//
//  Created by Claude on 31.10.2025.
//

import Foundation
import SwiftUI

@Observable
class FriendAnalyticsViewModel {
    let friend: Friend

    init(friend: Friend) {
        self.friend = friend
    }

    // MARK: - Helper Properties

    /// Calculates current streak of consistent communication
    private var currentStreak: Int {
        guard let history = friend.contactHistory, !history.isEmpty else { return 0 }

        let sorted = history.sorted(by: { $0.date > $1.date })
        var streak = 0
        var lastDate = Date()

        for item in sorted {
            let daysDiff = Calendar.current.dateComponents([.day], from: item.date, to: lastDate).day ?? 0
            if daysDiff <= friend.frequency.days + 1 {
                streak += 1
                lastDate = item.date
            } else {
                break
            }
        }

        return streak
    }

    // MARK: - Consistency Score

    struct ConsistencyMetrics {
        let score: Int // 0-100
        let category: ConsistencyCategory
        let targetDays: Int
        let averageDays: Double
        let deviation: Double
    }

    enum ConsistencyCategory: String {
        case excellent = "Mükemmel"
        case good = "İyi"
        case moderate = "Orta"
        case poor = "Düzensiz"

        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .blue
            case .moderate: return .orange
            case .poor: return .red
            }
        }

        var icon: String {
            switch self {
            case .excellent: return "checkmark.seal.fill"
            case .good: return "checkmark.circle.fill"
            case .moderate: return "exclamationmark.circle.fill"
            case .poor: return "xmark.circle.fill"
            }
        }
    }

    var consistencyMetrics: ConsistencyMetrics {
        guard let history = friend.contactHistory,
              !history.isEmpty else {
            return ConsistencyMetrics(score: 0, category: .poor, targetDays: 0, averageDays: 0, deviation: 0)
        }

        let sortedHistory = history.sorted { $0.date > $1.date }
        let targetDays = friend.frequency.days

        // Son 10 iletişim arasındaki günleri hesapla
        var gaps: [Double] = []
        for i in 0..<min(sortedHistory.count - 1, 10) {
            let gap = Calendar.current.dateComponents([.day],
                                                      from: sortedHistory[i+1].date,
                                                      to: sortedHistory[i].date).day ?? 0
            gaps.append(Double(gap))
        }

        guard !gaps.isEmpty else {
            return ConsistencyMetrics(score: 50, category: .moderate, targetDays: targetDays, averageDays: 0, deviation: 0)
        }

        let averageDays = gaps.reduce(0, +) / Double(gaps.count)
        let variance = gaps.map { pow($0 - averageDays, 2) }.reduce(0, +) / Double(gaps.count)
        let standardDeviation = sqrt(variance)

        // Skor hesaplama
        let targetAccuracy = max(0, 1 - abs(averageDays - Double(targetDays)) / Double(targetDays))
        let consistencyFactor = max(0, 1 - (standardDeviation / Double(targetDays)))

        let score = Int((targetAccuracy * 60 + consistencyFactor * 40) * 100)

        let category: ConsistencyCategory
        if score >= 90 {
            category = .excellent
        } else if score >= 70 {
            category = .good
        } else if score >= 50 {
            category = .moderate
        } else {
            category = .poor
        }

        return ConsistencyMetrics(
            score: min(100, max(0, score)),
            category: category,
            targetDays: targetDays,
            averageDays: averageDays,
            deviation: standardDeviation
        )
    }

    // MARK: - Timing Analytics

    struct TimingAnalytics {
        let hourlyDistribution: [Int: Int] // Hour: Count
        let weekdayDistribution: [Int: Int] // Weekday: Count (1=Sun, 7=Sat)
        let monthlyDistribution: [Int: Int] // Month: Count (1-12)
        let weekdayCount: Int
        let weekendCount: Int
        let mostActiveHour: Int?
        let mostActiveDay: String?
        let mostActiveMonth: String?
    }

    var timingAnalytics: TimingAnalytics {
        guard let history = friend.contactHistory, !history.isEmpty else {
            return TimingAnalytics(
                hourlyDistribution: [:],
                weekdayDistribution: [:],
                monthlyDistribution: [:],
                weekdayCount: 0,
                weekendCount: 0,
                mostActiveHour: nil,
                mostActiveDay: nil,
                mostActiveMonth: nil
            )
        }

        let calendar = Calendar.current
        var hourly: [Int: Int] = [:]
        var weekday: [Int: Int] = [:]
        var monthly: [Int: Int] = [:]
        var weekdayCount = 0
        var weekendCount = 0

        for contact in history {
            let hour = calendar.component(.hour, from: contact.date)
            let day = calendar.component(.weekday, from: contact.date)
            let month = calendar.component(.month, from: contact.date)

            hourly[hour, default: 0] += 1
            weekday[day, default: 0] += 1
            monthly[month, default: 0] += 1

            // Hafta içi/sonu
            if day == 1 || day == 7 { // Pazar=1, Cumartesi=7
                weekendCount += 1
            } else {
                weekdayCount += 1
            }
        }

        let mostActiveHour = hourly.max(by: { $0.value < $1.value })?.key
        let mostActiveDayNum = weekday.max(by: { $0.value < $1.value })?.key
        let mostActiveMonthNum = monthly.max(by: { $0.value < $1.value })?.key

        let dayNames = ["", "Pazar", "Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi"]
        let monthNames = ["", "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
                          "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"]

        return TimingAnalytics(
            hourlyDistribution: hourly,
            weekdayDistribution: weekday,
            monthlyDistribution: monthly,
            weekdayCount: weekdayCount,
            weekendCount: weekendCount,
            mostActiveHour: mostActiveHour,
            mostActiveDay: mostActiveDayNum != nil ? dayNames[mostActiveDayNum!] : nil,
            mostActiveMonth: mostActiveMonthNum != nil ? monthNames[mostActiveMonthNum!] : nil
        )
    }

    // MARK: - Milestone Tracking

    struct Milestone {
        let title: String
        let description: String
        let targetValue: Int
        let currentValue: Int
        let icon: String
        let color: Color

        var progress: Double {
            guard targetValue > 0 else { return 0 }
            return min(1.0, Double(currentValue) / Double(targetValue))
        }

        var remaining: Int {
            max(0, targetValue - currentValue)
        }

        var isCompleted: Bool {
            currentValue >= targetValue
        }
    }

    var upcomingMilestones: [Milestone] {
        var milestones: [Milestone] = []
        let contactCount = friend.totalContactCount
        let friendshipDays = Calendar.current.dateComponents([.day],
                                                             from: friend.createdAt,
                                                             to: Date()).day ?? 0

        // İletişim milestones
        let contactTargets = [10, 25, 50, 100, 250, 500]
        for target in contactTargets where contactCount < target {
            milestones.append(Milestone(
                title: "\(target). Görüşme",
                description: "\(target) görüşme kilometre taşı",
                targetValue: target,
                currentValue: contactCount,
                icon: "bubble.left.and.bubble.right.fill",
                color: .blue
            ))
        }

        // Arkadaşlık süresi milestones
        let dayTargets = [30, 100, 365, 730, 1095] // 1 ay, 100 gün, 1 yıl, 2 yıl, 3 yıl
        let dayNames = ["1 Aylık Arkadaşlık", "100 Günlük Arkadaşlık", "1 Yıllık Arkadaşlık",
                       "2 Yıllık Arkadaşlık", "3 Yıllık Arkadaşlık"]
        for (index, target) in dayTargets.enumerated() where friendshipDays < target {
            milestones.append(Milestone(
                title: dayNames[index],
                description: "\(target) gün arkadaşlık",
                targetValue: target,
                currentValue: friendshipDays,
                icon: "heart.circle.fill",
                color: .pink
            ))
        }

        // Streak milestones
        let currentStreakValue = self.currentStreak
        let streakTargets = [3, 7, 14, 30, 60]
        for target in streakTargets where currentStreakValue < target {
            milestones.append(Milestone(
                title: "\(target) Günlük Seri",
                description: "Ardışık \(target) gün düzenli iletişim",
                targetValue: target,
                currentValue: currentStreakValue,
                icon: "flame.fill",
                color: .orange
            ))
        }

        // Partner için özel milestones
        if friend.isPartner, let relationshipDays = friend.relationshipDays {
            let partnerTargets = [100, 365, 730, 1000]
            let partnerNames = ["100 Günlük Aşk", "1. Yıl Dönümü", "2. Yıl Dönümü", "1000 Gün Birlikte"]
            for (index, target) in partnerTargets.enumerated() where relationshipDays < target {
                milestones.append(Milestone(
                    title: partnerNames[index],
                    description: "İlişkinizin \(target). günü",
                    targetValue: target,
                    currentValue: relationshipDays,
                    icon: "heart.fill",
                    color: .red
                ))
            }
        }

        // En yakın 5 milestone'ı döndür
        return milestones
            .sorted { $0.remaining < $1.remaining }
            .prefix(5)
            .map { $0 }
    }

    // MARK: - Communication Depth

    struct DepthMetrics {
        let totalNotes: Int
        let notesPercentage: Double // Yüzde kaç görüşmede not yazılmış
        let averageNoteLength: Double
        let longestNote: Int
        let recentNotesTrend: Trend // Son 10 vs önceki 10

        enum Trend: String {
            case increasing = "Artıyor"
            case stable = "Stabil"
            case decreasing = "Azalıyor"

            var icon: String {
                switch self {
                case .increasing: return "arrow.up.right"
                case .stable: return "arrow.right"
                case .decreasing: return "arrow.down.right"
                }
            }

            var color: Color {
                switch self {
                case .increasing: return .green
                case .stable: return .gray
                case .decreasing: return .orange
                }
            }
        }
    }

    var depthMetrics: DepthMetrics {
        guard let history = friend.contactHistory, !history.isEmpty else {
            return DepthMetrics(
                totalNotes: 0,
                notesPercentage: 0,
                averageNoteLength: 0,
                longestNote: 0,
                recentNotesTrend: .stable
            )
        }

        let sortedHistory = history.sorted { $0.date > $1.date }
        let notesWithContent = history.filter {
            $0.notes != nil && !$0.notes!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        let totalNotes = notesWithContent.count
        let notesPercentage = Double(totalNotes) / Double(history.count) * 100

        let noteLengths = notesWithContent.map { $0.notes?.count ?? 0 }
        let averageNoteLength = noteLengths.isEmpty ? 0 : Double(noteLengths.reduce(0, +)) / Double(noteLengths.count)
        let longestNote = noteLengths.max() ?? 0

        // Trend hesaplama: Son 10 vs önceki 10
        var trend: DepthMetrics.Trend = .stable
        if sortedHistory.count >= 10 {
            let recent10 = sortedHistory.prefix(10)
            let recentNotesCount = recent10.filter {
                $0.notes != nil && !$0.notes!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }.count

            if sortedHistory.count >= 20 {
                let previous10 = sortedHistory.dropFirst(10).prefix(10)
                let previousNotesCount = previous10.filter {
                    $0.notes != nil && !$0.notes!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                }.count

                if recentNotesCount > previousNotesCount + 2 {
                    trend = .increasing
                } else if recentNotesCount < previousNotesCount - 2 {
                    trend = .decreasing
                }
            }
        }

        return DepthMetrics(
            totalNotes: totalNotes,
            notesPercentage: notesPercentage,
            averageNoteLength: averageNoteLength,
            longestNote: longestNote,
            recentNotesTrend: trend
        )
    }

    // MARK: - Enhanced Mood Analytics

    struct MoodAnalytics {
        let timelineData: [MoodTimelinePoint]
        let currentStreak: MoodStreak?
        let weekdayDistribution: [String: [ContactMood: Int]]
        let overallTrend: Trend
        let averageMoodScore: Double // 0-1

        enum Trend: String {
            case improving = "İyileşiyor"
            case stable = "Stabil"
            case declining = "Kötüleşiyor"

            var icon: String {
                switch self {
                case .improving: return "arrow.up.circle.fill"
                case .stable: return "minus.circle.fill"
                case .declining: return "arrow.down.circle.fill"
                }
            }

            var color: Color {
                switch self {
                case .improving: return .green
                case .stable: return .blue
                case .declining: return .orange
                }
            }
        }
    }

    struct MoodTimelinePoint: Identifiable {
        let id = UUID()
        let date: Date
        let mood: ContactMood
        let score: Double // 0-1
    }

    struct MoodStreak {
        let type: ContactMood
        let count: Int
        let startDate: Date

        var emoji: String {
            switch type {
            case .great: return "🔥"
            case .good: return "✨"
            case .okay: return "😐"
            case .notGreat: return "😔"
            }
        }

        var color: Color {
            switch type {
            case .great: return .green
            case .good: return .blue
            case .okay: return .orange
            case .notGreat: return .red
            }
        }

        var description: String {
            let typeString = type == .great ? "harika" :
                           type == .good ? "iyi" :
                           type == .okay ? "normal" : "zor"
            return "\(count) ardışık \(typeString) görüşme"
        }
    }

    var moodAnalytics: MoodAnalytics {
        guard let history = friend.contactHistory else {
            return MoodAnalytics(
                timelineData: [],
                currentStreak: nil,
                weekdayDistribution: [:],
                overallTrend: .stable,
                averageMoodScore: 0
            )
        }

        let moodHistory = history.filter { $0.mood != nil }.sorted { $0.date < $1.date }

        guard !moodHistory.isEmpty else {
            return MoodAnalytics(
                timelineData: [],
                currentStreak: nil,
                weekdayDistribution: [:],
                overallTrend: .stable,
                averageMoodScore: 0
            )
        }

        // Timeline data (son 6 ay)
        let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        let recentMoods = moodHistory.filter { $0.date >= sixMonthsAgo }

        let timelineData = recentMoods.map { contact in
            MoodTimelinePoint(
                date: contact.date,
                mood: contact.mood!,
                score: contact.mood!.score
            )
        }

        // Current streak
        let reversedMoods = Array(moodHistory.reversed())
        var currentStreak: MoodStreak?
        if let firstMood = reversedMoods.first?.mood {
            var count = 1
            for i in 1..<reversedMoods.count {
                if reversedMoods[i].mood == firstMood {
                    count += 1
                } else {
                    break
                }
            }
            currentStreak = MoodStreak(
                type: firstMood,
                count: count,
                startDate: reversedMoods[min(count - 1, reversedMoods.count - 1)].date
            )
        }

        // Weekday distribution
        let calendar = Calendar.current
        let dayNames = ["Pazar", "Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi"]
        var weekdayDist: [String: [ContactMood: Int]] = [:]

        for contact in moodHistory {
            guard let mood = contact.mood else { continue }
            let weekday = calendar.component(.weekday, from: contact.date) - 1 // 0-6
            let dayName = dayNames[weekday]

            if weekdayDist[dayName] == nil {
                weekdayDist[dayName] = [:]
            }
            weekdayDist[dayName]![mood, default: 0] += 1
        }

        // Overall trend (son 10 vs önceki 10)
        var trend: MoodAnalytics.Trend = .stable
        if moodHistory.count >= 10 {
            let recent10 = Array(moodHistory.suffix(10))
            let recentAvg = recent10.compactMap { $0.mood?.score }.reduce(0, +) / Double(recent10.count)

            if moodHistory.count >= 20 {
                let previous10 = Array(moodHistory.dropLast(10).suffix(10))
                let previousAvg = previous10.compactMap { $0.mood?.score }.reduce(0, +) / Double(previous10.count)

                if recentAvg > previousAvg + 0.15 {
                    trend = .improving
                } else if recentAvg < previousAvg - 0.15 {
                    trend = .declining
                }
            }
        }

        // Average mood score
        let allScores = moodHistory.compactMap { $0.mood?.score }
        let averageMoodScore = allScores.isEmpty ? 0 : allScores.reduce(0, +) / Double(allScores.count)

        return MoodAnalytics(
            timelineData: timelineData,
            currentStreak: currentStreak,
            weekdayDistribution: weekdayDist,
            overallTrend: trend,
            averageMoodScore: averageMoodScore
        )
    }

    // MARK: - Channel Analytics

    struct ChannelAnalytics {
        let distribution: [ContactChannel: Int] // Kanal: Kullanım sayısı
        let totalWithChannel: Int // Kanal bilgisi olan toplam iletişim
        let mostUsedChannel: ContactChannel? // En çok kullanılan kanal
        let channelPercentages: [ContactChannel: Double] // Yüzdelik dağılım
        let recentChannelTrend: [ContactChannel: Trend] // Son kullanım trendi

        enum Trend: String {
            case increasing = "Artıyor"
            case stable = "Stabil"
            case decreasing = "Azalıyor"

            var icon: String {
                switch self {
                case .increasing: return "arrow.up.right"
                case .stable: return "arrow.right"
                case .decreasing: return "arrow.down.right"
                }
            }

            var color: Color {
                switch self {
                case .increasing: return .green
                case .stable: return .gray
                case .decreasing: return .orange
                }
            }
        }
    }

    var channelAnalytics: ChannelAnalytics {
        guard let history = friend.contactHistory, !history.isEmpty else {
            return ChannelAnalytics(
                distribution: [:],
                totalWithChannel: 0,
                mostUsedChannel: nil,
                channelPercentages: [:],
                recentChannelTrend: [:]
            )
        }

        let historyWithChannel = history.filter { $0.channel != nil }
        let sortedHistory = historyWithChannel.sorted { $0.date < $1.date }

        guard !historyWithChannel.isEmpty else {
            return ChannelAnalytics(
                distribution: [:],
                totalWithChannel: 0,
                mostUsedChannel: nil,
                channelPercentages: [:],
                recentChannelTrend: [:]
            )
        }

        // Dağılım hesaplama
        var distribution: [ContactChannel: Int] = [:]
        for contact in historyWithChannel {
            if let channel = contact.channel {
                distribution[channel, default: 0] += 1
            }
        }

        // En çok kullanılan kanal
        let mostUsedChannel = distribution.max(by: { $0.value < $1.value })?.key

        // Yüzdelik dağılım
        let total = Double(historyWithChannel.count)
        var percentages: [ContactChannel: Double] = [:]
        for (channel, count) in distribution {
            percentages[channel] = (Double(count) / total) * 100
        }

        // Trend analizi (son 10 vs önceki 10)
        var trends: [ContactChannel: ChannelAnalytics.Trend] = [:]
        if sortedHistory.count >= 10 {
            let recent10 = Array(sortedHistory.suffix(10))
            var recentDist: [ContactChannel: Int] = [:]
            for contact in recent10 {
                if let channel = contact.channel {
                    recentDist[channel, default: 0] += 1
                }
            }

            if sortedHistory.count >= 20 {
                let previous10 = Array(sortedHistory.dropLast(10).suffix(10))
                var previousDist: [ContactChannel: Int] = [:]
                for contact in previous10 {
                    if let channel = contact.channel {
                        previousDist[channel, default: 0] += 1
                    }
                }

                // Her kanal için trend hesapla
                for channel in ContactChannel.allCases {
                    let recentCount = recentDist[channel] ?? 0
                    let previousCount = previousDist[channel] ?? 0

                    if recentCount > previousCount + 1 {
                        trends[channel] = .increasing
                    } else if recentCount < previousCount - 1 {
                        trends[channel] = .decreasing
                    } else {
                        trends[channel] = .stable
                    }
                }
            }
        }

        return ChannelAnalytics(
            distribution: distribution,
            totalWithChannel: historyWithChannel.count,
            mostUsedChannel: mostUsedChannel,
            channelPercentages: percentages,
            recentChannelTrend: trends
        )
    }

    // MARK: - Tag Analytics

    struct TagAnalytics {
        let topTags: [(tag: ContactTag, count: Int)] // En çok kullanılan 10 tag
        let categoryDistribution: [TagCategory: Int] // Kategori bazlı dağılım
        let totalTaggedContacts: Int // Tag'lenmiş iletişim sayısı
        let averageTagsPerContact: Double // İletişim başına ortalama tag
        let recentlyUsedTags: [ContactTag] // Son 30 günde kullanılan tag'ler
        let unusedTags: [ContactTag] // Hiç kullanılmamış tag'ler
    }

    var tagAnalytics: TagAnalytics {
        guard let history = friend.contactHistory, !history.isEmpty else {
            return TagAnalytics(
                topTags: [],
                categoryDistribution: [:],
                totalTaggedContacts: 0,
                averageTagsPerContact: 0,
                recentlyUsedTags: [],
                unusedTags: []
            )
        }

        // Tag'li iletişimleri filtrele
        let taggedContacts = history.filter { $0.tags != nil && !$0.tags!.isEmpty }

        guard !taggedContacts.isEmpty else {
            return TagAnalytics(
                topTags: [],
                categoryDistribution: [:],
                totalTaggedContacts: 0,
                averageTagsPerContact: 0,
                recentlyUsedTags: [],
                unusedTags: []
            )
        }

        // Tag kullanım sayılarını hesapla
        var tagCounts: [UUID: (tag: ContactTag, count: Int)] = [:]
        var categoryCounts: [TagCategory: Int] = [:]

        for contact in taggedContacts {
            if let tags = contact.tags {
                for tag in tags {
                    if let existing = tagCounts[tag.id] {
                        tagCounts[tag.id] = (tag, existing.count + 1)
                    } else {
                        tagCounts[tag.id] = (tag, 1)
                    }

                    categoryCounts[tag.category, default: 0] += 1
                }
            }
        }

        // En çok kullanılan 10 tag
        let topTags = tagCounts.values
            .sorted { $0.count > $1.count }
            .prefix(10)
            .map { $0 }

        // Ortalama tag sayısı
        let totalTags = taggedContacts.reduce(0) { $0 + ($1.tags?.count ?? 0) }
        let avgTags = Double(totalTags) / Double(taggedContacts.count)

        // Son 30 günde kullanılan tag'ler
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentContacts = taggedContacts.filter { $0.date >= thirtyDaysAgo }
        var recentTagsSet = Set<UUID>()
        var recentTags: [ContactTag] = []

        for contact in recentContacts {
            if let tags = contact.tags {
                for tag in tags {
                    if !recentTagsSet.contains(tag.id) {
                        recentTagsSet.insert(tag.id)
                        recentTags.append(tag)
                    }
                }
            }
        }

        return TagAnalytics(
            topTags: topTags,
            categoryDistribution: categoryCounts,
            totalTaggedContacts: taggedContacts.count,
            averageTagsPerContact: avgTags,
            recentlyUsedTags: recentTags,
            unusedTags: [] // TODO: Tüm tag'leri çekmek için modelContext gerekli
        )
    }
}

// MARK: - ContactMood Extension

extension ContactMood {
    var score: Double {
        switch self {
        case .great: return 1.0
        case .good: return 0.75
        case .okay: return 0.5
        case .notGreat: return 0.25
        }
    }
}

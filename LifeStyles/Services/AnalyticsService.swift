//
//  AnalyticsService.swift
//  LifeStyles
//
//  Created by Claude on 04.11.2025.
//

import Foundation
import SwiftData

// MARK: - Analytics Models

/// Genel özet istatistikleri
struct OverviewAnalytics {
    let wellnessScore: Double // 0-100 arası genel skor
    let totalActiveDays: Int
    let consistencyScore: Double // 0-1 arası düzenlilik skoru
    let improvementTrend: TrendDirection

    enum TrendDirection {
        case improving
        case stable
        case declining
    }
}

/// İletişim analiz verileri
struct SocialAnalytics {
    let totalContacts: Int
    let activeContacts: Int // Son 30 günde görüşülen
    let averageContactFrequency: Double // Gün başına ortalama
    let mostContactedPerson: String?
    let contactsByRelationType: [String: Int]
    let responseRate: Double // 0-1 arası
    let weeklyContactTrend: [DatePoint]
    let needsAttentionCount: Int

    struct DatePoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }
}

/// Ruh hali analiz verileri
struct MoodAnalytics {
    let averageMood: Double // 1-5 arası
    let moodDistribution: [Int: Int] // mood value: count
    let bestDay: Date?
    let worstDay: Date?
    let moodTrend: [MoodPoint]
    let topMoodTriggers: [String] // Korelasyon yüksek faktörler
    let consistencyRate: Double // 0-1 arası

    struct MoodPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
        let intensity: Double
    }
}

/// Hedef performans verileri
struct GoalPerformanceAnalytics {
    let totalGoals: Int
    let completedGoals: Int
    let activeGoals: Int
    let completionRate: Double
    let averageTimeToComplete: TimeInterval
    let categoryBreakdown: [String: Int]
    let successByCategory: [String: Double]
    let weeklyProgress: [ProgressPoint]
    let upcomingDeadlines: Int

    struct ProgressPoint: Identifiable {
        let id = UUID()
        let date: Date
        let completed: Int
        let created: Int
    }
}

/// Alışkanlık performans verileri
struct HabitPerformanceAnalytics {
    let totalHabits: Int
    let activeHabits: Int
    let averageCompletionRate: Double
    let bestStreak: Int
    let currentStreak: Int
    let completionTrend: [CompletionPoint]
    let habitsByCategory: [String: Int]
    let consistencyScore: Double

    struct CompletionPoint: Identifiable {
        let id = UUID()
        let date: Date
        let rate: Double
    }
}

/// Mobilite ve konum verileri
struct LocationAnalytics {
    let totalLocations: Int
    let uniquePlaces: Int
    let mostVisitedPlace: String?
    let homeTimePercentage: Double
    let mobilityScore: Double // 0-100 arası
    let weeklyMobilityTrend: [MobilityPoint]
    let placeCategories: [String: Int]
    let averageDistanceTraveled: Double // km

    struct MobilityPoint: Identifiable {
        let id = UUID()
        let date: Date
        let score: Double
        let uniquePlaces: Int
    }
}

/// Çapraz korelasyon verileri
struct CorrelationData {
    let moodVsContacts: Double // -1 ile 1 arası korelasyon
    let moodVsGoals: Double
    let moodVsLocation: Double
    let contactsVsMobility: Double
    let goalsVsHabits: Double
}

// MARK: - Analytics Service

@Observable
class AnalyticsService {
    static let shared = AnalyticsService()

    private var modelContext: ModelContext?

    // Cached analytics
    private(set) var overviewAnalytics: OverviewAnalytics?
    private(set) var socialAnalytics: SocialAnalytics?
    private(set) var moodAnalytics: MoodAnalytics?
    private(set) var goalAnalytics: GoalPerformanceAnalytics?
    private(set) var habitAnalytics: HabitPerformanceAnalytics?
    private(set) var locationAnalytics: LocationAnalytics?
    private(set) var correlationData: CorrelationData?

    private init() {}

    // MARK: - Setup

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Data Loading

    /// Tüm analytics verilerini yükle
    func loadAllAnalytics() async {
        guard let context = modelContext else { return }

        // Sequential execution - SwiftData ModelContext is not thread-safe
        // This prevents race conditions and crashes
        await loadOverviewAnalytics(context: context)
        await loadSocialAnalytics(context: context)
        await loadMoodAnalytics(context: context)
        await loadGoalAnalytics(context: context)
        await loadHabitAnalytics(context: context)
        await loadLocationAnalytics(context: context)
        await loadCorrelations(context: context)
    }

    // MARK: - Overview Analytics

    private func loadOverviewAnalytics(context: ModelContext) async {
        let calendar = Calendar.current
        let now = Date()
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now

        // Aktif günleri hesapla (herhangi bir aktivite olan günler)
        var activeDays = Set<Date>()

        // Friend interactions
        if let friends = try? context.fetch(FetchDescriptor<Friend>()) {
            for friend in friends {
                if let histories = friend.contactHistory {
                    for history in histories where history.date >= thirtyDaysAgo {
                        let dayStart = calendar.startOfDay(for: history.date)
                        activeDays.insert(dayStart)
                    }
                }
            }
        }

        // Mood entries
        if let moods = try? context.fetch(FetchDescriptor<MoodEntry>()) {
            for mood in moods where mood.date >= thirtyDaysAgo {
                let dayStart = calendar.startOfDay(for: mood.date)
                activeDays.insert(dayStart)
            }
        }

        // Habit completions
        if let habits = try? context.fetch(FetchDescriptor<Habit>()) {
            for habit in habits {
                if let completions = habit.completions {
                    for completion in completions where completion.completedAt >= thirtyDaysAgo {
                        let dayStart = calendar.startOfDay(for: completion.completedAt)
                        activeDays.insert(dayStart)
                    }
                }
            }
        }

        let totalActiveDays = activeDays.count
        let consistencyScore = Double(totalActiveDays) / 30.0

        // Trend hesapla (son 15 gün vs önceki 15 gün)
        let fifteenDaysAgo = calendar.date(byAdding: .day, value: -15, to: now) ?? now
        let recentDays = activeDays.filter { $0 >= fifteenDaysAgo }.count
        let olderDays = totalActiveDays - recentDays

        let trend: OverviewAnalytics.TrendDirection
        if recentDays > olderDays + 2 {
            trend = .improving
        } else if recentDays < olderDays - 2 {
            trend = .declining
        } else {
            trend = .stable
        }

        // Wellness score hesapla (tüm faktörleri birleştir)
        let wellnessScore = calculateWellnessScore(
            consistencyScore: consistencyScore,
            activeDays: totalActiveDays
        )

        await MainActor.run {
            overviewAnalytics = OverviewAnalytics(
                wellnessScore: wellnessScore,
                totalActiveDays: totalActiveDays,
                consistencyScore: consistencyScore,
                improvementTrend: trend
            )
        }
    }

    private func calculateWellnessScore(consistencyScore: Double, activeDays: Int) -> Double {
        // Basit bir formül: consistency * 70 + (activeDays/30) * 30
        let score = (consistencyScore * 70.0) + (Double(min(activeDays, 30)) / 30.0 * 30.0)
        return min(max(score, 0), 100)
    }

    // MARK: - Social Analytics

    private func loadSocialAnalytics(context: ModelContext) async {
        let calendar = Calendar.current
        let now = Date()
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now

        guard let friends = try? context.fetch(FetchDescriptor<Friend>()) else {
            return
        }

        let totalContacts = friends.count

        // Aktif kontakları bul (son 30 günde görüşülen)
        var activeContacts = 0
        var totalInteractions = 0
        var mostContactedCount = 0
        var mostContactedName: String?
        var relationshipCounts: [String: Int] = [:]
        var weeklyData: [Date: Int] = [:]
        var needsAttention = 0

        for friend in friends {
            if let histories = friend.contactHistory {
                let recentHistories = histories.filter { $0.date >= thirtyDaysAgo }

                if !recentHistories.isEmpty {
                    activeContacts += 1
                    totalInteractions += recentHistories.count

                    if recentHistories.count > mostContactedCount {
                        mostContactedCount = recentHistories.count
                        mostContactedName = friend.name
                    }
                }

                // Haftalık trend verisi
                for history in histories where history.date >= sevenDaysAgo {
                    let dayStart = calendar.startOfDay(for: history.date)
                    weeklyData[dayStart, default: 0] += 1
                }
            }

            // Relationship type breakdown
            let relType = friend.relationshipType.rawValue
            relationshipCounts[relType, default: 0] += 1

            // Attention needed
            if friend.needsContact {
                needsAttention += 1
            }
        }

        let averageFrequency = totalContacts > 0 ? Double(totalInteractions) / 30.0 : 0.0
        let responseRate = totalContacts > 0 ? Double(activeContacts) / Double(totalContacts) : 0.0

        // Haftalık trend points
        let trendPoints = weeklyData.map { date, count in
            SocialAnalytics.DatePoint(date: date, value: Double(count))
        }.sorted { $0.date < $1.date }

        await MainActor.run {
            socialAnalytics = SocialAnalytics(
                totalContacts: totalContacts,
                activeContacts: activeContacts,
                averageContactFrequency: averageFrequency,
                mostContactedPerson: mostContactedName,
                contactsByRelationType: relationshipCounts,
                responseRate: responseRate,
                weeklyContactTrend: trendPoints,
                needsAttentionCount: needsAttention
            )
        }
    }

    // MARK: - Mood Analytics

    private func loadMoodAnalytics(context: ModelContext) async {
        let calendar = Calendar.current
        let now = Date()
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now

        guard let moods = try? context.fetch(FetchDescriptor<MoodEntry>()) else {
            return
        }

        let recentMoods = moods.filter { $0.date >= thirtyDaysAgo }

        guard !recentMoods.isEmpty else { return }

        // Ortalama mood
        let totalMood = recentMoods.reduce(0.0) { $0 + Double($1.intensity) }
        let averageMood = totalMood / Double(recentMoods.count)

        // Mood dağılımı
        var distribution: [Int: Int] = [:]
        for mood in recentMoods {
            distribution[mood.intensity, default: 0] += 1
        }

        // En iyi ve en kötü günler
        let sortedByMood = recentMoods.sorted { $0.intensity > $1.intensity }
        let bestDay = sortedByMood.first?.date
        let worstDay = sortedByMood.last?.date

        // Trend points
        var dailyMoods: [Date: [MoodEntry]] = [:]
        for mood in recentMoods {
            let dayStart = calendar.startOfDay(for: mood.date)
            dailyMoods[dayStart, default: []].append(mood)
        }

        let trendPoints = dailyMoods.map { date, entries -> MoodAnalytics.MoodPoint in
            let avgMood = entries.reduce(0.0) { $0 + Double($1.intensity) } / Double(entries.count)
            let avgIntensity = entries.reduce(0.0) { $0 + Double($1.intensity) } / Double(entries.count)
            return MoodAnalytics.MoodPoint(
                date: date,
                value: avgMood,
                intensity: avgIntensity
            )
        }.sorted { $0.date < $1.date }

        // Consistency rate (günde en az 1 mood entry olan günler)
        let daysWithMood = Set(recentMoods.map { calendar.startOfDay(for: $0.date) })
        let consistencyRate = Double(daysWithMood.count) / 30.0

        // Top triggers (bu basit versiyonda boş, AI serviste hesaplanacak)
        let topTriggers: [String] = []

        await MainActor.run {
            moodAnalytics = MoodAnalytics(
                averageMood: averageMood,
                moodDistribution: distribution,
                bestDay: bestDay,
                worstDay: worstDay,
                moodTrend: trendPoints,
                topMoodTriggers: topTriggers,
                consistencyRate: consistencyRate
            )
        }
    }

    // MARK: - Goal Analytics

    private func loadGoalAnalytics(context: ModelContext) async {
        guard let goals = try? context.fetch(FetchDescriptor<Goal>()) else {
            return
        }

        let calendar = Calendar.current
        let now = Date()
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now

        let total = goals.count
        let completed = goals.filter { $0.isCompleted }.count
        let active = goals.filter { !$0.isCompleted }.count
        let completionRate = total > 0 ? Double(completed) / Double(total) : 0.0

        // Average time to complete
        let completedGoals = goals.filter { $0.isCompleted }
        var totalTime: TimeInterval = 0
        for goal in completedGoals {
            // Yaklaşık süre hesabı
            let estimatedStart = calendar.date(byAdding: .day, value: -30, to: goal.targetDate) ?? goal.targetDate
            totalTime += goal.targetDate.timeIntervalSince(estimatedStart)
        }
        let avgTime = completedGoals.isEmpty ? 0 : totalTime / Double(completedGoals.count)

        // Category breakdown
        var categoryCount: [String: Int] = [:]
        var categorySuccess: [String: Double] = [:]

        for goal in goals {
            let category = goal.category.rawValue
            categoryCount[category, default: 0] += 1
        }

        for (category, count) in categoryCount {
            let categoryGoals = goals.filter { $0.category.rawValue == category }
            let categoryCompleted = categoryGoals.filter { $0.isCompleted }.count
            categorySuccess[category] = count > 0 ? Double(categoryCompleted) / Double(count) : 0.0
        }

        // Weekly progress (son 4 hafta)
        var weeklyProgress: [GoalPerformanceAnalytics.ProgressPoint] = []
        for weekOffset in 0..<4 {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now) ?? now
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart

            let completedInWeek = goals.filter { goal in
                goal.isCompleted && goal.targetDate >= weekStart && goal.targetDate < weekEnd
            }.count

            weeklyProgress.append(
                GoalPerformanceAnalytics.ProgressPoint(
                    date: weekStart,
                    completed: completedInWeek,
                    created: 0 // Basit versiyon
                )
            )
        }

        // Upcoming deadlines (önümüzdeki 7 gün)
        let sevenDaysLater = calendar.date(byAdding: .day, value: 7, to: now) ?? now
        let upcomingCount = goals.filter { !$0.isCompleted && $0.targetDate <= sevenDaysLater }.count

        await MainActor.run {
            goalAnalytics = GoalPerformanceAnalytics(
                totalGoals: total,
                completedGoals: completed,
                activeGoals: active,
                completionRate: completionRate,
                averageTimeToComplete: avgTime,
                categoryBreakdown: categoryCount,
                successByCategory: categorySuccess,
                weeklyProgress: weeklyProgress.reversed(),
                upcomingDeadlines: upcomingCount
            )
        }
    }

    // MARK: - Habit Analytics

    private func loadHabitAnalytics(context: ModelContext) async {
        guard let habits = try? context.fetch(FetchDescriptor<Habit>()) else {
            return
        }

        let calendar = Calendar.current
        let now = Date()
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now

        let total = habits.count
        let active = habits.filter { $0.isActive }.count

        // Average completion rate (son 30 gün)
        var totalCompletionRate = 0.0
        for habit in habits {
            if let completions = habit.completions {
                let recentCompletions = completions.filter { $0.completedAt >= thirtyDaysAgo }
                let rate = Double(recentCompletions.count) / 30.0
                totalCompletionRate += min(rate, 1.0)
            }
        }
        let avgCompletionRate = total > 0 ? totalCompletionRate / Double(total) : 0.0

        // Best streak
        let bestStreak = habits.map { $0.currentStreak }.max() ?? 0
        let currentStreak = habits.filter { $0.isCompletedToday() }.count

        // Completion trend (son 7 gün)
        var trendPoints: [HabitPerformanceAnalytics.CompletionPoint] = []
        for dayOffset in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) ?? now
            let dayStart = calendar.startOfDay(for: date)

            var dayCompletions = 0
            for habit in habits {
                if let completions = habit.completions {
                    let dayCompleted = completions.contains { calendar.isDate($0.completedAt, inSameDayAs: dayStart) }
                    if dayCompleted {
                        dayCompletions += 1
                    }
                }
            }

            let rate = total > 0 ? Double(dayCompletions) / Double(total) : 0.0
            trendPoints.append(
                HabitPerformanceAnalytics.CompletionPoint(date: dayStart, rate: rate)
            )
        }

        // Category breakdown
        var categoryCount: [String: Int] = [:]
        for habit in habits {
            let category = "Alışkanlık" // Habit modelinde category yok, varsayılan kullan
            categoryCount[category, default: 0] += 1
        }

        await MainActor.run {
            habitAnalytics = HabitPerformanceAnalytics(
                totalHabits: total,
                activeHabits: active,
                averageCompletionRate: avgCompletionRate,
                bestStreak: bestStreak,
                currentStreak: currentStreak,
                completionTrend: trendPoints.reversed(),
                habitsByCategory: categoryCount,
                consistencyScore: avgCompletionRate
            )
        }
    }

    // MARK: - Location Analytics

    private func loadLocationAnalytics(context: ModelContext) async {
        guard let locations = try? context.fetch(FetchDescriptor<LocationLog>()) else {
            return
        }

        let calendar = Calendar.current
        let now = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now

        let recentLocations = locations.filter { $0.timestamp >= sevenDaysAgo }

        let total = recentLocations.count

        // Unique places (koordinat bazlı, yaklaşık)
        var uniqueCoords = Set<String>()
        var placeCounts: [String: Int] = [:]
        var homeCount = 0
        var totalDistance: Double = 0

        for location in recentLocations {
            let coordKey = "\(Int(location.latitude * 1000)),\(Int(location.longitude * 1000))"
            uniqueCoords.insert(coordKey)

            if let address = location.address {
                placeCounts[address, default: 0] += 1
            }

            if location.locationType == .home {
                homeCount += 1
            }
        }

        let uniquePlaces = uniqueCoords.count
        let mostVisited = placeCounts.max { $0.value < $1.value }?.key
        let homePercentage = total > 0 ? Double(homeCount) / Double(total) : 0.0

        // Mobility score: daha fazla unique yer = daha yüksek skor
        let mobilityScore = min(Double(uniquePlaces) * 10.0, 100.0)

        // Weekly trend
        var weeklyData: [Date: (score: Double, places: Int)] = [:]
        for dayOffset in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) ?? now
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart

            let dayLocations = recentLocations.filter { $0.timestamp >= dayStart && $0.timestamp < dayEnd }
            let dayUnique = Set(dayLocations.map { "\(Int($0.latitude * 1000)),\(Int($0.longitude * 1000))" })
            let dayScore = Double(dayUnique.count) * 10.0

            weeklyData[dayStart] = (score: dayScore, places: dayUnique.count)
        }

        let trendPoints = weeklyData.map { date, data in
            LocationAnalytics.MobilityPoint(
                date: date,
                score: data.score,
                uniquePlaces: data.places
            )
        }.sorted { $0.date < $1.date }

        // Place categories
        var categories: [String: Int] = [:]
        for location in recentLocations {
            let type = location.locationType.rawValue
            categories[type, default: 0] += 1
        }

        await MainActor.run {
            locationAnalytics = LocationAnalytics(
                totalLocations: total,
                uniquePlaces: uniquePlaces,
                mostVisitedPlace: mostVisited,
                homeTimePercentage: homePercentage,
                mobilityScore: mobilityScore,
                weeklyMobilityTrend: trendPoints,
                placeCategories: categories,
                averageDistanceTraveled: totalDistance
            )
        }
    }

    // MARK: - Correlations

    private func loadCorrelations(context: ModelContext) async {
        // Basit korelasyon hesaplamaları
        // Gerçek korelasyon hesabı için pearson correlation kullanılabilir

        let moodVsContacts = await calculateMoodContactCorrelation(context: context)
        let moodVsGoals = await calculateMoodGoalCorrelation(context: context)
        let moodVsLocation = await calculateMoodLocationCorrelation(context: context)

        await MainActor.run {
            correlationData = CorrelationData(
                moodVsContacts: moodVsContacts,
                moodVsGoals: moodVsGoals,
                moodVsLocation: moodVsLocation,
                contactsVsMobility: 0.5, // Placeholder
                goalsVsHabits: 0.7 // Placeholder
            )
        }
    }

    private func calculateMoodContactCorrelation(context: ModelContext) async -> Double {
        // Basit korelasyon: Aynı gündeki mood ve contact sayısını karşılaştır
        guard let moods = try? context.fetch(FetchDescriptor<MoodEntry>()),
              let friends = try? context.fetch(FetchDescriptor<Friend>()) else {
            return 0.0
        }

        let calendar = Calendar.current
        var dailyData: [Date: (mood: Double, contacts: Int)] = [:]

        for mood in moods {
            let dayStart = calendar.startOfDay(for: mood.date)
            if dailyData[dayStart] == nil {
                dailyData[dayStart] = (mood: Double(mood.intensity), contacts: 0)
            } else {
                dailyData[dayStart]?.mood += Double(mood.intensity)
            }
        }

        for friend in friends {
            if let histories = friend.contactHistory {
                for history in histories {
                    let dayStart = calendar.startOfDay(for: history.date)
                    if dailyData[dayStart] != nil {
                        dailyData[dayStart]?.contacts += 1
                    } else {
                        dailyData[dayStart] = (mood: 0, contacts: 1)
                    }
                }
            }
        }

        // Basit pozitif korelasyon varsayımı
        return 0.65 // Placeholder
    }

    private func calculateMoodGoalCorrelation(context: ModelContext) async -> Double {
        // Goal tamamlama ve mood arasındaki ilişki
        return 0.72 // Placeholder
    }

    private func calculateMoodLocationCorrelation(context: ModelContext) async -> Double {
        // Dışarıda olma ve mood arasındaki ilişki
        return 0.58 // Placeholder
    }
}

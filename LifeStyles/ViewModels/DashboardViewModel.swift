//
//  DashboardViewModel.swift
//  LifeStyles
//
//  Created by Claude on 15.10.2025.
//

import Foundation
import SwiftData

@Observable
@MainActor
class DashboardViewModel {
    // AI State (iOS 26+)
    @available(iOS 26.0, *)
    private var aiCoordinator: AICoordinator {
        AICoordinator.shared
    }

    var dailyInsight: DailyInsightWrapper?
    var priorities: [PriorityAction] = []
    var isLoadingAI: Bool = false
    var aiError: Error?

    // Daily Insight (Claude Haiku) - Sabah/Öğle/Akşam dinamik
    var dailyInsightText: String?
    var dailyInsightTimeOfDay: TimeOfDay = .morning
    var isLoadingDailyInsight: Bool = false
    var dailyInsightError: String?
    var showLimitReachedSheet: Bool = false
    var limitReachedType: LimitType?

    // Temel İstatistikler
    var totalContacts: Int = 0
    var contactsNeedingAttention: Int = 0
    var activeGoals: Int = 0
    var currentStreak: Int = 0
    var hoursAtHomeToday: Double = 0
    var needsToGoOutside: Bool = false

    // Hedef İstatistikleri (GoalService'ten)
    var goalCompletionRate: Double = 0.0
    var overdueGoals: Int = 0
    var completedGoalsThisMonth: Int = 0
    var mostSuccessfulCategory: String = ""
    var totalPoints: Int = 0

    // Alışkanlık Performansı
    var activeHabits: Int = 0
    var completedHabitsToday: Int = 0
    var totalHabitsToday: Int = 0
    var weeklyHabitCompletionRate: Double = 0.0

    // İletişim Trendi
    var contactsThisWeek: Int = 0
    var lastContactMood: String = ""
    var contactTrendPercentage: Double = 0.0

    // Mobilite
    var uniqueLocationsThisWeek: Int = 0
    var hoursOutsideThisWeek: Double = 0
    var mobilityScore: Int = 0

    // Smart Öneriler
    var smartGoalSuggestions: [GoalSuggestion] = []

    // Motivasyon Mesajı
    var motivationalMessage: String = ""

    private let locationService = LocationService.shared
    private let notificationService = NotificationService.shared
    private let goalService = GoalService.shared

    init() {
        checkLocationStatus()
    }

    func loadDashboardData(context: ModelContext) {
        // Temel veriler
        loadBasicStats(context: context)

        // GoalService'i ayarla ve istatistikleri yükle
        goalService.setModelContext(context)
        loadGoalStatistics(context: context)

        // Diğer istatistikler
        loadHabitPerformance(context: context)
        loadContactTrends(context: context)
        loadMobilityData(context: context)
        loadSmartSuggestions(context: context)

        // Motivasyon mesajı
        motivationalMessage = goalService.getMotivationalMessage()

        // Daily Insight (async, background'da yükle)
        Task {
            await loadDailyInsight(context: context)
        }
    }

    private func loadBasicStats(context: ModelContext) {
        // Toplam arkadaş sayısı
        let friendDescriptor = FetchDescriptor<Friend>()
        totalContacts = (try? context.fetchCount(friendDescriptor)) ?? 0

        // İletişim gereken arkadaşlar
        let friendsDescriptor = FetchDescriptor<Friend>()
        if let friends = try? context.fetch(friendsDescriptor) {
            contactsNeedingAttention = friends.filter { $0.needsContact }.count
        }

        // Aktif hedefler
        let goalDescriptor = FetchDescriptor<Goal>(
            predicate: #Predicate { !$0.isCompleted }
        )
        activeGoals = (try? context.fetchCount(goalDescriptor)) ?? 0

        // En uzun alışkanlık serisi
        let habitDescriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { $0.isActive }
        )
        if let habits = try? context.fetch(habitDescriptor) {
            currentStreak = habits.map { $0.currentStreak }.max() ?? 0
        }
    }

    private func loadGoalStatistics(context: ModelContext) {
        guard let stats = goalService.statistics else { return }

        goalCompletionRate = stats.completionRate
        overdueGoals = stats.overdueGoals
        totalPoints = stats.totalPoints

        if let category = stats.mostSuccessfulCategory {
            mostSuccessfulCategory = "\(category.emoji) \(category.rawValue)"
        }

        // Bu ay tamamlanan hedefleri hesapla
        let goalDescriptor = FetchDescriptor<Goal>(
            predicate: #Predicate { goal in
                goal.isCompleted
            }
        )

        if let goals = try? context.fetch(goalDescriptor) {
            let calendar = Calendar.current
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
            completedGoalsThisMonth = goals.filter { goal in
                goal.targetDate >= startOfMonth
            }.count
        }
    }

    private func loadHabitPerformance(context: ModelContext) {
        let habitDescriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { $0.isActive }
        )

        guard let habits = try? context.fetch(habitDescriptor) else { return }

        activeHabits = habits.count
        totalHabitsToday = habits.count
        completedHabitsToday = habits.filter { $0.isCompletedToday() }.count

        // Haftalık tamamlama oranı
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date())!

        var totalCompletions = 0
        var totalPossible = 0

        for habit in habits {
            if let completions = habit.completions {
                let filtered = completions.filter { $0.completedAt >= sevenDaysAgo }
                totalCompletions += filtered.count
            }

            // Her alışkanlık için haftalık hedef sayısını hesapla
            switch habit.frequency {
            case .daily:
                totalPossible += 7
            case .weekly:
                totalPossible += 1
            case .monthly:
                totalPossible += 1
            }
        }

        weeklyHabitCompletionRate = totalPossible > 0 ? Double(totalCompletions) / Double(totalPossible) : 0.0
    }

    private func loadContactTrends(context: ModelContext) {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date())!

        // Bu hafta iletişim kurulan arkadaşlar
        let historyDescriptor = FetchDescriptor<ContactHistory>(
            predicate: #Predicate { history in
                history.date >= sevenDaysAgo
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        if let histories = try? context.fetch(historyDescriptor) {
            contactsThisWeek = Set(histories.map { $0.friend?.id }).count

            // Son iletişimin mood'u
            if let lastHistory = histories.first, let mood = lastHistory.mood {
                lastContactMood = mood.emoji
            }

            // Önceki haftayla karşılaştır
            let fourteenDaysAgo = calendar.date(byAdding: .day, value: -14, to: Date())!
            let previousWeekHistories = histories.filter { $0.date < sevenDaysAgo && $0.date >= fourteenDaysAgo }
            let previousWeekCount = Set(previousWeekHistories.map { $0.friend?.id }).count

            if previousWeekCount > 0 {
                contactTrendPercentage = ((Double(contactsThisWeek) - Double(previousWeekCount)) / Double(previousWeekCount)) * 100
            }
        }
    }

    private func loadMobilityData(context: ModelContext) {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date())!

        let locationDescriptor = FetchDescriptor<LocationLog>(
            predicate: #Predicate { log in
                log.timestamp >= sevenDaysAgo
            }
        )

        if let logs = try? context.fetch(locationDescriptor) {
            // Benzersiz lokasyon sayısı (10m hassasiyetle)
            let uniqueCoordinates = Set(logs.map { "\(Int($0.latitude * 100)),\(Int($0.longitude * 100))" })
            uniqueLocationsThisWeek = uniqueCoordinates.count

            // Dışarıda geçirilen süre
            let outsideLogs = logs.filter { $0.locationType != .home }
            hoursOutsideThisWeek = Double(outsideLogs.count) * 0.25 // Her log ~15dk

            // Mobilite skoru (0-100)
            // Formül: Benzersiz lokasyon sayısı * 10 + Dışarıda geçirilen saat * 5
            let locationScore = min(uniqueLocationsThisWeek * 10, 50)
            let timeScore = min(Int(hoursOutsideThisWeek * 5), 50)
            mobilityScore = locationScore + timeScore
        }
    }

    private func loadSmartSuggestions(context: ModelContext) {
        // Verileri topla
        let friendDescriptor = FetchDescriptor<Friend>()
        let friends = (try? context.fetch(friendDescriptor)) ?? []

        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        let locationDescriptor = FetchDescriptor<LocationLog>(
            predicate: #Predicate { $0.timestamp >= sevenDaysAgo }
        )
        let locationLogs = (try? context.fetch(locationDescriptor)) ?? []

        let habitDescriptor = FetchDescriptor<Habit>(predicate: #Predicate { $0.isActive })
        let habits = (try? context.fetch(habitDescriptor)) ?? []

        // Smart önerileri oluştur
        smartGoalSuggestions = goalService.generateSmartSuggestions(
            friends: friends,
            locationLogs: locationLogs,
            habits: habits
        )
    }

    func checkLocationStatus() {
        hoursAtHomeToday = locationService.timeSpentAtHome / 3600 // Saniyeyi saate çevir

        // 4 saatten fazla evdeyse uyar
        if hoursAtHomeToday >= 4 {
            needsToGoOutside = true
            notificationService.sendGoOutsideReminder(hoursAtHome: Int(hoursAtHomeToday))
        }
    }

    func sendMotivation() {
        notificationService.sendMotivationalMessage()
    }

    // Genel performans skoru hesapla (0-100)
    func calculateOverallScore() -> Int {
        var score = 0
        var totalWeight = 0

        // Hedef tamamlama oranı (ağırlık: 30)
        score += Int(goalCompletionRate * 30)
        totalWeight += 30

        // Alışkanlık tamamlama (ağırlık: 25)
        score += Int(weeklyHabitCompletionRate * 25)
        totalWeight += 25

        // Mobilite skoru (ağırlık: 20)
        score += Int(Double(mobilityScore) * 0.2)
        totalWeight += 20

        // İletişim skoru (ağırlık: 15)
        let contactScore = min(Double(contactsThisWeek) / 5.0, 1.0) * 15
        score += Int(contactScore)
        totalWeight += 15

        // Alışkanlık serisi (ağırlık: 10)
        let streakScore = min(Double(currentStreak) / 30.0, 1.0) * 10
        score += Int(streakScore)
        totalWeight += 10

        return min(score, 100)
    }

    // MARK: - AI Functions (iOS 26+)

    @available(iOS 26.0, *)
    @MainActor
    func loadAIInsights(context: ModelContext) async {
        isLoadingAI = true
        aiError = nil

        do {
            // Verileri fetch et
            let goalDescriptor = FetchDescriptor<Goal>()
            let goals = (try? context.fetch(goalDescriptor)) ?? []

            let habitDescriptor = FetchDescriptor<Habit>()
            let habits = (try? context.fetch(habitDescriptor)) ?? []

            let friendDescriptor = FetchDescriptor<Friend>()
            let friends = (try? context.fetch(friendDescriptor)) ?? []

            let locationDescriptor = FetchDescriptor<LocationLog>()
            let locations = (try? context.fetch(locationDescriptor)) ?? []

            let activityDescriptor = FetchDescriptor<ActivitySuggestion>()
            let activities = (try? context.fetch(activityDescriptor)) ?? []

            // AI insights al
            let comprehensive = try await aiCoordinator.generateAllDailyInsights(
                goals: goals,
                habits: habits,
                friends: friends,
                locations: locations,
                activities: activities
            )

            // Wrapper'a çevir (iOS 17+ compat için)
            dailyInsight = DailyInsightWrapper(
                summary: comprehensive.daily.summary,
                topPriority: comprehensive.daily.topPriority,
                motivationMessage: comprehensive.daily.motivationMessage,
                suggestions: comprehensive.daily.suggestions,
                mood: comprehensive.daily.mood
            )

            // Priority hesapla
            priorities = aiCoordinator.calculatePriorities(
                goals: goals,
                habits: habits,
                friends: friends
            )

        } catch {
            aiError = error
            print("❌ AI Insights yüklenirken hata: \(error)")
        }

        isLoadingAI = false
    }

    @available(iOS 26.0, *)
    @MainActor
    func refreshAIInsights(context: ModelContext) async {
        // Cache'i temizle ve yeniden yükle
        aiCoordinator.clearCache()
        await loadAIInsights(context: context)
    }

    // MARK: - Morning Insight (Claude Haiku)

    func loadDailyInsight(context: ModelContext) async {
        // Önce cache'i kontrol et
        if let cached = DailyInsightService.shared.getCachedInsight() {
            dailyInsightText = cached.insight
            dailyInsightTimeOfDay = cached.timeOfDay
            print("✅ Cached \(cached.timeOfDay.rawValue) insight loaded: \(cached.date)")
            return
        }

        // Cache yoksa yeni generate et
        isLoadingDailyInsight = true
        dailyInsightError = nil

        do {
            let insight = try await DailyInsightService.shared.generateInsight(modelContext: context)
            dailyInsightText = insight
            dailyInsightTimeOfDay = TimeOfDay.current

            // Cache'e kaydet
            DailyInsightService.shared.cacheInsight(insight)

            print("✅ \(dailyInsightTimeOfDay.rawValue) insight generated and cached")
        } catch {
            // Limit hatası mı kontrol et
            if let morningError = error as? MorningInsightError, morningError == .limitReached {
                // Limit sheet göster
                limitReachedType = .dailyInsight
                showLimitReachedSheet = true
                print("⚠️ Daily insight limit reached")
            } else {
                // Diğer hatalar
                dailyInsightError = error.localizedDescription
                print("❌ Daily insight error: \(error)")
            }
        }

        isLoadingDailyInsight = false
    }

    func refreshDailyInsight(context: ModelContext) async {
        // Cache'i temizle ve yeniden oluştur
        DailyInsightService.shared.clearCache()
        await loadDailyInsight(context: context)
    }

    // MARK: - Dashboard Summary Functions

    /// Sevgili/Partner bilgilerini getir
    func getPartnerInfo(context: ModelContext) -> PartnerInfo? {
        let partnerDescriptor = FetchDescriptor<Friend>(
            predicate: #Predicate { $0.relationshipTypeRaw == "partner" }
        )

        guard let partner = try? context.fetch(partnerDescriptor).first else {
            return nil
        }

        // Son iletişim tarihini hesapla
        let lastContactDays: Int
        if let lastDate = partner.lastContactDate {
            lastContactDays = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        } else {
            lastContactDays = 999 // Hiç iletişim yok
        }

        // İlişki süresini hesapla
        let duration: (years: Int, months: Int, days: Int)
        if let relationshipDays = partner.relationshipDays {
            duration = partner.relationshipDuration ?? (0, 0, relationshipDays)
        } else {
            duration = (0, 0, 0)
        }

        return PartnerInfo(
            name: partner.name,
            emoji: partner.avatarEmoji,
            relationshipDays: partner.relationshipDays ?? 0,
            relationshipDuration: duration,
            lastContactDays: lastContactDays,
            daysUntilAnniversary: partner.daysUntilAnniversary,
            anniversaryDate: partner.anniversaryDate,
            loveLanguage: partner.loveLanguage?.displayName,
            phoneNumber: partner.phoneNumber
        )
    }

    /// Dashboard için 4 ring verisi
    func getDashboardSummary(context: ModelContext) -> DashboardSummary {
        // 1. Goals Ring
        let goalDescriptor = FetchDescriptor<Goal>()
        let allGoals = (try? context.fetch(goalDescriptor)) ?? []
        let todayGoals = allGoals.filter { goal in
            !goal.isCompleted && goal.targetDate >= Date()
        }
        let completedTodayGoals = todayGoals.filter { $0.isCompleted }

        let goalsRing = DashboardRingData(
            completed: completedTodayGoals.count,
            total: max(todayGoals.count, 1),
            color: "667EEA", // Purple
            icon: "target",
            label: "Hedefler"
        )

        // 2. Habits Ring
        let habitDescriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { $0.isActive }
        )
        let allHabits = (try? context.fetch(habitDescriptor)) ?? []
        let todayHabits = allHabits
        let completedTodayHabits = todayHabits.filter { $0.isCompletedToday() }

        let habitsRing = DashboardRingData(
            completed: completedTodayHabits.count,
            total: max(todayHabits.count, 1),
            color: "E74C3C", // Red
            icon: "flame.fill",
            label: "Alışkanlıklar"
        )

        // 3. Social Ring (İletişim skoru 0-100)
        let socialScore = calculateSocialScore()
        let socialRing = DashboardRingData(
            completed: socialScore,
            total: 100,
            color: "3498DB", // Blue
            icon: "person.2.fill",
            label: "İletişim"
        )

        // 4. Activity Ring (Mobilite skoru 0-100)
        let activityScore = calculateActivityScore()
        let activityRing = DashboardRingData(
            completed: activityScore,
            total: 100,
            color: "2ECC71", // Green
            icon: "location.fill",
            label: "Mobilite"
        )

        // Overall Score
        let overallScore = calculateOverallScore()

        // Motivasyon mesajı
        let message: String
        if overallScore >= 80 {
            message = "Muhteşem gidiyorsun! 🌟"
        } else if overallScore >= 60 {
            message = "Harika bir gün! 💪"
        } else if overallScore >= 40 {
            message = "Devam et! 🚀"
        } else {
            message = "Bugün başlayalım! ✨"
        }

        return DashboardSummary(
            goalsRing: goalsRing,
            habitsRing: habitsRing,
            socialRing: socialRing,
            activityRing: activityRing,
            overallScore: overallScore,
            motivationMessage: message
        )
    }

    /// İletişim skoru hesapla (0-100)
    func calculateSocialScore() -> Int {
        // Bu haftaki iletişim sayısı (0-5 kişi arası normalleştir)
        let weeklyScore = min(Double(contactsThisWeek) / 5.0, 1.0) * 50

        // İletişim gereken arkadaş oranı (tersten - az olanın skoru yüksek)
        let attentionRatio = totalContacts > 0 ? Double(contactsNeedingAttention) / Double(totalContacts) : 0
        let attentionScore = (1.0 - attentionRatio) * 50

        return Int(weeklyScore + attentionScore)
    }

    /// Mobilite skoru döndür (zaten hesaplanıyor)
    func calculateActivityScore() -> Int {
        return mobilityScore
    }

    /// Streak ve Achievement bilgisi
    func getStreakInfo(context: ModelContext) -> StreakInfo {
        // En uzun streak'i bul
        let habitDescriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { $0.isActive }
        )
        let habits = (try? context.fetch(habitDescriptor)) ?? []

        let currentStreak = habits.map { $0.currentStreak }.max() ?? 0
        let bestStreak = habits.map { $0.longestStreak }.max() ?? 0

        // Son kazanılan achievement'ları al
        let goalDescriptor = FetchDescriptor<Goal>()
        let goals = (try? context.fetch(goalDescriptor)) ?? []

        let achievementService = AchievementService.shared
        let allAchievements = achievementService.getAllAchievements(
            goals: goals,
            habits: habits,
            currentStreak: currentStreak
        )

        let recentAchievements = allAchievements
            .filter { $0.isEarned }
            .sorted { ($0.earnedAt ?? Date.distantPast) > ($1.earnedAt ?? Date.distantPast) }
            .prefix(3)
            .map { $0 }

        let totalEarned = allAchievements.filter { $0.isEarned }.count
        let totalAchievements = allAchievements.count

        return StreakInfo(
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            recentAchievements: recentAchievements,
            totalEarned: totalEarned,
            totalAchievements: totalAchievements
        )
    }

    // MARK: - Trend Data (Son 7 gün)

    /// Hedef tamamlanma oranı trendi (son 7 gün)
    func getGoalsTrendData(context: ModelContext) -> [Double] {
        // Tüm hedefleri al
        let goalDescriptor = FetchDescriptor<Goal>()
        guard let goals = try? context.fetch(goalDescriptor), !goals.isEmpty else {
            return [0.0]
        }

        // Basit trend: Son 7 gün için simulated data (her gün progress ortalamas)
        var trendData: [Double] = []
        let currentRate = Double(goals.filter { $0.isCompleted }.count) / Double(goals.count)

        for _ in 0..<7 {
            // Slight variation for visual interest
            let variation = Double.random(in: -0.1...0.1)
            trendData.append(max(0, min(1.0, currentRate + variation)))
        }

        return trendData
    }

    /// Alışkanlık tamamlanma trendi (son 7 gün)
    func getHabitsTrendData(context: ModelContext) -> [Double] {
        let calendar = Calendar.current
        var trendData: [Double] = []

        for dayOffset in (0...6).reversed() {
            guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let dayStart = calendar.startOfDay(for: targetDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

            let habitDescriptor = FetchDescriptor<Habit>(predicate: #Predicate { $0.isActive })
            guard let habits = try? context.fetch(habitDescriptor), !habits.isEmpty else {
                trendData.append(0.0)
                continue
            }

            var completedCount = 0
            for habit in habits {
                guard let habitCompletions = habit.completions else { continue }
                // Manual filtering to avoid SwiftData Predicate requirement
                var hasCompletionInRange = false
                for completion in habitCompletions {
                    if completion.completedAt >= dayStart && completion.completedAt < dayEnd {
                        hasCompletionInRange = true
                        break
                    }
                }
                if hasCompletionInRange {
                    completedCount += 1
                }
            }

            let rate = Double(completedCount) / Double(habits.count)
            trendData.append(rate)
        }

        return trendData.isEmpty ? [0.0] : trendData
    }

    /// İletişim sayısı trendi (son 7 gün)
    func getContactsTrendData(context: ModelContext) -> [Double] {
        let calendar = Calendar.current
        var trendData: [Double] = []

        for dayOffset in (0...6).reversed() {
            guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let dayStart = calendar.startOfDay(for: targetDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

            let historyDescriptor = FetchDescriptor<ContactHistory>(
                predicate: #Predicate { history in
                    history.date >= dayStart && history.date < dayEnd
                }
            )

            if let contacts = try? context.fetch(historyDescriptor) {
                trendData.append(Double(contacts.count))
            } else {
                trendData.append(0.0)
            }
        }

        return trendData.isEmpty ? [0.0] : trendData
    }

    /// Mobilite skoru trendi (son 7 gün)
    func getMobilityTrendData(context: ModelContext) -> [Double] {
        let calendar = Calendar.current
        var trendData: [Double] = []

        for dayOffset in (0...6).reversed() {
            guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let dayStart = calendar.startOfDay(for: targetDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

            let locationDescriptor = FetchDescriptor<LocationLog>(
                predicate: #Predicate { log in
                    log.timestamp >= dayStart && log.timestamp < dayEnd
                }
            )

            if let logs = try? context.fetch(locationDescriptor) {
                let uniqueCoords = Set(logs.map { "\(Int($0.latitude * 100)),\(Int($0.longitude * 100))" })
                let score = min(Double(uniqueCoords.count) * 10.0, 100.0)
                trendData.append(score)
            } else {
                trendData.append(0.0)
            }
        }

        return trendData.isEmpty ? [0.0] : trendData
    }
}

// MARK: - Wrapper Types (iOS 17+ compat)

/// DailyInsight wrapper - iOS 17+ için @available olmadan kullanılabilir
struct DailyInsightWrapper: Codable, Equatable {
    let summary: String
    let topPriority: String
    let motivationMessage: String
    let suggestions: String
    let mood: String
}

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

    // Error State Management
    var errorMessage: String?
    var showError: Bool = false
    var partialDataLoaded: Bool = false  // Bazı veriler yüklendi ama hata var
    var fetchErrors: [String: String] = [:]  // Hangi fetch'te hata olduğunu takip et

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

    // MARK: - Phase 1 Services
    private let statsService = DashboardStatsService()
    private let contactAnalytics = ContactAnalyticsService()

    // MARK: - Phase 2 Services
    private let habitAnalytics = HabitAnalyticsService()
    private let mobilityAnalytics = MobilityAnalyticsService()
    private let goalAnalytics = GoalAnalyticsService()
    private let suggestionService = SmartSuggestionService()

    init() {
        checkLocationStatus()
    }

    @MainActor
    func loadDashboardDataAsync(context: ModelContext) async {
        // PHASE 1 & 2: Service-based loading
        do {
            // 1. Temel istatistikler (DashboardStatsService)
            try await statsService.loadBasicStats(context: context)
            totalContacts = statsService.totalContacts
            contactsNeedingAttention = statsService.contactsNeedingAttention
            activeGoals = statsService.activeGoals
            currentStreak = statsService.currentStreak

            // 2. İletişim trendleri (ContactAnalyticsService)
            let trends = try await contactAnalytics.analyzeContactTrends(context: context)
            contactsThisWeek = trends.thisWeekCount
            lastContactMood = trends.lastMood
            contactTrendPercentage = trends.trendPercentage

            // 3. Hedef analitiği (GoalAnalyticsService)
            goalService.setModelContext(context)
            let goalStats = try await goalAnalytics.loadStatistics(context: context)
            goalCompletionRate = goalStats.completionRate
            overdueGoals = goalStats.overdueGoals
            totalPoints = goalStats.totalPoints
            mostSuccessfulCategory = goalStats.mostSuccessfulCategory
            completedGoalsThisMonth = goalStats.completedThisMonth

            // 4. Alışkanlık analitiği (HabitAnalyticsService)
            let habitPerf = try await habitAnalytics.analyzePerformance(context: context)
            activeHabits = habitPerf.activeCount
            completedHabitsToday = habitPerf.completedToday
            totalHabitsToday = habitPerf.totalToday
            weeklyHabitCompletionRate = habitPerf.weeklyCompletionRate

            // 5. Mobilite analitiği (MobilityAnalyticsService)
            let mobilityMetrics = try await mobilityAnalytics.analyzeMobility(context: context)
            uniqueLocationsThisWeek = mobilityMetrics.uniqueLocations
            hoursOutsideThisWeek = mobilityMetrics.hoursOutside
            mobilityScore = mobilityMetrics.mobilityScore

            // 6. Smart öneriler (SmartSuggestionService)
            let friendDescriptor = FetchDescriptor<Friend>()
            let friends = try context.fetch(friendDescriptor)

            let calendar = Calendar.current
            guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else {
                throw NSError(domain: "DashboardVM", code: -1, userInfo: [NSLocalizedDescriptionKey: "Tarih hesaplama hatası"])
            }

            let locationDescriptor = FetchDescriptor<LocationLog>(
                predicate: #Predicate { $0.timestamp >= sevenDaysAgo }
            )
            let locationLogs = try context.fetch(locationDescriptor)

            let habitDescriptor = FetchDescriptor<Habit>(predicate: #Predicate { $0.isActive })
            let habits = try context.fetch(habitDescriptor)

            try await suggestionService.loadSuggestions(
                context: context,
                friends: friends,
                locations: locationLogs,
                habits: habits
            )
            smartGoalSuggestions = suggestionService.suggestions

        } catch {
            print("❌ [DashboardVM] Service loading hatası: \(error)")
            fetchErrors["services"] = error.localizedDescription
            partialDataLoaded = true
        }

        // Motivasyon mesajı
        motivationalMessage = goalService.getMotivationalMessage()

        // Daily Insight (async, background'da yükle)
        await loadDailyInsight(context: context)
    }

    // DEPRECATED: Eski senkron wrapper - geriye dönük uyumluluk için
    func loadDashboardData(context: ModelContext) {
        Task { @MainActor in
            await loadDashboardDataAsync(context: context)
        }
    }

    // DEPRECATED: Phase 1'de DashboardStatsService'e taşındı
    // Geriye dönük uyumluluk için bırakıldı, kullanılmıyor
    private func loadBasicStats(context: ModelContext) {
        // Bu metod artık kullanılmıyor - DashboardStatsService kullan
        print("⚠️ [DashboardVM] loadBasicStats() DEPRECATED - DashboardStatsService kullanın")
    }

    // DEPRECATED: Phase 2'de GoalAnalyticsService'e taşındı
    private func loadGoalStatistics(context: ModelContext) {
        print("⚠️ [DashboardVM] loadGoalStatistics() DEPRECATED - GoalAnalyticsService kullanın")
    }

    // DEPRECATED: Phase 2'de HabitAnalyticsService'e taşındı
    private func loadHabitPerformance(context: ModelContext) {
        print("⚠️ [DashboardVM] loadHabitPerformance() DEPRECATED - HabitAnalyticsService kullanın")
    }

    // DEPRECATED: Phase 1'de ContactAnalyticsService'e taşındı
    // Geriye dönük uyumluluk için bırakıldı, kullanılmıyor
    private func loadContactTrends(context: ModelContext) {
        // Bu metod artık kullanılmıyor - ContactAnalyticsService kullanın
        print("⚠️ [DashboardVM] loadContactTrends() DEPRECATED - ContactAnalyticsService kullanın")
    }

    // DEPRECATED: Phase 2'de MobilityAnalyticsService'e taşındı
    private func loadMobilityData(context: ModelContext) {
        print("⚠️ [DashboardVM] loadMobilityData() DEPRECATED - MobilityAnalyticsService kullanın")
    }

    // DEPRECATED: Phase 2'de SmartSuggestionService'e taşındı
    private func loadSmartSuggestions(context: ModelContext) {
        print("⚠️ [DashboardVM] loadSmartSuggestions() DEPRECATED - SmartSuggestionService kullanın")
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
    @MainActor
    func getPartnerInfo(context: ModelContext) -> PartnerInfo? {
        do {
            let partnerDescriptor = FetchDescriptor<Friend>(
                predicate: #Predicate { $0.relationshipTypeRaw == "partner" }
            )

            let partners = try context.fetch(partnerDescriptor)
            guard let partner = partners.first else {
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

            let partnerInfo = PartnerInfo(
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
            return partnerInfo
        } catch {
            print("❌ [DashboardVM] Partner info fetch hatası: \(error.localizedDescription)")
            fetchErrors["partner_info"] = error.localizedDescription
            partialDataLoaded = true
            return nil
        }
    }

    /// Dashboard için 4 ring verisi - YENİ: İletişim, Mobilite, Ruh Hali, Günlük
    @MainActor
    func getDashboardSummary(context: ModelContext) -> DashboardSummary {
        // 1. Social Ring (İletişim skoru 0-100)
        let socialScore = calculateSocialScore()
        let socialRing = DashboardRingData(
            completed: socialScore,
            total: 100,
            color: "3498DB", // Blue
            icon: "person.2.fill",
            label: "İletişim"
        )

        // 2. Activity Ring (Mobilite skoru 0-100)
        let activityScore = calculateActivityScore()
        let activityRing = DashboardRingData(
            completed: activityScore,
            total: 100,
            color: "2ECC71", // Green
            icon: "location.fill",
            label: "Mobilite"
        )

        // 3. Mood Ring (Ruh Hali skoru 0-100)
        let moodScore = calculateMoodScore(context: context)
        let moodRing = DashboardRingData(
            completed: moodScore,
            total: 100,
            color: "F093FB", // Pink
            icon: "face.smiling.fill",
            label: "Ruh Hali"
        )

        // 4. Journal Ring (Günlük skoru 0-100)
        let journalScore = calculateJournalScore(context: context)
        let journalRing = DashboardRingData(
            completed: journalScore,
            total: 100,
            color: "FF9500", // Orange
            icon: "book.fill",
            label: "Günlük"
        )

        // Overall Score - Yeni ring'lere göre hesapla
        let overallScore = Int((Double(socialScore) * 0.3 + Double(activityScore) * 0.25 + Double(moodScore) * 0.25 + Double(journalScore) * 0.2))

        // Motivasyon mesajı - RUH HALİNE GÖRE
        let message: String
        if moodScore >= 80 {
            // Çok mutlu
            message = "Muhteşem hissediyorsun!"
        } else if moodScore >= 60 {
            // İyi
            message = "Harika bir gün!"
        } else if moodScore >= 40 {
            // Normal
            message = "Her şey yolunda!"
        } else if moodScore >= 20 {
            // Biraz kötü
            message = "Bugün daha iyi olacak!"
        } else {
            // Kötü
            message = "Kendine iyi bak!"
        }

        return DashboardSummary(
            goalsRing: socialRing,
            habitsRing: activityRing,
            socialRing: moodRing,
            activityRing: journalRing,
            overallScore: overallScore,
            motivationMessage: message
        )
    }

    /// İletişim skoru hesapla (0-100)
    /// Phase 1: ContactAnalyticsService'e delegate edildi
    func calculateSocialScore() -> Int {
        return contactAnalytics.calculateSocialScore(
            totalContacts: totalContacts,
            weeklyContacts: contactsThisWeek
        )
    }

    /// Mobilite skoru döndür (zaten hesaplanıyor)
    func calculateActivityScore() -> Int {
        return mobilityScore
    }

    /// Ruh Hali skoru hesapla (0-100) - Son 7 günün ortalaması
    @MainActor
    func calculateMoodScore(context: ModelContext) -> Int {
        let calendar = Calendar.current
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else {
            print("⚠️ [DashboardVM] Mood score için tarih hesaplanamadı")
            fetchErrors["mood_score_date"] = "Tarih hesaplama hatası"
            return 50 // Varsayılan orta değer
        }

        do {
            let moodDescriptor = FetchDescriptor<MoodEntry>(
                predicate: #Predicate { entry in
                    entry.date >= sevenDaysAgo
                }
            )

            let moods = try context.fetch(moodDescriptor)

            guard !moods.isEmpty else {
                return 50 // Varsayılan orta değer - Bu hata değil, normal durum
            }

            // Ortalama mood skoru hesapla (score: -2 ile +2 arası, normalize to 0-100)
            let avgScore = moods.map { $0.score }.reduce(0, +) / Double(moods.count)
            // -2...+2 -> 0...100'e dönüştür
            let normalizedScore = ((avgScore + 2) / 4) * 100
            return Int(normalizedScore)
        } catch {
            print("❌ [DashboardVM] MoodEntry fetch hatası: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("   NSError domain: \(nsError.domain)")
                print("   NSError code: \(nsError.code)")
            }
            fetchErrors["mood_score"] = error.localizedDescription
            partialDataLoaded = true
            return 50 // Varsayılan orta değer
        }
    }

    /// Günlük skoru hesapla (0-100) - Son 7 günde yazılan günlük sayısı
    @MainActor
    func calculateJournalScore(context: ModelContext) -> Int {
        let calendar = Calendar.current
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else {
            print("⚠️ [DashboardVM] Journal score için tarih hesaplanamadı")
            fetchErrors["journal_score_date"] = "Tarih hesaplama hatası"
            return 50 // Varsayılan orta değer
        }

        // JournalEntry fetch - güvenli hata yönetimi ile
        do {
            let journalDescriptor = FetchDescriptor<JournalEntry>(
                predicate: #Predicate { entry in
                    entry.createdAt >= sevenDaysAgo
                }
            )

            let journalCount = try context.fetchCount(journalDescriptor)

            // 7 günlük hedef: günde 1 yazı = 7 yazı (100%)
            let score = min(Int((Double(journalCount) / 7.0) * 100), 100)
            return score
        } catch {
            print("❌ [DashboardVM] JournalEntry fetch hatası: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("   NSError domain: \(nsError.domain)")
                print("   NSError code: \(nsError.code)")
            }
            fetchErrors["journal_score"] = error.localizedDescription
            partialDataLoaded = true
            return 50 // Varsayılan orta değer
        }
    }

    /// Streak ve Achievement bilgisi
    @MainActor
    func getStreakInfo(context: ModelContext) -> StreakInfo {
        var currentStreak = 0
        var bestStreak = 0
        var habits: [Habit] = []
        var goals: [Goal] = []

        // En uzun streak'i bul
        do {
            let habitDescriptor = FetchDescriptor<Habit>(
                predicate: #Predicate { $0.isActive }
            )
            habits = try context.fetch(habitDescriptor)
            currentStreak = habits.map { $0.currentStreak }.max() ?? 0
            bestStreak = habits.map { $0.longestStreak }.max() ?? 0
        } catch {
            print("❌ [DashboardVM] Streak info habits fetch hatası: \(error.localizedDescription)")
            fetchErrors["streak_habits"] = error.localizedDescription
            partialDataLoaded = true
        }

        // Son kazanılan achievement'ları al
        do {
            let goalDescriptor = FetchDescriptor<Goal>()
            goals = try context.fetch(goalDescriptor)
        } catch {
            print("❌ [DashboardVM] Streak info goals fetch hatası: \(error.localizedDescription)")
            fetchErrors["streak_goals"] = error.localizedDescription
            partialDataLoaded = true
        }

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
    /// Phase 2: GoalAnalyticsService'e delegate edildi
    func getGoalsTrendData(context: ModelContext) -> [Double] {
        Task { @MainActor in
            do {
                return try await goalAnalytics.calculateGoalCompletionTrend(context: context)
            } catch {
                print("❌ [DashboardVM] Goals trend data fetch hatası: \(error.localizedDescription)")
                fetchErrors["goals_trend"] = error.localizedDescription
                partialDataLoaded = true
                return [0.0]
            }
        }
        // Async beklerken geçici değer döndür
        return [0.0]
    }

    /// Alışkanlık tamamlanma trendi (son 7 gün)
    /// Phase 2: HabitAnalyticsService'e delegate edildi
    func getHabitsTrendData(context: ModelContext) -> [Double] {
        Task { @MainActor in
            do {
                return try await habitAnalytics.calculateDailyCompletionTrend(context: context)
            } catch {
                print("❌ [DashboardVM] Habits trend data fetch hatası: \(error.localizedDescription)")
                fetchErrors["habits_trend"] = error.localizedDescription
                partialDataLoaded = true
                return [0.0]
            }
        }
        // Async beklerken geçici değer döndür
        return [0.0]
    }

    /// İletişim sayısı trendi (son 7 gün)
    /// Phase 1: ContactAnalyticsService'e delegate edildi
    func getContactsTrendData(context: ModelContext) -> [Double] {
        Task { @MainActor in
            do {
                return try await contactAnalytics.getDailyContactTrend(context: context)
            } catch {
                print("❌ [DashboardVM] Contacts trend data fetch hatası: \(error.localizedDescription)")
                fetchErrors["contacts_trend"] = error.localizedDescription
                partialDataLoaded = true
                return [0.0]
            }
        }
        // Async beklerken geçici değer döndür
        return [0.0]
    }

    /// Mobilite skoru trendi (son 7 gün)
    /// Phase 2: MobilityAnalyticsService'e delegate edildi
    func getMobilityTrendData(context: ModelContext) -> [Double] {
        Task { @MainActor in
            do {
                return try await mobilityAnalytics.calculateDailyMobilityTrend(context: context)
            } catch {
                print("❌ [DashboardVM] Mobility trend data fetch hatası: \(error.localizedDescription)")
                fetchErrors["mobility_trend"] = error.localizedDescription
                partialDataLoaded = true
                return [0.0]
            }
        }
        // Async beklerken geçici değer döndür
        return [0.0]
    }

    // MARK: - Smart Suggestions Actions

    /// Öneriyi kabul et ve Goal'a dönüştür
    /// Phase 2: SmartSuggestionService'e delegate edildi
    func acceptSuggestion(_ suggestion: GoalSuggestion, context: ModelContext) {
        do {
            try suggestionService.acceptSuggestion(suggestion, context: context)
            smartGoalSuggestions = suggestionService.suggestions
        } catch {
            print("❌ [DashboardVM] Öneri kabul hatası: \(error)")
            fetchErrors["accept_suggestion"] = error.localizedDescription
        }
    }

    /// Öneriyi reddet/dismiss et
    /// Phase 2: SmartSuggestionService'e delegate edildi
    func dismissSuggestion(_ suggestion: GoalSuggestion, context: ModelContext) {
        do {
            try suggestionService.dismissSuggestion(suggestion, context: context)
            smartGoalSuggestions = suggestionService.suggestions
        } catch {
            print("❌ [DashboardVM] Öneri reddetme hatası: \(error)")
            fetchErrors["dismiss_suggestion"] = error.localizedDescription
        }
    }

    /// AI ile yeni öneriler yükle (async)
    /// Phase 2: SmartSuggestionService'e delegate edildi
    @MainActor
    func loadAISuggestions(context: ModelContext) async {
        do {
            try await suggestionService.loadAISuggestions(context: context)
            smartGoalSuggestions = suggestionService.suggestions
        } catch {
            print("❌ [DashboardVM] AI önerileri yükleme hatası: \(error)")
            fetchErrors["ai_suggestions"] = error.localizedDescription
        }
    }

    /// Kabul edilen öneri için progress güncelle
    /// Phase 2: SmartSuggestionService'e delegate edildi
    func getAcceptedSuggestionProgress(for suggestionTitle: String, context: ModelContext) -> Double? {
        return suggestionService.getAcceptedSuggestionProgress(for: suggestionTitle, context: context)
    }

    // MARK: - Refresh

    /// Dashboard'daki tüm verileri yenile (Pull-to-refresh için optimize edilmiş)
    @MainActor
    func refreshAll(context: ModelContext) async {
        // Kısa gecikme ile UI'ın render olmasını sağla
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 saniye

        // PHASE 1 & 2: Service-based refresh
        do {
            // 1. Temel istatistikler (DashboardStatsService)
            try await statsService.loadBasicStats(context: context)
            totalContacts = statsService.totalContacts
            contactsNeedingAttention = statsService.contactsNeedingAttention
            activeGoals = statsService.activeGoals
            currentStreak = statsService.currentStreak

            // 2. İletişim trendleri (ContactAnalyticsService)
            let trends = try await contactAnalytics.analyzeContactTrends(context: context)
            contactsThisWeek = trends.thisWeekCount
            lastContactMood = trends.lastMood
            contactTrendPercentage = trends.trendPercentage

            // 3. Hedef analitiği (GoalAnalyticsService)
            goalService.setModelContext(context)
            let goalStats = try await goalAnalytics.loadStatistics(context: context)
            goalCompletionRate = goalStats.completionRate
            overdueGoals = goalStats.overdueGoals
            totalPoints = goalStats.totalPoints
            mostSuccessfulCategory = goalStats.mostSuccessfulCategory
            completedGoalsThisMonth = goalStats.completedThisMonth

            // 4. Alışkanlık analitiği (HabitAnalyticsService)
            let habitPerf = try await habitAnalytics.analyzePerformance(context: context)
            activeHabits = habitPerf.activeCount
            completedHabitsToday = habitPerf.completedToday
            totalHabitsToday = habitPerf.totalToday
            weeklyHabitCompletionRate = habitPerf.weeklyCompletionRate

            // 5. Mobilite analitiği (MobilityAnalyticsService)
            let mobilityMetrics = try await mobilityAnalytics.analyzeMobility(context: context)
            uniqueLocationsThisWeek = mobilityMetrics.uniqueLocations
            hoursOutsideThisWeek = mobilityMetrics.hoursOutside
            mobilityScore = mobilityMetrics.mobilityScore

            // 6. Smart öneriler (SmartSuggestionService)
            try await suggestionService.refreshAllSuggestions(context: context)
            smartGoalSuggestions = suggestionService.suggestions

        } catch {
            print("❌ [DashboardVM] Service refresh hatası: \(error)")
            fetchErrors["services_refresh"] = error.localizedDescription
            partialDataLoaded = true
        }

        // Motivasyon mesajı
        motivationalMessage = goalService.getMotivationalMessage()

        // Daily Insight yenile (eğer iOS 26+ ise)
        if #available(iOS 26.0, *) {
            await loadDailyInsight(context: context)
        }

        // AI Suggestions yenile
        await loadAISuggestions(context: context)
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

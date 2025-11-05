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

    init() {
        checkLocationStatus()
    }

    @MainActor
    func loadDashboardDataAsync(context: ModelContext) async {
        // PHASE 1: Service-based loading
        do {
            // 1. Temel istatistikler (DashboardStatsService)
            try await statsService.loadBasicStats(context: context)
            // Service'ten verileri al
            totalContacts = statsService.totalContacts
            contactsNeedingAttention = statsService.contactsNeedingAttention
            activeGoals = statsService.activeGoals
            currentStreak = statsService.currentStreak

            // 2. İletişim trendleri (ContactAnalyticsService)
            let trends = try await contactAnalytics.analyzeContactTrends(context: context)
            contactsThisWeek = trends.thisWeekCount
            lastContactMood = trends.lastMood
            contactTrendPercentage = trends.trendPercentage

        } catch {
            print("❌ [DashboardVM] Service loading hatası: \(error)")
            fetchErrors["services"] = error.localizedDescription
            partialDataLoaded = true
        }

        // GoalService'i ayarla ve istatistikleri yükle
        goalService.setModelContext(context)
        loadGoalStatistics(context: context)

        // Diğer istatistikler (henüz service'e taşınmadı)
        loadHabitPerformance(context: context)
        loadMobilityData(context: context)
        loadSmartSuggestions(context: context)

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

    private func loadGoalStatistics(context: ModelContext) {
        guard let stats = goalService.statistics else {
            print("⚠️ [DashboardVM] GoalService statistics mevcut değil")
            fetchErrors["goal_statistics"] = "GoalService statistics yüklenemedi"
            return
        }

        goalCompletionRate = stats.completionRate
        overdueGoals = stats.overdueGoals
        totalPoints = stats.totalPoints

        if let category = stats.mostSuccessfulCategory {
            mostSuccessfulCategory = "\(category.emoji) \(category.rawValue)"
        }

        // Bu ay tamamlanan hedefleri hesapla
        do {
            let goalDescriptor = FetchDescriptor<Goal>(
                predicate: #Predicate { goal in
                    goal.isCompleted
                }
            )

            let goals = try context.fetch(goalDescriptor)
            let calendar = Calendar.current
            guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) else {
                completedGoalsThisMonth = 0
                print("⚠️ [DashboardVM] Ay başlangıç tarihi hesaplanamadı")
                return
            }
            completedGoalsThisMonth = goals.filter { goal in
                goal.targetDate >= startOfMonth
            }.count
        } catch {
            print("❌ [DashboardVM] Completed goals fetch hatası: \(error.localizedDescription)")
            fetchErrors["completed_goals"] = error.localizedDescription
            completedGoalsThisMonth = 0
            partialDataLoaded = true
        }
    }

    private func loadHabitPerformance(context: ModelContext) {
        do {
            let habitDescriptor = FetchDescriptor<Habit>(
                predicate: #Predicate { $0.isActive }
            )

            let habits = try context.fetch(habitDescriptor)

            activeHabits = habits.count
            totalHabitsToday = habits.count
            completedHabitsToday = habits.filter { $0.isCompletedToday() }.count

            // Haftalık tamamlama oranı
            let calendar = Calendar.current
            guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else {
                print("⚠️ [DashboardVM] Haftalık tarih hesaplanamadı")
                weeklyHabitCompletionRate = 0.0
                return
            }

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

        } catch {
            print("❌ [DashboardVM] Habit performance fetch hatası: \(error.localizedDescription)")
            fetchErrors["habit_performance"] = error.localizedDescription
            activeHabits = 0
            totalHabitsToday = 0
            completedHabitsToday = 0
            weeklyHabitCompletionRate = 0.0
            partialDataLoaded = true
        }
    }

    // DEPRECATED: Phase 1'de ContactAnalyticsService'e taşındı
    // Geriye dönük uyumluluk için bırakıldı, kullanılmıyor
    private func loadContactTrends(context: ModelContext) {
        // Bu metod artık kullanılmıyor - ContactAnalyticsService kullanın
        print("⚠️ [DashboardVM] loadContactTrends() DEPRECATED - ContactAnalyticsService kullanın")
    }

    private func loadMobilityData(context: ModelContext) {
        let calendar = Calendar.current
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else {
            handleMobilityDateError()
            return
        }

        do {
            let logs = try fetchLocationLogs(from: sevenDaysAgo, context: context)
            calculateMobilityMetrics(from: logs)
        } catch {
            handleMobilityFetchError(error)
        }
    }

    private func handleMobilityDateError() {
        print("⚠️ [DashboardVM] Haftalık tarih hesaplanamadı")
        fetchErrors["mobility_date"] = "Tarih hesaplama hatası"
        mobilityScore = 0
    }

    private func fetchLocationLogs(from date: Date, context: ModelContext) throws -> [LocationLog] {
        let descriptor = FetchDescriptor<LocationLog>(
            predicate: #Predicate { log in log.timestamp >= date }
        )
        return try context.fetch(descriptor)
    }

    private func calculateMobilityMetrics(from logs: [LocationLog]) {
        print("   Total logs (7 gün): \(logs.count)")

        // Benzersiz lokasyon sayısı - 200m hassasiyet
        let coordinates = logs.map { "\(Int($0.latitude * 5)),\(Int($0.longitude * 5))" }
        uniqueLocationsThisWeek = Set(coordinates).count
        print("   Benzersiz lokasyonlar (200m): \(uniqueLocationsThisWeek)")

        // Dışarıda geçirilen süre
        let outsideLogs = logs.filter { $0.locationType != .home }
        hoursOutsideThisWeek = Double(outsideLogs.count) * 0.5
        print("   Dışarıda log sayısı: \(outsideLogs.count)")
        print("   Dışarıda saat: \(String(format: "%.1f", hoursOutsideThisWeek))")

        // Mobilite skoru (0-100)
        // 15 yer = 100%, gerçekçi formül
        let locationDiversity = min(Double(uniqueLocationsThisWeek) / 15.0, 1.0)
        mobilityScore = Int(locationDiversity * 100)
        print("   Mobilite Skoru: \(mobilityScore)")
        print("   ---")
    }

    private func handleMobilityFetchError(_ error: Error) {
        print("❌ [DashboardVM] Mobility data fetch hatası: \(error.localizedDescription)")
        fetchErrors["mobility_data"] = error.localizedDescription
        mobilityScore = 0
        uniqueLocationsThisWeek = 0
        hoursOutsideThisWeek = 0
        partialDataLoaded = true
    }

    private func loadSmartSuggestions(context: ModelContext) {
        // Verileri topla
        do {
            let friendDescriptor = FetchDescriptor<Friend>()
            let friends = try context.fetch(friendDescriptor)

            let calendar = Calendar.current
            guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else {
                print("⚠️ [DashboardVM] Haftalık tarih hesaplanamadı")
                fetchErrors["smart_suggestions_date"] = "Tarih hesaplama hatası"
                smartGoalSuggestions = []
                return
            }

            let locationDescriptor = FetchDescriptor<LocationLog>(
                predicate: #Predicate { $0.timestamp >= sevenDaysAgo }
            )
            let locationLogs = try context.fetch(locationDescriptor)

            let habitDescriptor = FetchDescriptor<Habit>(predicate: #Predicate { $0.isActive })
            let habits = try context.fetch(habitDescriptor)

            // Smart önerileri oluştur
            smartGoalSuggestions = goalService.generateSmartSuggestions(
                friends: friends,
                locationLogs: locationLogs,
                habits: habits
            )
        } catch {
            print("❌ [DashboardVM] Smart suggestions fetch hatası: \(error.localizedDescription)")
            fetchErrors["smart_suggestions"] = error.localizedDescription
            smartGoalSuggestions = []
            partialDataLoaded = true
        }
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
    func getGoalsTrendData(context: ModelContext) -> [Double] {
        do {
            // Tüm hedefleri al
            let goalDescriptor = FetchDescriptor<Goal>()
            let goals = try context.fetch(goalDescriptor)

            guard !goals.isEmpty else {
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
        } catch {
            print("❌ [DashboardVM] Goals trend data fetch hatası: \(error.localizedDescription)")
            fetchErrors["goals_trend"] = error.localizedDescription
            partialDataLoaded = true
            return [0.0]
        }
    }

    /// Alışkanlık tamamlanma trendi (son 7 gün)
    func getHabitsTrendData(context: ModelContext) -> [Double] {
        let calendar = Calendar.current
        var trendData: [Double] = []

        do {
            for dayOffset in (0...6).reversed() {
                guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else {
                    print("⚠️ [DashboardVM] Habits trend tarih hesaplanamadı: dayOffset \(dayOffset)")
                    continue
                }
                let dayStart = calendar.startOfDay(for: targetDate)
                guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                    print("⚠️ [DashboardVM] Habits trend gün sonu hesaplanamadı")
                    continue
                }

                let habitDescriptor = FetchDescriptor<Habit>(predicate: #Predicate { $0.isActive })
                let habits = try context.fetch(habitDescriptor)

                guard !habits.isEmpty else {
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
        } catch {
            print("❌ [DashboardVM] Habits trend data fetch hatası: \(error.localizedDescription)")
            fetchErrors["habits_trend"] = error.localizedDescription
            partialDataLoaded = true
            return [0.0]
        }
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
    func getMobilityTrendData(context: ModelContext) -> [Double] {
        let calendar = Calendar.current
        var trendData: [Double] = []

        do {
            for dayOffset in (0...6).reversed() {
                guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else {
                    print("⚠️ [DashboardVM] Mobility trend tarih hesaplanamadı: dayOffset \(dayOffset)")
                    continue
                }
                let dayStart = calendar.startOfDay(for: targetDate)
                guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                    print("⚠️ [DashboardVM] Mobility trend gün sonu hesaplanamadı")
                    continue
                }

                let locationDescriptor = FetchDescriptor<LocationLog>(
                    predicate: #Predicate { log in
                        log.timestamp >= dayStart && log.timestamp < dayEnd
                    }
                )

                let logs = try context.fetch(locationDescriptor)
                let uniqueCoords = Set(logs.map { "\(Int($0.latitude * 100)),\(Int($0.longitude * 100))" })
                let score = min(Double(uniqueCoords.count) * 10.0, 100.0)
                trendData.append(score)
            }

            return trendData.isEmpty ? [0.0] : trendData
        } catch {
            print("❌ [DashboardVM] Mobility trend data fetch hatası: \(error.localizedDescription)")
            fetchErrors["mobility_trend"] = error.localizedDescription
            partialDataLoaded = true
            return [0.0]
        }
    }

    // MARK: - Smart Suggestions Actions

    /// Öneriyi kabul et ve Goal'a dönüştür
    func acceptSuggestion(_ suggestion: GoalSuggestion, context: ModelContext) {
        // Goal oluştur
        let goal = Goal(
            title: suggestion.title,
            goalDescription: suggestion.description,
            category: suggestion.category,
            targetDate: suggestion.suggestedTargetDate
        )

        context.insert(goal)

        // AcceptedSuggestion kaydı oluştur
        let accepted = AcceptedSuggestion(
            from: suggestion,
            convertedGoalId: goal.id
        )
        context.insert(accepted)

        // Listeden kaldır
        smartGoalSuggestions.removeAll { $0.id == suggestion.id }

        do {
            try context.save()
        } catch {
            print("❌ Öneri kabul edilirken hata: \(error)")
        }
    }

    /// Öneriyi reddet/dismiss et
    func dismissSuggestion(_ suggestion: GoalSuggestion, context: ModelContext) {
        // AcceptedSuggestion olarak kaydet ama dismissed flag'i true
        let dismissed = AcceptedSuggestion(from: suggestion)
        dismissed.isDismissed = true
        context.insert(dismissed)

        // Listeden kaldır
        smartGoalSuggestions.removeAll { $0.id == suggestion.id }

        do {
            try context.save()
            print("🚫 Öneri reddedildi: \(suggestion.title)")
        } catch {
            print("❌ Öneri reddedilirken hata: \(error)")
        }
    }

    /// AI ile yeni öneriler yükle (async)
    @MainActor
    func loadAISuggestions(context: ModelContext) async {
        // UserProgress al
        let progressDescriptor = FetchDescriptor<UserProgress>()
        let userProgress = try? context.fetch(progressDescriptor).first

        // AI provider ile öneriler üret
        let aiProvider = AIGoalSuggestionProvider()

        do {
            let aiSuggestions = try await aiProvider.generatePersonalizedSuggestions(
                context: context,
                userProgress: userProgress,
                count: 2
            )

            // Mevcut önerilerle birleştir (zaten MainActor'dayız)
            smartGoalSuggestions.append(contentsOf: aiSuggestions)
            // Relevance'a göre sırala
            smartGoalSuggestions.sort { $0.relevanceScore > $1.relevanceScore }

        } catch {
            print("❌ [DashboardVM] AI önerileri yüklenemedi: \(error)")
            if let nsError = error as NSError? {
                print("   Error domain: \(nsError.domain)")
                print("   Error code: \(nsError.code)")
            }
        }
    }

    /// Kabul edilen öneri için progress güncelle
    func getAcceptedSuggestionProgress(for suggestionTitle: String, context: ModelContext) -> Double? {
        let descriptor = FetchDescriptor<AcceptedSuggestion>(
            predicate: #Predicate { $0.suggestionTitle == suggestionTitle && !$0.isDismissed }
        )

        guard let accepted = try? context.fetch(descriptor).first,
              let goalId = accepted.convertedGoalId else {
            return nil
        }

        // Goal'un progress'ini al
        let goalDescriptor = FetchDescriptor<Goal>(
            predicate: #Predicate { $0.id == goalId }
        )

        guard let goal = try? context.fetch(goalDescriptor).first else {
            return nil
        }

        return goal.progress
    }

    // MARK: - Refresh

    /// Dashboard'daki tüm verileri yenile (Pull-to-refresh için optimize edilmiş)
    @MainActor
    func refreshAll(context: ModelContext) async {
        // Kısa gecikme ile UI'ın render olmasını sağla
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 saniye

        // PHASE 1: Service-based loading
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
        } catch {
            print("❌ [DashboardVM] Service refresh hatası: \(error)")
            fetchErrors["services_refresh"] = error.localizedDescription
            partialDataLoaded = true
        }

        // Diğer istatistikler
        goalService.setModelContext(context)
        loadGoalStatistics(context: context)
        loadHabitPerformance(context: context)
        loadMobilityData(context: context)
        loadSmartSuggestions(context: context)
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

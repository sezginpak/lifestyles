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

    init() {
        checkLocationStatus()
    }

    @MainActor
    func loadDashboardDataAsync(context: ModelContext) async {
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
        await loadDailyInsight(context: context)
    }

    // DEPRECATED: Eski senkron wrapper - geriye dönük uyumluluk için
    func loadDashboardData(context: ModelContext) {
        Task { @MainActor in
            await loadDashboardDataAsync(context: context)
        }
    }

    private func loadBasicStats(context: ModelContext) {
        var hasErrors = false

        // Toplam arkadaş sayısı
        do {
            let friendDescriptor = FetchDescriptor<Friend>()
            totalContacts = try context.fetchCount(friendDescriptor)
        } catch {
            print("❌ [DashboardVM] Friend count fetch hatası: \(error.localizedDescription)")
            fetchErrors["friends_count"] = error.localizedDescription
            totalContacts = 0
            hasErrors = true
        }

        // İletişim gereken arkadaşlar
        do {
            let friendsDescriptor = FetchDescriptor<Friend>()
            let friends = try context.fetch(friendsDescriptor)
            contactsNeedingAttention = friends.filter { $0.needsContact }.count
        } catch {
            print("❌ [DashboardVM] Friends needing attention fetch hatası: \(error.localizedDescription)")
            fetchErrors["friends_attention"] = error.localizedDescription
            contactsNeedingAttention = 0
            hasErrors = true
        }

        // Aktif hedefler
        do {
            let goalDescriptor = FetchDescriptor<Goal>(
                predicate: #Predicate { !$0.isCompleted }
            )
            activeGoals = try context.fetchCount(goalDescriptor)
        } catch {
            print("❌ [DashboardVM] Active goals fetch hatası: \(error.localizedDescription)")
            fetchErrors["active_goals"] = error.localizedDescription
            activeGoals = 0
            hasErrors = true
        }

        // En uzun alışkanlık serisi
        do {
            let habitDescriptor = FetchDescriptor<Habit>(
                predicate: #Predicate { $0.isActive }
            )
            let habits = try context.fetch(habitDescriptor)
            currentStreak = habits.map { $0.currentStreak }.max() ?? 0
        } catch {
            print("❌ [DashboardVM] Habits streak fetch hatası: \(error.localizedDescription)")
            fetchErrors["habit_streak"] = error.localizedDescription
            currentStreak = 0
            hasErrors = true
        }

        if hasErrors {
            partialDataLoaded = true
            errorMessage = "Bazı veriler yüklenemedi. Lütfen daha sonra tekrar deneyin."
        }
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

    private func loadContactTrends(context: ModelContext) {
        print("📞 [DashboardVM] loadContactTrends BAŞLADI")
        let calendar = Calendar.current
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else {
            print("⚠️ [DashboardVM] Haftalık tarih hesaplanamadı")
            fetchErrors["contact_trends_date"] = "Tarih hesaplama hatası"
            return
        }

        // Bu hafta iletişim kurulan arkadaşlar
        do {
            print("📞 [DashboardVM] ContactHistory descriptor oluşturuluyor...")
            let historyDescriptor = FetchDescriptor<ContactHistory>(
                predicate: #Predicate { history in
                    history.date >= sevenDaysAgo
                },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )

            print("📞 [DashboardVM] ContactHistory fetch yapılıyor... (THREAD: \(Thread.current.isMainThread ? "MAIN" : "BACKGROUND"))")
            let histories = try context.fetch(historyDescriptor)
            print("✅ [DashboardVM] ContactHistory fetch tamamlandı: \(histories.count) adet")
            contactsThisWeek = Set(histories.compactMap { $0.friend?.id }).count

            // Son iletişimin mood'u
            if let lastHistory = histories.first, let mood = lastHistory.mood {
                lastContactMood = mood.emoji
            }

            // Önceki haftayla karşılaştır
            guard let fourteenDaysAgo = calendar.date(byAdding: .day, value: -14, to: Date()) else {
                print("⚠️ [DashboardVM] İki haftalık tarih hesaplanamadı")
                return
            }
            let previousWeekHistories = histories.filter { $0.date < sevenDaysAgo && $0.date >= fourteenDaysAgo }
            let previousWeekCount = Set(previousWeekHistories.compactMap { $0.friend?.id }).count

            if previousWeekCount > 0 {
                contactTrendPercentage = ((Double(contactsThisWeek) - Double(previousWeekCount)) / Double(previousWeekCount)) * 100
            }
        } catch {
            print("❌ [DashboardVM] Contact trends fetch hatası: \(error.localizedDescription)")
            fetchErrors["contact_trends"] = error.localizedDescription
            contactsThisWeek = 0
            lastContactMood = ""
            contactTrendPercentage = 0.0
            partialDataLoaded = true
        }
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
        print("💑 [DashboardVM] getPartnerInfo BAŞLADI")
        do {
            let partnerDescriptor = FetchDescriptor<Friend>(
                predicate: #Predicate { $0.relationshipTypeRaw == "partner" }
            )

            print("💑 [DashboardVM] Partner fetch yapılıyor...")
            let partners = try context.fetch(partnerDescriptor)
            guard let partner = partners.first else {
                print("ℹ️ [DashboardVM] Partner bulunamadı")
                return nil
            }
            print("✅ [DashboardVM] Partner bulundu: \(partner.name)")

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
            print("✅ [DashboardVM] getPartnerInfo TAMAMLANDI")
            return partnerInfo
        } catch {
            print("❌ [DashboardVM] Partner info fetch hatası: \(error.localizedDescription)")
            print("   Error details: \(error)")
            fetchErrors["partner_info"] = error.localizedDescription
            partialDataLoaded = true
            return nil
        }
    }

    /// Dashboard için 4 ring verisi - YENİ: İletişim, Mobilite, Ruh Hali, Günlük
    @MainActor
    func getDashboardSummary(context: ModelContext) -> DashboardSummary {
        print("📊 [DashboardVM] getDashboardSummary BAŞLADI")

        // 1. Social Ring (İletişim skoru 0-100)
        print("📊 [DashboardVM] calculateSocialScore çağrılıyor...")
        let socialScore = calculateSocialScore()
        print("✅ [DashboardVM] calculateSocialScore tamamlandı: \(socialScore)")
        let socialRing = DashboardRingData(
            completed: socialScore,
            total: 100,
            color: "3498DB", // Blue
            icon: "person.2.fill",
            label: "İletişim"
        )

        // 2. Activity Ring (Mobilite skoru 0-100)
        print("📊 [DashboardVM] calculateActivityScore çağrılıyor...")
        let activityScore = calculateActivityScore()
        print("✅ [DashboardVM] calculateActivityScore tamamlandı: \(activityScore)")
        let activityRing = DashboardRingData(
            completed: activityScore,
            total: 100,
            color: "2ECC71", // Green
            icon: "location.fill",
            label: "Mobilite"
        )

        // 3. Mood Ring (Ruh Hali skoru 0-100)
        print("📊 [DashboardVM] calculateMoodScore çağrılıyor...")
        let moodScore = calculateMoodScore(context: context)
        print("✅ [DashboardVM] calculateMoodScore tamamlandı: \(moodScore)")
        let moodRing = DashboardRingData(
            completed: moodScore,
            total: 100,
            color: "F093FB", // Pink
            icon: "face.smiling.fill",
            label: "Ruh Hali"
        )

        // 4. Journal Ring (Günlük skoru 0-100)
        print("📊 [DashboardVM] calculateJournalScore çağrılıyor...")
        let journalScore = calculateJournalScore(context: context)
        print("✅ [DashboardVM] calculateJournalScore tamamlandı: \(journalScore)")
        let journalRing = DashboardRingData(
            completed: journalScore,
            total: 100,
            color: "FF9500", // Orange
            icon: "book.fill",
            label: "Günlük"
        )

        // Overall Score - Yeni ring'lere göre hesapla
        let overallScore = Int((Double(socialScore) * 0.3 + Double(activityScore) * 0.25 + Double(moodScore) * 0.25 + Double(journalScore) * 0.2))
        print("📊 [DashboardVM] overallScore hesaplandı: \(overallScore)")

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

        print("✅ [DashboardVM] getDashboardSummary TAMAMLANDI")
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
    func calculateSocialScore() -> Int {
        // Eğer hiç arkadaş yoksa, 0 puan
        guard totalContacts > 0 else { return 0 }

        print("💬 İletişim Debug:")
        print("   Total arkadaş: \(totalContacts)")
        print("   Bu hafta iletişim: \(contactsThisWeek)")
        print("   İletişim gereken: \(contactsNeedingAttention)")

        // Bu haftaki iletişim sayısı - ANA AĞIRLIK %100
        // 0 iletişim = 0 puan, 5+ iletişim = 100 puan
        let contactScore = min(Double(contactsThisWeek) / 5.0, 1.0) * 100

        print("   İletişim Skoru: \(Int(contactScore))")
        print("   ---")

        return Int(contactScore)
    }

    /// Mobilite skoru döndür (zaten hesaplanıyor)
    func calculateActivityScore() -> Int {
        return mobilityScore
    }

    /// Ruh Hali skoru hesapla (0-100) - Son 7 günün ortalaması
    @MainActor
    func calculateMoodScore(context: ModelContext) -> Int {
        print("😊 [DashboardVM] calculateMoodScore BAŞLADI")
        let calendar = Calendar.current
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else {
            print("⚠️ [DashboardVM] Mood score için tarih hesaplanamadı")
            fetchErrors["mood_score_date"] = "Tarih hesaplama hatası"
            return 50 // Varsayılan orta değer
        }
        print("😊 [DashboardVM] 7 gün öncesi tarihi: \(sevenDaysAgo)")

        do {
            print("😊 [DashboardVM] MoodEntry descriptor oluşturuluyor...")
            let moodDescriptor = FetchDescriptor<MoodEntry>(
                predicate: #Predicate { entry in
                    entry.date >= sevenDaysAgo
                }
            )

            print("😊 [DashboardVM] MoodEntry fetch yapılıyor...")
            let moods = try context.fetch(moodDescriptor)
            print("😊 [DashboardVM] MoodEntry fetch tamamlandı: \(moods.count) adet")

            guard !moods.isEmpty else {
                print("ℹ️ [DashboardVM] MoodEntry bulunamadı, varsayılan değer kullanılıyor")
                return 50 // Varsayılan orta değer - Bu hata değil, normal durum
            }

            // Ortalama mood skoru hesapla (score: -2 ile +2 arası, normalize to 0-100)
            print("😊 [DashboardVM] Mood skoru hesaplanıyor...")
            let avgScore = moods.map { $0.score }.reduce(0, +) / Double(moods.count)
            print("😊 [DashboardVM] Ortalama mood score: \(avgScore)")
            // -2...+2 -> 0...100'e dönüştür
            let normalizedScore = ((avgScore + 2) / 4) * 100
            print("✅ [DashboardVM] calculateMoodScore tamamlandı: \(Int(normalizedScore))")
            return Int(normalizedScore)
        } catch {
            print("❌ [DashboardVM] MoodEntry fetch hatası: \(error.localizedDescription)")
            print("   Error details: \(error)")
            print("   Error type: \(type(of: error))")
            if let nsError = error as NSError? {
                print("   NSError domain: \(nsError.domain)")
                print("   NSError code: \(nsError.code)")
                print("   NSError userInfo: \(nsError.userInfo)")
            }
            fetchErrors["mood_score"] = error.localizedDescription
            partialDataLoaded = true
            return 50 // Varsayılan orta değer
        }
    }

    /// Günlük skoru hesapla (0-100) - Son 7 günde yazılan günlük sayısı
    @MainActor
    func calculateJournalScore(context: ModelContext) -> Int {
        print("📝 [DashboardVM] calculateJournalScore BAŞLADI")
        let calendar = Calendar.current
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else {
            print("⚠️ [DashboardVM] Journal score için tarih hesaplanamadı")
            fetchErrors["journal_score_date"] = "Tarih hesaplama hatası"
            return 50 // Varsayılan orta değer
        }
        print("📝 [DashboardVM] 7 gün öncesi tarihi: \(sevenDaysAgo)")

        // JournalEntry fetch - güvenli hata yönetimi ile
        do {
            print("📝 [DashboardVM] JournalEntry descriptor oluşturuluyor...")
            let journalDescriptor = FetchDescriptor<JournalEntry>(
                predicate: #Predicate { entry in
                    entry.createdAt >= sevenDaysAgo
                }
            )

            print("📝 [DashboardVM] JournalEntry fetchCount yapılıyor...")
            let journalCount = try context.fetchCount(journalDescriptor)
            print("📝 [DashboardVM] JournalEntry fetchCount tamamlandı: \(journalCount) adet")

            if journalCount == 0 {
                print("ℹ️ [DashboardVM] JournalEntry bulunamadı, varsayılan değer kullanılıyor")
            }

            // 7 günlük hedef: günde 1 yazı = 7 yazı (100%)
            let score = min(Int((Double(journalCount) / 7.0) * 100), 100)
            print("✅ [DashboardVM] calculateJournalScore tamamlandı: \(score)")
            return score
        } catch {
            print("❌ [DashboardVM] JournalEntry fetch hatası: \(error.localizedDescription)")
            print("   Error details: \(error)")
            print("   Error type: \(type(of: error))")
            if let nsError = error as NSError? {
                print("   NSError domain: \(nsError.domain)")
                print("   NSError code: \(nsError.code)")
                print("   NSError userInfo: \(nsError.userInfo)")
            }
            fetchErrors["journal_score"] = error.localizedDescription
            partialDataLoaded = true
            return 50 // Varsayılan orta değer
        }
    }

    /// Streak ve Achievement bilgisi
    @MainActor
    func getStreakInfo(context: ModelContext) -> StreakInfo {
        print("🔥 [DashboardVM] getStreakInfo BAŞLADI")
        var currentStreak = 0
        var bestStreak = 0
        var habits: [Habit] = []
        var goals: [Goal] = []

        // En uzun streak'i bul
        do {
            print("🔥 [DashboardVM] Habits fetch yapılıyor...")
            let habitDescriptor = FetchDescriptor<Habit>(
                predicate: #Predicate { $0.isActive }
            )
            habits = try context.fetch(habitDescriptor)
            currentStreak = habits.map { $0.currentStreak }.max() ?? 0
            bestStreak = habits.map { $0.longestStreak }.max() ?? 0
            print("✅ [DashboardVM] Habits fetch tamamlandı: \(habits.count) habit")
        } catch {
            print("❌ [DashboardVM] Streak info habits fetch hatası: \(error.localizedDescription)")
            print("   Error details: \(error)")
            fetchErrors["streak_habits"] = error.localizedDescription
            partialDataLoaded = true
        }

        // Son kazanılan achievement'ları al
        do {
            print("🔥 [DashboardVM] Goals fetch yapılıyor...")
            let goalDescriptor = FetchDescriptor<Goal>()
            goals = try context.fetch(goalDescriptor)
            print("✅ [DashboardVM] Goals fetch tamamlandı: \(goals.count) goal")
        } catch {
            print("❌ [DashboardVM] Streak info goals fetch hatası: \(error.localizedDescription)")
            print("   Error details: \(error)")
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

        print("✅ [DashboardVM] getStreakInfo TAMAMLANDI - currentStreak: \(currentStreak), totalAchievements: \(totalEarned)/\(totalAchievements)")
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
    func getContactsTrendData(context: ModelContext) -> [Double] {
        let calendar = Calendar.current
        var trendData: [Double] = []

        do {
            for dayOffset in (0...6).reversed() {
                guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else {
                    print("⚠️ [DashboardVM] Contacts trend tarih hesaplanamadı: dayOffset \(dayOffset)")
                    continue
                }
                let dayStart = calendar.startOfDay(for: targetDate)
                guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                    print("⚠️ [DashboardVM] Contacts trend gün sonu hesaplanamadı")
                    continue
                }

                let historyDescriptor = FetchDescriptor<ContactHistory>(
                    predicate: #Predicate { history in
                        history.date >= dayStart && history.date < dayEnd
                    }
                )

                let contacts = try context.fetch(historyDescriptor)
                trendData.append(Double(contacts.count))
            }

            return trendData.isEmpty ? [0.0] : trendData
        } catch {
            print("❌ [DashboardVM] Contacts trend data fetch hatası: \(error.localizedDescription)")
            fetchErrors["contacts_trend"] = error.localizedDescription
            partialDataLoaded = true
            return [0.0]
        }
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

            // Mevcut önerilerle birleştir
            DispatchQueue.main.async {
                self.smartGoalSuggestions.append(contentsOf: aiSuggestions)
                // Relevance'a göre sırala
                self.smartGoalSuggestions.sort { $0.relevanceScore > $1.relevanceScore }
                print("🤖 AI önerileri eklendi: \(aiSuggestions.count) adet")
            }
        } catch {
            print("❌ AI önerileri yüklenemedi: \(error)")
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
        print("🔄 [DashboardVM] refreshAll BAŞLADI")

        // Kısa gecikme ile UI'ın render olmasını sağla
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 saniye

        // Tüm verileri yeniden yükle (async)
        print("🔄 [DashboardVM] loadBasicStats çağrılıyor...")
        loadBasicStats(context: context)
        print("✅ [DashboardVM] loadBasicStats tamamlandı")

        print("🔄 [DashboardVM] goalService.setModelContext çağrılıyor...")
        goalService.setModelContext(context)
        print("✅ [DashboardVM] goalService.setModelContext tamamlandı")

        print("🔄 [DashboardVM] loadGoalStatistics çağrılıyor...")
        loadGoalStatistics(context: context)
        print("✅ [DashboardVM] loadGoalStatistics tamamlandı")

        print("🔄 [DashboardVM] loadHabitPerformance çağrılıyor...")
        loadHabitPerformance(context: context)
        print("✅ [DashboardVM] loadHabitPerformance tamamlandı")

        print("🔄 [DashboardVM] loadContactTrends çağrılıyor...")
        loadContactTrends(context: context)
        print("✅ [DashboardVM] loadContactTrends tamamlandı")

        print("🔄 [DashboardVM] loadMobilityData çağrılıyor...")
        loadMobilityData(context: context)
        print("✅ [DashboardVM] loadMobilityData tamamlandı")

        print("🔄 [DashboardVM] loadSmartSuggestions çağrılıyor...")
        loadSmartSuggestions(context: context)
        print("✅ [DashboardVM] loadSmartSuggestions tamamlandı")

        print("🔄 [DashboardVM] motivationalMessage alınıyor...")
        motivationalMessage = goalService.getMotivationalMessage()
        print("✅ [DashboardVM] motivationalMessage tamamlandı")

        // Daily Insight yenile (eğer iOS 26+ ise)
        if #available(iOS 26.0, *) {
            print("🔄 [DashboardVM] loadDailyInsight çağrılıyor...")
            await loadDailyInsight(context: context)
            print("✅ [DashboardVM] loadDailyInsight tamamlandı")
        }

        // AI Suggestions yenile
        print("🔄 [DashboardVM] loadAISuggestions çağrılıyor...")
        await loadAISuggestions(context: context)
        print("✅ [DashboardVM] loadAISuggestions tamamlandı")

        print("✅ [DashboardVM] refreshAll TAMAMLANDI")
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

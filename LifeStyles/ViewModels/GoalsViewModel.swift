//
//  GoalsViewModel.swift
//  LifeStyles
//
//  Created by Claude on 15.10.2025.
//

import Foundation
import SwiftData

@Observable
class GoalsViewModel {
    var goals: [Goal] = []
    var habits: [Habit] = []
    var selectedCategory: GoalCategory = .personal
    var showingAddGoal = false
    var showingAddHabit = false
    var goalSuggestions: [GoalSuggestion] = []
    var showingSuggestionsSheet = false

    // Stats (NEW)
    var weeklyGoalStats: WeeklyGoalStats = .empty()
    var monthlyGoalStats: MonthlyGoalStats = .empty()
    var weeklyHabitStats: WeeklyHabitStats = .empty()
    var monthlyHabitStats: MonthlyHabitStats = .empty()
    var combinedStats: CombinedStats = .empty()
    var currentStreak: Int = 0

    // Achievements (NEW)
    var achievements: [Achievement] = []
    var newlyEarnedAchievements: [Achievement] = []
    var showingAchievementCelebration = false

    // Filter & Display (NEW)
    var selectedCategoryFilter: GoalCategory? = nil
    var todaysFocus: [Goal] = []

    // AI State (iOS 26+)
    var goalInsights: [UUID: GoalInsightWrapper] = [:]
    var habitInsights: [UUID: HabitInsightWrapper] = [:]
    var isLoadingAI: [UUID: Bool] = [:]
    var selectedGoalForAI: Goal?
    var selectedHabitForAI: Habit?

    @available(iOS 26.0, *)
    private var goalAIService: GoalAIService {
        GoalAIService.shared
    }

    @available(iOS 26.0, *)
    private var habitAIService: HabitAIService {
        HabitAIService.shared
    }

    private let notificationService = NotificationService.shared
    private let goalService = GoalService.shared
    private let achievementService = AchievementService.shared
    private var modelContext: ModelContext?

    func loadGoals(context: ModelContext) {
        self.modelContext = context
        goalService.setModelContext(context)

        let goalDescriptor = FetchDescriptor<Goal>(sortBy: [SortDescriptor(\.targetDate)])
        goals = (try? context.fetch(goalDescriptor)) ?? []

        // İstatistikleri güncelle
        goalService.updateStatistics()

        // Yeni stats hesapla (NEW)
        updateStreak()
        calculateWeeklyStats()
        calculateMonthlyStats()
        todaysFocus = getTodaysFocus()
        checkAndAwardAchievements()
    }

    func loadHabits(context: ModelContext) {
        let habitDescriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        habits = (try? context.fetch(habitDescriptor)) ?? []

        // Stats güncelle (NEW)
        calculateWeeklyStats()
        calculateMonthlyStats()
        updateCombinedStats()
    }

    // MARK: - Akıllı Hedef Önerileri

    /// Tüm verilerden otomatik hedef önerileri oluştur
    func generateSmartGoalSuggestions(friends: [Friend], locationLogs: [LocationLog]) {
        goalSuggestions = goalService.generateSmartSuggestions(
            friends: friends,
            locationLogs: locationLogs,
            habits: habits
        )
    }

    /// Bir öneriyi gerçek hedefe dönüştür
    func acceptSuggestion(_ suggestion: GoalSuggestion, context: ModelContext) {
        let goal = goalService.createGoalFromSuggestion(suggestion)
        context.insert(goal)
        goals.append(goal)

        try? context.save()

        // Hatırlatıcı kur
        if goal.reminderEnabled {
            notificationService.scheduleGoalReminder(
                goalTitle: goal.title,
                daysLeft: goal.daysRemaining
            )
        }

        // Öneriyi listeden kaldır
        goalSuggestions.removeAll { $0.id == suggestion.id }

        HapticFeedback.success()
    }

    // MARK: - İstatistikler

    var statistics: GoalStatistics? {
        goalService.statistics
    }

    var motivationalMessage: String {
        goalService.getMotivationalMessage()
    }

    func addGoal(
        title: String,
        description: String,
        category: GoalCategory,
        targetDate: Date,
        context: ModelContext
    ) {
        let goal = Goal(
            title: title,
            goalDescription: description,
            category: category,
            targetDate: targetDate
        )

        context.insert(goal)
        goals.append(goal)

        try? context.save()

        // Hatırlatıcı kur
        if goal.reminderEnabled {
            notificationService.scheduleGoalReminder(
                goalTitle: title,
                daysLeft: goal.daysRemaining
            )
        }

        // Success feedback
        HapticFeedback.success()

        // Draft temizle
        DraftManager.shared.clearDraftGoal()

        print("✅ Hedef eklendi: \(title)")
    }

    func updateGoalProgress(goal: Goal, progress: Double) {
        goal.progress = min(max(progress, 0), 1.0) // 0-1 arası sınırla

        if goal.progress >= 1.0 {
            completeGoal(goal)
        }
    }

    func completeGoal(_ goal: Goal) {
        goal.isCompleted = true
        goal.progress = 1.0

        // Tebrik bildirimi
        notificationService.sendMotivationalMessage()
    }

    func deleteGoal(_ goal: Goal, context: ModelContext) {
        context.delete(goal)
        goals.removeAll { $0.id == goal.id }
        try? context.save()
    }

    // MARK: - Habits

    func addHabit(
        name: String,
        description: String,
        frequency: HabitFrequency,
        targetCount: Int,
        reminderTime: Date?,
        context: ModelContext
    ) {
        let habit = Habit(
            name: name,
            habitDescription: description,
            frequency: frequency,
            targetCount: targetCount,
            reminderTime: reminderTime
        )

        context.insert(habit)
        habits.append(habit)

        try? context.save()

        // Hatırlatıcı kur
        if let reminderTime = reminderTime {
            notificationService.scheduleHabitReminder(habitName: name, at: reminderTime)
        }

        // Success feedback
        HapticFeedback.success()

        // Draft temizle
        DraftManager.shared.clearDraftHabit()

        print("✅ Alışkanlık eklendi: \(name)")
    }

    func toggleHabitCompletion(habit: Habit, context: ModelContext) {
        if habit.isCompletedToday() {
            // Bugünkü completion'ı kaldır
            if let completion = habit.completions?.first(where: {
                Calendar.current.isDateInToday($0.completedAt)
            }) {
                context.delete(completion)
                habit.currentStreak = max(0, habit.currentStreak - 1)
            }
        } else {
            // Yeni completion ekle
            let completion = HabitCompletion(completedAt: Date())
            completion.habit = habit
            context.insert(completion)

            // Seriyi güncelle
            habit.currentStreak += 1
            if habit.currentStreak > habit.longestStreak {
                habit.longestStreak = habit.currentStreak
            }

            // Motivasyon bildirimi
            if habit.currentStreak % 7 == 0 { // Her 7 günde bir
                notificationService.sendMotivationalMessage()
            }
        }

        try? context.save()
    }

    func deleteHabit(_ habit: Habit, context: ModelContext) {
        context.delete(habit)
        habits.removeAll { $0.id == habit.id }
        try? context.save()
    }

    // Filtrelenmiş hedefler
    var activeGoals: [Goal] {
        goals.filter { !$0.isCompleted }
    }

    var completedGoals: [Goal] {
        goals.filter { $0.isCompleted }
    }

    var overdueGoals: [Goal] {
        goals.filter { $0.isOverdue }
    }

    // Aktif alışkanlıklar
    var activeHabits: [Habit] {
        habits.filter { $0.isActive }
    }

    var todaysHabits: [Habit] {
        activeHabits.filter { $0.frequency == .daily }
    }

    // MARK: - AI Functions (iOS 26+)

    @available(iOS 26.0, *)
    func loadGoalInsight(for goal: Goal) async {
        isLoadingAI[goal.id] = true

        do {
            let insight = try await goalAIService.generateInsight(for: goal)

            // Wrapper'a çevir
            goalInsights[goal.id] = GoalInsightWrapper(
                summary: insight.summary,
                strategy: insight.strategy,
                motivation: insight.motivation,
                nextSteps: insight.nextSteps,
                urgency: insight.urgency
            )
        } catch {
            print("❌ Goal insight hatası: \(error)")
        }

        isLoadingAI[goal.id] = false
    }

    @available(iOS 26.0, *)
    func loadHabitInsight(for habit: Habit) async {
        isLoadingAI[habit.id] = true

        do {
            let insight = try await habitAIService.generateInsight(for: habit)

            // Wrapper'a çevir
            habitInsights[habit.id] = HabitInsightWrapper(
                suggestion: insight.suggestion,
                trigger: insight.trigger,
                reward: insight.reward,
                encouragement: insight.encouragement
            )
        } catch {
            print("❌ Habit insight hatası: \(error)")
        }

        isLoadingAI[habit.id] = false
    }

    @available(iOS 26.0, *)
    func generateGoalSuggestion(category: GoalCategory) async -> String? {
        do {
            return try await goalAIService.suggestGoal(category: category)
        } catch {
            print("❌ Goal suggestion hatası: \(error)")
            return nil
        }
    }

    @available(iOS 26.0, *)
    func generateHabitSuggestion() async -> String? {
        do {
            return try await habitAIService.suggestHabit(userGoals: goals)
        } catch {
            print("❌ Habit suggestion hatası: \(error)")
            return nil
        }
    }

    // MARK: - Stats Calculation (NEW)

    func calculateWeeklyStats() {
        let calendar = Calendar.current
        let today = Date()

        // Goals Weekly Stats
        var dailyGoalCompletions = Array(repeating: 0, count: 7)
        var weeklyCompletedGoals = 0
        var weeklyTotalGoals = activeGoals.count
        var weeklyProgressSum = 0.0

        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }

            // Bu günde tamamlanan hedefleri say
            let completedThisDay = goals.filter { goal in
                guard goal.isCompleted else { return false }
                return calendar.isDate(goal.createdAt, inSameDayAs: date) // Basitleştirilmiş
            }.count

            dailyGoalCompletions[6 - dayOffset] = completedThisDay
            weeklyCompletedGoals += completedThisDay
        }

        // Average progress
        if !activeGoals.isEmpty {
            weeklyProgressSum = activeGoals.reduce(0.0) { $0 + $1.progress }
            weeklyProgressSum /= Double(activeGoals.count)
        }

        let weeklyCompletionRate = weeklyTotalGoals > 0 ? Double(weeklyCompletedGoals) / Double(weeklyTotalGoals) : 0.0
        let bestDay = WeeklyGoalStats.calculateBestDay(from: dailyGoalCompletions)

        weeklyGoalStats = WeeklyGoalStats(
            completionRate: weeklyCompletionRate,
            completedCount: weeklyCompletedGoals,
            totalCount: weeklyTotalGoals,
            dailyCompletions: dailyGoalCompletions,
            bestDay: bestDay,
            averageProgress: weeklyProgressSum,
            streak: currentStreak
        )

        // Habits Weekly Stats
        var dailyHabitCompletions = Array(repeating: 0, count: 7)
        var weeklyCompletedDays = 0

        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }

            var dayCompleted = false
            for habit in activeHabits {
                if let completions = habit.completions,
                   completions.contains(where: { calendar.isDate($0.completedAt, inSameDayAs: date) }) {
                    dailyHabitCompletions[6 - dayOffset] += 1
                    dayCompleted = true
                }
            }

            if dayCompleted {
                weeklyCompletedDays += 1
            }
        }

        let habitBestDay = WeeklyHabitStats.calculateBestDay(from: dailyHabitCompletions)
        let totalHabitStreak = activeHabits.reduce(0) { $0 + $1.currentStreak }

        weeklyHabitStats = WeeklyHabitStats(
            completionRate: Double(weeklyCompletedDays) / 7.0,
            completedDays: weeklyCompletedDays,
            totalHabits: activeHabits.count,
            dailyCompletions: dailyHabitCompletions,
            bestDay: habitBestDay,
            totalStreak: totalHabitStreak
        )
    }

    func calculateMonthlyStats() {
        // Goals Monthly Stats
        let completedGoalsCount = completedGoals.count
        let activeGoalsCount = activeGoals.count
        let overdueCount = overdueGoals.count

        var categoriesBreakdown: [String: Int] = [:]
        for goal in completedGoals {
            let categoryName = goal.category.displayName
            categoriesBreakdown[categoryName, default: 0] += 1
        }

        let averageProgress = activeGoals.isEmpty ? 0.0 : activeGoals.reduce(0.0) { $0 + $1.progress } / Double(activeGoals.count)

        monthlyGoalStats = MonthlyGoalStats(
            completionRate: activeGoalsCount > 0 ? Double(completedGoalsCount) / Double(activeGoalsCount + completedGoalsCount) : 0.0,
            totalCompleted: completedGoalsCount,
            totalActive: activeGoalsCount,
            categoriesBreakdown: categoriesBreakdown,
            averageProgress: averageProgress,
            overdueCount: overdueCount,
            weeklyTrend: [] // Basitleştirilmiş, gerçek hesaplama gerektirir
        )

        // Habits Monthly Stats
        let totalHabitCompletions = habits.reduce(0) { $0 + ($1.completions?.count ?? 0) }
        let averageStreak = habits.isEmpty ? 0.0 : Double(habits.reduce(0) { $0 + $1.currentStreak }) / Double(habits.count)
        let longestStreak = habits.map { $0.longestStreak }.max() ?? 0

        monthlyHabitStats = MonthlyHabitStats(
            completionRate: habits.isEmpty ? 0.0 : habits.reduce(0.0) { $0 + $1.monthlyCompletionRate } / Double(habits.count),
            totalCompletions: totalHabitCompletions,
            totalHabits: habits.count,
            averageStreak: averageStreak,
            longestStreak: longestStreak,
            weeklyTrend: []
        )
    }

    func updateCombinedStats() {
        // Bugünkü tamamlanan/toplam
        let calendar = Calendar.current
        let today = Date()

        var todayCompleted = 0
        var todayTotal = 0

        // Bugünkü hedefler (deadline bugün olanlar)
        let todaysGoals = activeGoals.filter { calendar.isDateInToday($0.targetDate) }
        todayTotal += todaysGoals.count
        todayCompleted += todaysGoals.filter { $0.isCompleted }.count

        // Bugünkü alışkanlıklar
        let todaysHabits = todaysHabits
        todayTotal += todaysHabits.count
        todayCompleted += todaysHabits.filter { $0.isCompletedToday() }.count

        // Motivasyon mesajı
        let motivationMessage = generateMotivationMessage(
            completionRate: Double(todayCompleted) / max(Double(todayTotal), 1.0),
            streak: currentStreak
        )

        combinedStats = CombinedStats(
            todayCompleted: todayCompleted,
            todayTotal: todayTotal,
            weeklyCompletionRate: weeklyGoalStats.completionRate,
            currentStreak: currentStreak,
            motivationMessage: motivationMessage
        )
    }

    func updateStreak() {
        // Basitleştirilmiş streak hesaplama
        // Gerçek implementasyonda son 30 günü kontrol etmeli
        let calendar = Calendar.current
        var streak = 0
        var checkDate = Date()

        for _ in 0..<30 {
            let dayHasActivity = goals.contains { goal in
                calendar.isDate(goal.createdAt, inSameDayAs: checkDate) && goal.isCompleted
            } || habits.contains { habit in
                habit.completions?.contains(where: {
                    calendar.isDate($0.completedAt, inSameDayAs: checkDate)
                }) ?? false
            }

            if dayHasActivity {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }

        currentStreak = streak
    }

    func getTodaysFocus() -> [Goal] {
        // Priority score'a göre sırala, en yüksek 3'ü al
        activeGoals.sorted { $0.focusScore > $1.focusScore }.prefix(3).map { $0 }
    }

    func checkAndAwardAchievements() {
        // Yeni achievement'ları kontrol et
        let newAchievements = achievementService.checkNewAchievements(
            goals: goals,
            habits: habits,
            currentStreak: currentStreak
        )

        if !newAchievements.isEmpty {
            newlyEarnedAchievements = newAchievements
            showingAchievementCelebration = true

            // Celebration notification
            notificationService.sendMotivationalMessage()
            HapticFeedback.success()
        }

        // Tüm achievement'ları güncelle
        achievements = achievementService.getAllAchievements(
            goals: goals,
            habits: habits,
            currentStreak: currentStreak
        )
    }

    // MARK: - Quick Actions (NEW)

    func quickCompleteGoal(_ goal: Goal) {
        goal.isCompleted = true
        goal.progress = 1.0
        notificationService.sendMotivationalMessage()
        HapticFeedback.success()

        // Stats ve achievements güncelle
        calculateWeeklyStats()
        calculateMonthlyStats()
        checkAndAwardAchievements()
    }

    func updateMilestone(_ milestone: GoalMilestone, isCompleted: Bool) {
        if isCompleted {
            milestone.complete()
        } else {
            milestone.uncomplete()
        }

        // Milestone tamamlandıysa goal progress'i güncelle
        if let goal = milestone.goal {
            goal.progress = goal.milestoneProgress
        }
    }

    // MARK: - Helpers

    private func generateMotivationMessage(completionRate: Double, streak: Int) -> String {
        if streak >= 30 {
            return "Efsanesin! 30 gün seri! 🔥"
        } else if streak >= 7 {
            return "Harika gidiyorsun! 7 gün seri! 🌟"
        } else if completionRate >= 0.8 {
            return "Bugün çok üretkensin! 💪"
        } else if completionRate >= 0.5 {
            return "İyi bir başlangıç! Devam et! 🚀"
        } else {
            return "Hadi başlayalım! Bugün yeni bir gün! ☀️"
        }
    }
}

// MARK: - Wrapper Types (iOS 17+ compat)

struct GoalInsightWrapper: Codable {
    let summary: String
    let strategy: String
    let motivation: String
    let nextSteps: String
    let urgency: String
}

struct HabitInsightWrapper: Codable {
    let suggestion: String
    let trigger: String
    let reward: String
    let encouragement: String
}

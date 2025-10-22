//
//  AICoordinator.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//

import Foundation
import FoundationModels

/// Tüm AI servislerini merkezi olarak yöneten koordinatör
@available(iOS 26.0, *)
@Observable
class AICoordinator {
    static let shared = AICoordinator()

    // AI Services
    let goalService = GoalAIService.shared
    let habitService = HabitAIService.shared
    let activityService = ActivityAIService.shared
    let dashboardService = DashboardAIService.shared
    let friendService = FriendAIService.shared

    // Cache
    private var cache: [String: (data: Any, timestamp: Date)] = [:]
    private let cacheExpiration: TimeInterval = 300 // 5 dakika

    // Rate Limiting
    private var lastRequestTimes: [String: Date] = [:]
    private let rateLimitInterval: TimeInterval = 2.0 // 2 saniye

    // State
    var isProcessing: Bool = false
    var lastError: Error?

    private init() {}

    // MARK: - Caching

    /// Cache'den veri al (varsa ve geçerliyse)
    func getCached<T>(key: String) -> T? {
        guard let cached = cache[key] else { return nil }

        // Expiration kontrolü
        if Date().timeIntervalSince(cached.timestamp) > cacheExpiration {
            cache.removeValue(forKey: key)
            return nil
        }

        return cached.data as? T
    }

    /// Cache'e veri kaydet
    func setCached<T>(key: String, data: T) {
        cache[key] = (data, Date())
    }

    /// Cache'i temizle
    func clearCache() {
        cache.removeAll()
    }

    /// Belirli bir key'in cache'ini temizle
    func clearCache(for key: String) {
        cache.removeValue(forKey: key)
    }

    // MARK: - Rate Limiting

    /// Rate limit kontrolü - true dönerse istek yapılabilir
    func canMakeRequest(for key: String) -> Bool {
        guard let lastRequest = lastRequestTimes[key] else {
            lastRequestTimes[key] = Date()
            return true
        }

        let timeSinceLastRequest = Date().timeIntervalSince(lastRequest)
        if timeSinceLastRequest >= rateLimitInterval {
            lastRequestTimes[key] = Date()
            return true
        }

        return false
    }

    /// Rate limit bekleme süresi (saniye)
    func getRateLimitWaitTime(for key: String) -> TimeInterval {
        guard let lastRequest = lastRequestTimes[key] else {
            return 0
        }

        let timeSinceLastRequest = Date().timeIntervalSince(lastRequest)
        let remaining = rateLimitInterval - timeSinceLastRequest

        return max(0, remaining)
    }

    // MARK: - Toplu İşlemler

    /// Tüm servislerin günlük insight'larını al
    func generateAllDailyInsights(
        goals: [Goal],
        habits: [Habit],
        friends: [Friend],
        locations: [LocationLog],
        activities: [ActivitySuggestion]
    ) async throws -> ComprehensiveInsight {
        isProcessing = true
        defer { isProcessing = false }

        // Cache kontrolü
        let cacheKey = "daily_insights_\(Date().formatted(.dateTime.year().month().day()))"
        if let cached: ComprehensiveInsight = getCached(key: cacheKey) {
            print("✅ Cache'den günlük insight alındı")
            return cached
        }

        // Rate limit kontrolü
        guard canMakeRequest(for: "comprehensive_insight") else {
            let waitTime = getRateLimitWaitTime(for: "comprehensive_insight")
            throw AICoordinatorError.rateLimited(waitTime: waitTime)
        }

        async let dailyInsight = dashboardService.generateDailyInsight(
            goals: goals,
            habits: habits,
            friends: friends,
            recentLocations: locations,
            recentActivities: activities
        )

        async let topGoalInsight: GoalInsight? = {
            guard let topGoal = goals.first(where: { !$0.isCompleted }) else { return nil }
            return try? await goalService.generateInsight(for: topGoal)
        }()

        async let topHabitInsight: HabitInsight? = {
            guard let topHabit = habits.first(where: { $0.isActive }) else { return nil }
            return try? await habitService.generateInsight(for: topHabit)
        }()

        async let friendsSummary: String? = {
            let needsContact = friends.filter { $0.needsContact }
            guard !needsContact.isEmpty else { return nil }
            return "\(needsContact.count) arkadaşınla iletişim kurman gerekiyor"
        }()

        let results = try await (
            daily: dailyInsight,
            goal: topGoalInsight,
            habit: topHabitInsight,
            friends: friendsSummary
        )

        let comprehensive = ComprehensiveInsight(
            daily: results.daily,
            topGoal: results.goal,
            topHabit: results.habit,
            friendsSummary: results.friends
        )

        // Cache'e kaydet
        setCached(key: cacheKey, data: comprehensive)

        return comprehensive
    }

    /// Öncelikli aksiyonları hesapla
    func calculatePriorities(
        goals: [Goal],
        habits: [Habit],
        friends: [Friend]
    ) -> [PriorityAction] {
        var priorities: [PriorityAction] = []

        // Overdue goals
        let overdueGoals = goals.filter { $0.isOverdue && !$0.isCompleted }
        for goal in overdueGoals.prefix(2) {
            priorities.append(PriorityAction(
                title: "Gecikmiş hedef: \(goal.title)",
                description: "\(abs(goal.daysRemaining)) gün gecikmiş",
                priority: .high,
                type: .goal,
                relatedId: goal.id
            ))
        }

        // Near deadline goals
        let nearDeadline = goals.filter { $0.daysRemaining <= 3 && !$0.isCompleted && !$0.isOverdue }
        for goal in nearDeadline.prefix(1) {
            priorities.append(PriorityAction(
                title: "Yaklaşan hedef: \(goal.title)",
                description: "\(goal.daysRemaining) gün kaldı",
                priority: .medium,
                type: .goal,
                relatedId: goal.id
            ))
        }

        // Habits to complete today
        let todayHabits = habits.filter { $0.isActive && !$0.isCompletedToday() }
        if !todayHabits.isEmpty {
            priorities.append(PriorityAction(
                title: "Bugünkü alışkanlıklar",
                description: "\(todayHabits.count) alışkanlık bekliyor",
                priority: .medium,
                type: .habit,
                relatedId: nil
            ))
        }

        // Broken streaks
        let brokenStreaks = habits.filter { $0.currentStreak == 0 && $0.longestStreak > 0 }
        if let habit = brokenStreaks.first {
            priorities.append(PriorityAction(
                title: "Seri kırıldı: \(habit.name)",
                description: "Yeniden başla!",
                priority: .medium,
                type: .habit,
                relatedId: habit.id
            ))
        }

        // Friends needing contact
        let needsContact = friends.filter { $0.needsContact }
        if !needsContact.isEmpty {
            let topFriend = needsContact.max(by: { $0.daysOverdue < $1.daysOverdue })!
            priorities.append(PriorityAction(
                title: "İletişim gerekli: \(topFriend.name)",
                description: "\(topFriend.daysOverdue) gündür görüşülmedi",
                priority: topFriend.isImportant ? .high : .medium,
                type: .friend,
                relatedId: topFriend.id
            ))
        }

        // Sort by priority
        return priorities.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }

    // MARK: - Error Handling

    func handleError(_ error: Error) {
        lastError = error
        print("❌ AICoordinator hatası: \(error)")
    }

    func clearError() {
        lastError = nil
    }
}

// MARK: - Supporting Types

@available(iOS 26.0, *)
struct ComprehensiveInsight: Codable {
    let daily: DailyInsight
    let topGoal: GoalInsight?
    let topHabit: HabitInsight?
    let friendsSummary: String?
}

struct PriorityAction: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let priority: Priority
    let type: ActionType
    let relatedId: UUID?

    enum Priority: Int, Codable {
        case low = 1
        case medium = 2
        case high = 3

        var displayName: String {
            switch self {
            case .low: return "Düşük"
            case .medium: return "Orta"
            case .high: return "Yüksek"
            }
        }

        var color: String {
            switch self {
            case .low: return "blue"
            case .medium: return "orange"
            case .high: return "red"
            }
        }
    }

    enum ActionType: String, Codable {
        case goal = "goal"
        case habit = "habit"
        case friend = "friend"
        case activity = "activity"
    }
}

enum AICoordinatorError: LocalizedError {
    case rateLimited(waitTime: TimeInterval)
    case cacheError
    case serviceUnavailable

    var errorDescription: String? {
        switch self {
        case .rateLimited(let waitTime):
            return "Çok fazla istek yapıldı. Lütfen \(Int(waitTime)) saniye bekleyin."
        case .cacheError:
            return "Cache hatası oluştu."
        case .serviceUnavailable:
            return "AI servisi şu anda kullanılamıyor."
        }
    }
}

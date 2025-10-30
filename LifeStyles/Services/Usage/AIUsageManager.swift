//
//  AIUsageManager.swift
//  LifeStyles
//
//  AI Usage Tracking & Limits
//  Created by Claude on 22.10.2025.
//

import Foundation

@Observable
class AIUsageManager {
    static let shared = AIUsageManager()

    // MARK: - Constants

    private let freeMessageLimit = 5  // Free tier: 5 mesaj/gün
    private let freeDailyInsightLimit = 1  // Free tier: 1 daily insight/gün
    private let freeActivitySuggestionLimit = 3  // Free tier: 3 aktivite önerisi/gün
    private let freeGoalSuggestionLimit = 3  // Free tier: 3 hedef önerisi/gün

    // UserDefaults keys
    private let usageCountKey = "ai_usage_count"
    private let usageDateKey = "ai_usage_date"
    private let totalMessagesKey = "ai_total_messages"

    // Daily Insight keys
    private let dailyInsightCountKey = "ai_daily_insight_count"

    // Activity/Goal Suggestion keys
    private let activitySuggestionCountKey = "ai_activity_suggestion_count"
    private let goalSuggestionCountKey = "ai_goal_suggestion_count"

    // MARK: - Published State

    private(set) var todayMessageCount: Int = 0
    private(set) var totalMessagesAllTime: Int = 0
    private(set) var todayDailyInsightCount: Int = 0
    private(set) var todayActivitySuggestionCount: Int = 0
    private(set) var todayGoalSuggestionCount: Int = 0
    private(set) var lastResetDate: Date?

    private init() {
        loadUsageData()
        checkAndResetIfNeeded()
    }

    // MARK: - Public Methods

    /// Check if user can send a message (free tier check)
    func canSendMessage(isPremium: Bool) -> Bool {
        if isPremium {
            return true  // Premium users have unlimited
        }

        checkAndResetIfNeeded()
        return todayMessageCount < freeMessageLimit
    }

    /// Get remaining messages for today (free tier)
    func getRemainingMessages(isPremium: Bool) -> Int {
        if isPremium {
            return Int.max  // Unlimited
        }

        checkAndResetIfNeeded()
        return max(0, freeMessageLimit - todayMessageCount)
    }

    /// Track a sent message
    func trackMessage() {
        checkAndResetIfNeeded()

        todayMessageCount += 1
        totalMessagesAllTime += 1

        saveUsageData()

        print("📊 AI Usage: \(todayMessageCount)/\(freeMessageLimit) today, \(totalMessagesAllTime) total")
    }

    /// Force reset usage (for testing)
    func resetUsage() {
        todayMessageCount = 0
        todayDailyInsightCount = 0
        todayActivitySuggestionCount = 0
        todayGoalSuggestionCount = 0
        lastResetDate = Date()
        saveUsageData()
        print("🔄 AI Usage reset")
    }

    /// Get usage stats
    func getUsageStats() -> UsageStats {
        checkAndResetIfNeeded()

        return UsageStats(
            todayCount: todayMessageCount,
            dailyLimit: freeMessageLimit,
            totalAllTime: totalMessagesAllTime,
            lastResetDate: lastResetDate ?? Date()
        )
    }

    // MARK: - Daily Insight Methods

    /// Check if user can generate daily insight
    func canGenerateDailyInsight(isPremium: Bool) -> Bool {
        if isPremium {
            return true  // Premium users have unlimited
        }

        checkAndResetIfNeeded()
        return todayDailyInsightCount < freeDailyInsightLimit
    }

    /// Track daily insight generation
    func trackDailyInsight() {
        checkAndResetIfNeeded()
        todayDailyInsightCount += 1
        saveUsageData()
        print("📊 Daily Insight Usage: \(todayDailyInsightCount)/\(freeDailyInsightLimit) today")
    }

    // MARK: - Activity Suggestion Methods

    /// Check if user can get activity suggestion
    func canGetActivitySuggestion(isPremium: Bool) -> Bool {
        if isPremium {
            return true
        }

        checkAndResetIfNeeded()
        return todayActivitySuggestionCount < freeActivitySuggestionLimit
    }

    /// Track activity suggestion
    func trackActivitySuggestion() {
        checkAndResetIfNeeded()
        todayActivitySuggestionCount += 1
        saveUsageData()
        print("📊 Activity Suggestion Usage: \(todayActivitySuggestionCount)/\(freeActivitySuggestionLimit) today")
    }

    // MARK: - Goal Suggestion Methods

    /// Check if user can get goal suggestion
    func canGetGoalSuggestion(isPremium: Bool) -> Bool {
        if isPremium {
            return true
        }

        checkAndResetIfNeeded()
        return todayGoalSuggestionCount < freeGoalSuggestionLimit
    }

    /// Track goal suggestion
    func trackGoalSuggestion() {
        checkAndResetIfNeeded()
        todayGoalSuggestionCount += 1
        saveUsageData()
        print("📊 Goal Suggestion Usage: \(todayGoalSuggestionCount)/\(freeGoalSuggestionLimit) today")
    }

    // MARK: - Private Methods

    private func loadUsageData() {
        todayMessageCount = UserDefaults.standard.integer(forKey: usageCountKey)
        totalMessagesAllTime = UserDefaults.standard.integer(forKey: totalMessagesKey)
        todayDailyInsightCount = UserDefaults.standard.integer(forKey: dailyInsightCountKey)
        todayActivitySuggestionCount = UserDefaults.standard.integer(forKey: activitySuggestionCountKey)
        todayGoalSuggestionCount = UserDefaults.standard.integer(forKey: goalSuggestionCountKey)

        if let savedDate = UserDefaults.standard.object(forKey: usageDateKey) as? Date {
            lastResetDate = savedDate
        }
    }

    private func saveUsageData() {
        UserDefaults.standard.set(todayMessageCount, forKey: usageCountKey)
        UserDefaults.standard.set(totalMessagesAllTime, forKey: totalMessagesKey)
        UserDefaults.standard.set(todayDailyInsightCount, forKey: dailyInsightCountKey)
        UserDefaults.standard.set(todayActivitySuggestionCount, forKey: activitySuggestionCountKey)
        UserDefaults.standard.set(todayGoalSuggestionCount, forKey: goalSuggestionCountKey)
        UserDefaults.standard.set(lastResetDate ?? Date(), forKey: usageDateKey)
    }

    private func checkAndResetIfNeeded() {
        guard let lastReset = lastResetDate else {
            // İlk kullanım
            lastResetDate = Date()
            saveUsageData()
            return
        }

        let calendar = Calendar.current

        // Bugün mü?
        if calendar.isDateInToday(lastReset) {
            return  // Aynı gün, reset yok
        }

        // Farklı gün, reset et
        print("🔄 AI Usage reset - new day")
        todayMessageCount = 0
        todayDailyInsightCount = 0
        todayActivitySuggestionCount = 0
        todayGoalSuggestionCount = 0
        lastResetDate = Date()
        saveUsageData()
    }
}

// MARK: - Usage Stats Model

struct UsageStats: Codable {
    let todayCount: Int
    let dailyLimit: Int
    let totalAllTime: Int
    let lastResetDate: Date

    var remainingToday: Int {
        max(0, dailyLimit - todayCount)
    }

    var usagePercentage: Double {
        min(1.0, Double(todayCount) / Double(dailyLimit))
    }

    var isLimitReached: Bool {
        todayCount >= dailyLimit
    }
}

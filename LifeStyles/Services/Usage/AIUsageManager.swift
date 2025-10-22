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

    // UserDefaults keys
    private let usageCountKey = "ai_usage_count"
    private let usageDateKey = "ai_usage_date"
    private let totalMessagesKey = "ai_total_messages"

    // MARK: - Published State

    private(set) var todayMessageCount: Int = 0
    private(set) var totalMessagesAllTime: Int = 0
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

    // MARK: - Private Methods

    private func loadUsageData() {
        todayMessageCount = UserDefaults.standard.integer(forKey: usageCountKey)
        totalMessagesAllTime = UserDefaults.standard.integer(forKey: totalMessagesKey)

        if let savedDate = UserDefaults.standard.object(forKey: usageDateKey) as? Date {
            lastResetDate = savedDate
        }
    }

    private func saveUsageData() {
        UserDefaults.standard.set(todayMessageCount, forKey: usageCountKey)
        UserDefaults.standard.set(totalMessagesAllTime, forKey: totalMessagesKey)
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

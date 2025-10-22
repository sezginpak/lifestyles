//
//  NotificationAnalytics.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Notification performance tracking and analytics
//

import Foundation

// MARK: - Analytics Statistics

struct NotificationStats: Codable {
    let totalSent: Int
    let totalOpened: Int
    let totalActions: Int
    let openRate: Double
    let actionRate: Double
    let categoryBreakdown: [String: CategoryStats]
    let weeklyTrend: [DailyStats]

    var formattedOpenRate: String {
        return String(format: "%.1f%%", openRate * 100)
    }

    var formattedActionRate: String {
        return String(format: "%.1f%%", actionRate * 100)
    }
}

struct CategoryStats: Codable {
    let categoryName: String
    let sent: Int
    let opened: Int
    let actions: Int

    var openRate: Double {
        guard sent > 0 else { return 0.0 }
        return Double(opened) / Double(sent)
    }
}

struct DailyStats: Codable {
    let date: Date
    let sent: Int
    let opened: Int

    var openRate: Double {
        guard sent > 0 else { return 0.0 }
        return Double(opened) / Double(sent)
    }
}

// MARK: - Notification Analytics

@Observable
class NotificationAnalytics {

    static let shared = NotificationAnalytics()

    private let defaults = UserDefaults.standard

    private init() {}

    // MARK: - Statistics

    /// Genel istatistikleri al
    func getOverallStats() -> NotificationStats {
        let totalSent = defaults.integer(forKey: UserDefaults.AnalyticsKeys.totalNotificationsSent)
        let totalOpened = defaults.integer(forKey: UserDefaults.AnalyticsKeys.totalNotificationsOpened)
        let totalActions = defaults.integer(forKey: UserDefaults.AnalyticsKeys.totalActionsExecuted)

        let openRate = totalSent > 0 ? Double(totalOpened) / Double(totalSent) : 0.0
        let actionRate = totalOpened > 0 ? Double(totalActions) / Double(totalOpened) : 0.0

        let categoryBreakdown = getCategoryBreakdown()
        let weeklyTrend = getWeeklyTrend()

        return NotificationStats(
            totalSent: totalSent,
            totalOpened: totalOpened,
            totalActions: totalActions,
            openRate: openRate,
            actionRate: actionRate,
            categoryBreakdown: categoryBreakdown,
            weeklyTrend: weeklyTrend
        )
    }

    /// Kategori bazlı istatistikler
    func getCategoryBreakdown() -> [String: CategoryStats] {
        let history = defaults.getNotificationHistory()

        var breakdown: [String: CategoryStats] = [:]

        for entry in history {
            let category = entry.category
            var stats = breakdown[category] ?? CategoryStats(categoryName: category, sent: 0, opened: 0, actions: 0)

            var newStats = CategoryStats(
                categoryName: category,
                sent: stats.sent + 1,
                opened: stats.opened + (entry.openedAt != nil ? 1 : 0),
                actions: stats.actions + (entry.actionTaken != nil ? 1 : 0)
            )

            breakdown[category] = newStats
        }

        return breakdown
    }

    /// Haftalık trend
    func getWeeklyTrend() -> [DailyStats] {
        let history = defaults.getNotificationHistory()
        let calendar = Calendar.current

        // Son 7 gün
        let today = calendar.startOfDay(for: Date())
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!

        var dailyStats: [Date: DailyStats] = [:]

        // Son 7 günü initialize et
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                dailyStats[date] = DailyStats(date: date, sent: 0, opened: 0)
            }
        }

        // History'den verileri grupla
        for entry in history {
            let dayStart = calendar.startOfDay(for: entry.sentAt)

            guard dayStart >= weekAgo else { continue }

            var stats = dailyStats[dayStart] ?? DailyStats(date: dayStart, sent: 0, opened: 0)

            stats = DailyStats(
                date: dayStart,
                sent: stats.sent + 1,
                opened: stats.opened + (entry.openedAt != nil ? 1 : 0)
            )

            dailyStats[dayStart] = stats
        }

        // Tarihe göre sırala
        return dailyStats.values.sorted { $0.date < $1.date }
    }

    // MARK: - Best Performing Categories

    /// En iyi performans gösteren kategoriler
    func getBestPerformingCategories(limit: Int = 5) -> [CategoryStats] {
        let breakdown = getCategoryBreakdown()

        return breakdown.values
            .filter { $0.sent >= 3 } // En az 3 gönderim olmalı
            .sorted { $0.openRate > $1.openRate }
            .prefix(limit)
            .map { $0 }
    }

    /// En kötü performans gösteren kategoriler
    func getWorstPerformingCategories(limit: Int = 5) -> [CategoryStats] {
        let breakdown = getCategoryBreakdown()

        return breakdown.values
            .filter { $0.sent >= 3 }
            .sorted { $0.openRate < $1.openRate }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Time Analysis

    /// En iyi saatleri analiz et (en çok açılan bildirim saatleri)
    func getBestHours() -> [Int] {
        let history = defaults.getNotificationHistory()
        let calendar = Calendar.current

        var hourCounts: [Int: (opened: Int, total: Int)] = [:]

        for entry in history {
            let hour = calendar.component(.hour, from: entry.sentAt)

            var counts = hourCounts[hour] ?? (opened: 0, total: 0)
            counts.total += 1
            if entry.openedAt != nil {
                counts.opened += 1
            }
            hourCounts[hour] = counts
        }

        // Open rate'e göre sırala
        let sortedHours = hourCounts.sorted { (hour1, hour2) in
            let rate1 = Double(hour1.value.opened) / Double(hour1.value.total)
            let rate2 = Double(hour2.value.opened) / Double(hour2.value.total)
            return rate1 > rate2
        }

        return sortedHours.prefix(5).map { $0.key }
    }

    // MARK: - Performance Score

    /// Genel performans skoru (0-100)
    func getPerformanceScore() -> Double {
        let stats = getOverallStats()

        // Metrikler
        let openRateWeight = 0.4
        let actionRateWeight = 0.3
        let volumeWeight = 0.2
        let consistencyWeight = 0.1

        // Open rate skoru (0-100)
        let openRateScore = stats.openRate * 100

        // Action rate skoru (0-100)
        let actionRateScore = stats.actionRate * 100

        // Volume skoru (0-100, max 50 bildirim/gün hedefi)
        let avgDailyVolume = Double(stats.totalSent) / 7.0
        let volumeScore = min(avgDailyVolume / 50.0 * 100, 100)

        // Consistency skoru (haftalık tutarlılık)
        let consistencyScore = calculateConsistencyScore(weeklyTrend: stats.weeklyTrend)

        // Weighted toplam
        let totalScore = (openRateScore * openRateWeight) +
                        (actionRateScore * actionRateWeight) +
                        (volumeScore * volumeWeight) +
                        (consistencyScore * consistencyWeight)

        return totalScore
    }

    private func calculateConsistencyScore(weeklyTrend: [DailyStats]) -> Double {
        guard weeklyTrend.count > 1 else { return 0.0 }

        // Günlük varyansı hesapla
        let openRates = weeklyTrend.map { $0.openRate }
        let avgOpenRate = openRates.reduce(0.0, +) / Double(openRates.count)

        let variance = openRates.map { pow($0 - avgOpenRate, 2) }.reduce(0.0, +) / Double(openRates.count)
        let stdDev = sqrt(variance)

        // Düşük standard deviation = yüksek tutarlılık
        let consistencyScore = max(0, 100 - (stdDev * 1000)) // Normalize

        return consistencyScore
    }

    // MARK: - Recommendations

    /// İyileştirme önerileri
    func getRecommendations() -> [String] {
        var recommendations: [String] = []

        let stats = getOverallStats()

        // Open rate düşükse
        if stats.openRate < 0.3 {
            recommendations.append("📊 Open rate düşük (%\(Int(stats.openRate * 100))). Bildirim zamanlamasını optimize edin.")
        }

        // Action rate düşükse
        if stats.actionRate < 0.2 {
            recommendations.append("🎯 Action rate düşük (%\(Int(stats.actionRate * 100))). Bildirim içeriğini daha actionable yapın.")
        }

        // En kötü kategoriyi bul
        if let worstCategory = getWorstPerformingCategories(limit: 1).first {
            if worstCategory.openRate < 0.2 {
                recommendations.append("⚠️ '\(worstCategory.categoryName)' kategorisi düşük performans gösteriyor. İçeriği gözden geçirin.")
            }
        }

        // Günlük limit kontrolü
        let avgDaily = Double(stats.totalSent) / 7.0
        if avgDaily > 40 {
            recommendations.append("🔔 Günlük bildirim sayısı yüksek (\(Int(avgDaily))). Kullanıcıları rahatsız edebilir.")
        }

        // Haftalık trend kontrolü
        let recentTrend = stats.weeklyTrend.suffix(3)
        let avgRecentOpenRate = recentTrend.map { $0.openRate }.reduce(0.0, +) / 3.0
        if avgRecentOpenRate < stats.openRate * 0.7 {
            recommendations.append("📉 Son günlerde engagement düşüyor. Stratejinizi gözden geçirin.")
        }

        if recommendations.isEmpty {
            recommendations.append("✅ Bildirim performansı iyi görünüyor! Devam edin.")
        }

        return recommendations
    }

    // MARK: - Debug Info

    /// Debug bilgisi göster
    func printDebugInfo() {
        let stats = getOverallStats()

        print("""

        📊 NOTIFICATION ANALYTICS
        ========================
        Total Sent: \(stats.totalSent)
        Total Opened: \(stats.totalOpened)
        Total Actions: \(stats.totalActions)
        Open Rate: \(stats.formattedOpenRate)
        Action Rate: \(stats.formattedActionRate)
        Performance Score: \(Int(getPerformanceScore()))

        Best Hours: \(getBestHours())

        Recommendations:
        \(getRecommendations().joined(separator: "\n"))

        """)
    }

    // MARK: - Reset

    /// Tüm analytics verilerini sıfırla (test için)
    func resetAllAnalytics() {
        defaults.set(0, forKey: UserDefaults.AnalyticsKeys.totalNotificationsSent)
        defaults.set(0, forKey: UserDefaults.AnalyticsKeys.totalNotificationsOpened)
        defaults.set(0, forKey: UserDefaults.AnalyticsKeys.totalActionsExecuted)
        defaults.removeObject(forKey: UserDefaults.AnalyticsKeys.notificationHistory)

        print("🗑️ Tüm notification analytics sıfırlandı")
    }
}

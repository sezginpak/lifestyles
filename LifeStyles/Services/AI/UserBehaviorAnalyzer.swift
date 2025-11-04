//
//  UserBehaviorAnalyzer.swift
//  LifeStyles
//
//  Analyzes user behavior and learns notification preferences
//  Kullanıcı davranışını analiz edip bildirim tercihlerini öğrenir
//

import Foundation
import SwiftData

@Observable
class UserBehaviorAnalyzer {
    static let shared = UserBehaviorAnalyzer()

    // Model context (SwiftData)
    private var modelContext: ModelContext?

    // In-memory cache
    private var timingCache: [String: NotificationTiming] = [:]

    private init() {}

    // MARK: - Setup

    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        loadTimings()
    }

    // MARK: - Learning & Recording

    /// Bildirim gönderildiğinde kaydet
    func recordNotificationSent(category: String) {
        let timing = getOrCreateTiming(for: category)
        timing.recordNotificationSent()
        saveTiming(timing)

        print("📊 Bildirim kaydedildi: \(category)")
    }

    /// Bildirim açıldığında kaydet
    func recordNotificationOpened(
        category: String,
        sentAt: Date,
        openedAt: Date = Date()
    ) {
        let timing = getOrCreateTiming(for: category)
        timing.recordNotificationOpened(sentAt: sentAt, openedAt: openedAt)
        saveTiming(timing)

        // Analytics log
        let timeToOpen = openedAt.timeIntervalSince(sentAt)
        print("✅ Bildirim açıldı: \(category) - \(String(format: "%.1f", timeToOpen))s sonra")
        print("   Open rate: \(String(format: "%.1f", timing.averageOpenRate * 100))%")
    }

    /// Bildirim dismiss edildiğinde kaydet
    func recordNotificationDismissed(
        category: String,
        sentAt: Date,
        dismissedAt: Date = Date()
    ) {
        let timing = getOrCreateTiming(for: category)
        timing.recordNotificationDismissed(sentAt: sentAt, dismissedAt: dismissedAt)
        saveTiming(timing)

        print("❌ Bildirim kapatıldı: \(category)")
    }

    /// Bildirimde aksiyon alındığında kaydet
    func recordNotificationAction(category: String) {
        let timing = getOrCreateTiming(for: category)
        timing.recordAction()
        saveTiming(timing)

        print("⚡ Bildirim aksiyonu: \(category)")
    }

    // MARK: - Predictions

    /// En iyi gönderim zamanını tahmin et (sonraki 24 saat)
    func predictBestTime(for category: String, within hours: Int = 24) -> Date? {
        let timing = getOrCreateTiming(for: category)

        guard timing.isModelReady else {
            print("⚠️ Model henüz hazır değil: \(category)")
            return getDefaultBestTime(for: category)
        }

        if let bestTime = timing.predictBestTime(within: hours) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            print("🎯 Tahmin edilen en iyi zaman: \(formatter.string(from: bestTime))")
            return bestTime
        }

        return getDefaultBestTime(for: category)
    }

    /// Belirli saat aralığında en iyi saati tahmin et
    func predictBestHour(
        for category: String,
        between startHour: Int,
        and endHour: Int
    ) -> Int? {
        let timing = getOrCreateTiming(for: category)

        guard timing.isModelReady else {
            return getDefaultHour(for: category)
        }

        return timing.predictBestTime(between: startHour, and: endHour)
    }

    /// Şu an bildirim göndermek için uygun mu?
    func isGoodTimeNow(for category: String) -> Bool {
        let timing = getOrCreateTiming(for: category)

        // Model hazır değilse varsayılan kurallara göre değerlendir
        guard timing.isModelReady else {
            return isDefaultGoodTime(for: category)
        }

        // ML model'e göre değerlendir
        return timing.isOptimalTimeNow
    }

    /// Engagement skoru al
    func getEngagementScore(for category: String) -> Double {
        let timing = getOrCreateTiming(for: category)
        return timing.engagementScore
    }

    /// Tüm kategoriler için performans raporu
    func getPerformanceReport() -> [String: PerformanceMetrics] {
        var report: [String: PerformanceMetrics] = [:]

        for (category, timing) in timingCache {
            report[category] = PerformanceMetrics(
                totalSent: timing.totalNotificationsSent,
                totalOpened: timing.totalNotificationsOpened,
                openRate: timing.averageOpenRate,
                engagementScore: timing.engagementScore,
                optimalHours: timing.optimalHours,
                isModelReady: timing.isModelReady
            )
        }

        return report
    }

    // MARK: - Timing Management

    private func getOrCreateTiming(for category: String) -> NotificationTiming {
        // Cache'de var mı kontrol et
        if let cached = timingCache[category] {
            return cached
        }

        // SwiftData'dan yükle
        if let context = modelContext {
            let descriptor = FetchDescriptor<NotificationTiming>(
                predicate: #Predicate { $0.category == category }
            )

            if let existing = try? context.fetch(descriptor).first {
                timingCache[category] = existing
                return existing
            }

            // Yoksa yeni oluştur
            let newTiming = NotificationTiming(category: category)
            context.insert(newTiming)
            try? context.save()
            timingCache[category] = newTiming
            return newTiming
        }

        // Context yoksa sadece cache'de tut
        let newTiming = NotificationTiming(category: category)
        timingCache[category] = newTiming
        return newTiming
    }

    private func saveTiming(_ timing: NotificationTiming) {
        // Cache'i güncelle
        timingCache[timing.category] = timing

        // SwiftData'ya kaydet
        if let context = modelContext {
            try? context.save()
        }
    }

    private func loadTimings() {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<NotificationTiming>()
        if let timings = try? context.fetch(descriptor) {
            for timing in timings {
                timingCache[timing.category] = timing
            }
            print("✅ \(timings.count) timing kaydı yüklendi")
        }
    }

    // MARK: - Default Behavior

    private func getDefaultBestTime(for category: String) -> Date? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())

        let defaultHour = getDefaultHour(for: category) ?? 9
        components.hour = defaultHour
        components.minute = 0

        return calendar.date(from: components)
    }

    private func getDefaultHour(for category: String) -> Int? {
        // Kategori bazlı varsayılan optimal saatler
        switch category.lowercased() {
        case "contact", "contact_reminder":
            return [9, 12, 15, 18].randomElement() // Sabah, öğle, öğleden sonra, akşam

        case "goal", "goal_reminder":
            return 9 // Sabah motivasyon

        case "habit", "habit_reminder":
            return 20 // Akşam

        case "activity", "activity_suggestion":
            return [14, 15, 16].randomElement() // Öğleden sonra

        case "motivation":
            return 8 // Sabah erken

        case "streak", "streak_warning":
            return 21 // Akşam geç (son şans)

        default:
            return 12 // Öğle vakti
        }
    }

    private func isDefaultGoodTime(for category: String) -> Bool {
        let hour = Calendar.current.component(.hour, from: Date())

        // Gece yarısı - sabah erken asla
        if hour < 8 || hour >= 22 {
            return false
        }

        // Kategori bazlı kontrol
        switch category.lowercased() {
        case "contact", "contact_reminder":
            return hour >= 9 && hour < 21

        case "goal", "goal_reminder":
            return hour >= 8 && hour < 12 // Sabahları

        case "habit", "habit_reminder":
            return hour >= 19 && hour < 22 // Akşamları

        case "activity", "activity_suggestion":
            return hour >= 10 && hour < 20

        case "motivation":
            return hour >= 7 && hour < 10 // Sabah

        case "streak", "streak_warning":
            return hour >= 18 // Akşamdan itibaren

        default:
            return hour >= 9 && hour < 21
        }
    }

    // MARK: - Analytics

    /// Model güvenilirliği ve hazırlık durumu
    func getModelStatus(for category: String) -> ModelStatus {
        let timing = getOrCreateTiming(for: category)

        return ModelStatus(
            category: category,
            isReady: timing.isModelReady,
            confidenceScore: timing.confidenceScore,
            totalSamples: timing.totalSamples,
            lastUpdated: timing.lastUpdated
        )
    }

    /// Tüm kategoriler için genel istatistik
    func getOverallStatistics() -> OverallStatistics {
        let allTimings = Array(timingCache.values)

        let totalSent = allTimings.reduce(0) { $0 + $1.totalNotificationsSent }
        let totalOpened = allTimings.reduce(0) { $0 + $1.totalNotificationsOpened }
        let overallOpenRate = totalSent > 0 ? Double(totalOpened) / Double(totalSent) : 0.0

        let avgEngagement = allTimings.isEmpty ? 0.0 :
            allTimings.reduce(0.0) { $0 + $1.engagementScore } / Double(allTimings.count)

        let readyModels = allTimings.filter { $0.isModelReady }.count

        return OverallStatistics(
            totalNotificationsSent: totalSent,
            totalNotificationsOpened: totalOpened,
            overallOpenRate: overallOpenRate,
            averageEngagement: avgEngagement,
            readyModels: readyModels,
            totalModels: allTimings.count
        )
    }

    /// Debug bilgisi yazdır
    func printDebugInfo() {
        print("\n📊 === User Behavior Analyzer Debug Info ===")

        let stats = getOverallStatistics()
        print("📈 Genel İstatistikler:")
        print("   Toplam Gönderilen: \(stats.totalNotificationsSent)")
        print("   Toplam Açılan: \(stats.totalNotificationsOpened)")
        print("   Open Rate: \(String(format: "%.1f", stats.overallOpenRate * 100))%")
        print("   Avg Engagement: \(String(format: "%.1f", stats.averageEngagement))")
        print("   Hazır Modeller: \(stats.readyModels)/\(stats.totalModels)")

        print("\n📋 Kategori Detayları:")
        for (category, metrics) in getPerformanceReport().sorted(by: { $0.key < $1.key }) {
            print("   \(category):")
            print("      Sent: \(metrics.totalSent) | Opened: \(metrics.totalOpened)")
            print("      Open Rate: \(String(format: "%.1f", metrics.openRate * 100))%")
            print("      Engagement: \(String(format: "%.1f", metrics.engagementScore))")
            print("      Optimal Hours: \(metrics.optimalHours)")
            print("      Model Ready: \(metrics.isModelReady ? "✅" : "⏳")")
        }

        print("==========================================\n")
    }

    /// Tüm verileri sıfırla (test için)
    func resetAllData() {
        guard let context = modelContext else { return }

        // Tüm timing kayıtlarını sil
        let descriptor = FetchDescriptor<NotificationTiming>()
        if let timings = try? context.fetch(descriptor) {
            for timing in timings {
                context.delete(timing)
            }
            try? context.save()
        }

        // Cache'i temizle
        timingCache.removeAll()

        print("🗑️ Tüm öğrenme verileri sıfırlandı")
    }
}

// MARK: - Supporting Types

struct PerformanceMetrics {
    let totalSent: Int
    let totalOpened: Int
    let openRate: Double
    let engagementScore: Double
    let optimalHours: [Int]
    let isModelReady: Bool
}

struct ModelStatus {
    let category: String
    let isReady: Bool
    let confidenceScore: Double
    let totalSamples: Int
    let lastUpdated: Date

    var description: String {
        """
        Category: \(category)
        Ready: \(isReady ? "✅" : "⏳")
        Confidence: \(String(format: "%.1f", confidenceScore * 100))%
        Samples: \(totalSamples)
        Last Updated: \(lastUpdated)
        """
    }
}

struct OverallStatistics {
    let totalNotificationsSent: Int
    let totalNotificationsOpened: Int
    let overallOpenRate: Double
    let averageEngagement: Double
    let readyModels: Int
    let totalModels: Int

    var readinessPercentage: Double {
        guard totalModels > 0 else { return 0.0 }
        return Double(readyModels) / Double(totalModels) * 100
    }
}

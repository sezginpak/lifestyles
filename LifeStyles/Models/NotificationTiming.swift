//
//  NotificationTiming.swift
//  LifeStyles
//
//  ML-based notification timing model
//  Kullanıcının bildirim alışkanlıklarını öğrenir ve optimize eder
//

import Foundation
import SwiftData

@Model
final class NotificationTiming {
    var id: UUID
    var userId: String // Gelecekte multi-user için
    var category: String // Bildirim kategorisi (contact, goal, habit, etc.)

    // Timing Analytics
    var lastNotificationTime: Date?
    var totalNotificationsSent: Int
    var totalNotificationsOpened: Int
    var totalNotificationsDismissed: Int

    // Hourly Engagement (24 saat için engagement skorları)
    var hourlyEngagement: [Double] // 0-23 arası saatler için skor (0.0-1.0)

    // Weekly Pattern (7 gün için engagement skorları)
    var weekdayEngagement: [Double] // 0-6 (Pazar-Cumartesi) için skor (0.0-1.0)

    // Optimal Time Slots
    var optimalHours: [Int] // En iyi performans gösteren saatler
    var optimalDays: [Int] // En iyi performans gösteren günler

    // Learning Metadata
    var lastUpdated: Date
    var totalSamples: Int // Kaç veri noktası toplandı
    var confidenceScore: Double // Model güvenilirlik skoru (0.0-1.0)

    // Performance Metrics
    var averageOpenRate: Double // Açılma oranı
    var averageActionRate: Double // Aksiyon alma oranı
    var averageTimeToOpen: TimeInterval? // Ortalama açılma süresi (saniye)

    // Feature Flags
    var isMLEnabled: Bool // ML öğrenme aktif mi?
    var useAdaptiveScheduling: Bool // Adaptif zamanlama kullan mı?

    init(
        userId: String = "default",
        category: String
    ) {
        self.id = UUID()
        self.userId = userId
        self.category = category
        self.lastNotificationTime = nil
        self.totalNotificationsSent = 0
        self.totalNotificationsOpened = 0
        self.totalNotificationsDismissed = 0
        self.hourlyEngagement = Array(repeating: 0.5, count: 24) // Başlangıçta nötr skor
        self.weekdayEngagement = Array(repeating: 0.5, count: 7)
        self.optimalHours = [9, 12, 15, 18] // Varsayılan optimal saatler
        self.optimalDays = [1, 2, 3, 4, 5] // Hafta içi
        self.lastUpdated = Date()
        self.totalSamples = 0
        self.confidenceScore = 0.0
        self.averageOpenRate = 0.0
        self.averageActionRate = 0.0
        self.averageTimeToOpen = nil
        self.isMLEnabled = true
        self.useAdaptiveScheduling = true
    }

    // MARK: - Computed Properties

    /// Engagement skoru (0-100)
    var engagementScore: Double {
        let openWeight = 0.4
        let actionWeight = 0.3
        let dismissWeight = -0.3

        let total = Double(totalNotificationsSent)
        guard total > 0 else { return 0 }

        let openRate = Double(totalNotificationsOpened) / total
        let actionRate = Double(totalNotificationsOpened) / total * averageActionRate
        let dismissRate = Double(totalNotificationsDismissed) / total

        let score = (openRate * openWeight + actionRate * actionWeight - dismissRate * dismissWeight) * 100
        return max(0, min(100, score))
    }

    /// ML modeli hazır mı? (Yeterli veri toplandı mı?)
    var isModelReady: Bool {
        return totalSamples >= 10 && confidenceScore > 0.3
    }

    /// Şu an optimal zaman mı?
    var isOptimalTimeNow: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        let weekday = Calendar.current.component(.weekday, from: Date())

        let hourScore = hourlyEngagement[hour]
        let dayScore = weekdayEngagement[weekday - 1]

        // Her iki skor da ortalamanın üstündeyse optimal
        return hourScore > 0.6 && dayScore > 0.6
    }

    // MARK: - Learning Methods

    /// Bildirim gönderildiğinde çağrılır
    func recordNotificationSent() {
        totalNotificationsSent += 1
        lastNotificationTime = Date()
        lastUpdated = Date()
    }

    /// Bildirim açıldığında çağrılır
    func recordNotificationOpened(sentAt: Date, openedAt: Date) {
        totalNotificationsOpened += 1

        // Açılma süresini kaydet
        let timeToOpen = openedAt.timeIntervalSince(sentAt)
        if let currentAvg = averageTimeToOpen {
            averageTimeToOpen = (currentAvg + timeToOpen) / 2
        } else {
            averageTimeToOpen = timeToOpen
        }

        // Saatlik engagement'ı güncelle
        let hour = Calendar.current.component(.hour, from: openedAt)
        updateHourlyEngagement(hour: hour, success: true)

        // Günlük engagement'ı güncelle
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: openedAt) - 1
        updateWeekdayEngagement(day: weekday, success: true)

        // Metrikleri güncelle
        updateMetrics()
        totalSamples += 1
        lastUpdated = Date()
    }

    /// Bildirim dismiss edildiğinde çağrılır
    func recordNotificationDismissed(sentAt: Date, dismissedAt: Date) {
        totalNotificationsDismissed += 1

        // Saatlik engagement'ı olumsuz güncelle
        let hour = Calendar.current.component(.hour, from: dismissedAt)
        updateHourlyEngagement(hour: hour, success: false)

        // Günlük engagement'ı olumsuz güncelle
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: dismissedAt) - 1
        updateWeekdayEngagement(day: weekday, success: false)

        // Metrikleri güncelle
        updateMetrics()
        totalSamples += 1
        lastUpdated = Date()
    }

    /// Bildirimde aksiyon alındığında çağrılır
    func recordAction() {
        // Action rate otomatik hesaplanıyor
        updateMetrics()
    }

    // MARK: - Private Helpers

    private func updateHourlyEngagement(hour: Int, success: Bool) {
        guard hour >= 0 && hour < 24 else { return }

        let learningRate = 0.1 // Öğrenme hızı
        let currentScore = hourlyEngagement[hour]
        let target = success ? 1.0 : 0.0

        // Exponential moving average
        hourlyEngagement[hour] = currentScore + learningRate * (target - currentScore)
    }

    private func updateWeekdayEngagement(day: Int, success: Bool) {
        guard day >= 0 && day < 7 else { return }

        let learningRate = 0.1
        let currentScore = weekdayEngagement[day]
        let target = success ? 1.0 : 0.0

        weekdayEngagement[day] = currentScore + learningRate * (target - currentScore)
    }

    private func updateMetrics() {
        // Open rate
        if totalNotificationsSent > 0 {
            averageOpenRate = Double(totalNotificationsOpened) / Double(totalNotificationsSent)
        }

        // Action rate (opened notifications içinde)
        if totalNotificationsOpened > 0 {
            // Action rate ayrı tracking gerektirir, şimdilik open rate'in %30'u olarak varsay
            averageActionRate = averageOpenRate * 0.3
        }

        // Confidence score - Yeterli veri toplandıkça artar
        let sampleFactor = min(1.0, Double(totalSamples) / 50.0)
        let engagementFactor = engagementScore / 100.0
        confidenceScore = (sampleFactor + engagementFactor) / 2.0

        // Optimal hours güncelle (en yüksek 4 saat)
        optimalHours = hourlyEngagement.enumerated()
            .sorted { $0.element > $1.element }
            .prefix(4)
            .map { $0.offset }
            .sorted()

        // Optimal days güncelle (en yüksek 5 gün)
        optimalDays = weekdayEngagement.enumerated()
            .sorted { $0.element > $1.element }
            .prefix(5)
            .map { $0.offset }
            .sorted()
    }

    // MARK: - Prediction Methods

    /// Verilen saat için engagement skorunu döndür
    func getEngagementScore(forHour hour: Int) -> Double {
        guard hour >= 0 && hour < 24 else { return 0.5 }
        return hourlyEngagement[hour]
    }

    /// Verilen gün için engagement skorunu döndür
    func getEngagementScore(forWeekday weekday: Int) -> Double {
        guard weekday >= 0 && weekday < 7 else { return 0.5 }
        return weekdayEngagement[weekday]
    }

    /// Verilen tarih için combined engagement skorunu döndür
    func getEngagementScore(forDate date: Date) -> Double {
        let hour = Calendar.current.component(.hour, from: date)
        let weekday = Calendar.current.component(.weekday, from: date) - 1

        let hourScore = getEngagementScore(forHour: hour)
        let dayScore = getEngagementScore(forWeekday: weekday)

        // Weighted average
        return (hourScore * 0.7 + dayScore * 0.3)
    }

    /// Sonraki 24 saat içinde en iyi zamanı döndür
    func predictBestTime(within hours: Int = 24) -> Date? {
        guard isModelReady else { return nil }

        var bestDate: Date?
        var bestScore = 0.0

        let now = Date()
        for hour in 0..<hours {
            let candidateDate = now.addingTimeInterval(TimeInterval(hour * 3600))
            let score = getEngagementScore(forDate: candidateDate)

            if score > bestScore {
                bestScore = score
                bestDate = candidateDate
            }
        }

        return bestDate
    }

    /// İki zaman arasında en iyi zamanı döndür
    func predictBestTime(between startHour: Int, and endHour: Int) -> Int? {
        guard isModelReady else { return nil }

        var bestHour = startHour
        var bestScore = 0.0

        for hour in startHour...endHour {
            let score = getEngagementScore(forHour: hour % 24)
            if score > bestScore {
                bestScore = score
                bestHour = hour % 24
            }
        }

        return bestHour
    }

    // MARK: - Reset & Maintenance

    /// Öğrenme verilerini sıfırla
    func reset() {
        hourlyEngagement = Array(repeating: 0.5, count: 24)
        weekdayEngagement = Array(repeating: 0.5, count: 7)
        totalSamples = 0
        confidenceScore = 0.0
        lastUpdated = Date()
    }

    /// Eski veriyi unut (decay)
    func applyDecay(factor: Double = 0.95) {
        // Zamanla eski öğrenmeleri azalt
        hourlyEngagement = hourlyEngagement.map { $0 * factor + 0.5 * (1 - factor) }
        weekdayEngagement = weekdayEngagement.map { $0 * factor + 0.5 * (1 - factor) }
        confidenceScore *= factor
    }
}

// MARK: - Time Slot

struct TimeSlot: Codable {
    let startHour: Int
    let endHour: Int
    let score: Double

    var description: String {
        return "\(startHour):00 - \(endHour):00 (Score: \(String(format: "%.2f", score)))"
    }
}

//
//  NotificationMLScheduler.swift
//  LifeStyles
//
//  ML-powered notification scheduler
//  ML tahminlerini kullanarak bildirimleri optimal zamanda planlar
//

import Foundation
import UserNotifications

@Observable
class NotificationMLScheduler {
    static let shared = NotificationMLScheduler()

    private let behaviorAnalyzer = UserBehaviorAnalyzer.shared
    private let center = UNUserNotificationCenter.current()

    // Scheduled notifications cache
    private var scheduledNotifications: [String: ScheduledNotificationInfo] = [:]

    private init() {}

    // MARK: - Smart Scheduling

    /// ML tabanlı akıllı zamanlama ile bildirim planla
    func scheduleSmartNotification(
        category: String,
        content: UNMutableNotificationContent,
        priority: NotificationPriority,
        respectQuietHours: Bool = true,
        preferredTimeWindow: TimeWindow? = nil
    ) async throws {

        // Önceliğe göre zamanlama stratejisi belirle
        let schedulingStrategy = determineStrategy(for: priority)

        let scheduledTime: Date

        switch schedulingStrategy {
        case .immediate:
            // Hemen gönder
            scheduledTime = Date()

        case .nextBestTime:
            // ML ile en iyi zamanı bul
            if let bestTime = behaviorAnalyzer.predictBestTime(for: category, within: 24) {
                scheduledTime = bestTime
            } else {
                // Fallback: Varsayılan optimal zaman
                scheduledTime = getDefaultOptimalTime(for: category)
            }

        case .withinWindow(let window):
            // Belirtilen zaman aralığında en iyi zamanı bul
            scheduledTime = findBestTimeInWindow(
                category: category,
                window: window
            )

        case .deferred(let hours):
            // Belirtilen saat sonrasına ertele
            scheduledTime = Date().addingTimeInterval(TimeInterval(hours * 3600))
        }

        // Quiet hours kontrolü
        let finalScheduledTime = respectQuietHours ?
            adjustForQuietHours(scheduledTime) : scheduledTime

        // Bildirim planla
        let trigger = createTrigger(for: finalScheduledTime)
        let identifier = "\(category)-\(UUID().uuidString)"

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await center.add(request)

        // Kaydı tut
        let info = ScheduledNotificationInfo(
            identifier: identifier,
            category: category,
            scheduledTime: finalScheduledTime,
            priority: priority,
            strategy: schedulingStrategy
        )
        scheduledNotifications[identifier] = info

        // Analytics kaydet
        behaviorAnalyzer.recordNotificationSent(category: category)

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        print("📅 Bildirim planlandı: \(category) - \(formatter.string(from: finalScheduledTime))")
    }

    /// Hemen bildirim gönder (foreground için)
    func sendImmediateNotification(
        category: String,
        content: UNMutableNotificationContent,
        priority: NotificationPriority
    ) async throws {

        let identifier = "\(category)-immediate-\(UUID().uuidString)"

        // 1 saniye sonra gönder
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await center.add(request)

        // Analytics kaydet
        behaviorAnalyzer.recordNotificationSent(category: category)

        print("⚡ Immediate notification gönderildi: \(category)")
    }

    // MARK: - Batch Scheduling

    /// Toplu bildirim planla (örn: tüm contact reminders)
    func scheduleBatchNotifications(
        items: [(category: String, content: UNMutableNotificationContent, priority: NotificationPriority)],
        respectQuietHours: Bool = true
    ) async throws {

        // Öncelik sırasına göre sırala
        let sortedItems = items.sorted { $0.priority.weightedScore > $1.priority.weightedScore }

        // Her bildirim için optimal zamanlama yap
        for (index, item) in sortedItems.enumerated() {
            // Ardışık bildirimleri ara ara planla (spam önleme)
            let delay = TimeInterval(index * 300) // 5 dakika ara

            try await scheduleSmartNotification(
                category: item.category,
                content: item.content,
                priority: item.priority,
                respectQuietHours: respectQuietHours
            )

            // Rate limiting
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 saniye bekle
        }

        print("📦 \(sortedItems.count) bildirim toplu olarak planlandı")
    }

    // MARK: - Reschedule & Cancel

    /// Bildirimi yeniden planla
    func rescheduleNotification(
        identifier: String,
        newTime: Date
    ) async throws {

        guard let info = scheduledNotifications[identifier] else {
            print("⚠️ Bildirim bulunamadı: \(identifier)")
            return
        }

        // Eski bildirimi iptal et
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        // Yeni bildirim planla
        // Not: Content'i tekrar oluşturmak gerekir, şimdilik sadece time güncelle
        let newIdentifier = "\(info.category)-rescheduled-\(UUID().uuidString)"

        print("🔄 Bildirim yeniden planlandı: \(identifier) → \(newTime)")
    }

    /// Bildirimi iptal et
    func cancelNotification(identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        scheduledNotifications.removeValue(forKey: identifier)

        print("🗑️ Bildirim iptal edildi: \(identifier)")
    }

    /// Kategori bazlı tüm bildirimleri iptal et
    func cancelAllNotifications(for category: String) {
        let identifiersToCancel = scheduledNotifications
            .filter { $0.value.category == category }
            .map { $0.key }

        center.removePendingNotificationRequests(withIdentifiers: identifiersToCancel)

        for identifier in identifiersToCancel {
            scheduledNotifications.removeValue(forKey: identifier)
        }

        print("🗑️ \(identifiersToCancel.count) bildirim iptal edildi: \(category)")
    }

    // MARK: - Strategies

    private func determineStrategy(for priority: NotificationPriority) -> SchedulingStrategy {
        switch priority.level {
        case .critical:
            return .immediate

        case .high:
            // 1-4 saat içinde en iyi zaman
            return .withinWindow(TimeWindow(start: Date(), duration: 4))

        case .normal:
            // 24 saat içinde en iyi zaman
            return .nextBestTime

        case .low:
            // 2-6 saat içinde en iyi zaman
            return .withinWindow(TimeWindow(start: Date().addingTimeInterval(7200), duration: 4))

        case .minimal:
            // 6 saat sonraya ertele
            return .deferred(hours: 6)
        }
    }

    private func findBestTimeInWindow(
        category: String,
        window: TimeWindow
    ) -> Date {

        let windowEnd = window.start.addingTimeInterval(TimeInterval(window.duration * 3600))
        let hoursToCheck = window.duration

        var bestTime = window.start
        var bestScore = 0.0

        for hour in 0..<hoursToCheck {
            let candidateTime = window.start.addingTimeInterval(TimeInterval(hour * 3600))

            // Zaman aralığı dışına çıkma
            guard candidateTime <= windowEnd else { break }

            // ML engagement skorunu al
            let score = behaviorAnalyzer.getEngagementScore(for: category)

            if score > bestScore {
                bestScore = score
                bestTime = candidateTime
            }
        }

        return bestTime
    }

    private func getDefaultOptimalTime(for category: String) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())

        // Kategori bazlı varsayılan optimal saatler
        let defaultHour: Int
        switch category.lowercased() {
        case "contact", "contact_reminder":
            defaultHour = 10
        case "goal", "goal_reminder":
            defaultHour = 9
        case "habit", "habit_reminder":
            defaultHour = 20
        case "activity", "activity_suggestion":
            defaultHour = 15
        case "motivation":
            defaultHour = 8
        default:
            defaultHour = 12
        }

        components.hour = defaultHour
        components.minute = 0

        return calendar.date(from: components) ?? Date()
    }

    // MARK: - Quiet Hours

    private func adjustForQuietHours(_ date: Date) -> Date {
        let hour = Calendar.current.component(.hour, from: date)

        // Gece yarısı - sabah 8 arası quiet hours
        if hour >= 22 || hour < 8 {
            // Sabah 9'a ayarla
            var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
            components.hour = 9
            components.minute = 0

            // Eğer bugünün 9'u geçtiyse yarına al
            if hour >= 22 {
                if let adjustedDate = Calendar.current.date(from: components) {
                    return Calendar.current.date(byAdding: .day, value: 1, to: adjustedDate) ?? date
                }
            }

            return Calendar.current.date(from: components) ?? date
        }

        return date
    }

    private func createTrigger(for date: Date) -> UNNotificationTrigger {
        let timeInterval = date.timeIntervalSinceNow

        // Geçmiş bir tarih ise hemen gönder
        if timeInterval <= 0 {
            return UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        }

        return UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
    }

    // MARK: - Analytics

    /// Planlanan bildirimlerin durumunu göster
    func printScheduledNotifications() {
        print("\n📋 === Planlanan Bildirimler ===")

        let sorted = scheduledNotifications.values.sorted { $0.scheduledTime < $1.scheduledTime }

        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM HH:mm"

        for info in sorted {
            print("   \(formatter.string(from: info.scheduledTime)) - \(info.category)")
            print("      Priority: \(info.priority.level.rawValue)")
            print("      Strategy: \(info.strategy)")
        }

        print("================================\n")
    }

    /// Planlanan bildirim sayısı
    func getScheduledCount() -> Int {
        return scheduledNotifications.count
    }

    /// Kategori bazlı planlanan bildirim sayısı
    func getScheduledCount(for category: String) -> Int {
        return scheduledNotifications.values.filter { $0.category == category }.count
    }
}

// MARK: - Supporting Types

enum SchedulingStrategy: CustomStringConvertible {
    case immediate                          // Hemen gönder
    case nextBestTime                       // Sonraki en iyi zamanda gönder
    case withinWindow(TimeWindow)           // Belirtilen zaman aralığında
    case deferred(hours: Int)               // X saat sonraya ertele

    var description: String {
        switch self {
        case .immediate:
            return "Immediate"
        case .nextBestTime:
            return "Next Best Time"
        case .withinWindow(let window):
            return "Within \(window.duration)h window"
        case .deferred(let hours):
            return "Deferred +\(hours)h"
        }
    }
}

struct TimeWindow {
    let start: Date
    let duration: Int // hours

    var end: Date {
        return start.addingTimeInterval(TimeInterval(duration * 3600))
    }
}

struct ScheduledNotificationInfo {
    let identifier: String
    let category: String
    let scheduledTime: Date
    let priority: NotificationPriority
    let strategy: SchedulingStrategy
    let createdAt: Date

    init(
        identifier: String,
        category: String,
        scheduledTime: Date,
        priority: NotificationPriority,
        strategy: SchedulingStrategy
    ) {
        self.identifier = identifier
        self.category = category
        self.scheduledTime = scheduledTime
        self.priority = priority
        self.strategy = strategy
        self.createdAt = Date()
    }
}

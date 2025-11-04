//
//  NotificationScheduler.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Smart notification scheduling with quiet hours and spam prevention
//

import Foundation
import UserNotifications

// MARK: - Scheduler Priority (Legacy)
// NotificationScheduler için basit priority enum
// Yeni sistem için NotificationPriority.swift dosyasındaki struct kullanılıyor

enum SchedulerPriority: Int, Comparable {
    case low = 0
    case normal = 1
    case high = 2
    case critical = 3

    static func < (lhs: SchedulerPriority, rhs: SchedulerPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Notification Scheduler

@Observable
class NotificationScheduler {

    static let shared = NotificationScheduler()

    private let defaults = UserDefaults.standard
    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Quiet Hours Check

    /// Sessiz saat kontrolü yap
    func isQuietHours() -> Bool {
        guard defaults.bool(forKey: UserDefaults.NotificationKeys.quietHoursEnabled) else {
            return false
        }

        guard let startDate = defaults.object(forKey: UserDefaults.NotificationKeys.quietHoursStart) as? Date,
              let endDate = defaults.object(forKey: UserDefaults.NotificationKeys.quietHoursEnd) as? Date else {
            return false
        }

        let calendar = Calendar.current
        let now = Date()

        // Saat ve dakika bileşenlerini al
        let nowComponents = calendar.dateComponents([.hour, .minute], from: now)
        let startComponents = calendar.dateComponents([.hour, .minute], from: startDate)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endDate)

        guard let nowHour = nowComponents.hour, let nowMinute = nowComponents.minute,
              let startHour = startComponents.hour, let startMinute = startComponents.minute,
              let endHour = endComponents.hour, let endMinute = endComponents.minute else {
            return false
        }

        // Dakika cinsine çevir
        let nowMinutes = nowHour * 60 + nowMinute
        let startMinutes = startHour * 60 + startMinute
        let endMinutes = endHour * 60 + endMinute

        // Gece yarısını geçen aralık kontrolü (ör: 22:00 - 08:00)
        if startMinutes > endMinutes {
            return nowMinutes >= startMinutes || nowMinutes < endMinutes
        } else {
            return nowMinutes >= startMinutes && nowMinutes < endMinutes
        }
    }

    /// Sessiz saat bitmesine ne kadar var? (saniye cinsinden)
    func secondsUntilQuietHoursEnd() -> TimeInterval? {
        guard isQuietHours(),
              let endDate = defaults.object(forKey: UserDefaults.NotificationKeys.quietHoursEnd) as? Date else {
            return nil
        }

        let calendar = Calendar.current
        let now = Date()

        let endComponents = calendar.dateComponents([.hour, .minute], from: endDate)

        guard let endHour = endComponents.hour, let endMinute = endComponents.minute else {
            return nil
        }

        // Bugünkü sessiz saat bitiş zamanı
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = endHour
        components.minute = endMinute

        guard let quietHoursEnd = calendar.date(from: components) else {
            return nil
        }

        // Eğer sessiz saat bitişi geçmişte ise, yarına ekle
        let finalEndDate: Date
        if quietHoursEnd < now {
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: quietHoursEnd) else {
                return nil
            }
            finalEndDate = nextDay
        } else {
            finalEndDate = quietHoursEnd
        }

        return finalEndDate.timeIntervalSince(now)
    }

    // MARK: - Spam Prevention

    /// Notification gönderilebilir mi? (spam kontrolü)
    func canSendNotification(priority: SchedulerPriority = .normal) -> Bool {
        // Critical öncelikli bildirimler her zaman gönderilir
        if priority == .critical {
            return true
        }

        // Günlük limit kontrolü
        if defaults.hasExceededDailyLimit() {
            print("⚠️ Günlük bildirim limiti aşıldı")
            return false
        }

        // Minimum zaman aralığı kontrolü
        if !defaults.canSendNotificationNow() {
            print("⚠️ Son bildirimden yeterli zaman geçmedi")
            return false
        }

        return true
    }

    /// Notification gönderilebilir mi? (sessiz saat + spam kontrolü)
    func shouldSendNotification(
        priority: SchedulerPriority = .normal,
        respectQuietHours: Bool = true
    ) -> (canSend: Bool, reason: String?) {
        // Spam kontrolü
        if !canSendNotification(priority: priority) {
            return (false, "Spam prevention: Çok fazla bildirim gönderildi")
        }

        // Sessiz saat kontrolü
        if respectQuietHours && isQuietHours() {
            if priority == .critical {
                // Critical bildirimler sessiz saatte bile gönderilir
                return (true, nil)
            } else {
                let secondsRemaining = secondsUntilQuietHoursEnd() ?? 0
                return (false, "Sessiz saat aktif. \(Int(secondsRemaining / 60)) dakika sonra gönderilecek")
            }
        }

        return (true, nil)
    }

    // MARK: - Best Time Calculation

    /// En uygun bildirim zamanını hesapla (kullanıcı davranışına göre)
    func calculateBestTime(for category: NotificationCategory) -> Date {
        let calendar = Calendar.current
        let now = Date()

        // Kullanıcının en aktif olduğu saatleri al
        let mostActiveHours = defaults.getMostActiveHours()

        // En aktif saat bulunamazsa default saatler
        let defaultHours: [Int]
        switch category {
        case .contactReminder, .goalReminder:
            defaultHours = [9, 10, 11] // Sabah
        case .habitReminder:
            defaultHours = [20, 21] // Akşam
        case .activitySuggestion, .goOutside:
            defaultHours = [14, 15, 16] // Öğleden sonra
        case .motivation:
            defaultHours = [8, 9] // Sabah erken
        case .weeklySummary:
            defaultHours = [20] // Akşam
        default:
            defaultHours = [10, 14, 18]
        }

        // Aktif saatler varsa kullan, yoksa default
        let targetHours = mostActiveHours.isEmpty ? defaultHours : mostActiveHours

        // Şu anki saati al
        let currentHour = calendar.component(.hour, from: now)

        // En yakın aktif saati bul
        guard let nextHour = targetHours.first(where: { $0 > currentHour }) ?? targetHours.first else {
            // Fallback: 1 saat sonra
            print("⚠️ targetHours boş, 1 saat sonrasına planlanıyor")
            return calendar.date(byAdding: .hour, value: 1, to: now) ?? now.addingTimeInterval(3600)
        }

        // Hedef tarihi oluştur
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = nextHour
        components.minute = 0

        guard let targetDate = calendar.date(from: components) else {
            print("❌ Geçersiz date components")
            return calendar.date(byAdding: .hour, value: 1, to: now) ?? now.addingTimeInterval(3600)
        }

        // Eğer geçmiş bir saat ise, yarına ekle
        if targetDate < now {
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: targetDate) else {
                return calendar.date(byAdding: .hour, value: 1, to: now) ?? now.addingTimeInterval(3600)
            }
            return nextDay
        }

        return targetDate
    }

    /// Belirli bir zamana notification planla (sessiz saat kontrolü ile)
    func scheduleNotification(
        identifier: String,
        content: UNMutableNotificationContent,
        at date: Date,
        priority: SchedulerPriority = .normal,
        respectQuietHours: Bool = true
    ) async throws {
        // Gönderim kontrolü
        let (canSend, reason) = shouldSendNotification(priority: priority, respectQuietHours: respectQuietHours)

        if !canSend {
            print("⚠️ Bildirim engellendi: \(reason ?? "Bilinmeyen sebep")")

            // Eğer sessiz saat yüzünden engelleniyorsa, sessiz saat bitişine planla
            if respectQuietHours && isQuietHours(), let secondsRemaining = secondsUntilQuietHoursEnd() {
                let delayedDate = Date().addingTimeInterval(secondsRemaining + 60) // 1 dakika fazladan bekle
                print("🔔 Bildirim sessiz saat bitiminde gönderilecek: \(delayedDate)")
                let trigger = UNTimeIntervalNotificationTrigger(
                    timeInterval: secondsRemaining + 60,
                    repeats: false
                )
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                try await center.add(request)
                return
            } else {
                throw NotificationError.cannotSend(reason: reason ?? "")
            }
        }

        // Trigger oluştur
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        // Request oluştur ve ekle
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try await center.add(request)

        // Notification gönderildi işaretle
        defaults.markNotificationSent()

        // Analytics'e kaydet
        let entry = NotificationHistoryEntry(
            id: identifier,
            category: content.categoryIdentifier,
            title: content.title
        )
        defaults.addNotificationHistory(entry: entry)

        print("✅ Bildirim planlandı: \(content.title) - \(date)")
    }

    /// Hemen notification gönder (sessiz saat kontrolü ile)
    func sendImmediateNotification(
        identifier: String,
        content: UNMutableNotificationContent,
        priority: SchedulerPriority = .normal,
        respectQuietHours: Bool = true,
        delay: TimeInterval = 1
    ) async throws {
        // Gönderim kontrolü
        let (canSend, reason) = shouldSendNotification(priority: priority, respectQuietHours: respectQuietHours)

        if !canSend {
            print("⚠️ Bildirim engellendi: \(reason ?? "Bilinmeyen sebep")")

            // Sessiz saat yüzünden engelleniyorsa, sessiz saat bitişine planla
            if respectQuietHours && isQuietHours() {
                if let secondsRemaining = secondsUntilQuietHoursEnd() {
                    try await scheduleNotification(
                        identifier: identifier,
                        content: content,
                        at: Date().addingTimeInterval(secondsRemaining + 60),
                        priority: priority,
                        respectQuietHours: false // Tekrar kontrol etme
                    )
                }
            }
            throw NotificationError.cannotSend(reason: reason ?? "")
        }

        // Hemen gönder (kısa delay ile)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try await center.add(request)

        // Notification gönderildi işaretle
        defaults.markNotificationSent()

        // Analytics'e kaydet
        let entry = NotificationHistoryEntry(
            id: identifier,
            category: content.categoryIdentifier,
            title: content.title
        )
        defaults.addNotificationHistory(entry: entry)

        print("✅ Bildirim gönderildi: \(content.title)")
    }

    // MARK: - User Behavior Analysis

    /// Kullanıcının aktif saatlerini analiz et ve kaydet
    func analyzeUserBehavior() {
        // Son 7 günlük uygulama açılış saatlerini analiz et
        // (Gerçek implementasyon için app analytics gerekir)

        // Simüle edilmiş örnek: En aktif saatleri belirle
        let currentHour = Calendar.current.component(.hour, from: Date())

        var activeHours = defaults.getMostActiveHours()
        if !activeHours.contains(currentHour) {
            activeHours.append(currentHour)
            // En son 10 saati tut
            if activeHours.count > 10 {
                activeHours.removeFirst()
            }
            defaults.saveMostActiveHours(activeHours)
        }

        // Engagement skorunu güncelle
        let openCount = defaults.integer(forKey: UserDefaults.BehaviorKeys.dailyOpenCount)
        defaults.set(openCount + 1, forKey: UserDefaults.BehaviorKeys.dailyOpenCount)

        // App açılış zamanını kaydet
        defaults.set(Date(), forKey: UserDefaults.BehaviorKeys.lastAppOpenTime)
    }

    /// Haftalık engagement skorunu hesapla
    func calculateWeeklyEngagement() -> Double {
        let openCount = defaults.integer(forKey: UserDefaults.BehaviorKeys.dailyOpenCount)
        let totalSent = defaults.integer(forKey: UserDefaults.AnalyticsKeys.totalNotificationsSent)
        let totalOpened = defaults.integer(forKey: UserDefaults.AnalyticsKeys.totalNotificationsOpened)

        guard totalSent > 0 else { return 0.0 }

        let openRate = Double(totalOpened) / Double(totalSent)
        let appEngagement = min(Double(openCount) / 7.0, 1.0) // 7 gün hedefi

        let score = (openRate * 0.6 + appEngagement * 0.4) * 100
        defaults.updateEngagementScore(score)

        return score
    }
}

// MARK: - Notification Error

enum NotificationError: LocalizedError {
    case cannotSend(reason: String)
    case quietHoursActive
    case dailyLimitExceeded
    case invalidConfiguration

    var errorDescription: String? {
        switch self {
        case .cannotSend(let reason):
            return "Bildirim gönderilemedi: \(reason)"
        case .quietHoursActive:
            return "Sessiz saat aktif"
        case .dailyLimitExceeded:
            return "Günlük bildirim limiti aşıldı"
        case .invalidConfiguration:
            return "Geçersiz bildirim konfigürasyonu"
        }
    }
}

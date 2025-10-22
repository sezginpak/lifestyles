//
//  NotificationUserDefaults+Keys.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  UserDefaults keys for notification system
//

import Foundation

// MARK: - Notification UserDefaults Keys

extension UserDefaults {

    // MARK: - Settings Keys (SettingsViewModel ile senkronize)

    /// Bildirim tercihleri
    enum NotificationKeys {
        static let quietHoursEnabled = "quietHoursEnabled"
        static let quietHoursStart = "quietHoursStart"
        static let quietHoursEnd = "quietHoursEnd"
        static let reminderFrequency = "reminderFrequency"
        static let dailyMotivationEnabled = "dailyMotivationEnabled"
        static let notificationsEnabled = "notificationsEnabled"
        static let locationTrackingEnabled = "locationTrackingEnabled"
    }

    // MARK: - Analytics Keys

    /// Bildirim performans tracking
    enum AnalyticsKeys {
        static let totalNotificationsSent = "analytics_totalNotificationsSent"
        static let totalNotificationsOpened = "analytics_totalNotificationsOpened"
        static let totalActionsExecuted = "analytics_totalActionsExecuted"
        static let lastNotificationDate = "analytics_lastNotificationDate"
        static let notificationHistory = "analytics_notificationHistory" // JSON array
    }

    // MARK: - User Behavior Keys

    /// Kullanıcı davranış analizi
    enum BehaviorKeys {
        static let mostActiveHours = "behavior_mostActiveHours" // [Int] array
        static let preferredNotificationTimes = "behavior_preferredTimes"
        static let lastAppOpenTime = "behavior_lastAppOpen"
        static let dailyOpenCount = "behavior_dailyOpenCount"
        static let weeklyEngagementScore = "behavior_weeklyEngagement"
    }

    // MARK: - Spam Prevention Keys

    /// Spam önleme ve limitler
    enum SpamKeys {
        static let dailyNotificationCount = "spam_dailyCount"
        static let dailyNotificationDate = "spam_dailyDate"
        static let maxDailyNotifications = "spam_maxDaily" // default 20
        static let lastNotificationTimestamp = "spam_lastTimestamp"
        static let minTimeBetweenNotifications = "spam_minInterval" // saniye, default 300 (5 dakika)
    }

    // MARK: - Geofence Keys

    /// Konum bazlı bildirim ayarları
    enum GeofenceKeys {
        static let homeGeofenceEnabled = "geofence_homeEnabled"
        static let homeGeofenceLatitude = "geofence_homeLatitude"
        static let homeGeofenceLongitude = "geofence_homeLongitude"
        static let homeGeofenceRadius = "geofence_homeRadius"
        static let lastHomeEntry = "geofence_lastHomeEntry"
        static let lastHomeExit = "geofence_lastHomeExit"
        static let hoursAtHome = "geofence_hoursAtHome"
    }

    // MARK: - Helper Methods

    /// Günlük notification sayacını sıfırla (yeni gün başladığında)
    func resetDailyNotificationCount() {
        let today = Calendar.current.startOfDay(for: Date())
        let savedDate = object(forKey: SpamKeys.dailyNotificationDate) as? Date ?? Date.distantPast

        if !Calendar.current.isDate(today, inSameDayAs: savedDate) {
            set(0, forKey: SpamKeys.dailyNotificationCount)
            set(today, forKey: SpamKeys.dailyNotificationDate)
        }
    }

    /// Günlük notification sayısını artır
    func incrementDailyNotificationCount() {
        resetDailyNotificationCount()
        let current = integer(forKey: SpamKeys.dailyNotificationCount)
        set(current + 1, forKey: SpamKeys.dailyNotificationCount)
    }

    /// Günlük limit aşıldı mı?
    func hasExceededDailyLimit() -> Bool {
        resetDailyNotificationCount()
        let count = integer(forKey: SpamKeys.dailyNotificationCount)
        let limit = integer(forKey: SpamKeys.maxDailyNotifications)
        let actualLimit = limit > 0 ? limit : 20 // default 20
        return count >= actualLimit
    }

    /// Son notification'dan yeterli zaman geçti mi?
    func canSendNotificationNow() -> Bool {
        guard let lastTimestamp = object(forKey: SpamKeys.lastNotificationTimestamp) as? Date else {
            return true
        }

        let minInterval = double(forKey: SpamKeys.minTimeBetweenNotifications)
        let actualInterval = minInterval > 0 ? minInterval : 300 // default 5 dakika

        let timeSinceLastNotification = Date().timeIntervalSince(lastTimestamp)
        return timeSinceLastNotification >= actualInterval
    }

    /// Notification gönderildi işaretle
    func markNotificationSent() {
        set(Date(), forKey: SpamKeys.lastNotificationTimestamp)
        incrementDailyNotificationCount()
    }

    /// En aktif saatleri kaydet
    func saveMostActiveHours(_ hours: [Int]) {
        set(hours, forKey: BehaviorKeys.mostActiveHours)
    }

    /// En aktif saatleri al
    func getMostActiveHours() -> [Int] {
        return array(forKey: BehaviorKeys.mostActiveHours) as? [Int] ?? []
    }

    /// Kullanıcı engagement skorunu güncelle
    func updateEngagementScore(_ score: Double) {
        set(score, forKey: BehaviorKeys.weeklyEngagementScore)
    }

    /// Engagement skorunu al
    func getEngagementScore() -> Double {
        return double(forKey: BehaviorKeys.weeklyEngagementScore)
    }
}

// MARK: - Notification History Entry

struct NotificationHistoryEntry: Codable {
    let id: String
    let category: String
    let title: String
    let sentAt: Date
    var openedAt: Date?
    var actionTaken: String?

    init(id: String, category: String, title: String, sentAt: Date = Date()) {
        self.id = id
        self.category = category
        self.title = title
        self.sentAt = sentAt
    }
}

// MARK: - Notification History Manager

extension UserDefaults {

    /// Notification history'ye entry ekle
    func addNotificationHistory(entry: NotificationHistoryEntry) {
        var history = getNotificationHistory()
        history.append(entry)

        // Son 100 kaydı tut
        if history.count > 100 {
            history = Array(history.suffix(100))
        }

        if let encoded = try? JSONEncoder().encode(history) {
            set(encoded, forKey: AnalyticsKeys.notificationHistory)
        }
    }

    /// Notification history'yi al
    func getNotificationHistory() -> [NotificationHistoryEntry] {
        guard let data = data(forKey: AnalyticsKeys.notificationHistory),
              let history = try? JSONDecoder().decode([NotificationHistoryEntry].self, from: data) else {
            return []
        }
        return history
    }

    /// Notification açıldı işaretle
    func markNotificationOpened(id: String) {
        var history = getNotificationHistory()
        if let index = history.firstIndex(where: { $0.id == id }) {
            history[index].openedAt = Date()
            if let encoded = try? JSONEncoder().encode(history) {
                set(encoded, forKey: AnalyticsKeys.notificationHistory)
            }
        }

        // Analytics sayacını artır
        let count = integer(forKey: AnalyticsKeys.totalNotificationsOpened)
        set(count + 1, forKey: AnalyticsKeys.totalNotificationsOpened)
    }

    /// Action tamamlandı işaretle
    func markActionExecuted(id: String, action: String) {
        var history = getNotificationHistory()
        if let index = history.firstIndex(where: { $0.id == id }) {
            history[index].actionTaken = action
            if let encoded = try? JSONEncoder().encode(history) {
                set(encoded, forKey: AnalyticsKeys.notificationHistory)
            }
        }

        // Analytics sayacını artır
        let count = integer(forKey: AnalyticsKeys.totalActionsExecuted)
        set(count + 1, forKey: AnalyticsKeys.totalActionsExecuted)
    }
}

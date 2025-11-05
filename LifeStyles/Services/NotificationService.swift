//
//  NotificationService.swift
//  LifeStyles
//
//  Created by Claude on 15.10.2025.
//  Refactored on 21.10.2025 - Core notification methods only
//  Further refactored on 05.11.2025 - Extension-based architecture
//

import Foundation
import UserNotifications
import CoreLocation

@Observable
class NotificationService {
    static let shared = NotificationService()

    let center = UNUserNotificationCenter.current()
    private let languageManager = LanguageManager.shared

    private init() {}

    // MARK: - Language Support

    var currentLanguage: AppLanguage {
        languageManager.currentLanguage
    }

    // MARK: - Core Methods

    /// İzin durumunu kontrol et
    func checkPermission() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    /// İzin iste
    func requestPermission() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    /// Tüm bekleyen bildirimleri iptal et
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Smart Notification API

    /// Smart notification gönderimi (sessiz saat + scheduler + analytics + rich media)
    func sendSmartNotification(
        title: String,
        body: String,
        category: NotificationCategory,
        priority: SchedulerPriority = .normal,
        respectQuietHours: Bool = true,
        emoji: String? = nil,
        userInfo: [String: Any] = [:]
    ) async throws {
        // Content oluştur
        let content = NotificationCategoryManager.createContent(
            title: title,
            body: body,
            category: category,
            userInfo: userInfo
        )

        // Rich media ekle
        if let emoji = emoji {
            content.addRichMedia(emoji: emoji, category: category)
        } else {
            content.addRichMedia(category: category)
        }

        // Scheduler ile gönder
        let identifier = "\(category.rawValue)-\(UUID().uuidString)"
        try await NotificationScheduler.shared.sendImmediateNotification(
            identifier: identifier,
            content: content,
            priority: priority,
            respectQuietHours: respectQuietHours
        )
    }

    /// Friend için smart notification
    func sendFriendNotification(
        friend: Friend,
        title: String,
        body: String,
        priority: SchedulerPriority = .normal
    ) async throws {
        var userInfo: [String: Any] = [
            "friendId": friend.id.uuidString
        ]

        let content = NotificationCategoryManager.createContent(
            title: title,
            body: body,
            category: .contactReminder,
            userInfo: userInfo
        )

        let identifier = "friend-\(friend.id.uuidString)-\(UUID().uuidString)"
        try await NotificationScheduler.shared.sendImmediateNotification(
            identifier: identifier,
            content: content,
            priority: priority,
            respectQuietHours: true
        )
    }

    /// Goal için smart notification
    func sendGoalNotification(
        goal: Goal,
        title: String,
        body: String,
        priority: SchedulerPriority = .normal
    ) async throws {
        var userInfo: [String: Any] = [
            "goalId": goal.id.uuidString
        ]

        try await sendSmartNotification(
            title: title,
            body: body,
            category: .goalReminder,
            priority: priority,
            respectQuietHours: true,
            emoji: "🎯",
            userInfo: userInfo
        )
    }

    /// Habit için smart notification
    func sendHabitNotification(
        habit: Habit,
        title: String,
        body: String,
        priority: SchedulerPriority = .normal
    ) async throws {
        var userInfo: [String: Any] = [
            "habitId": habit.id.uuidString
        ]

        try await sendSmartNotification(
            title: title,
            body: body,
            category: .habitReminder,
            priority: priority,
            respectQuietHours: true,
            emoji: "⭐",
            userInfo: userInfo
        )
    }

    // MARK: - Initialization & Helpers

    /// Tüm notification sistemini başlat
    func initializeNotificationSystem() {
        // Delegate setup
        NotificationDelegate.shared.setup()

        // Categories kaydet
        NotificationCategoryManager.shared.registerAllCategories()

        // Geofence sync (eğer konum izni varsa)
        GeofenceNotificationManager.shared.syncWithLocationService()

        print("✅ Notification sistem başlatıldı")
    }

    /// Analytics raporu göster
    func printAnalytics() {
        NotificationAnalytics.shared.printDebugInfo()
    }

    /// Sessiz saat kontrolü
    func isQuietHours() -> Bool {
        return NotificationScheduler.shared.isQuietHours()
    }

    /// Günlük limiti aşıldı mı?
    func hasExceededDailyLimit() -> Bool {
        return UserDefaults.standard.hasExceededDailyLimit()
    }

    /// Engagement skorunu al
    func getEngagementScore() -> Double {
        return NotificationScheduler.shared.calculateWeeklyEngagement()
    }
}

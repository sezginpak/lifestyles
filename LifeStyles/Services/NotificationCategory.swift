//
//  NotificationCategory.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Notification categories and interactive actions
//

import Foundation
import UserNotifications

// MARK: - Notification Categories

enum NotificationCategory: String, CaseIterable {
    case contactReminder = "CONTACT_REMINDER"
    case goalReminder = "GOAL_REMINDER"
    case habitReminder = "HABIT_REMINDER"
    case activitySuggestion = "ACTIVITY_SUGGESTION"
    case goOutside = "GO_OUTSIDE"
    case contactCompleted = "CONTACT_COMPLETED"
    case weeklySummary = "WEEKLY_SUMMARY"
    case motivation = "MOTIVATION"
    case aiGoalMotivation = "AI_GOAL_MOTIVATION"
    case aiHabitSuggestion = "AI_HABIT_SUGGESTION"
    case aiContactMessage = "AI_CONTACT_MESSAGE"
    case geofenceHome = "GEOFENCE_HOME"
    case geofenceActivity = "GEOFENCE_ACTIVITY"
    case streakWarning = "STREAK_WARNING"
    case badgeEarned = "BADGE_EARNED"
    case levelUp = "LEVEL_UP"

    /// Kategori için uygun action'lar
    var actions: [NotificationActionType] {
        switch self {
        case .contactReminder:
            return [.open, .dismiss]
        case .goalReminder, .habitReminder:
            return [.open, .dismiss]
        case .activitySuggestion:
            return [.open, .dismiss]
        case .goOutside:
            return [.open, .dismiss]
        case .contactCompleted:
            return [.open]
        case .weeklySummary:
            return [.open]
        case .motivation:
            return [.dismiss]
        case .aiGoalMotivation, .aiHabitSuggestion, .aiContactMessage:
            return [.open, .dismiss]
        case .geofenceHome, .geofenceActivity:
            return [.open, .dismiss]
        case .streakWarning:
            return [.open, .dismiss]
        case .badgeEarned, .levelUp:
            return [.open]
        }
    }

    /// Kategori için deep link path
    var deepLinkPath: String {
        switch self {
        case .contactReminder, .contactCompleted, .aiContactMessage:
            return "contacts"
        case .goalReminder, .aiGoalMotivation:
            return "goals"
        case .habitReminder, .aiHabitSuggestion:
            return "goals" // Goals view'da habits da var
        case .activitySuggestion, .goOutside, .geofenceActivity:
            return "location"
        case .weeklySummary, .motivation:
            return "dashboard"
        case .geofenceHome:
            return "location"
        case .streakWarning, .badgeEarned, .levelUp:
            return "dashboard"
        }
    }

    /// Thread identifier (gruplama için)
    var threadIdentifier: String {
        switch self {
        case .contactReminder, .contactCompleted, .aiContactMessage:
            return "thread-contacts"
        case .goalReminder, .aiGoalMotivation:
            return "thread-goals"
        case .habitReminder, .aiHabitSuggestion:
            return "thread-habits"
        case .activitySuggestion, .goOutside, .geofenceActivity, .streakWarning:
            return "thread-activities"
        case .weeklySummary:
            return "thread-summary"
        case .motivation:
            return "thread-motivation"
        case .geofenceHome:
            return "thread-location"
        case .badgeEarned, .levelUp:
            return "thread-achievements"
        }
    }

    /// Kategori önceliği
    var interruptionLevel: UNNotificationInterruptionLevel {
        switch self {
        case .streakWarning, .contactReminder:
            return .timeSensitive // Önemli ve zaman hassas
        case .goOutside, .geofenceHome:
            return .active // Normal bildirim
        case .motivation, .weeklySummary:
            return .passive // Sessiz bildirim
        default:
            return .active
        }
    }
}

// MARK: - Notification Action Types

enum NotificationActionType: String, CaseIterable {
    case open = "ACTION_OPEN"
    case dismiss = "ACTION_DISMISS"

    /// Action'ın görünen adı
    var title: String {
        switch self {
        case .open:
            return "Aç"
        case .dismiss:
            return "Kapat"
        }
    }

    /// Action için icon (SF Symbol)
    var icon: UNNotificationActionIcon? {
        switch self {
        case .open:
            if #available(iOS 15.0, *) {
                return .init(systemImageName: "app.fill")
            }
            return nil
        case .dismiss:
            if #available(iOS 15.0, *) {
                return .init(systemImageName: "xmark.circle.fill")
            }
            return nil
        }
    }

    /// Action options
    var options: UNNotificationActionOptions {
        switch self {
        case .open:
            return [.foreground] // Uygulamayı açar
        case .dismiss:
            return [.destructive] // Kırmızı renkte gösterir
        }
    }

    /// UNNotificationAction oluştur
    func createAction() -> UNNotificationAction {
        return UNNotificationAction(
            identifier: rawValue,
            title: title,
            options: options,
            icon: icon
        )
    }
}

// MARK: - Category Registration

class NotificationCategoryManager {

    static let shared = NotificationCategoryManager()

    private init() {}

    /// Tüm kategorileri kaydet
    func registerAllCategories() {
        let center = UNUserNotificationCenter.current()

        let categories: Set<UNNotificationCategory> = Set(
            NotificationCategory.allCases.map { category in
                // Her kategori için action'ları oluştur
                let actions = category.actions.map { $0.createAction() }

                // Category oluştur
                return UNNotificationCategory(
                    identifier: category.rawValue,
                    actions: actions,
                    intentIdentifiers: [],
                    options: getCategoryOptions(for: category)
                )
            }
        )

        center.setNotificationCategories(categories)
        print("✅ \(categories.count) notification category kaydedildi")
    }

    /// Kategori için options
    private func getCategoryOptions(for category: NotificationCategory) -> UNNotificationCategoryOptions {
        switch category {
        case .contactReminder, .goalReminder, .habitReminder:
            return [.customDismissAction] // Dismiss action göster
        case .weeklySummary:
            return [.allowInCarPlay] // CarPlay'de göster
        default:
            return []
        }
    }

    /// Kategori için content oluştur (helper)
    static func createContent(
        title: String,
        body: String,
        category: NotificationCategory,
        sound: UNNotificationSound = .default,
        badge: Int? = nil,
        userInfo: [String: Any] = [:]
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound
        content.categoryIdentifier = category.rawValue
        content.threadIdentifier = category.threadIdentifier
        content.interruptionLevel = category.interruptionLevel

        if let badge = badge {
            content.badge = NSNumber(value: badge)
        }

        // Deep link path ekle
        var info = userInfo
        info["deepLink"] = category.deepLinkPath
        content.userInfo = info

        return content
    }
}

// MARK: - Deep Link Handler

struct DeepLinkHandler {

    /// UserInfo'dan deep link path'i al
    static func extractDeepLink(from userInfo: [AnyHashable: Any]) -> String? {
        return userInfo["deepLink"] as? String
    }

    /// Deep link path'inden notification category'yi tespit et
    static func extractCategory(from userInfo: [AnyHashable: Any]) -> NotificationCategory? {
        guard let categoryString = userInfo["categoryIdentifier"] as? String else {
            return nil
        }
        return NotificationCategory(rawValue: categoryString)
    }

    /// Friend ID'yi al (contact notification'ları için)
    static func extractFriendId(from userInfo: [AnyHashable: Any]) -> String? {
        return userInfo["friendId"] as? String
    }

    /// Goal ID'yi al
    static func extractGoalId(from userInfo: [AnyHashable: Any]) -> String? {
        return userInfo["goalId"] as? String
    }

    /// Habit ID'yi al
    static func extractHabitId(from userInfo: [AnyHashable: Any]) -> String? {
        return userInfo["habitId"] as? String
    }
}

//
//  NotificationDelegate.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Notification response handling and deep linking
//

import Foundation
import UserNotifications
import SwiftUI

// MARK: - Notification Delegate

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationDelegate()

    // Deep link handler callback
    var onDeepLink: ((String, [String: String]) -> Void)?

    private let defaults = UserDefaults.standard

    private override init() {
        super.init()
    }

    // MARK: - Foreground Notification

    /// App foreground'dayken bildirim göster
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // iOS 14+ için banner + sound + badge göster
        completionHandler([.banner, .sound, .badge])

        print("📱 Foreground notification: \(notification.request.content.title)")
    }

    // MARK: - Notification Response

    /// Kullanıcı bildirime tıkladığında
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let identifier = response.notification.request.identifier
        let actionIdentifier = response.actionIdentifier

        print("📲 Notification response: \(identifier), Action: \(actionIdentifier)")

        // Analytics tracking
        if actionIdentifier == UNNotificationDefaultActionIdentifier {
            // Bildirimsadece tıklandı (action değil)
            defaults.markNotificationOpened(id: identifier)
        } else if actionIdentifier != UNNotificationDismissActionIdentifier {
            // Action tıklandı (dismiss hariç)
            defaults.markActionExecuted(id: identifier, action: actionIdentifier)
        }

        // Action'a göre işlem yap
        handleAction(actionIdentifier: actionIdentifier, userInfo: userInfo)

        // Deep link handle et
        if actionIdentifier == UNNotificationDefaultActionIdentifier || actionIdentifier == NotificationActionType.open.rawValue {
            handleDeepLink(userInfo: userInfo)
        }

        completionHandler()
    }

    // MARK: - Action Handling

    private func handleAction(actionIdentifier: String, userInfo: [AnyHashable: Any]) {
        switch actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            // Normal tıklama - deep link handle edilecek
            print("🔔 Default action - opening app")

        case NotificationActionType.open.rawValue:
            // "Aç" butonu - deep link handle edilecek
            print("📂 Open action")

        case NotificationActionType.dismiss.rawValue:
            // "Kapat" butonu - hiçbir şey yapma
            print("❌ Dismiss action")

        case UNNotificationDismissActionIdentifier:
            // Sistem dismiss - hiçbir şey yapma
            print("🚫 System dismiss")

        default:
            print("❓ Unknown action: \(actionIdentifier)")
        }
    }

    // MARK: - Deep Link Handling

    private func handleDeepLink(userInfo: [AnyHashable: Any]) {
        guard let deepLinkPath = DeepLinkHandler.extractDeepLink(from: userInfo) else {
            print("⚠️ Deep link path bulunamadı")
            return
        }

        print("🔗 Deep link: \(deepLinkPath)")

        // ID'leri çıkar
        var parameters: [String: String] = [:]

        if let friendId = DeepLinkHandler.extractFriendId(from: userInfo) {
            parameters["friendId"] = friendId
        }

        if let goalId = DeepLinkHandler.extractGoalId(from: userInfo) {
            parameters["goalId"] = goalId
        }

        if let habitId = DeepLinkHandler.extractHabitId(from: userInfo) {
            parameters["habitId"] = habitId
        }

        // Callback'i çağır (ContentView'da handle edilecek)
        onDeepLink?(deepLinkPath, parameters)
    }

}

// MARK: - Deep Link Router

/// Deep link routing için ObservableObject
@Observable
class DeepLinkRouter {
    var activeTab: Int = 0
    var friendId: String?
    var goalId: String?
    var habitId: String?

    /// Deep link'i handle et ve ilgili view'a yönlendir
    func handle(path: String, parameters: [String: String]) {
        print("🧭 Routing to: \(path), params: \(parameters)")

        // ID'leri kaydet
        self.friendId = parameters["friendId"]
        self.goalId = parameters["goalId"]
        self.habitId = parameters["habitId"]

        // Tab'ı değiştir
        switch path {
        case "dashboard":
            activeTab = 0
        case "contacts":
            activeTab = 1
        case "location":
            activeTab = 2
        case "goals":
            activeTab = 3
        case "settings":
            activeTab = 4
        default:
            print("❓ Unknown deep link path: \(path)")
        }
    }

    /// Deep link'i temizle
    func clearDeepLink() {
        friendId = nil
        goalId = nil
        habitId = nil
    }
}

// MARK: - Notification Setup Helper

extension NotificationDelegate {

    /// Notification sistemi setup et
    func setup() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        // Kategorileri kaydet
        NotificationCategoryManager.shared.registerAllCategories()

        print("✅ NotificationDelegate setup tamamlandı")
    }

    /// Deep link callback'i ayarla
    func setDeepLinkHandler(_ handler: @escaping (String, [String: String]) -> Void) {
        self.onDeepLink = handler
    }
}

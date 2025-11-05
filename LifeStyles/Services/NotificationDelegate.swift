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
import UIKit

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

        case NotificationActionType.callNow.rawValue:
            // "Şimdi Ara" butonu - Aramayı başlat
            handleCallNowAction(userInfo: userInfo)

        case NotificationActionType.snooze10.rawValue:
            // "10dk Ertele" butonu - 10 dakika sonraya ertele
            handleSnoozeAction(userInfo: userInfo)

        case NotificationActionType.sendMessage.rawValue:
            // "Mesaj Gönder" butonu - Mesaj uygulamasını aç
            handleSendMessageAction(userInfo: userInfo)

        case UNNotificationDismissActionIdentifier:
            // Sistem dismiss - hiçbir şey yapma
            print("🚫 System dismiss")

        default:
            print("❓ Unknown action: \(actionIdentifier)")
        }
    }

    // MARK: - Call Reminder Action Handlers

    /// "Şimdi Ara" action'ını handle et
    private func handleCallNowAction(userInfo: [AnyHashable: Any]) {
        guard let phoneNumber = userInfo["phoneNumber"] as? String,
              !phoneNumber.isEmpty else {
            print("❌ Telefon numarası bulunamadı")
            return
        }

        // Telefon numarasını güvenli şekilde validate et ve temizle
        let cleanPhone = sanitizePhoneNumber(phoneNumber)

        // Güvenlik: Sadece sayı ve + karakteri kabul et (regex validation)
        let phoneRegex = "^[+]?[0-9]+$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)

        guard phonePredicate.evaluate(with: cleanPhone) else {
            print("❌ [SECURITY] Invalid phone number format detected: \(phoneNumber)")
            print("⚠️ Phone number must contain only digits and optional + prefix")
            return
        }

        // Ek güvenlik: Minimum ve maksimum uzunluk kontrolü
        guard cleanPhone.count >= 7 && cleanPhone.count <= 20 else {
            print("❌ [SECURITY] Phone number length invalid: \(cleanPhone.count) digits")
            return
        }

        // Güvenli URL oluşturma
        guard let url = URL(string: "tel:\(cleanPhone)"),
              url.scheme == "tel" else {
            print("❌ [SECURITY] Failed to create secure tel: URL")
            return
        }

        DispatchQueue.main.async {
            UIApplication.shared.open(url) { success in
                if success {
                    print("✅ Telefon uygulaması açıldı: \(cleanPhone)")
                } else {
                    print("❌ Telefon uygulaması açılamadı")
                }
            }
        }
    }

    /// Telefon numarasını güvenli şekilde temizle
    private func sanitizePhoneNumber(_ phoneNumber: String) -> String {
        // Whitelist approach: Sadece sayılar ve + karakterini koru
        let allowedCharacters = CharacterSet(charactersIn: "+0123456789")
        let filtered = phoneNumber.unicodeScalars.filter { allowedCharacters.contains($0) }
        return String(String.UnicodeScalarView(filtered))
    }

    /// "10dk Ertele" action'ını handle et
    private func handleSnoozeAction(userInfo: [AnyHashable: Any]) {
        guard let friendId = userInfo["friendId"] as? String,
              let friendName = userInfo["friendName"] as? String else {
            print("❌ Friend bilgisi bulunamadı")
            return
        }

        print("⏰ 10 dakika erteleniyor: \(friendName)")

        // 10 dakika sonraya yeni bildirim planla
        // Not: Friend nesnesi gerektirdiği için manuel olarak content oluşturacağız
        Task {
            let center = UNUserNotificationCenter.current()
            let identifier = "call-reminder-snooze-\(friendId)-\(Date().timeIntervalSince1970)"

            // userInfo'yu [String: Any] tipine dönüştür
            let convertedUserInfo = userInfo.reduce(into: [String: Any]()) { result, pair in
                if let key = pair.key as? String {
                    result[key] = pair.value
                }
            }

            let content = NotificationCategoryManager.createContent(
                title: "📞 \(friendName) ile İletişim Zamanı! (Ertelendi)",
                body: "Hatırlatma: \(friendName) ile konuşma zamanı. Aramak için dokunun.",
                category: .callReminder,
                sound: .defaultCritical,
                userInfo: convertedUserInfo
            )

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 600, repeats: false) // 10 dakika = 600 saniye

            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            do {
                try await center.add(request)
                print("✅ 10 dakika sonraya ertelendi: \(friendName)")
            } catch {
                print("❌ Erteleme başarısız: \(error)")
            }
        }
    }

    /// "Mesaj Gönder" action'ını handle et
    private func handleSendMessageAction(userInfo: [AnyHashable: Any]) {
        guard let phoneNumber = userInfo["phoneNumber"] as? String,
              !phoneNumber.isEmpty else {
            print("❌ Telefon numarası bulunamadı")
            return
        }

        // Telefon numarasını güvenli şekilde validate et ve temizle
        let cleanPhone = sanitizePhoneNumber(phoneNumber)

        // Güvenlik: Sadece sayı ve + karakteri kabul et (regex validation)
        let phoneRegex = "^[+]?[0-9]+$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)

        guard phonePredicate.evaluate(with: cleanPhone) else {
            print("❌ [SECURITY] Invalid phone number format detected: \(phoneNumber)")
            print("⚠️ Phone number must contain only digits and optional + prefix")
            return
        }

        // Ek güvenlik: Minimum ve maksimum uzunluk kontrolü
        guard cleanPhone.count >= 7 && cleanPhone.count <= 20 else {
            print("❌ [SECURITY] Phone number length invalid: \(cleanPhone.count) digits")
            return
        }

        // Güvenli URL oluşturma
        guard let url = URL(string: "sms:\(cleanPhone)"),
              url.scheme == "sms" else {
            print("❌ [SECURITY] Failed to create secure sms: URL")
            return
        }

        DispatchQueue.main.async {
            UIApplication.shared.open(url) { success in
                if success {
                    print("✅ Mesaj uygulaması açıldı: \(cleanPhone)")
                } else {
                    print("❌ Mesaj uygulaması açılamadı")
                }
            }
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
    var shouldShowFriendDetail: Bool = false
    var shouldCompleteContact: Bool = false

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

    /// Widget deep link'ini handle et (URL scheme ile)
    func handleWidgetURL(_ url: URL) {
        print("🔗 Widget URL: \(url)")

        // URL format: lifestyles://friend-detail/{friendId}
        guard url.scheme == "lifestyles" else { return }

        let path = url.host ?? ""
        let components = url.pathComponents.filter { $0 != "/" }

        switch path {
        case "friend-detail":
            // Friend detail sayfasına git
            if let friendId = components.first {
                print("👤 Opening friend detail: \(friendId)")
                self.friendId = friendId
                self.shouldShowFriendDetail = true
                self.activeTab = 1 // Contacts tab
            }

        case "complete-contact":
            // İletişim tamamlama aksiyonu
            if let friendId = components.first {
                print("✅ Completing contact: \(friendId)")
                self.friendId = friendId
                self.shouldCompleteContact = true
                self.activeTab = 1 // Contacts tab
            }

        case "call-friend":
            // Arkadaşı ara (telefon uygulaması açılacak)
            if let friendId = components.first {
                print("📞 Calling friend: \(friendId)")
                self.friendId = friendId
                self.activeTab = 1 // Contacts tab
            }

        default:
            print("❓ Unknown widget URL path: \(path)")
        }
    }

    /// Deep link'i temizle
    func clearDeepLink() {
        friendId = nil
        goalId = nil
        habitId = nil
        shouldShowFriendDetail = false
        shouldCompleteContact = false
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

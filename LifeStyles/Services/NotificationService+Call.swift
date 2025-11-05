//
//  NotificationService+Call.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Call reminder and Live Activity notification methods
//

import Foundation
import UserNotifications

extension NotificationService {

    // MARK: - Call Reminder Methods

    /// Arama hatırlatması planla (X dakika sonraya)
    /// - Parameters:
    ///   - friend: Arkadaş
    ///   - minutes: Kaç dakika sonra hatırlatsın
    ///   - useCallKit: CallKit kullan (test modu, varsayılan: false)
    func scheduleCallReminder(for friend: Friend, after minutes: Int, useCallKit: Bool = false) {
        Task {
            guard await checkPermission() else {
                print("❌ Bildirim izni yok")
                return
            }

            let identifier = "call-reminder-\(friend.id.uuidString)-\(Date().timeIntervalSince1970)"

            let content = NotificationCategoryManager.createContent(
                title: "📞 \(friend.name) ile İletişim Zamanı!",
                body: "Hatırlatma: \(friend.name) ile konuşma zamanı. Aramak için dokunun.",
                category: .callReminder,
                sound: .defaultCritical,
                userInfo: [
                    "friendId": friend.id.uuidString,
                    "friendName": friend.name,
                    "phoneNumber": friend.phoneNumber ?? "",
                    "useCallKit": useCallKit
                ]
            )

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: Double(minutes * 60),
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            do {
                try await center.add(request)
                print("✅ Arama hatırlatması planlandı: \(friend.name) - \(minutes) dakika sonra")

                showInfoToast(
                    title: "Hatırlatma Kuruldu",
                    message: "\(minutes) dakika sonra \(friend.name) ile iletişim hatırlatması gelecek",
                    emoji: "⏰"
                )
            } catch {
                print("❌ Arama hatırlatması planlanamadı: \(error)")
            }
        }
    }

    /// Time Sensitive bildirim gönder (Production kullanım)
    /// Ekran kilitli iken banner + ses + titreşim gösterir
    /// - Parameter friend: Arkadaş
    func sendTimeSensitiveCallReminder(for friend: Friend) {
        Task {
            guard await checkPermission() else {
                print("❌ Bildirim izni yok")
                return
            }

            let identifier = "call-reminder-immediate-\(friend.id.uuidString)"

            let content = NotificationCategoryManager.createContent(
                title: "📞 \(friend.name) Seni Bekliyor!",
                body: "Şimdi aramak için harika bir zaman. Hızlı aksiyonlar için kaydırın.",
                category: .callReminder,
                sound: .defaultCritical,
                userInfo: [
                    "friendId": friend.id.uuidString,
                    "friendName": friend.name,
                    "phoneNumber": friend.phoneNumber ?? ""
                ]
            )

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            do {
                try await center.add(request)
                print("✅ Time Sensitive bildirim gönderildi: \(friend.name)")
            } catch {
                print("❌ Time Sensitive bildirim gönderilemedi: \(error)")
            }
        }
    }

    /// Arama hatırlatmasını 10 dakika ertel (snooze)
    /// - Parameter friend: Arkadaş
    func snoozeCallReminder(for friend: Friend) {
        scheduleCallReminder(for: friend, after: 10)
        print("⏰ Arama hatırlatması 10 dakika ertelendi: \(friend.name)")
    }

    // MARK: - Live Activity Methods

    /// Live Activity ile arama hatırlatması başlat
    /// Dinamik Ada'da (Dynamic Island) gerçek zamanlı bildirim gösterir
    /// - Parameters:
    ///   - friend: Arkadaş
    ///   - minutes: Kaç dakika sonra
    @available(iOS 16.1, *)
    func startLiveActivityReminder(for friend: Friend, after minutes: Int) {
        let reminderTime = Date().addingTimeInterval(TimeInterval(minutes * 60))

        if let activityId = LiveActivityService.shared.startCallReminder(
            for: friend,
            reminderTime: reminderTime,
            duration: minutes
        ) {
            print("✅ Live Activity başlatıldı: \(friend.name) - \(minutes) dakika")

            showSuccessToast(
                title: "Hatırlatma Başlatıldı",
                message: "\(minutes) dakika sonra \(friend.name) ile konuşma hatırlatması Dynamic Island'da görünecek",
                emoji: "📱"
            )
        } else {
            print("❌ Live Activity başlatılamadı")
            showErrorToast(
                title: "Live Activity Hatası",
                message: "Live Activity başlatılamadı. Ayarları kontrol edin.",
                emoji: "⚠️"
            )

            // Fallback: Normal bildirim kullan
            scheduleCallReminder(for: friend, after: minutes)
        }
    }

    /// Live Activity'yi sonlandır
    /// - Parameter friend: Arkadaş
    @available(iOS 16.1, *)
    func endLiveActivityReminder(for friend: Friend) {
        LiveActivityService.shared.endCallReminder(friendId: friend.id.uuidString)
        print("✅ Live Activity sonlandırıldı: \(friend.name)")
    }

    /// Arkadaş için aktif Live Activity var mı kontrol et
    /// - Parameter friend: Arkadaş
    /// - Returns: Aktif Live Activity varsa true
    @available(iOS 16.1, *)
    func hasActiveLiveActivity(for friend: Friend) -> Bool {
        return LiveActivityService.shared.hasActiveActivity(for: friend.id.uuidString)
    }
}

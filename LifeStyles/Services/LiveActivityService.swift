//
//  LiveActivityService.swift
//  LifeStyles
//
//  Created by Claude on 30.10.2025.
//  Live Activity management for call reminders
//

import Foundation
import ActivityKit
import SwiftUI

@available(iOS 16.1, *)
@Observable
class LiveActivityService {

    static let shared = LiveActivityService()

    // Aktif Live Activity'leri takip et
    private var activeActivities: [String: Activity<CallReminderAttributes>] = [:]

    private init() {}

    // MARK: - Public API

    /// Arama hatırlatması için Live Activity başlat
    /// - Parameters:
    ///   - friend: Arkadaş
    ///   - reminderTime: Hatırlatma zamanı
    ///   - duration: Süre (dakika)
    /// - Returns: Activity ID veya nil
    @discardableResult
    func startCallReminder(
        for friend: Friend,
        reminderTime: Date,
        duration: Int
    ) -> String? {
        print("🚀 Live Activity başlatılıyor...")
        print("📱 Friend: \(friend.name)")
        print("⏰ Reminder Time: \(reminderTime)")
        print("⏱️ Duration: \(duration) dakika")

        // ActivityKit desteği kontrolü
        let authInfo = ActivityAuthorizationInfo()
        print("🔐 Activities Enabled: \(authInfo.areActivitiesEnabled)")
        print("🔐 Frequent Updates Enabled: \(authInfo.frequentPushesEnabled)")

        guard authInfo.areActivitiesEnabled else {
            print("❌ Live Activities devre dışı!")
            print("⚠️ Ayarlar → [Uygulamanız] → Live Activities açık olmalı")
            return nil
        }

        // Aynı arkadaş için zaten aktif bir activity var mı kontrol et
        if let existingActivity = activeActivities[friend.id.uuidString] {
            print("⚠️ Bu arkadaş için zaten aktif Live Activity var, güncelleniyor...")
            updateCallReminder(friendId: friend.id.uuidString, elapsedSeconds: 0)
            return friend.id.uuidString
        }

        // Attributes oluştur
        let attributes = CallReminderAttributes(
            friendId: friend.id.uuidString,
            friendEmoji: friend.avatarEmoji
        )

        // Initial state
        let initialState = CallReminderAttributes.ContentState(
            friendName: friend.name,
            phoneNumber: friend.phoneNumber,
            reminderTime: reminderTime,
            elapsedSeconds: 0,
            status: .waiting
        )

        do {
            // Live Activity başlat
            let activity = try Activity<CallReminderAttributes>.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )

            // Kaydet
            activeActivities[friend.id.uuidString] = activity

            print("✅ Live Activity başlatıldı: \(friend.name)")
            print("📱 Activity ID: \(activity.id)")

            // Timer başlat (her saniye güncelle)
            startTimer(for: friend.id.uuidString, reminderTime: reminderTime)

            return friend.id.uuidString

        } catch {
            print("❌ Live Activity başlatılamadı: \(error)")
            return nil
        }
    }

    /// Live Activity'yi güncelle
    func updateCallReminder(friendId: String, elapsedSeconds: Int) {
        guard let activity = activeActivities[friendId] else {
            print("⚠️ Aktif Live Activity bulunamadı: \(friendId)")
            return
        }

        Task {
            let currentState = activity.content.state
            let newStatus: CallReminderAttributes.ContentState.ReminderStatus =
                Date() > currentState.reminderTime ? .overdue : .waiting

            let newState = CallReminderAttributes.ContentState(
                friendName: currentState.friendName,
                phoneNumber: currentState.phoneNumber,
                reminderTime: currentState.reminderTime,
                elapsedSeconds: elapsedSeconds,
                status: newStatus
            )

            let contentState = ActivityContent(state: newState, staleDate: nil)
            await activity.update(contentState)
        }
    }

    /// Live Activity'yi sonlandır
    func endCallReminder(friendId: String, dismissalPolicy: ActivityUIDismissalPolicy = .default) {
        guard let activity = activeActivities[friendId] else {
            print("⚠️ Aktif Live Activity bulunamadı: \(friendId)")
            return
        }

        Task {
            await activity.end(dismissalPolicy: dismissalPolicy)
            activeActivities.removeValue(forKey: friendId)
            print("✅ Live Activity sonlandırıldı: \(friendId)")
        }
    }

    /// Tüm aktif Live Activity'leri sonlandır
    func endAllActivities() {
        Task {
            for (friendId, activity) in activeActivities {
                await activity.end(dismissalPolicy: .default)
                print("✅ Live Activity sonlandırıldı: \(friendId)")
            }
            activeActivities.removeAll()
        }
    }

    /// Aktif Live Activity var mı?
    func hasActiveActivity(for friendId: String) -> Bool {
        return activeActivities[friendId] != nil
    }

    /// Tüm aktif Live Activity'leri al
    func getAllActiveActivities() -> [String] {
        return Array(activeActivities.keys)
    }

    // MARK: - Private Methods

    /// Her saniye Live Activity'yi güncelle
    private func startTimer(for friendId: String, reminderTime: Date) {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            // Activity hala aktif mi?
            guard self.activeActivities[friendId] != nil else {
                timer.invalidate()
                return
            }

            // Geçen süreyi hesapla
            let elapsed = Int(Date().timeIntervalSince(reminderTime))

            // Güncelle
            self.updateCallReminder(friendId: friendId, elapsedSeconds: elapsed)

            // 1 saat sonra otomatik sonlandır
            if elapsed > 3600 {
                self.endCallReminder(friendId: friendId)
                timer.invalidate()
            }
        }
    }
}

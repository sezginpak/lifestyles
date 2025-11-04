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
import UIKit

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
        print("📱 iOS Version Check: \(ProcessInfo.processInfo.operatingSystemVersion)")

        guard authInfo.areActivitiesEnabled else {
            print("❌ Live Activities devre dışı!")
            print("⚠️ ÇÖZÜM 1: iPhone Ayarlar → LifeStyles → Live Activities (AÇIK yapın)")
            print("⚠️ ÇÖZÜM 2: iPhone Ayarlar → Ekran ve Parlaklık → Always On Display (AÇIK yapın - iPhone 14 Pro+)")
            print("⚠️ ÇÖZÜM 3: Uygulamayı kapatıp yeniden açın")
            print("⚠️ ÇÖZÜM 4: Telefonu yeniden başlatın")
            return nil
        }

        // Aynı arkadaş için zaten aktif bir activity var mı kontrol et
        if let existingActivity = activeActivities[friend.id.uuidString] {
            print("⚠️ Bu arkadaş için zaten aktif Live Activity var, güncelleniyor...")
            updateCallReminder(friendId: friend.id.uuidString, elapsedSeconds: 0)
            return friend.id.uuidString
        }

        // Profil fotoğrafını base64'e encode et (eğer varsa)
        // NOT: Live Activity boyut sınırı ~4KB, agresif sıkıştırma gerekli
        var profileImageBase64: String? = nil
        if let imageData = friend.profileImageData {
            // Çok küçült (max 40x40) ve agresif compress
            #if canImport(UIKit)
            if let uiImage = UIImage(data: imageData),
               let thumbnail = uiImage.preparingThumbnail(of: CGSize(width: 40, height: 40)),
               let jpegData = thumbnail.jpegData(compressionQuality: 0.3) {
                let base64 = jpegData.base64EncodedString()
                // 2KB'den küçükse kullan, değilse atla
                if base64.count < 2048 {
                    profileImageBase64 = base64
                    print("✅ Profil fotoğrafı eklendi: \(base64.count) bytes")
                } else {
                    print("⚠️ Profil fotoğrafı çok büyük, atlanıyor: \(base64.count) bytes")
                }
            }
            #endif
        }

        // Özel tarih hesaplamaları
        var hasUpcomingBirthday = false
        var daysUntilBirthday: Int? = nil

        if let specialDates = friend.specialDates {
            for specialDate in specialDates {
                // Doğum günü kontrolü (7 gün içinde)
                if specialDate.title.lowercased().contains("doğum") ||
                   specialDate.title.lowercased().contains("birthday") {
                    let days = specialDate.daysUntil
                    if days >= 0 && days <= 7 {
                        hasUpcomingBirthday = true
                        daysUntilBirthday = days
                    }
                }
            }
        }

        // Yıldönümü kontrolü (partner için, 14 gün içinde)
        var hasUpcomingAnniversary = false
        var daysUntilAnniversary: Int? = nil

        if friend.isPartner, let days = friend.daysUntilAnniversary {
            if days >= 0 && days <= 14 {
                hasUpcomingAnniversary = true
                daysUntilAnniversary = days
            }
        }

        // Balance'ı kısa formatta hazırla (boyut tasarrufu için)
        var shortBalance: String? = nil
        if friend.hasOutstandingTransactions {
            let balance = friend.balance
            if balance > 0 {
                shortBalance = "+₺\(Int(truncating: balance as NSDecimalNumber))"
            } else if balance < 0 {
                shortBalance = "-₺\(Int(truncating: abs(balance) as NSDecimalNumber))"
            }
        }

        // Attributes oluştur
        let attributes = CallReminderAttributes(
            friendId: friend.id.uuidString,
            friendEmoji: friend.avatarEmoji,
            profileImageBase64: profileImageBase64,
            relationshipType: friend.relationshipType.rawValue,
            isVIP: friend.isImportant,
            loveLanguage: friend.loveLanguage?.rawValue,
            contactFrequency: friend.frequency.rawValue,
            daysOverdue: friend.daysOverdue,
            hasDebt: friend.totalDebt > 0,
            hasCredit: friend.totalCredit > 0,
            balance: shortBalance,
            hasUpcomingBirthday: hasUpcomingBirthday,
            daysUntilBirthday: daysUntilBirthday,
            hasUpcomingAnniversary: hasUpcomingAnniversary,
            daysUntilAnniversary: daysUntilAnniversary
        )

        // Debug: Toplam attribute boyutu
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(attributes) {
            print("📦 Attributes boyutu: \(jsonData.count) bytes")
            if jsonData.count > 4000 {
                print("⚠️ UYARI: Attributes çok büyük! (>\(jsonData.count) bytes)")
            }
        }

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
            print("❌ Live Activity başlatılamadı!")
            print("🔍 Hata Detayı: \(error)")
            print("🔍 Hata Türü: \(type(of: error))")
            print("🔍 LocalizedDescription: \(error.localizedDescription)")

            // Özel hata mesajları
            let errorString = String(describing: error)
            if errorString.contains("attributesTooLarge") {
                print("⚠️ HATA: Attribute verisi çok büyük!")
                print("💡 Profil fotoğrafı boyutunu azaltın veya kaldırın")
            } else if errorString.contains("disabled") {
                print("⚠️ HATA: Live Activities devre dışı!")
                print("💡 iPhone Ayarlar → LifeStyles → Live Activities açın")
            }

            print("\n💡 Genel Çözümler:")
            print("1. iPhone Ayarlar → LifeStyles → Live Activities AÇIK olmalı")
            print("2. Clean Build (⌘+Shift+K) yapıp tekrar deneyin")
            print("3. Telefonu yeniden başlatın")

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

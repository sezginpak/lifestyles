//
//  CallReminderAttributes.swift
//  LifeStyles
//
//  Created by Claude on 30.10.2025.
//  Live Activity attributes for call reminders
//

import Foundation
import ActivityKit

/// Arama hatırlatması için Live Activity attributes
struct CallReminderAttributes: ActivityAttributes {

    /// Static (değişmeyen) content
    public struct ContentState: Codable, Hashable {
        /// Arkadaş adı
        var friendName: String

        /// Telefon numarası
        var phoneNumber: String?

        /// Hatırlatma zamanı (timestamp)
        var reminderTime: Date

        /// Geçen süre (saniye)
        var elapsedSeconds: Int

        /// Durum (waiting, overdue)
        var status: ReminderStatus

        enum ReminderStatus: String, Codable, Hashable {
            case waiting = "Bekliyor"
            case overdue = "Gecikti"
            case calling = "Aranıyor"
        }
    }

    /// Fixed (sabit) data
    var friendId: String
    var friendEmoji: String?
    var profileImageBase64: String? // Profil fotoğrafı (base64 encoded)

    // Dinamik UI için yeni alanlar
    var relationshipType: String // "partner", "family", "colleague", "friend"
    var isVIP: Bool // Önemli kişi mi?
    var loveLanguage: String? // Sevgi dili (partner için)
    var contactFrequency: String // İletişim sıklığı
    var daysOverdue: Int // Kaç gün gecikmiş

    // Borç/Alacak
    var hasDebt: Bool // Borç var mı?
    var hasCredit: Bool // Alacak var mı?
    var balance: String? // Formatted balance (örn: "+₺300" veya "-₺500")

    // Özel Tarihler
    var hasUpcomingBirthday: Bool // 7 gün içinde doğum günü var mı?
    var daysUntilBirthday: Int? // Doğum gününe kaç gün kaldı
    var hasUpcomingAnniversary: Bool // 14 gün içinde yıldönümü var mı? (partner için)
    var daysUntilAnniversary: Int? // Yıldönümüne kaç gün kaldı
}

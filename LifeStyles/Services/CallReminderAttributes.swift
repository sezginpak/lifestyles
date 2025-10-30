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
}

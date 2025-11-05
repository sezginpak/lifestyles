//
//  CallReminderIntents.swift
//  CallReminderWidget
//
//  App Intents for Live Activity actions
//  Ensures widget closes after action

import AppIntents
import ActivityKit
import SwiftUI
import Foundation

// MARK: - Complete Call Intent

/// İletişimi tamamla ve widget'ı kapat
@available(iOS 16.0, *)
struct CompleteCallIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "İletişimi Tamamla"
    static var description = IntentDescription("İletişimi tamamlanmış olarak işaretle ve widget'ı kapat")

    @Parameter(title: "Friend ID")
    var friendId: String

    init() {
        self.friendId = ""
    }

    init(friendId: String) {
        self.friendId = friendId
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        // Widget'ı kapat
        await endActivity()

        // Deep link yerine direkt return - ana uygulama widgetURL'den açılacak
        return .result()
    }

    /// Tüm aktif CallReminder activity'lerini sonlandır
    private func endActivity() async {
        if #available(iOS 16.2, *) {
            for activity in Activity<CallReminderAttributes>.activities {
                if activity.attributes.friendId == friendId {
                    await activity.end(nil, dismissalPolicy: .immediate)
                }
            }
        }
    }
}

// MARK: - Call Phone Intent

/// Telefon ile ara (URL açma widget yerine sistem tarafından handle edilir)
@available(iOS 16.0, *)
struct CallPhoneIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Telefon Ara"
    static var description = IntentDescription("Telefon ile ara")

    @Parameter(title: "Friend ID")
    var friendId: String

    @Parameter(title: "Phone Number")
    var phoneNumber: String

    init() {
        self.friendId = ""
        self.phoneNumber = ""
    }

    init(friendId: String, phoneNumber: String) {
        self.friendId = friendId
        self.phoneNumber = phoneNumber
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        // Intent'ten direkt tel: URL'i kullanamayız
        // Bunun yerine widget'tan Link kullanacağız

        // Widget'ı kapat
        await endActivity()

        return .result()
    }

    private func endActivity() async {
        if #available(iOS 16.2, *) {
            for activity in Activity<CallReminderAttributes>.activities {
                if activity.attributes.friendId == friendId {
                    await activity.end(nil, dismissalPolicy: .immediate)
                }
            }
        }
    }
}

// MARK: - Send Message Intent

/// Mesaj gönder (URL açma widget yerine sistem tarafından handle edilir)
@available(iOS 16.0, *)
struct SendMessageIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Mesaj Gönder"
    static var description = IntentDescription("Mesaj gönder")

    @Parameter(title: "Friend ID")
    var friendId: String

    @Parameter(title: "Phone Number")
    var phoneNumber: String

    init() {
        self.friendId = ""
        self.phoneNumber = ""
    }

    init(friendId: String, phoneNumber: String) {
        self.friendId = friendId
        self.phoneNumber = phoneNumber
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        // Intent'ten direkt sms: URL'i kullanamayız
        // Bunun yerine widget'tan Link kullanacağız

        // Widget'ı kapat
        await endActivity()

        return .result()
    }

    private func endActivity() async {
        if #available(iOS 16.2, *) {
            for activity in Activity<CallReminderAttributes>.activities {
                if activity.attributes.friendId == friendId {
                    await activity.end(nil, dismissalPolicy: .immediate)
                }
            }
        }
    }
}

// MARK: - Snooze Intent

/// Hatırlatmayı ertele
@available(iOS 16.0, *)
struct SnoozeReminderIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Hatırlatmayı Ertele"
    static var description = IntentDescription("10 dakika sonra tekrar hatırlat")

    @Parameter(title: "Friend ID")
    var friendId: String

    init() {
        self.friendId = ""
    }

    init(friendId: String) {
        self.friendId = friendId
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        // Widget'ı kapat
        await endActivity()

        return .result()
    }

    private func endActivity() async {
        if #available(iOS 16.2, *) {
            for activity in Activity<CallReminderAttributes>.activities {
                if activity.attributes.friendId == friendId {
                    await activity.end(nil, dismissalPolicy: .immediate)
                }
            }
        }
    }
}

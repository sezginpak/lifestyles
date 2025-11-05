//
//  FriendsWidgetIntents.swift
//  FriendsWidget
//
//  App Intents for Friends Widget actions
//  Call friend, message friend, open friend detail
//
//  Created by Claude on 04.11.2025.
//

import AppIntents
import Foundation
import WidgetKit
import UIKit

// MARK: - Call Friend Intent

struct CallFriendIntent: AppIntent {
    static var title: LocalizedStringResource = "Arkadaşı Ara"
    static var description = IntentDescription("Arkadaşı telefon ile arar")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Friend ID")
    var friendId: String

    @Parameter(title: "Phone Number")
    var phoneNumber: String

    func perform() async throws -> some IntentResult {
        // Telefon numarasını temizle
        let cleanPhone = phoneNumber.replacingOccurrences(of: " ", with: "")

        // Telefon URL'ini aç (sistem otomatik olarak ana uygulamayı kullanır)
        if let url = URL(string: "tel:\(cleanPhone)") {
            return .result(opensIntent: OpenURLIntent(url))
        }

        return .result()
    }
}

// MARK: - Message Friend Intent

struct MessageFriendIntent: AppIntent {
    static var title: LocalizedStringResource = "Arkadaşa Mesaj Gönder"
    static var description = IntentDescription("Arkadaşa mesaj gönderir")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Friend ID")
    var friendId: String

    @Parameter(title: "Phone Number")
    var phoneNumber: String

    func perform() async throws -> some IntentResult {
        // Telefon numarasını temizle
        let cleanPhone = phoneNumber.replacingOccurrences(of: " ", with: "")

        // Mesaj URL'ini aç
        if let url = URL(string: "sms:\(cleanPhone)") {
            return .result(opensIntent: OpenURLIntent(url))
        }

        return .result()
    }
}

// MARK: - Open Friend Detail Intent

struct OpenFriendDetailIntent: AppIntent {
    static var title: LocalizedStringResource = "Arkadaş Detayını Aç"
    static var description = IntentDescription("Arkadaş detay sayfasını açar")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Friend ID")
    var friendId: String

    func perform() async throws -> some IntentResult {
        // Ana uygulamayı aç ve friend detail'a git
        if let url = URL(string: "lifestyles://friend-detail/\(friendId)") {
            return .result(opensIntent: OpenURLIntent(url))
        }

        return .result()
    }
}

// MARK: - Complete Contact Intent

struct CompleteContactIntent: AppIntent {
    static var title: LocalizedStringResource = "İletişim Tamamlandı"
    static var description = IntentDescription("İletişimi tamamlandı olarak işaretle")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Friend ID")
    var friendId: String

    func perform() async throws -> some IntentResult {
        // Ana uygulamayı aç ve iletişim tamamla
        if let url = URL(string: "lifestyles://complete-contact/\(friendId)") {
            return .result(opensIntent: OpenURLIntent(url))
        }

        return .result()
    }
}

// MARK: - Refresh Widget Intent

struct RefreshFriendsWidgetIntent: AppIntent {
    static var title: LocalizedStringResource = "Widget'ı Yenile"
    static var description = IntentDescription("Arkadaş widget'ını yeniler")

    func perform() async throws -> some IntentResult {
        // Widget'ı yenile
        WidgetCenter.shared.reloadAllTimelines()

        return .result()
    }
}

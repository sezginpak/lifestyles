//
//  NotificationAttachment.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Rich media attachment creator for notifications
//

import Foundation
import UserNotifications
import UIKit

// MARK: - Notification Attachment Creator

class NotificationAttachmentCreator {

    static let shared = NotificationAttachmentCreator()

    private init() {}

    // MARK: - Emoji Attachment

    /// Emoji'den image oluştur ve notification attachment yap
    func createEmojiAttachment(emoji: String, size: CGSize = CGSize(width: 300, height: 300)) -> UNNotificationAttachment? {
        // Emoji'den UIImage oluştur
        guard let image = renderEmoji(emoji, size: size) else {
            print("⚠️ Emoji render edilemedi: \(emoji)")
            return nil
        }

        // Geçici dosyaya kaydet
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")

        guard let imageData = image.pngData() else {
            print("⚠️ Image data oluşturulamadı")
            return nil
        }

        do {
            try imageData.write(to: tempURL)
            let attachment = try UNNotificationAttachment(identifier: "emoji-\(emoji)", url: tempURL, options: nil)
            return attachment
        } catch {
            print("❌ Attachment oluşturma hatası: \(error)")
            return nil
        }
    }

    /// Emoji'yi UIImage'e render et
    private func renderEmoji(_ emoji: String, size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            // Arka plan (gradient)
            let gradientColors = [
                UIColor.systemBlue.cgColor,
                UIColor.systemPurple.cgColor
            ]

            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: gradientColors as CFArray,
                locations: [0.0, 1.0]
            )!

            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )

            // Emoji text
            let fontSize = size.height * 0.6
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: fontSize),
                .foregroundColor: UIColor.white
            ]

            let emojiString = emoji as NSString
            let textSize = emojiString.size(withAttributes: attributes)

            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )

            emojiString.draw(in: textRect, withAttributes: attributes)
        }

        return image
    }

    // MARK: - Avatar Attachment

    /// Friend için avatar attachment oluştur
    func createAvatarAttachment(emoji: String, name: String) -> UNNotificationAttachment? {
        return createEmojiAttachment(emoji: emoji, size: CGSize(width: 400, height: 400))
    }

    /// Kategori için icon attachment oluştur
    func createCategoryIcon(category: NotificationCategory) -> UNNotificationAttachment? {
        let emoji: String

        switch category {
        case .contactReminder:
            emoji = "👥"
        case .goalReminder:
            emoji = "🎯"
        case .habitReminder:
            emoji = "⭐"
        case .activitySuggestion:
            emoji = "🏃"
        case .goOutside:
            emoji = "🌞"
        case .contactCompleted:
            emoji = "✅"
        case .weeklySummary:
            emoji = "📊"
        case .motivation:
            emoji = "💪"
        case .aiGoalMotivation:
            emoji = "🤖"
        case .aiHabitSuggestion:
            emoji = "💡"
        case .aiContactMessage:
            emoji = "✉️"
        case .geofenceHome:
            emoji = "🏠"
        case .geofenceActivity:
            emoji = "📍"
        case .streakWarning:
            emoji = "🔥"
        case .badgeEarned:
            emoji = "🏆"
        case .levelUp:
            emoji = "⬆️"
        }

        return createEmojiAttachment(emoji: emoji)
    }

    // MARK: - Sound Management

    /// Custom notification sound seç
    func getSound(for category: NotificationCategory) -> UNNotificationSound {
        switch category {
        case .streakWarning:
            return .defaultCritical // Kritik uyarı sesi
        case .badgeEarned, .levelUp:
            return .default // Başarı sesi (default ile başla)
        case .motivation:
            return .default // Yumuşak ses
        default:
            return .default
        }
    }

    // MARK: - Attachment Options

    /// Attachment için options
    private func attachmentOptions() -> [String: Any] {
        return [
            UNNotificationAttachmentOptionsTypeHintKey: "public.png"
        ]
    }
}

// MARK: - Content Extension Helper

extension UNMutableNotificationContent {

    /// Rich media ekle (emoji attachment + custom sound)
    func addRichMedia(emoji: String? = nil, category: NotificationCategory? = nil) {
        // Emoji attachment
        if let emoji = emoji {
            if let attachment = NotificationAttachmentCreator.shared.createEmojiAttachment(emoji: emoji) {
                self.attachments = [attachment]
            }
        }
        // Kategori icon'u
        else if let category = category {
            if let attachment = NotificationAttachmentCreator.shared.createCategoryIcon(category: category) {
                self.attachments = [attachment]
            }
        }

        // Custom sound
        if let category = category {
            self.sound = NotificationAttachmentCreator.shared.getSound(for: category)
        }
    }

    /// Friend avatar ekle
    func addFriendAvatar(emoji: String, name: String) {
        if let attachment = NotificationAttachmentCreator.shared.createAvatarAttachment(emoji: emoji, name: name) {
            self.attachments = [attachment]
        }
    }
}

// MARK: - Preview Helper

#if DEBUG
extension NotificationAttachmentCreator {

    /// Test için emoji attachment oluştur
    func testEmojiAttachment() {
        let emojis = ["👋", "🎯", "💪", "🏆", "🌞"]

        for emoji in emojis {
            if let attachment = createEmojiAttachment(emoji: emoji) {
                print("✅ Test başarılı: \(emoji) - \(attachment.url)")
            } else {
                print("❌ Test başarısız: \(emoji)")
            }
        }
    }
}
#endif

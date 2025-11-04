//
//  RichNotificationBuilder.swift
//  LifeStyles
//
//  Builds rich, interactive notifications
//  Zengin ve etkileşimli bildirimler oluşturur
//

import Foundation
import UserNotifications

class RichNotificationBuilder {
    static let shared = RichNotificationBuilder()

    private init() {}

    // MARK: - Builder Methods

    /// Basit bildirim oluştur
    func buildSimple(
        title: String,
        body: String,
        sound: UNNotificationSound = .default
    ) -> UNMutableNotificationContent {

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound
        return content
    }

    /// Friend reminder bildirimi oluştur
    func buildFriendReminder(
        friend: Friend,
        daysOverdue: Int
    ) -> UNMutableNotificationContent {

        let content = UNMutableNotificationContent()

        // Title ve body
        content.title = "📞 \(friend.name) ile İletişim Zamanı"
        if daysOverdue > 0 {
            content.body = "\(daysOverdue) gün gecikti. Aramak veya mesaj göndermek için dokunun."
        } else {
            content.body = "İletişim kurma zamanı geldi!"
        }

        // Category (actions için)
        content.categoryIdentifier = "CONTACT_REMINDER"

        // Sound (Important ise kritik)
        content.sound = friend.isImportant ? .defaultCritical : .default

        // User info
        content.userInfo = [
            "friendId": friend.id.uuidString,
            "friendName": friend.name,
            "daysOverdue": daysOverdue,
            "isImportant": friend.isImportant
        ]

        // Interrupt level
        if #available(iOS 15.0, *) {
            content.interruptionLevel = friend.isImportant || daysOverdue > 7 ? .timeSensitive : .active
        }

        // Badge
        content.badge = 1

        return content
    }

    /// Goal reminder bildirimi oluştur
    func buildGoalReminder(
        goal: Goal,
        daysLeft: Int?
    ) -> UNMutableNotificationContent {

        let content = UNMutableNotificationContent()
        content.title = "🎯 Hedef Hatırlatması"

        if let days = daysLeft {
            content.body = "\(goal.title) için \(days) gün kaldı! Progress: \(Int(goal.progress * 100))%"
        } else {
            content.body = "\(goal.title) - Bugün üzerinde çalışmayı unutma!"
        }

        content.categoryIdentifier = "GOAL_REMINDER"
        content.sound = .default

        content.userInfo = [
            "goalId": goal.id.uuidString,
            "goalTitle": goal.title,
            "progress": goal.progress
        ]

        return content
    }

    /// Habit reminder bildirimi oluştur
    func buildHabitReminder(
        habit: Habit,
        currentStreak: Int = 0
    ) -> UNMutableNotificationContent {

        let content = UNMutableNotificationContent()
        content.title = "⭐ Alışkanlık Zamanı"
        content.body = "\(habit.name) yapma zamanı!"

        if currentStreak > 0 {
            content.body += " 🔥 \(currentStreak) günlük streak'ini koru!"
        }

        content.categoryIdentifier = "HABIT_REMINDER"
        content.sound = .default

        content.userInfo = [
            "habitId": habit.id.uuidString,
            "habitName": habit.name,
            "streak": currentStreak
        ]

        if #available(iOS 15.0, *) {
            content.interruptionLevel = currentStreak > 7 ? .timeSensitive : .active
        }

        return content
    }

    /// Streak warning bildirimi oluştur
    func buildStreakWarning(
        currentStreak: Int,
        hoursRemaining: Int
    ) -> UNMutableNotificationContent {

        let content = UNMutableNotificationContent()
        content.title = "🔥 Dikkat! Streak Tehlikede!"
        content.body = "\(currentStreak) günlük streak'ini kaybetme! \(hoursRemaining) saat kaldı."

        content.categoryIdentifier = "STREAK_WARNING"
        content.sound = .defaultCritical

        content.userInfo = [
            "streak": currentStreak,
            "hoursRemaining": hoursRemaining
        ]

        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }

        content.badge = 1

        return content
    }

    /// Activity suggestion bildirimi oluştur
    func buildActivitySuggestion(
        title: String,
        description: String,
        location: String? = nil
    ) -> UNMutableNotificationContent {

        let content = UNMutableNotificationContent()
        content.title = "💡 \(title)"
        content.body = description

        if let location = location {
            content.subtitle = "📍 \(location)"
        }

        content.categoryIdentifier = "ACTIVITY_SUGGESTION"
        content.sound = .default

        content.userInfo = [
            "suggestionTitle": title,
            "location": location ?? ""
        ]

        if #available(iOS 15.0, *) {
            content.interruptionLevel = .passive
        }

        return content
    }

    /// Motivation bildirimi oluştur
    func buildMotivation(
        message: String
    ) -> UNMutableNotificationContent {

        let content = UNMutableNotificationContent()
        content.title = "💪 Günlük Motivasyon"
        content.body = message

        content.categoryIdentifier = "MOTIVATION"
        content.sound = .default

        if #available(iOS 15.0, *) {
            content.interruptionLevel = .passive
        }

        return content
    }

    /// Achievement bildirimi oluştur
    func buildAchievement(
        title: String,
        description: String,
        emoji: String = "🏆"
    ) -> UNMutableNotificationContent {

        let content = UNMutableNotificationContent()
        content.title = "\(emoji) \(title)"
        content.body = description

        content.categoryIdentifier = "BADGE_EARNED"
        content.sound = .default

        content.userInfo = [
            "achievementTitle": title,
            "emoji": emoji
        ]

        if #available(iOS 15.0, *) {
            content.interruptionLevel = .active
        }

        content.badge = 1

        return content
    }

    // MARK: - Advanced Features

    /// Inline reply destekli bildirim
    func addInlineReply(
        to content: UNMutableNotificationContent,
        actionIdentifier: String = "INLINE_REPLY"
    ) {
        // Inline reply için özel action category gerekir
        // NotificationCategory'de tanımlanmalı
        content.userInfo["supportsInlineReply"] = true
    }

    /// Media attachment ekle
    func addMediaAttachment(
        to content: UNMutableNotificationContent,
        imageUrl: URL?
    ) async throws {

        guard let url = imageUrl else { return }

        // Download image
        let (data, _) = try await URLSession.shared.data(from: url)

        // Save to temp
        let tempDir = FileManager.default.temporaryDirectory
        let fileUrl = tempDir.appendingPathComponent(UUID().uuidString + ".jpg")
        try data.write(to: fileUrl)

        // Create attachment
        let attachment = try UNNotificationAttachment(
            identifier: "image",
            url: fileUrl,
            options: nil
        )

        content.attachments = [attachment]
    }

    /// Thread grouping ekle
    func addThreadGrouping(
        to content: UNMutableNotificationContent,
        threadId: String,
        summaryArgument: String? = nil
    ) {
        content.threadIdentifier = threadId

        if let summary = summaryArgument {
            content.summaryArgument = summary
        }
    }

    /// Target content identifier ekle (deep linking için)
    func addTargetContent(
        to content: UNMutableNotificationContent,
        targetIdentifier: String
    ) {
        if #available(iOS 15.0, *) {
            content.targetContentIdentifier = targetIdentifier
        }
    }

    /// Relevance score ekle (iOS 15+)
    func addRelevanceScore(
        to content: UNMutableNotificationContent,
        score: Double
    ) {
        if #available(iOS 15.0, *) {
            content.relevanceScore = max(0.0, min(1.0, score))
        }
    }
}

// MARK: - Content Extensions

extension UNMutableNotificationContent {

    /// Priority level'a göre interrupt level ayarla
    func setInterruptionLevel(for priority: PriorityLevel) {
        if #available(iOS 15.0, *) {
            switch priority {
            case .critical:
                self.interruptionLevel = .timeSensitive
            case .high:
                self.interruptionLevel = .active
            case .normal:
                self.interruptionLevel = .active
            case .low:
                self.interruptionLevel = .passive
            case .minimal:
                self.interruptionLevel = .passive
            }
        }
    }

    /// Sound level'a göre ses ayarla
    func setSound(for soundLevel: SoundLevel) {
        switch soundLevel {
        case .critical:
            self.sound = .defaultCritical
        case .loud, .normal:
            self.sound = .default
        case .soft:
            self.sound = .default // iOS'da soft sound yok
        case .silent:
            self.sound = nil
        }
    }
}

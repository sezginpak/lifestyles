//
//  NotificationService+Mood.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Mood and Journal notification methods
//

import Foundation
import UserNotifications

extension NotificationService {

    // MARK: - Mood Reminders

    /// Günlük mood hatırlatması zamanla
    /// - Parameters:
    ///   - hour: Saat (0-23, varsayılan: 20)
    ///   - minute: Dakika (0-59, varsayılan: 0)
    func scheduleDailyMoodReminder(hour: Int = 20, minute: Int = 0) {
        cancelDailyMoodReminder()

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let content = UNMutableNotificationContent()
        content.title = "Bugün Nasıl Hissettiniz?"
        content.body = "Ruh halinizi kaydetmeyi unutmayın 😊"
        content.sound = .default
        content.categoryIdentifier = "mood_reminder"
        content.userInfo = ["type": "mood_reminder"]

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily_mood_reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Mood reminder zamanlama hatası: \(error)")
            } else {
                print("✅ Günlük mood reminder zamanlandı: \(hour):\(String(format: "%02d", minute))")
            }
        }
    }

    /// Günlük mood reminder'ı iptal et
    func cancelDailyMoodReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_mood_reminder"])
    }

    /// Mood tracking teşvik bildirimi
    /// Belirli gün sayısı mood kaydı yapılmadığında gönderilir
    func sendMoodEncouragementNotification(daysWithoutMood: Int) async throws {
        let title = "Mood Tracking'e Devam!"
        let body: String

        if daysWithoutMood == 1 {
            body = "Dün mood kaydı yapmadınız. Bugün kaydetmeyi unutmayın!"
        } else {
            body = "\(daysWithoutMood) gündür mood kaydı yapmıyorsunuz. Yeniden başlamak için harika bir zaman!"
        }

        try await sendSmartNotification(
            title: title,
            body: body,
            category: .goalReminder,
            priority: .normal,
            respectQuietHours: true,
            emoji: "😊",
            userInfo: ["type": "mood_encouragement", "days": daysWithoutMood]
        )
    }

    /// Streak kırılma uyarısı gönder (Mood için)
    /// Mood tracking streak'i kaybetmek üzere iken tetiklenir
    func sendStreakBreakWarning(currentStreak: Int) async throws {
        guard currentStreak > 0 else { return }

        let title = "Streak Kırılıyor! 🔥"
        let body = "\(currentStreak) günlük streak'inizi kaybetmek üzeresiniz. Bugün mood'unuzu kaydedin!"

        try await sendSmartNotification(
            title: title,
            body: body,
            category: .habitReminder,
            priority: .high,
            respectQuietHours: false,
            emoji: "🔥",
            userInfo: ["type": "streak_warning", "streak": currentStreak]
        )
    }

    // MARK: - Journal Reminders

    /// Haftalık journal hatırlatması zamanla
    /// - Parameters:
    ///   - weekday: Gün (1=Pazar, 7=Cumartesi, varsayılan: 7=Cumartesi)
    ///   - hour: Saat (0-23, varsayılan: 19)
    ///   - minute: Dakika (0-59, varsayılan: 0)
    func scheduleWeeklyJournalReminder(weekday: Int = 7, hour: Int = 19, minute: Int = 0) {
        cancelWeeklyJournalReminder()

        var dateComponents = DateComponents()
        dateComponents.weekday = weekday
        dateComponents.hour = hour
        dateComponents.minute = minute

        let content = UNMutableNotificationContent()
        content.title = "Haftalık Journal Zamanı"
        content.body = "Bu haftayı değerlendirmek için journal yazın 📝"
        content.sound = .default
        content.categoryIdentifier = "journal_reminder"
        content.userInfo = ["type": "journal_reminder"]

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "weekly_journal_reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Journal reminder zamanlama hatası: \(error)")
            } else {
                let weekdayName = ["", "Pazar", "Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi"][min(weekday, 7)]
                print("✅ Haftalık journal reminder zamanlandı: \(weekdayName) \(hour):\(String(format: "%02d", minute))")
            }
        }
    }

    /// Haftalık journal reminder'ı iptal et
    func cancelWeeklyJournalReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["weekly_journal_reminder"])
    }
}

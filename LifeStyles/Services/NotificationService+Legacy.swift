//
//  NotificationService+Legacy.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Legacy notification methods preserved for backward compatibility
//

import Foundation
import UserNotifications

// MARK: - Legacy Notification Methods
// Bu metodlar backward compatibility için korunmuştur.
// Yeni kod için Smart Notification API kullanın.

extension NotificationService {

    // MARK: - Contact Reminders

    /// Kişi hatırlatıcısı gönder (Legacy)
    /// Yeni kod için sendSmartNotification() veya sendFriendNotification() kullan
    func scheduleContactReminder(contactName: String, daysSince: Int) {
        Task {
            guard await checkPermission() else {
                print("⚠️ Bildirim izni yok - Hatırlatıcı gönderilemedi")
                return
            }

            let content = UNMutableNotificationContent()
            content.title = String(
                localized: "notification.contact.reminder.title",
                comment: "Contact reminder title"
            )
            content.body = String(
                format: NSLocalizedString(
                    "notification.contact.reminder.body",
                    comment: "Contact reminder body"
                ),
                contactName,
                daysSince
            )
            content.sound = .default
            content.categoryIdentifier = "CONTACT_REMINDER"

            let randomSeconds = TimeInterval.random(in: 3600...14400)
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: randomSeconds,
                repeats: false
            )
            let request = UNNotificationRequest(
                identifier: "contact-\(contactName)-\(UUID().uuidString)",
                content: content,
                trigger: trigger
            )

            do {
                try await center.add(request)
                print("✅ Hatırlatıcı eklendi: \(contactName)")
            } catch {
                print("❌ Hatırlatıcı eklenemedi: \(error.localizedDescription)")
            }
        }
    }

    /// İletişim tamamlandı bildirimi
    func sendContactCompletedNotification(for friend: Friend) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification.contact.saved.title", comment: "Contact saved")
        content.body = "\(friend.name) ile iletişiminiz kaydedildi. Sonraki iletişim: \(formatDateLegacy(friend.nextContactDate))"
        content.sound = .default
        content.categoryIdentifier = "CONTACT_COMPLETED"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "contact-completed-\(friend.id.uuidString)",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    /// İletişim gerekli bildirimi (günlük kontrol - rastgele saatlerde)
    func scheduleContactReminders(for friends: [Friend]) {
        center.removePendingNotificationRequests(withIdentifiers: friends.map { "contact-reminder-\($0.id.uuidString)" })

        for friend in friends where friend.needsContact {
            let content = UNMutableNotificationContent()
            content.title = String(localized: "notification.contact.time.title", comment: "Contact time")
            content.body = "\(friend.name) ile iletişim kurma zamanı geldi. \(friend.daysOverdue) gün gecikti."
            content.sound = .default
            content.categoryIdentifier = "CONTACT_REMINDER"

            let timeSlots = [
                (start: 9, end: 12),
                (start: 14, end: 18),
                (start: 19, end: 21)
            ]

            let randomSlot = timeSlots.randomElement()!
            let randomHour = Int.random(in: randomSlot.start...randomSlot.end)
            let randomMinute = Int.random(in: 0...59)

            var dateComponents = DateComponents()
            dateComponents.hour = randomHour
            dateComponents.minute = randomMinute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "contact-reminder-\(friend.id.uuidString)",
                content: content,
                trigger: trigger
            )

            center.add(request)
            print("📅 \(friend.name) için bildirim zamanlandı: Her gün \(randomHour):\(String(format: "%02d", randomMinute))")
        }
    }

    /// Haftalık iletişim özeti
    func sendWeeklyContactSummary(totalContacts: Int, needsAttention: Int, completed: Int) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification.weekly.summary.title", comment: "Weekly summary")
        content.body = "Bu hafta \(completed)/\(totalContacts) kişiyle iletişim kurdunuz. \(needsAttention) kişi bekliyor."
        content.sound = .default
        content.categoryIdentifier = "WEEKLY_SUMMARY"

        var dateComponents = DateComponents()
        dateComponents.weekday = 1
        dateComponents.hour = 20
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "weekly-contact-summary",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    // MARK: - Activity Suggestions

    /// Aktivite önerisi bildirimi (Legacy)
    func sendActivitySuggestion(title: String, description: String) {
        Task {
            guard await checkPermission() else {
                print("⚠️ Bildirim izni yok - Aktivite önerisi gönderilemedi")
                return
            }

            let lastSentKey = "lastActivitySuggestionNotification"
            if let lastSent = UserDefaults.standard.object(forKey: lastSentKey) as? Date {
                let hoursSinceLastNotification = Date().timeIntervalSince(lastSent) / 3600
                if hoursSinceLastNotification < 1 {
                    let minutesRemaining = Int((1 - hoursSinceLastNotification) * 60)
                    print("⏳ Aktivite önerisi cooldown'da (\(minutesRemaining) dk kaldı)")
                    return
                }
            }

            center.removePendingNotificationRequests(withIdentifiers: ["activity-suggestion"])

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = description
            content.sound = .default
            content.categoryIdentifier = "ACTIVITY_SUGGESTION"

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1800, repeats: false)
            let request = UNNotificationRequest(
                identifier: "activity-suggestion",
                content: content,
                trigger: trigger
            )

            do {
                try await center.add(request)
                UserDefaults.standard.set(Date(), forKey: lastSentKey)
                print("✅ Aktivite önerisi bildirimi gönderildi: \(title)")
            } catch {
                print("❌ Aktivite önerisi gönderilemedi: \(error)")
            }
        }
    }

    /// "Evden çık" bildirimi (Legacy)
    func sendGoOutsideReminder(hoursAtHome: Int) {
        Task {
            guard await checkPermission() else {
                print("⚠️ Bildirim izni yok - Evden çık hatırlatıcısı gönderilemedi")
                return
            }

            let lastSentKey = "lastGoOutsideNotification"
            if let lastSent = UserDefaults.standard.object(forKey: lastSentKey) as? Date {
                let hoursSinceLastNotification = Date().timeIntervalSince(lastSent) / 3600
                if hoursSinceLastNotification < 2 {
                    print("⏳ Go outside bildirimi cooldown'da")
                    return
                }
            }

            center.removePendingNotificationRequests(withIdentifiers: ["go-outside"])

            let content = UNMutableNotificationContent()
            content.title = String(localized: "notification.go.outside.title", comment: "Go outside")
            content.body = "\(hoursAtHome) saattir evdesiniz. Biraz hava almaya ne dersiniz?"
            content.sound = .default
            content.categoryIdentifier = "GO_OUTSIDE"

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 600, repeats: false)
            let request = UNNotificationRequest(
                identifier: "go-outside",
                content: content,
                trigger: trigger
            )

            do {
                try await center.add(request)
                UserDefaults.standard.set(Date(), forKey: lastSentKey)
                print("✅ Go outside bildirimi gönderildi")
            } catch {
                print("❌ Go outside bildirimi gönderilemedi: \(error)")
            }
        }
    }

    // MARK: - Goal & Habit Reminders

    /// Hedef hatırlatıcısı (Legacy)
    func scheduleGoalReminder(goalTitle: String, daysLeft: Int) {
        Task {
            guard await checkPermission() else {
                print("⚠️ Bildirim izni yok - Hedef hatırlatıcısı oluşturulamadı")
                return
            }

            let content = UNMutableNotificationContent()

            switch currentLanguage {
            case .turkish:
                content.title = String(localized: "notification.goal.reminder.title", comment: "Goal reminder")
                content.body = "\(goalTitle) için \(daysLeft) gün kaldı!"
            case .english:
                content.title = "Goal Reminder 🎯"
                content.body = "\(daysLeft) days left for \(goalTitle)!"
            }

            content.sound = .default
            content.categoryIdentifier = "GOAL_REMINDER"

            var dateComponents = DateComponents()
            dateComponents.hour = 9
            dateComponents.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "goal-\(goalTitle)-\(UUID().uuidString)",
                content: content,
                trigger: trigger
            )

            do {
                try await center.add(request)
                print("✅ Hedef hatırlatıcısı oluşturuldu: \(goalTitle)")
            } catch {
                print("❌ Hedef hatırlatıcısı oluşturulamadı: \(error)")
            }
        }
    }

    /// Alışkanlık hatırlatıcısı (Legacy)
    func scheduleHabitReminder(habitName: String, at time: Date) {
        Task {
            guard await checkPermission() else {
                print("⚠️ Bildirim izni yok - Alışkanlık hatırlatıcısı oluşturulamadı")
                return
            }

            let content = UNMutableNotificationContent()
            content.title = String(localized: "notification.habit.reminder.title", comment: "Habit reminder")
            content.body = "\(habitName) yapma zamanı geldi!"
            content.sound = .default
            content.categoryIdentifier = "HABIT_REMINDER"

            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: time)

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: "habit-\(habitName)-\(UUID().uuidString)",
                content: content,
                trigger: trigger
            )

            do {
                try await center.add(request)
                print("✅ Alışkanlık hatırlatıcısı oluşturuldu: \(habitName)")
            } catch {
                print("❌ Alışkanlık hatırlatıcısı oluşturulamadı: \(error)")
            }
        }
    }

    // MARK: - Motivation & Gamification

    /// Motivasyon mesajı (Legacy)
    func sendMotivationalMessage() {
        let lastSentKey = "lastMotivationNotification"
        if let lastSent = UserDefaults.standard.object(forKey: lastSentKey) as? Date {
            let hoursSinceLastNotification = Date().timeIntervalSince(lastSent) / 3600
            if hoursSinceLastNotification < 24 {
                print("⏳ Motivasyon bildirimi cooldown'da")
                return
            }
        }

        center.removePendingNotificationRequests(withIdentifiers: ["motivation"])

        let content = UNMutableNotificationContent()

        switch currentLanguage {
        case .turkish:
            let messages = [
                "Bugün harika şeyler yapabilirsin! 💪",
                "Her gün bir adım daha ileriye! 🚀",
                "Sen başarabilirsin! 🌟",
                "Liderler asla pes etmez! 👑",
                "Bugün kendine yatırım yap! 📈"
            ]
            content.title = String(localized: "notification.motivation.title", comment: "Daily motivation")
            content.body = messages.randomElement() ?? messages[0]

        case .english:
            let messages = [
                "You can do amazing things today! 💪",
                "One step forward every day! 🚀",
                "You've got this! 🌟",
                "Leaders never give up! 👑",
                "Invest in yourself today! 📈"
            ]
            content.title = "Daily Motivation"
            content.body = messages.randomElement() ?? messages[0]
        }

        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
        let request = UNNotificationRequest(
            identifier: "motivation",
            content: content,
            trigger: trigger
        )

        center.add(request)
        UserDefaults.standard.set(Date(), forKey: lastSentKey)
        print("✅ Motivasyon bildirimi gönderildi")
    }

    /// Günlük aktivite hatırlatması (Legacy)
    func scheduleDailyActivityReminder() {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification.daily.activity.title", comment: "Daily activity")
        content.body = "Bugün kendine zaman ayırmayı unutma. Streak'ini koru!"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily-activity-reminder",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    /// Streak koparma uyarısı (Legacy)
    func sendStreakWarning(currentStreak: Int) {
        let content = UNMutableNotificationContent()
        content.title = "🔥 Dikkat! Streak'in Tehlikede!"
        content.body = "\(currentStreak) günlük streak'ini kaybetme! Bugün bir aktivite tamamla."
        content.sound = .defaultCritical

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 300, repeats: false)
        let request = UNNotificationRequest(
            identifier: "streak-warning",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    /// Badge kazanma bildirimi (Legacy)
    func sendBadgeEarnedNotification(badgeTitle: String, badgeDescription: String) {
        let content = UNMutableNotificationContent()
        content.title = "🏆 Yeni Rozet Kazandın!"
        content.body = "\(badgeTitle) - \(badgeDescription)"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "badge-earned-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    /// Seviye atlama bildirimi (Legacy)
    func sendLevelUpNotification(newLevel: Int) {
        let content = UNMutableNotificationContent()
        content.title = "⬆️ Seviye Atladın!"
        content.body = "Tebrikler! Artık Seviye \(newLevel) oldun! 🎉"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "level-up",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    /// Akşam aktivite hatırlatması (Legacy)
    func scheduleEveningActivityReminder() {
        let content = UNMutableNotificationContent()
        content.title = "🌙 Akşam Aktivitesi"
        content.body = "Günü güzel bir aktivite ile tamamla. Ne dersin?"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "evening-activity-reminder",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    // MARK: - Helpers

    private func formatDateLegacy(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
}

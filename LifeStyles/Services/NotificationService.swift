//
//  NotificationService.swift
//  LifeStyles
//
//  Created by Claude on 15.10.2025.
//  Refactored on 21.10.2025 - Core notification methods only
//

import Foundation
import UserNotifications
import CoreLocation

@Observable
class NotificationService {
    static let shared = NotificationService()

    let center = UNUserNotificationCenter.current()
    private let languageManager = LanguageManager.shared

    private init() {}

    // MARK: - Language Support

    private var currentLanguage: AppLanguage {
        languageManager.currentLanguage
    }

    // İzin durumunu kontrol et
    func checkPermission() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    // İzin iste
    func requestPermission() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    // Kişi hatırlatıcısı gönder
    func scheduleContactReminder(contactName: String, daysSince: Int) {
        let content = UNMutableNotificationContent()
        content.title = "İletişim Hatırlatması"
        content.body = "\(contactName) ile \(daysSince) gündür konuşmadınız. Aramayı düşünür müsünüz?"
        content.sound = .default
        content.categoryIdentifier = "CONTACT_REMINDER"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        let request = UNNotificationRequest(
            identifier: "contact-\(contactName)-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    // Aktivite önerisi bildirimi
    func sendActivitySuggestion(title: String, description: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = description
        content.sound = .default
        content.categoryIdentifier = "ACTIVITY_SUGGESTION"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "activity-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    // "Evden çık" bildirimi
    func sendGoOutsideReminder(hoursAtHome: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Dışarı Çıkma Zamanı! 🌞"
        content.body = "\(hoursAtHome) saattir evdesiniz. Biraz hava almaya ne dersiniz?"
        content.sound = .default
        content.categoryIdentifier = "GO_OUTSIDE"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "go-outside-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    // Hedef hatırlatıcısı
    func scheduleGoalReminder(goalTitle: String, daysLeft: Int) {
        let content = UNMutableNotificationContent()

        switch currentLanguage {
        case .turkish:
            content.title = "Hedef Hatırlatması 🎯"
            content.body = "\(goalTitle) için \(daysLeft) gün kaldı!"
        case .english:
            content.title = "Goal Reminder 🎯"
            content.body = "\(daysLeft) days left for \(goalTitle)!"
        }

        content.sound = .default
        content.categoryIdentifier = "GOAL_REMINDER"

        // Her gün saat 9:00'da
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "goal-\(goalTitle)-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    // Alışkanlık hatırlatıcısı
    func scheduleHabitReminder(habitName: String, at time: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Alışkanlık Zamanı! ⭐"
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

        center.add(request)
    }

    // Motivasyon mesajı
    func sendMotivationalMessage() {
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
            content.title = "Günlük Motivasyon"
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

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "motivation-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    // İletişim tamamlandı bildirimi
    func sendContactCompletedNotification(for friend: Friend) {
        let content = UNMutableNotificationContent()
        content.title = "İletişim Kaydedildi ✓"
        content.body = "\(friend.name) ile iletişiminiz kaydedildi. Sonraki iletişim: \(formatDate(friend.nextContactDate))"
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

    // İletişim gerekli bildirimi (günlük kontrol - rastgele saatlerde)
    func scheduleContactReminders(for friends: [Friend]) {
        // Önce eski hatırlatmaları iptal et
        center.removePendingNotificationRequests(withIdentifiers: friends.map { "contact-reminder-\($0.id.uuidString)" })

        for friend in friends where friend.needsContact {
            let content = UNMutableNotificationContent()
            content.title = "İletişim Zamanı! 📞"
            content.body = "\(friend.name) ile iletişim kurma zamanı geldi. \(friend.daysOverdue) gün gecikti."
            content.sound = .default
            content.categoryIdentifier = "CONTACT_REMINDER"

            // Rastgele saat dilimi seç (doğal görünmesi için)
            let timeSlots = [
                (start: 9, end: 12),   // Sabah
                (start: 14, end: 18),  // Öğleden sonra
                (start: 19, end: 21)   // Akşam
            ]

            let randomSlot = timeSlots.randomElement()!
            let randomHour = Int.random(in: randomSlot.start...randomSlot.end)
            let randomMinute = Int.random(in: 0...59)

            // Her gün rastgele saatte bildirim gönder
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

    // Haftalık iletişim özeti
    func sendWeeklyContactSummary(totalContacts: Int, needsAttention: Int, completed: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Haftalık İletişim Özeti 📊"
        content.body = "Bu hafta \(completed)/\(totalContacts) kişiyle iletişim kurdunuz. \(needsAttention) kişi bekliyor."
        content.sound = .default
        content.categoryIdentifier = "WEEKLY_SUMMARY"

        // Her Pazar saat 20:00
        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Pazar
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

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }

    // Tüm bekleyen bildirimleri iptal et
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Activity Notifications

    /// Günlük aktivite hatırlatması
    func scheduleDailyActivityReminder() {
        let content = UNMutableNotificationContent()
        content.title = "🎯 Günlük Aktivite Zamanı!"
        content.body = "Bugün kendine zaman ayırmayı unutma. Streak'ini koru!"
        content.sound = .default

        // Her gün sabah 9'da
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

    /// Streak koparma uyarısı
    func sendStreakWarning(currentStreak: Int) {
        let content = UNMutableNotificationContent()
        content.title = "🔥 Dikkat! Streak'in Tehlikede!"
        content.body = "\(currentStreak) günlük streak'ini kaybetme! Bugün bir aktivite tamamla."
        content.sound = .defaultCritical

        // 5 dakika sonra
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 300, repeats: false)

        let request = UNNotificationRequest(
            identifier: "streak-warning",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    /// Badge kazanma bildirimi
    func sendBadgeEarnedNotification(badgeTitle: String, badgeDescription: String) {
        let content = UNMutableNotificationContent()
        content.title = "🏆 Yeni Rozet Kazandın!"
        content.body = "\(badgeTitle) - \(badgeDescription)"
        content.sound = .default

        // Hemen gönder
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "badge-earned-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    /// Seviye atlama bildirimi
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

    /// Akşam aktivite hatırlatması
    func scheduleEveningActivityReminder() {
        let content = UNMutableNotificationContent()
        content.title = "🌙 Akşam Aktivitesi"
        content.body = "Günü güzel bir aktivite ile tamamla. Ne dersin?"
        content.sound = .default

        // Her gün akşam 8'de
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
}

// MARK: - Smart Notification API (New)

extension NotificationService {

    /// Smart notification gönderimi (sessiz saat + scheduler + analytics + rich media)
    func sendSmartNotification(
        title: String,
        body: String,
        category: NotificationCategory,
        priority: NotificationPriority = .normal,
        respectQuietHours: Bool = true,
        emoji: String? = nil,
        userInfo: [String: Any] = [:]
    ) async throws {
        // Content oluştur
        let content = NotificationCategoryManager.createContent(
            title: title,
            body: body,
            category: category,
            userInfo: userInfo
        )

        // Rich media ekle
        if let emoji = emoji {
            content.addRichMedia(emoji: emoji, category: category)
        } else {
            content.addRichMedia(category: category)
        }

        // Scheduler ile gönder
        let identifier = "\(category.rawValue)-\(UUID().uuidString)"
        try await NotificationScheduler.shared.sendImmediateNotification(
            identifier: identifier,
            content: content,
            priority: priority,
            respectQuietHours: respectQuietHours
        )
    }

    /// Friend için smart notification
    func sendFriendNotification(
        friend: Friend,
        title: String,
        body: String,
        priority: NotificationPriority = .normal
    ) async throws {
        var userInfo: [String: Any] = [
            "friendId": friend.id.uuidString
        ]

        let content = NotificationCategoryManager.createContent(
            title: title,
            body: body,
            category: .contactReminder,
            userInfo: userInfo
        )

        // Friend emoji avatar ekle (eğer varsa)
        // Not: Friend modelinde emojiAvatar property'si eklendiğinde açılacak
        // if let emoji = friend.emojiAvatar {
        //     content.addFriendAvatar(emoji: emoji, name: friend.name)
        // }

        let identifier = "friend-\(friend.id.uuidString)-\(UUID().uuidString)"
        try await NotificationScheduler.shared.sendImmediateNotification(
            identifier: identifier,
            content: content,
            priority: priority,
            respectQuietHours: true
        )
    }

    /// Goal için smart notification
    func sendGoalNotification(
        goal: Goal,
        title: String,
        body: String,
        priority: NotificationPriority = .normal
    ) async throws {
        var userInfo: [String: Any] = [
            "goalId": goal.id.uuidString
        ]

        try await sendSmartNotification(
            title: title,
            body: body,
            category: .goalReminder,
            priority: priority,
            respectQuietHours: true,
            emoji: "🎯",
            userInfo: userInfo
        )
    }

    /// Habit için smart notification
    func sendHabitNotification(
        habit: Habit,
        title: String,
        body: String,
        priority: NotificationPriority = .normal
    ) async throws {
        var userInfo: [String: Any] = [
            "habitId": habit.id.uuidString
        ]

        try await sendSmartNotification(
            title: title,
            body: body,
            category: .habitReminder,
            priority: priority,
            respectQuietHours: true,
            emoji: "⭐",
            userInfo: userInfo
        )
    }

    // MARK: - Mood & Journal Notifications

    /// Günlük mood hatırlatması zamanla
    func scheduleDailyMoodReminder(hour: Int = 20, minute: Int = 0) {
        // Mevcut reminder'ı iptal et
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

    /// Haftalık journal hatırlatması zamanla
    func scheduleWeeklyJournalReminder(weekday: Int = 7, hour: Int = 19, minute: Int = 0) {
        // Weekday: 1=Sunday, 7=Saturday
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
                let weekdayName = ["", "Pazar", "Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi"][weekday]
                print("✅ Haftalık journal reminder zamanlandı: \(weekdayName) \(hour):\(String(format: "%02d", minute))")
            }
        }
    }

    /// Haftalık journal reminder'ı iptal et
    func cancelWeeklyJournalReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["weekly_journal_reminder"])
    }

    /// Streak kırılma uyarısı gönder
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

    /// Mood tracking teşvik bildirimi
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

    // MARK: - Helpers

    /// Tüm notification sistemini başlat
    func initializeNotificationSystem() {
        // Delegate setup
        NotificationDelegate.shared.setup()

        // Categories kaydet
        NotificationCategoryManager.shared.registerAllCategories()

        // Geofence sync (eğer konum izni varsa)
        GeofenceNotificationManager.shared.syncWithLocationService()

        print("✅ Notification sistem başlatıldı")
    }

    /// Analytics raporu göster
    func printAnalytics() {
        NotificationAnalytics.shared.printDebugInfo()
    }

    /// Sessiz saat kontrolü
    func isQuietHours() -> Bool {
        return NotificationScheduler.shared.isQuietHours()
    }

    /// Günlük limiti aşıldı mı?
    func hasExceededDailyLimit() -> Bool {
        return UserDefaults.standard.hasExceededDailyLimit()
    }

    /// Engagement skorunu al
    func getEngagementScore() -> Double {
        return NotificationScheduler.shared.calculateWeeklyEngagement()
    }
}

// MARK: - Toast Integration

extension NotificationService {

    /// In-app toast bildirimi göster (sistem bildirimi yerine)
    /// Uygulama foreground'dayken kullanılır
    func showToast(
        title: String,
        message: String? = nil,
        type: ToastType = .info,
        emoji: String? = nil
    ) {
        ToastManager.shared.show(
            Toast(
                title: title,
                message: message,
                type: type,
                duration: 3.0,
                emoji: emoji
            )
        )
    }

    /// Arkadaş için toast göster
    func showFriendToast(
        friend: Friend,
        title: String,
        message: String? = nil
    ) {
        ToastManager.shared.success(
            title: title,
            message: message,
            emoji: friend.avatarEmoji ?? "👤"
        )
    }

    /// Hedef için toast göster
    func showGoalToast(
        title: String,
        message: String? = nil,
        isSuccess: Bool = true
    ) {
        if isSuccess {
            ToastManager.shared.success(
                title: title,
                message: message,
                emoji: "🎯"
            )
        } else {
            ToastManager.shared.warning(
                title: title,
                message: message,
                emoji: "🎯"
            )
        }
    }

    /// Habit için toast göster
    func showHabitToast(
        title: String,
        message: String? = nil,
        isCompleted: Bool = true
    ) {
        if isCompleted {
            ToastManager.shared.success(
                title: title,
                message: message,
                emoji: "⭐"
            )
        } else {
            ToastManager.shared.info(
                title: title,
                message: message,
                emoji: "⭐"
            )
        }
    }

    /// Mood için toast göster
    func showMoodToast(
        title: String,
        message: String? = nil,
        mood: String? = nil
    ) {
        ToastManager.shared.success(
            title: title,
            message: message,
            emoji: mood ?? "😊"
        )
    }

    /// Konum için toast göster
    func showLocationToast(
        title: String,
        message: String? = nil,
        type: ToastType = .info
    ) {
        ToastManager.shared.show(
            Toast(
                title: title,
                message: message,
                type: type,
                emoji: "📍"
            )
        )
    }

    /// Genel başarı toast
    func showSuccessToast(title: String, message: String? = nil, emoji: String? = nil) {
        ToastManager.shared.success(title: title, message: message, emoji: emoji)
    }

    /// Genel hata toast
    func showErrorToast(title: String, message: String? = nil, emoji: String? = nil) {
        ToastManager.shared.error(title: title, message: message, emoji: emoji)
    }

    /// Genel uyarı toast
    func showWarningToast(title: String, message: String? = nil, emoji: String? = nil) {
        ToastManager.shared.warning(title: title, message: message, emoji: emoji)
    }

    /// Genel bilgi toast
    func showInfoToast(title: String, message: String? = nil, emoji: String? = nil) {
        ToastManager.shared.info(title: title, message: message, emoji: emoji)
    }
}


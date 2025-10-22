//
//  NotificationAIService.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Refactored from NotificationService - AI powered notifications (iOS 26+)
//

import Foundation
import UserNotifications
import CoreLocation

// MARK: - AI Powered Notifications Extension

extension NotificationService {

    // MARK: - AI Powered Notifications (iOS 26+)

    @available(iOS 26.0, *)
    func scheduleAIGoalMotivation(for goal: Goal) async {
        let goalAIService = GoalAIService.shared

        do {
            let motivation = try await goalAIService.generateMotivation(for: goal)

            let content = UNMutableNotificationContent()
            content.title = "🎯 \(goal.title)"
            content.body = motivation
            content.sound = .default
            content.categoryIdentifier = "AI_GOAL_MOTIVATION"

            // Bugün saat 9'da gönder
            var dateComponents = DateComponents()
            dateComponents.hour = 9
            dateComponents.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(
                identifier: "ai-goal-\(goal.id.uuidString)",
                content: content,
                trigger: trigger
            )

            try await center.add(request)
        } catch {
            print("❌ AI goal motivasyon bildirimi hatası: \(error)")
        }
    }

    @available(iOS 26.0, *)
    func scheduleAIHabitReminder(for habit: Habit) async {
        let habitAIService = HabitAIService.shared

        do {
            let motivation = try await habitAIService.generateStreakMotivation(for: habit)

            let content = UNMutableNotificationContent()
            content.title = "🔥 \(habit.name)"
            content.body = motivation
            content.sound = .default
            content.categoryIdentifier = "AI_HABIT_REMINDER"

            // Alışkanlık reminder time'ında gönder
            if let reminderTime = habit.reminderTime {
                let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(
                    identifier: "ai-habit-\(habit.id.uuidString)",
                    content: content,
                    trigger: trigger
                )

                try await center.add(request)
            }
        } catch {
            print("❌ AI habit motivasyon bildirimi hatası: \(error)")
        }
    }

    @available(iOS 26.0, *)
    func scheduleAIDailyInsight(
        goals: [Goal],
        habits: [Habit],
        friends: [Friend]
    ) async {
        let dashboardAIService = DashboardAIService.shared

        do {
            // Sabah motivasyonu
            let todayGoals = goals.filter { !$0.isCompleted && $0.daysRemaining <= 7 }
            let todayHabits = habits.filter { $0.isActive && !$0.isCompletedToday() }

            let morningMotivation = try await dashboardAIService.generateMorningMotivation(
                todayGoals: todayGoals,
                todayHabits: todayHabits
            )

            let content = UNMutableNotificationContent()
            content.title = "🌅 Günaydın!"
            content.body = morningMotivation
            content.sound = .default
            content.categoryIdentifier = "AI_DAILY_INSIGHT"

            // Sabah 8'de gönder
            var dateComponents = DateComponents()
            dateComponents.hour = 8
            dateComponents.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "ai-daily-insight",
                content: content,
                trigger: trigger
            )

            try await center.add(request)
        } catch {
            print("❌ AI günlük insight bildirimi hatası: \(error)")
        }
    }

    @available(iOS 26.0, *)
    func scheduleAIEveningReflection(
        completedGoals: [Goal],
        completedHabits: [Habit],
        contactedFriends: [Friend]
    ) async {
        let dashboardAIService = DashboardAIService.shared

        do {
            let reflection = try await dashboardAIService.generateEveningReflection(
                completedGoals: completedGoals,
                completedHabits: completedHabits,
                contactedFriends: contactedFriends
            )

            let content = UNMutableNotificationContent()
            content.title = "🌙 Günün Özeti"
            content.body = reflection
            content.sound = .default
            content.categoryIdentifier = "AI_EVENING_REFLECTION"

            // Akşam 21:00'de gönder
            var dateComponents = DateComponents()
            dateComponents.hour = 21
            dateComponents.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "ai-evening-reflection",
                content: content,
                trigger: trigger
            )

            try await center.add(request)
        } catch {
            print("❌ AI akşam değerlendirmesi bildirimi hatası: \(error)")
        }
    }

    @available(iOS 26.0, *)
    func scheduleAIFriendSuggestion(for friend: Friend) async {
        let friendAIService = FriendAIService.shared

        do {
            let suggestion = try await friendAIService.generateSuggestion(for: friend)

            let content = UNMutableNotificationContent()
            content.title = "💬 \(friend.name)"
            content.body = suggestion
            content.sound = .default
            content.categoryIdentifier = "AI_FRIEND_SUGGESTION"

            // Hemen gönder (veya belirli bir zamanda)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let request = UNNotificationRequest(
                identifier: "ai-friend-\(friend.id.uuidString)",
                content: content,
                trigger: trigger
            )

            try await center.add(request)
        } catch {
            print("❌ AI friend suggestion bildirimi hatası: \(error)")
        }
    }

    @available(iOS 26.0, *)
    func scheduleAIActivitySuggestion(
        location: CLLocationCoordinate2D?,
        locationType: LocationType?
    ) async {
        let activityAIService = ActivityAIService.shared

        do {
            let recommendation = try await activityAIService.generateActivityRecommendation(
                location: location,
                locationType: locationType
            )

            let content = UNMutableNotificationContent()
            content.title = "🎯 \(recommendation.activity)"
            content.body = "\(recommendation.reason) • \(recommendation.location) • \(recommendation.estimatedDuration)"
            content.sound = .default
            content.categoryIdentifier = "AI_ACTIVITY_SUGGESTION"

            // 5 saniye sonra gönder
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let request = UNNotificationRequest(
                identifier: "ai-activity-\(UUID().uuidString)",
                content: content,
                trigger: trigger
            )

            try await center.add(request)
        } catch {
            print("❌ AI aktivite önerisi bildirimi hatası: \(error)")
        }
    }

    // MARK: - Toplu AI Bildirimlerini Planla

    @available(iOS 26.0, *)
    func scheduleAllAINotifications(
        goals: [Goal],
        habits: [Habit],
        friends: [Friend]
    ) async {
        // Günlük sabah bildirimi (tekrarlı)
        await scheduleAIDailyInsight(goals: goals, habits: habits, friends: friends)

        // Aktif hedefler için motivasyon
        for goal in goals.filter({ !$0.isCompleted && $0.daysRemaining <= 7 }) {
            await scheduleAIGoalMotivation(for: goal)
        }

        // Aktif alışkanlıklar için hatırlatıcı
        for habit in habits.filter({ $0.isActive && $0.reminderTime != nil }) {
            await scheduleAIHabitReminder(for: habit)
        }

        // İletişim gerekli arkadaşlar için öneri
        for friend in friends.filter({ $0.needsContact }).prefix(3) {
            await scheduleAIFriendSuggestion(for: friend)
        }

        print("✅ Tüm AI bildirimleri planlandı")
    }

    @available(iOS 26.0, *)
    func cancelAllAINotifications() {
        // Tüm AI bildirimlerini iptal et
        center.getPendingNotificationRequests { requests in
            let aiIdentifiers = requests
                .filter { $0.content.categoryIdentifier.hasPrefix("AI_") }
                .map { $0.identifier }

            self.center.removePendingNotificationRequests(withIdentifiers: aiIdentifiers)
            print("✅ Tüm AI bildirimleri iptal edildi (\(aiIdentifiers.count) adet)")
        }
    }
}

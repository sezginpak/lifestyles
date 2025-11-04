//
//  AchievementService.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Rozet/Achievement sistemi yönetimi
//

import Foundation
import SwiftData

// MARK: - Achievement Model

struct Achievement: Identifiable, Codable, Equatable {
    var id: String
    var title: String
    var description: String
    var emoji: String
    var category: AchievementCategory
    var requirement: Int // Gereksinim (ör: 7 gün, 10 hedef)
    var currentProgress: Int // Mevcut ilerleme
    var isEarned: Bool
    var earnedAt: Date?
    var colorHex: String

    var progressPercentage: Int {
        guard requirement > 0 else { return 100 }
        return min(Int((Double(currentProgress) / Double(requirement)) * 100), 100)
    }

    var isLocked: Bool {
        !isEarned
    }
}

enum AchievementCategory: String, Codable {
    case goal = "goal"
    case habit = "habit"
    case streak = "streak"
    case consistency = "consistency"
    case special = "special"

    var displayName: String {
        switch self {
        case .goal: return String(localized: "achievement.category.goal", comment: "Goals category")
        case .habit: return String(localized: "achievement.category.habit", comment: "Habits category")
        case .streak: return "Seri"
        case .consistency: return String(localized: "achievement.category.consistency", comment: "Consistency category")
        case .special: return String(localized: "achievement.category.special", comment: "Special category")
        }
    }
}

// MARK: - Achievement Service

@Observable
class AchievementService {
    static let shared = AchievementService()

    private let userDefaultsKey = "earned_achievements"
    private var earnedAchievementIDs: Set<String> = []

    private init() {
        loadEarnedAchievements()
    }

    // MARK: - All Achievements

    /// Tüm achievement'lar (16 adet)
    func getAllAchievements(goals: [Goal], habits: [Habit], currentStreak: Int) -> [Achievement] {
        var achievements: [Achievement] = []

        // Goal Achievements
        achievements.append(contentsOf: [
            createAchievement(
                id: "first_goal",
                title: String(localized: "achievement.first.goal.title", comment: "First goal"),
                description: String(localized: "achievement.first.goal.desc", comment: "First goal desc"),
                emoji: "🎯",
                category: .goal,
                requirement: 1,
                current: goals.count,
                color: "3498DB"
            ),
            createAchievement(
                id: "goal_crusher_10",
                title: String(localized: "achievement.goal.hunter.title", comment: "Goal hunter"),
                description: "10 hedef tamamla",
                emoji: "💪",
                category: .goal,
                requirement: 10,
                current: goals.filter { $0.isCompleted }.count,
                color: "E74C3C"
            ),
            createAchievement(
                id: "goal_crusher_50",
                title: "Hedef Efendisi",
                description: "50 hedef tamamla",
                emoji: "👑",
                category: .goal,
                requirement: 50,
                current: goals.filter { $0.isCompleted }.count,
                color: "F39C12"
            ),
            createAchievement(
                id: "category_king_health",
                title: String(localized: "achievement.health.king.title", comment: "Health king"),
                description: String(localized: "achievement.health.king.desc", comment: "Health king desc"),
                emoji: "❤️",
                category: .goal,
                requirement: 5,
                current: goals.filter { $0.isCompleted && $0.category == .health }.count,
                color: "E74C3C"
            )
        ])

        // Habit Achievements
        achievements.append(contentsOf: [
            createAchievement(
                id: "first_habit",
                title: String(localized: "achievement.first.habit.title", comment: "First habit"),
                description: String(localized: "achievement.first.habit.desc", comment: "First habit desc"),
                emoji: "⭐",
                category: .habit,
                requirement: 1,
                current: habits.count,
                color: "9B59B6"
            ),
            createAchievement(
                id: "habit_master_30",
                title: String(localized: "achievement.habit.master.title", comment: "Habit master"),
                description: String(localized: "achievement.habit.master.desc", comment: "Habit master desc"),
                emoji: "🏆",
                category: .habit,
                requirement: 30,
                current: habits.map { $0.bestStreak }.max() ?? 0,
                color: "F39C12"
            ),
            createAchievement(
                id: "habit_master_90",
                title: String(localized: "achievement.legendary.habit.title", comment: "Legendary habit"),
                description: String(localized: "achievement.legendary.habit.desc", comment: "Legendary habit desc"),
                emoji: "🔥",
                category: .habit,
                requirement: 90,
                current: habits.map { $0.bestStreak }.max() ?? 0,
                color: "E67E22"
            )
        ])

        // Streak Achievements
        achievements.append(contentsOf: [
            createAchievement(
                id: "week_warrior",
                title: String(localized: "achievement.week.warrior.title", comment: "Week warrior"),
                description: String(localized: "achievement.week.warrior.desc", comment: "Week warrior desc"),
                emoji: "🔥",
                category: .streak,
                requirement: 7,
                current: currentStreak,
                color: "E74C3C"
            ),
            createAchievement(
                id: "streak_30",
                title: String(localized: "achievement.month.champion.title", comment: "Month champion"),
                description: String(localized: "achievement.month.champion.desc", comment: "Month champion desc"),
                emoji: "🌟",
                category: .streak,
                requirement: 30,
                current: currentStreak,
                color: "F39C12"
            ),
            createAchievement(
                id: "streak_100",
                title: String(localized: "achievement.hundred.master.title", comment: "Hundred master"),
                description: String(localized: "achievement.hundred.master.desc", comment: "Hundred master desc"),
                emoji: "💎",
                category: .streak,
                requirement: 100,
                current: currentStreak,
                color: "3498DB"
            )
        ])

        // Consistency Achievements
        achievements.append(contentsOf: [
            createAchievement(
                id: "perfect_week",
                title: "Mükemmel Hafta",
                description: "Bir haftada tüm hedefleri %100 tamamla",
                emoji: "✨",
                category: .consistency,
                requirement: 1,
                current: 0, // Bu runtime'da hesaplanmalı
                color: "9B59B6"
            ),
            createAchievement(
                id: "early_bird",
                title: "Sabahçı",
                description: "Sabah 9'dan önce 5 hedef tamamla",
                emoji: "☀️",
                category: .consistency,
                requirement: 5,
                current: 0, // Bu runtime'da hesaplanmalı
                color: "F39C12"
            ),
            createAchievement(
                id: "night_owl",
                title: "Gece Kuşu",
                description: "Gece 10'dan sonra 5 hedef tamamla",
                emoji: "🌙",
                category: .consistency,
                requirement: 5,
                current: 0, // Bu runtime'da hesaplanmalı
                color: "34495E"
            )
        ])

        // Special Achievements
        achievements.append(contentsOf: [
            createAchievement(
                id: "all_categories",
                title: "Çok Yönlü",
                description: "Her kategoriden en az 1 hedef tamamla",
                emoji: "🎨",
                category: .special,
                requirement: 6, // 6 kategori
                current: Set(goals.filter { $0.isCompleted }.map { $0.category }).count,
                color: "16A085"
            ),
            createAchievement(
                id: "milestone_master",
                title: "Adım Adım",
                description: "5 farklı hedefte tüm milestone'ları tamamla",
                emoji: "📍",
                category: .special,
                requirement: 5,
                current: goals.filter { goal in
                    guard let milestones = goal.milestones, !milestones.isEmpty else { return false }
                    return milestones.allSatisfy { $0.isCompleted }
                }.count,
                color: "8E44AD"
            ),
            createAchievement(
                id: "social_butterfly",
                title: "Sosyal Kelebek",
                description: "Sosyal kategoride 3 hedef ve arkadaşlarla 10 iletişim",
                emoji: "🦋",
                category: .special,
                requirement: 1,
                current: 0, // Bu cross-data hesap gerektirir
                color: "3498DB"
            )
        ])

        return achievements
    }

    // MARK: - Private Helpers

    private func createAchievement(
        id: String,
        title: String,
        description: String,
        emoji: String,
        category: AchievementCategory,
        requirement: Int,
        current: Int,
        color: String
    ) -> Achievement {
        let isEarned = earnedAchievementIDs.contains(id) || current >= requirement

        return Achievement(
            id: id,
            title: title,
            description: description,
            emoji: emoji,
            category: category,
            requirement: requirement,
            currentProgress: current,
            isEarned: isEarned,
            earnedAt: isEarned ? (getEarnedDate(for: id) ?? Date()) : nil,
            colorHex: color
        )
    }

    // MARK: - Check & Award

    /// Yeni kazanılan achievement'ları kontrol et
    func checkNewAchievements(
        goals: [Goal],
        habits: [Habit],
        currentStreak: Int
    ) -> [Achievement] {
        let allAchievements = getAllAchievements(
            goals: goals,
            habits: habits,
            currentStreak: currentStreak
        )

        var newlyEarned: [Achievement] = []

        for achievement in allAchievements {
            if achievement.currentProgress >= achievement.requirement && !earnedAchievementIDs.contains(achievement.id) {
                // Yeni kazanıldı!
                earnedAchievementIDs.insert(achievement.id)
                newlyEarned.append(achievement)

                // Kazanma tarihini kaydet
                saveEarnedDate(for: achievement.id, date: Date())
            }
        }

        if !newlyEarned.isEmpty {
            saveEarnedAchievements()
        }

        return newlyEarned
    }

    // MARK: - Persistence

    private func loadEarnedAchievements() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            earnedAchievementIDs = decoded
        }
    }

    private func saveEarnedAchievements() {
        if let encoded = try? JSONEncoder().encode(earnedAchievementIDs) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    private func saveEarnedDate(for id: String, date: Date) {
        UserDefaults.standard.set(date, forKey: "achievement_date_\(id)")
    }

    private func getEarnedDate(for id: String) -> Date? {
        UserDefaults.standard.object(forKey: "achievement_date_\(id)") as? Date
    }

    // MARK: - Stats

    /// Kazanılan achievement sayısı
    var earnedCount: Int {
        earnedAchievementIDs.count
    }

    /// Toplam achievement sayısı
    let totalCount: Int = 16

    /// Completion yüzdesi
    var completionPercentage: Int {
        Int((Double(earnedCount) / Double(totalCount)) * 100)
    }
}

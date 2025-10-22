//
//  MoodStreakService.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Mood streak hesaplama ve badge yönetimi
//

import Foundation
import SwiftData

@Observable
class MoodStreakService {
    static let shared = MoodStreakService()

    private init() {}

    // UserDefaults keys
    private let currentStreakKey = "mood_current_streak"
    private let longestStreakKey = "mood_longest_streak"
    private let lastMoodDateKey = "mood_last_date"
    private let earnedBadgesKey = "mood_earned_badges"

    // MARK: - Streak Calculation

    /// Mood entry'lerden streak hesapla
    func calculateStreak(entries: [MoodEntry]) -> StreakData {
        guard !entries.isEmpty else { return .empty() }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Entry'leri tarihe göre sırala (yeniden eskiye)
        let sortedEntries = entries.sorted { $0.date > $1.date }

        guard let latestEntry = sortedEntries.first else { return .empty() }

        let latestDate = calendar.startOfDay(for: latestEntry.date)
        let daysSinceLatest = calendar.dateComponents([.day], from: latestDate, to: today).day ?? 0

        // Eğer 2 gün veya daha fazla geçmişse streak kırıldı
        if daysSinceLatest > 1 {
            return StreakData(
                currentStreak: 0,
                longestStreak: getLongestStreak(),
                lastMoodDate: latestEntry.date,
                streakBadges: getEarnedBadges(),
                isActive: false
            )
        }

        // Günlük entry'leri grupla
        let groupedByDay = Dictionary(grouping: sortedEntries) { entry -> Date in
            calendar.startOfDay(for: entry.date)
        }

        // Ardışık günleri say
        var currentStreak = 0
        var checkDate = today

        while groupedByDay[checkDate] != nil {
            currentStreak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else {
                break
            }
            checkDate = previousDay
        }

        // Longest streak'i hesapla veya UserDefaults'tan al
        let longestStreak = max(currentStreak, getLongestStreak())

        // Bugün kaydedildi mi?
        let isActive = groupedByDay[today] != nil

        // Badge'leri hesapla
        let badges = calculateBadges(currentStreak: currentStreak)

        // UserDefaults'a kaydet
        saveStreakData(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            lastMoodDate: latestEntry.date,
            badges: badges
        )

        return StreakData(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            lastMoodDate: latestEntry.date,
            streakBadges: badges,
            isActive: isActive
        )
    }

    // MARK: - Badge Management

    /// Streak'e göre badge'leri hesapla
    private func calculateBadges(currentStreak: Int) -> [StreakBadge] {
        let milestones = [7, 14, 30, 60, 100, 365]
        var badges: [StreakBadge] = []

        for milestone in milestones {
            if currentStreak >= milestone {
                let badge = StreakBadge(
                    days: milestone,
                    earnedDate: Date(),
                    emoji: StreakBadge.getBadgeForStreak(milestone)
                )
                badges.append(badge)
            }
        }

        return badges
    }

    /// Yeni badge kazanıldı mı kontrol et
    func checkNewBadgeEarned(oldStreak: Int, newStreak: Int) -> StreakBadge? {
        let milestones = [7, 14, 30, 60, 100, 365]

        for milestone in milestones {
            if oldStreak < milestone && newStreak >= milestone {
                return StreakBadge(
                    days: milestone,
                    earnedDate: Date(),
                    emoji: StreakBadge.getBadgeForStreak(milestone)
                )
            }
        }

        return nil
    }

    // MARK: - UserDefaults Persistence

    /// Streak verilerini kaydet
    private func saveStreakData(
        currentStreak: Int,
        longestStreak: Int,
        lastMoodDate: Date,
        badges: [StreakBadge]
    ) {
        UserDefaults.standard.set(currentStreak, forKey: currentStreakKey)
        UserDefaults.standard.set(longestStreak, forKey: longestStreakKey)
        UserDefaults.standard.set(lastMoodDate, forKey: lastMoodDateKey)

        // Badge'leri JSON olarak kaydet
        if let badgeData = try? JSONEncoder().encode(badges) {
            UserDefaults.standard.set(badgeData, forKey: earnedBadgesKey)
        }
    }

    /// Cached current streak
    func getCurrentStreak() -> Int {
        UserDefaults.standard.integer(forKey: currentStreakKey)
    }

    /// Cached longest streak
    func getLongestStreak() -> Int {
        UserDefaults.standard.integer(forKey: longestStreakKey)
    }

    /// Cached last mood date
    func getLastMoodDate() -> Date? {
        UserDefaults.standard.object(forKey: lastMoodDateKey) as? Date
    }

    /// Cached earned badges
    func getEarnedBadges() -> [StreakBadge] {
        guard let data = UserDefaults.standard.data(forKey: earnedBadgesKey),
              let badges = try? JSONDecoder().decode([StreakBadge].self, from: data) else {
            return []
        }
        return badges
    }

    // MARK: - Streak Reset

    /// Streak'i sıfırla (debug veya kullanıcı isteği için)
    func resetStreak() {
        UserDefaults.standard.removeObject(forKey: currentStreakKey)
        UserDefaults.standard.removeObject(forKey: lastMoodDateKey)
        UserDefaults.standard.removeObject(forKey: earnedBadgesKey)
        // Longest streak korunur
        print("✅ Streak reset edildi (longest streak korundu)")
    }

    /// Tüm streak verilerini sıfırla
    func resetAll() {
        UserDefaults.standard.removeObject(forKey: currentStreakKey)
        UserDefaults.standard.removeObject(forKey: longestStreakKey)
        UserDefaults.standard.removeObject(forKey: lastMoodDateKey)
        UserDefaults.standard.removeObject(forKey: earnedBadgesKey)
        print("✅ Tüm streak verileri silindi")
    }

    // MARK: - Streak Stats

    /// Streak istatistikleri
    func getStreakStats() -> (current: Int, longest: Int, badges: Int) {
        return (
            current: getCurrentStreak(),
            longest: getLongestStreak(),
            badges: getEarnedBadges().count
        )
    }
}

// Extension moved to MoodStats.swift to fix Codable synthesis

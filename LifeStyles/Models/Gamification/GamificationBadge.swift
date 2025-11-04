//
//  GamificationBadge.swift
//  LifeStyles
//
//  Gamification: Badge system for achievements
//  Created by Claude on 30.10.2025.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Badge Type

enum BadgeType: String, Codable, CaseIterable {
    // Journal Badges
    case firstJournal = "first_journal"
    case journal10 = "journal_10"
    case journal50 = "journal_50"
    case journal100 = "journal_100"

    // Mood Badges
    case firstMood = "first_mood"
    case mood7Days = "mood_7_days"
    case mood30Days = "mood_30_days"
    case moodMaster = "mood_master"

    // Streak Badges
    case streak3 = "streak_3"
    case streak7 = "streak_7"
    case streak30 = "streak_30"
    case streak100 = "streak_100"

    // Special Badges
    case earlyBird = "early_bird"          // Sabah 6-8 arası journal
    case nightOwl = "night_owl"            // Gece 22-24 arası journal
    case wordsmith = "wordsmith"           // 1000+ kelime journal
    case photographer = "photographer"     // 10 fotoğraflı journal

    var displayName: String {
        switch self {
        case .firstJournal: return "İlk Journal"
        case .journal10: return "10 Journal"
        case .journal50: return "50 Journal"
        case .journal100: return "100 Journal"
        case .firstMood: return "İlk Mood"
        case .mood7Days: return "7 Gün Mood"
        case .mood30Days: return "30 Gün Mood"
        case .moodMaster: return "Mood Ustası"
        case .streak3: return "3 Gün Streak"
        case .streak7: return "7 Gün Streak"
        case .streak30: return "30 Gün Streak"
        case .streak100: return "100 Gün Streak"
        case .earlyBird: return "Erken Kuş"
        case .nightOwl: return "Gece Kuşu"
        case .wordsmith: return "Kelime Ustası"
        case .photographer: return "Fotoğrafçı"
        }
    }

    var description: String {
        switch self {
        case .firstJournal: return "İlk journal'ını yazdın!"
        case .journal10: return "10 journal yazdın"
        case .journal50: return "50 journal yazdın"
        case .journal100: return "100 journal yazdın"
        case .firstMood: return "İlk mood'unu kaydettinn!"
        case .mood7Days: return "7 gün üst üste mood kaydı"
        case .mood30Days: return "30 gün üst üste mood kaydı"
        case .moodMaster: return "100 mood kaydı"
        case .streak3: return "3 gün üst üste journal"
        case .streak7: return "7 gün üst üste journal"
        case .streak30: return "30 gün üst üste journal"
        case .streak100: return "100 gün üst üste journal"
        case .earlyBird: return "Sabah erken journal yazdın"
        case .nightOwl: return "Gece geç journal yazdın"
        case .wordsmith: return "1000+ kelime journal yazdın"
        case .photographer: return "10 fotoğraflı journal"
        }
    }

    var emoji: String {
        switch self {
        case .firstJournal: return "📝"
        case .journal10: return "📚"
        case .journal50: return "📖"
        case .journal100: return "🏆"
        case .firstMood: return "😊"
        case .mood7Days: return "🎯"
        case .mood30Days: return "🌟"
        case .moodMaster: return "👑"
        case .streak3: return "🔥"
        case .streak7: return "💪"
        case .streak30: return "⭐"
        case .streak100: return "💎"
        case .earlyBird: return "🌅"
        case .nightOwl: return "🌙"
        case .wordsmith: return "✍️"
        case .photographer: return "📸"
        }
    }

    var color: Color {
        switch self {
        case .firstJournal, .firstMood:
            return .blue
        case .journal10, .mood7Days, .streak3:
            return .green
        case .journal50, .mood30Days, .streak7:
            return .purple
        case .journal100, .moodMaster, .streak30, .streak100:
            return .orange
        case .earlyBird:
            return .yellow
        case .nightOwl:
            return .indigo
        case .wordsmith:
            return .pink
        case .photographer:
            return .cyan
        }
    }

    var xpReward: Int {
        switch self {
        case .firstJournal, .firstMood:
            return 10
        case .journal10, .mood7Days, .streak3:
            return 25
        case .journal50, .mood30Days, .streak7:
            return 50
        case .journal100, .moodMaster, .streak30:
            return 100
        case .streak100:
            return 250
        case .earlyBird, .nightOwl, .wordsmith, .photographer:
            return 30
        }
    }
}

// MARK: - GamificationBadge Model

@Model
final class GamificationBadge {
    var id: UUID = UUID()
    var badgeTypeRaw: String = "first_journal"
    var earnedDate: Date = Date()
    var isViewed: Bool = false // Kullanıcı rozeti gördü mü?

    @Relationship
    var userProgress: UserProgress?

    init(
        id: UUID = UUID(),
        badgeType: BadgeType,
        earnedDate: Date = Date(),
        isViewed: Bool = false
    ) {
        self.id = id
        self.badgeTypeRaw = badgeType.rawValue
        self.earnedDate = earnedDate
        self.isViewed = isViewed
    }

    var badgeType: BadgeType {
        get { BadgeType(rawValue: badgeTypeRaw) ?? .firstJournal }
        set { badgeTypeRaw = newValue.rawValue }
    }

    func markAsViewed() {
        isViewed = true
    }
}

// MARK: - User Progress Model

@Model
final class UserProgress {
    var id: UUID = UUID()
    var totalXP: Int = 0
    var currentLevel: Int = 1
    var journalCount: Int = 0
    var moodCount: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastActivityDate: Date?

    // Relationship
    @Relationship(deleteRule: .cascade, inverse: \GamificationBadge.userProgress)
    var badges: [GamificationBadge]?

    init(
        id: UUID = UUID(),
        totalXP: Int = 0,
        currentLevel: Int = 1,
        journalCount: Int = 0,
        moodCount: Int = 0,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastActivityDate: Date? = nil,
        badges: [GamificationBadge]? = nil
    ) {
        self.id = id
        self.totalXP = totalXP
        self.currentLevel = currentLevel
        self.journalCount = journalCount
        self.moodCount = moodCount
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastActivityDate = lastActivityDate
        self.badges = badges
    }

    // MARK: - Level Calculations

    /// XP gereksinimi (Level * 100)
    var xpForNextLevel: Int {
        currentLevel * 100
    }

    /// Mevcut level'deki XP
    var xpInCurrentLevel: Int {
        totalXP - xpForPreviousLevels
    }

    /// Önceki level'ler için gereken toplam XP
    var xpForPreviousLevels: Int {
        guard currentLevel > 1 else { return 0 }
        return (1..<currentLevel).reduce(0) { $0 + ($1 * 100) }
    }

    /// Progress (0.0 - 1.0)
    var levelProgress: Double {
        Double(xpInCurrentLevel) / Double(xpForNextLevel)
    }

    // MARK: - Actions

    /// XP ekle ve level kontrolü yap
    func addXP(_ amount: Int) {
        totalXP += amount
        checkLevelUp()
    }

    /// Level kontrolü
    private func checkLevelUp() {
        while xpInCurrentLevel >= xpForNextLevel {
            currentLevel += 1
            HapticFeedback.success()
        }
    }

    /// Journal sayacını artır
    func incrementJournalCount() {
        journalCount += 1
    }

    /// Mood sayacını artır
    func incrementMoodCount() {
        moodCount += 1
    }

    /// Streak güncelle
    func updateStreak(for date: Date) {
        let calendar = Calendar.current

        if let lastDate = lastActivityDate {
            let daysDiff = calendar.dateComponents([.day], from: lastDate, to: date).day ?? 0

            if daysDiff == 1 {
                // Ertesi gün - streak devam ediyor
                currentStreak += 1
                if currentStreak > longestStreak {
                    longestStreak = currentStreak
                }
            } else if daysDiff > 1 {
                // Streak kırıldı
                currentStreak = 1
            }
            // daysDiff == 0 ise aynı gün, hiçbir şey yapma
        } else {
            // İlk aktivite
            currentStreak = 1
            longestStreak = 1
        }

        lastActivityDate = date
    }

    /// Badge ekle
    func addBadge(_ badge: GamificationBadge) {
        if badges == nil {
            badges = []
        }

        // Aynı badge'i tekrar ekleme
        if badges?.contains(where: { $0.badgeType == badge.badgeType }) == true {
            return
        }

        badges?.append(badge)
        addXP(badge.badgeType.xpReward)
    }

    /// Badge kontrolü
    func hasBadge(_ type: BadgeType) -> Bool {
        badges?.contains(where: { $0.badgeType == type }) ?? false
    }
}

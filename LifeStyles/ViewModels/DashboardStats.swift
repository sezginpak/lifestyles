//
//  DashboardStats.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Dashboard için stats yapıları
//

import Foundation

// MARK: - Dashboard Ring Data

struct DashboardRingData {
    let completed: Int
    let total: Int
    let color: String // Hex color
    let icon: String // SF Symbol
    let label: String

    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    var percentage: Int {
        Int(progress * 100)
    }
}

// MARK: - Dashboard Summary

struct DashboardSummary {
    let goalsRing: DashboardRingData
    let habitsRing: DashboardRingData
    let socialRing: DashboardRingData
    let activityRing: DashboardRingData
    let overallScore: Int
    let motivationMessage: String

    static func empty() -> DashboardSummary {
        DashboardSummary(
            goalsRing: DashboardRingData(
                completed: 0,
                total: 0,
                color: "667EEA",
                icon: "target",
                label: "Hedefler"
            ),
            habitsRing: DashboardRingData(
                completed: 0,
                total: 0,
                color: "E74C3C",
                icon: "flame.fill",
                label: "Alışkanlıklar"
            ),
            socialRing: DashboardRingData(
                completed: 0,
                total: 100,
                color: "3498DB",
                icon: "person.2.fill",
                label: "İletişim"
            ),
            activityRing: DashboardRingData(
                completed: 0,
                total: 100,
                color: "2ECC71",
                icon: "location.fill",
                label: "Mobilite"
            ),
            overallScore: 0,
            motivationMessage: "Başlayalım!"
        )
    }
}

// MARK: - Partner Info

struct PartnerInfo {
    let name: String
    let emoji: String?
    let relationshipDays: Int
    let relationshipDuration: (years: Int, months: Int, days: Int)
    let lastContactDays: Int // Kaç gün önce iletişim
    let daysUntilAnniversary: Int?
    let anniversaryDate: Date?
    let loveLanguage: String?
    let phoneNumber: String?

    var relationshipText: String {
        let (years, months, days) = relationshipDuration

        if years > 0 {
            if months > 0 {
                return "\(years) yıl \(months) ay"
            } else {
                return "\(years) yıl"
            }
        } else if months > 0 {
            if days > 0 {
                return "\(months) ay \(days) gün"
            } else {
                return "\(months) ay"
            }
        } else {
            return "\(days) gün"
        }
    }

    var lastContactText: String {
        if lastContactDays == 0 {
            return "Bugün"
        } else if lastContactDays == 1 {
            return "Dün"
        } else {
            return "\(lastContactDays) gün önce"
        }
    }

    var anniversaryText: String? {
        guard let days = daysUntilAnniversary else { return nil }

        if days == 0 {
            return "Bugün yıldönümünüz! 🎉"
        } else if days == 1 {
            return "Yarın yıldönümünüz! 🎊"
        } else if days <= 7 {
            return "Yıldönümünüze \(days) gün kaldı! 💕"
        } else if days <= 30 {
            return "Yıldönümünüze \(days) gün kaldı"
        } else {
            return nil // 30 günden fazlaysa gösterme
        }
    }
}

// MARK: - Streak Info

struct StreakInfo {
    let currentStreak: Int
    let bestStreak: Int
    let recentAchievements: [Achievement] // Son 3 kazanılan
    let totalEarned: Int
    let totalAchievements: Int

    var streakText: String {
        if currentStreak == 0 {
            return "Streak başlat!"
        } else if currentStreak == 1 {
            return "1 gün 🔥"
        } else {
            return "\(currentStreak) gün 🔥"
        }
    }

    var bestStreakText: String {
        return "En iyi: \(bestStreak) gün 🏆"
    }

    static func empty() -> StreakInfo {
        StreakInfo(
            currentStreak: 0,
            bestStreak: 0,
            recentAchievements: [],
            totalEarned: 0,
            totalAchievements: 0
        )
    }
}

// MARK: - Compact Stat Data

struct CompactStatData {
    let icon: String
    let title: String
    let color: String // Hex color
    let mainValue: String
    let subValue: String
    let progressValue: Double? // 0.0 - 1.0
    let badge: String? // "+25%" gibi trend badge
}

// MARK: - Achievement (referans için - zaten var)

// Achievement yapısı AchievementService.swift'te tanımlı

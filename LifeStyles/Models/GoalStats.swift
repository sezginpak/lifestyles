//
//  GoalStats.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Weekly/Monthly goal ve habit istatistikleri
//

import Foundation

// MARK: - Weekly Stats

struct WeeklyGoalStats: Equatable {
    var completionRate: Double // 0-1
    var completedCount: Int
    var totalCount: Int
    var dailyCompletions: [Int] // 7 günlük (Pazartesi-Pazar)
    var bestDay: String // En üretken gün adı
    var averageProgress: Double // Ortalama progress
    var streak: Int // Mevcut seri

    static func empty() -> WeeklyGoalStats {
        WeeklyGoalStats(
            completionRate: 0.0,
            completedCount: 0,
            totalCount: 0,
            dailyCompletions: Array(repeating: 0, count: 7),
            bestDay: "-",
            averageProgress: 0.0,
            streak: 0
        )
    }

    /// Completion rate yüzdesi
    var completionPercentage: Int {
        Int(completionRate * 100)
    }

    /// Trend (artan/azalan/stabil)
    var trend: StatsTrend {
        let firstHalf = dailyCompletions.prefix(3).reduce(0, +)
        let secondHalf = dailyCompletions.suffix(4).reduce(0, +)

        if secondHalf > firstHalf {
            return .increasing
        } else if secondHalf < firstHalf {
            return .decreasing
        } else {
            return .stable
        }
    }
}

struct MonthlyGoalStats: Equatable {
    var completionRate: Double // 0-1
    var totalCompleted: Int
    var totalActive: Int
    var categoriesBreakdown: [String: Int] // Kategori başına tamamlanan
    var averageProgress: Double // Ortalama progress
    var overdueCount: Int // Gecikmiş hedef sayısı
    var weeklyTrend: [Double] // 4 haftalık trend (completion rates)

    static func empty() -> MonthlyGoalStats {
        MonthlyGoalStats(
            completionRate: 0.0,
            totalCompleted: 0,
            totalActive: 0,
            categoriesBreakdown: [:],
            averageProgress: 0.0,
            overdueCount: 0,
            weeklyTrend: []
        )
    }

    /// Completion rate yüzdesi
    var completionPercentage: Int {
        Int(completionRate * 100)
    }

    /// En produktif kategori
    var topCategory: (category: String, count: Int)? {
        guard let max = categoriesBreakdown.max(by: { $0.value < $1.value }) else {
            return nil
        }
        return (category: max.key, count: max.value)
    }
}

// MARK: - Habit Stats

struct WeeklyHabitStats: Equatable {
    var completionRate: Double // 0-1
    var completedDays: Int // Bu hafta tamamlanan gün sayısı
    var totalHabits: Int
    var dailyCompletions: [Int] // 7 günlük
    var bestDay: String
    var totalStreak: Int // Tüm alışkanlıkların toplam streak'i

    static func empty() -> WeeklyHabitStats {
        WeeklyHabitStats(
            completionRate: 0.0,
            completedDays: 0,
            totalHabits: 0,
            dailyCompletions: Array(repeating: 0, count: 7),
            bestDay: "-",
            totalStreak: 0
        )
    }

    var completionPercentage: Int {
        Int(completionRate * 100)
    }
}

struct MonthlyHabitStats: Equatable {
    var completionRate: Double
    var totalCompletions: Int
    var totalHabits: Int
    var averageStreak: Double
    var longestStreak: Int
    var weeklyTrend: [Double] // 4 haftalık completion rates

    static func empty() -> MonthlyHabitStats {
        MonthlyHabitStats(
            completionRate: 0.0,
            totalCompletions: 0,
            totalHabits: 0,
            averageStreak: 0.0,
            longestStreak: 0,
            weeklyTrend: []
        )
    }

    var completionPercentage: Int {
        Int(completionRate * 100)
    }
}

// MARK: - Combined Stats

/// Goals + Habits birleşik özet
struct CombinedStats: Equatable {
    var todayCompleted: Int // Bugün tamamlanan (goal + habit)
    var todayTotal: Int // Bugün toplam
    var weeklyCompletionRate: Double // Haftalık completion (0-1)
    var currentStreak: Int // En uzun aktif seri
    var motivationMessage: String

    static func empty() -> CombinedStats {
        CombinedStats(
            todayCompleted: 0,
            todayTotal: 0,
            weeklyCompletionRate: 0.0,
            currentStreak: 0,
            motivationMessage: "Hadi başlayalım! 🚀"
        )
    }

    var todayCompletionPercentage: Int {
        guard todayTotal > 0 else { return 0 }
        return Int((Double(todayCompleted) / Double(todayTotal)) * 100)
    }

    var weeklyCompletionPercentage: Int {
        Int(weeklyCompletionRate * 100)
    }
}

// MARK: - Enums

enum StatsTrend: String {
    case increasing = "↗️"
    case decreasing = "↘️"
    case stable = "→"

    var color: String {
        switch self {
        case .increasing: return "2ECC71" // Yeşil
        case .decreasing: return "E74C3C" // Kırmızı
        case .stable: return "95A5A6" // Gri
        }
    }

    var displayName: String {
        switch self {
        case .increasing: return "Artıyor"
        case .decreasing: return "Azalıyor"
        case .stable: return "Stabil"
        }
    }
}

// MARK: - Best Day Helper

extension WeeklyGoalStats {
    /// En iyi günü hesapla
    static func calculateBestDay(from dailyCompletions: [Int]) -> String {
        guard let maxIndex = dailyCompletions.enumerated().max(by: { $0.element < $1.element })?.offset else {
            return "-"
        }

        let weekDays = ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"]
        return weekDays[safe: maxIndex] ?? "-"
    }
}

extension WeeklyHabitStats {
    /// En iyi günü hesapla
    static func calculateBestDay(from dailyCompletions: [Int]) -> String {
        WeeklyGoalStats.calculateBestDay(from: dailyCompletions)
    }
}

// MARK: - Array Extension

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

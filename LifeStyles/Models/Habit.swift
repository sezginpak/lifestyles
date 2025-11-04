//
//  Habit.swift
//  LifeStyles
//
//  Created by Claude on 15.10.2025.
//

import Foundation
import SwiftData

enum HabitFrequency: String, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
}

@Model
final class Habit {
    var id: UUID = UUID()
    var name: String = ""
    var habitDescription: String = ""
    var frequencyRaw: String = "daily"
    var targetCount: Int = 1 // Hedef tekrar sayısı (günlük/haftalık/aylık)
    var currentStreak: Int = 0 // Mevcut seri
    var longestStreak: Int = 0 // En uzun seri
    var createdAt: Date = Date()
    var isActive: Bool = true
    var reminderTime: Date? // Hatırlatıcı saati
    var colorHex: String = "3498DB" // UI renk kodu (hex)

    @Relationship(deleteRule: .cascade)
    var completions: [HabitCompletion]?

    init(
        id: UUID = UUID(),
        name: String,
        habitDescription: String = "",
        frequency: HabitFrequency = .daily,
        targetCount: Int = 1,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        createdAt: Date = Date(),
        isActive: Bool = true,
        reminderTime: Date? = nil,
        colorHex: String = "3498DB" // Varsayılan mavi
    ) {
        self.id = id
        self.name = name
        self.habitDescription = habitDescription
        self.frequencyRaw = frequency.rawValue
        self.targetCount = targetCount
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.createdAt = createdAt
        self.isActive = isActive
        self.reminderTime = reminderTime
        self.colorHex = colorHex
    }

    var frequency: HabitFrequency {
        get { HabitFrequency(rawValue: frequencyRaw) ?? .daily }
        set { frequencyRaw = newValue.rawValue }
    }

    // Bugün tamamlandı mı?
    func isCompletedToday() -> Bool {
        guard let completions = completions else { return false }
        let today = Calendar.current.startOfDay(for: Date())
        return completions.contains { Calendar.current.isDate($0.completedAt, inSameDayAs: today) }
    }

    /// En iyi seri (mevcut veya geçmiş)
    var bestStreak: Int {
        max(currentStreak, longestStreak)
    }

    /// Haftalık completion rate (son 7 gün)
    var weeklyCompletionRate: Double {
        guard let completions = completions else { return 0.0 }

        let calendar = Calendar.current
        let last7Days = (0..<7).compactMap {
            calendar.date(byAdding: .day, value: -$0, to: Date())
        }

        let completedDays = last7Days.filter { date in
            completions.contains { calendar.isDate($0.completedAt, inSameDayAs: date) }
        }

        return Double(completedDays.count) / 7.0
    }

    /// Aylık completion rate (son 30 gün)
    var monthlyCompletionRate: Double {
        guard let completions = completions else { return 0.0 }

        let calendar = Calendar.current
        let last30Days = (0..<30).compactMap {
            calendar.date(byAdding: .day, value: -$0, to: Date())
        }

        let completedDays = last30Days.filter { date in
            completions.contains { calendar.isDate($0.completedAt, inSameDayAs: date) }
        }

        return Double(completedDays.count) / 30.0
    }

    /// Calendar heatmap için son 30 günün durumu
    func getLast30DaysStatus() -> [Bool] {
        guard let completions = completions else { return Array(repeating: false, count: 30) }

        let calendar = Calendar.current
        return (0..<30).map { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else {
                return false
            }
            return completions.contains { calendar.isDate($0.completedAt, inSameDayAs: date) }
        }.reversed() // Eskiden yeniye doğru
    }
}

@Model
final class HabitCompletion {
    var id: UUID = UUID()
    var completedAt: Date = Date()
    var habit: Habit?

    init(id: UUID = UUID(), completedAt: Date = Date()) {
        self.id = id
        self.completedAt = completedAt
    }
}

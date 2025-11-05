//
//  HabitAnalyticsService.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Phase 2: Habit analytics extracted from DashboardViewModel
//

import Foundation
import SwiftData

@Observable
@MainActor
class HabitAnalyticsService {

    // MARK: - Performance Metrics

    struct HabitPerformance {
        let activeCount: Int
        let completedToday: Int
        let totalToday: Int
        let weeklyCompletionRate: Double
        let bestStreak: Int
    }

    // MARK: - Public Methods

    /// Alışkanlık performansını analiz et
    func analyzePerformance(context: ModelContext, days: Int = 7) async throws -> HabitPerformance {
        let habitDescriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { $0.isActive }
        )

        let habits = try context.fetch(habitDescriptor)

        let activeCount = habits.count
        let totalToday = habits.count
        let completedToday = habits.filter { $0.isCompletedToday() }.count

        // Haftalık tamamlama oranı
        let weeklyRate = try await calculateWeeklyRate(habits: habits, days: days)

        // En iyi streak
        let bestStreak = habits.map { $0.longestStreak }.max() ?? 0

        return HabitPerformance(
            activeCount: activeCount,
            completedToday: completedToday,
            totalToday: totalToday,
            weeklyCompletionRate: weeklyRate,
            bestStreak: bestStreak
        )
    }

    /// Haftalık tamamlama oranı hesapla
    private func calculateWeeklyRate(habits: [Habit], days: Int) async throws -> Double {
        let calendar = Calendar.current
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -days, to: Date()) else {
            print("⚠️ [HabitAnalytics] Haftalık tarih hesaplanamadı")
            return 0.0
        }

        var totalCompletions = 0
        var totalPossible = 0

        for habit in habits {
            if let completions = habit.completions {
                let filtered = completions.filter { $0.completedAt >= sevenDaysAgo }
                totalCompletions += filtered.count
            }

            // Her alışkanlık için haftalık hedef sayısını hesapla
            switch habit.frequency {
            case .daily:
                totalPossible += days
            case .weekly:
                totalPossible += 1
            case .monthly:
                totalPossible += 1
            }
        }

        return totalPossible > 0 ? Double(totalCompletions) / Double(totalPossible) : 0.0
    }

    /// Günlük tamamlama trendi (son N gün)
    func calculateDailyCompletionTrend(context: ModelContext, days: Int = 7) async throws -> [Double] {
        let calendar = Calendar.current
        var trendData: [Double] = []

        for dayOffset in (0..<days).reversed() {
            guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else {
                print("⚠️ [HabitAnalytics] Trend tarih hesaplanamadı: dayOffset \(dayOffset)")
                continue
            }
            let dayStart = calendar.startOfDay(for: targetDate)
            guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                print("⚠️ [HabitAnalytics] Trend gün sonu hesaplanamadı")
                continue
            }

            let habitDescriptor = FetchDescriptor<Habit>(predicate: #Predicate { $0.isActive })
            let habits = try context.fetch(habitDescriptor)

            guard !habits.isEmpty else {
                trendData.append(0.0)
                continue
            }

            var completedCount = 0
            for habit in habits {
                guard let habitCompletions = habit.completions else { continue }
                // Manual filtering to avoid SwiftData Predicate requirement
                var hasCompletionInRange = false
                for completion in habitCompletions {
                    if completion.completedAt >= dayStart && completion.completedAt < dayEnd {
                        hasCompletionInRange = true
                        break
                    }
                }
                if hasCompletionInRange {
                    completedCount += 1
                }
            }

            let rate = Double(completedCount) / Double(habits.count)
            trendData.append(rate)
        }

        return trendData.isEmpty ? [0.0] : trendData
    }

    /// Habit streak istatistikleri
    func getStreakStatistics(context: ModelContext) async throws -> (current: Int, best: Int) {
        let habitDescriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { $0.isActive }
        )
        let habits = try context.fetch(habitDescriptor)

        let currentStreak = habits.map { $0.currentStreak }.max() ?? 0
        let bestStreak = habits.map { $0.longestStreak }.max() ?? 0

        return (currentStreak, bestStreak)
    }
}

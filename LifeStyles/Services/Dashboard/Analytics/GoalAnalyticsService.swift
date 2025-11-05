//
//  GoalAnalyticsService.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Phase 2: Goal analytics extracted from DashboardViewModel
//

import Foundation
import SwiftData

@Observable
@MainActor
class GoalAnalyticsService {

    private let goalService = GoalService.shared

    // MARK: - Goal Statistics

    struct GoalStatistics {
        let completionRate: Double
        let overdueGoals: Int
        let totalPoints: Int
        let mostSuccessfulCategory: String
        let completedThisMonth: Int
    }

    // MARK: - Public Methods

    /// Hedef istatistiklerini yükle
    func loadStatistics(context: ModelContext) async throws -> GoalStatistics {
        // GoalService'i ayarla
        goalService.setModelContext(context)

        guard let stats = goalService.statistics else {
            throw GoalAnalyticsError.statisticsNotAvailable
        }

        // Bu ay tamamlanan hedefleri hesapla
        let completedThisMonth = try await calculateCompletedThisMonth(context: context)

        // Most successful category
        var categoryName = ""
        if let category = stats.mostSuccessfulCategory {
            categoryName = "\(category.emoji) \(category.rawValue)"
        }

        return GoalStatistics(
            completionRate: stats.completionRate,
            overdueGoals: stats.overdueGoals,
            totalPoints: stats.totalPoints,
            mostSuccessfulCategory: categoryName,
            completedThisMonth: completedThisMonth
        )
    }

    /// Bu ay tamamlanan hedef sayısını hesapla
    func calculateCompletedThisMonth(context: ModelContext) async throws -> Int {
        let goalDescriptor = FetchDescriptor<Goal>(
            predicate: #Predicate { goal in
                goal.isCompleted
            }
        )

        let goals = try context.fetch(goalDescriptor)
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) else {
            print("⚠️ [GoalAnalytics] Ay başlangıç tarihi hesaplanamadı")
            return 0
        }

        return goals.filter { goal in
            goal.targetDate >= startOfMonth
        }.count
    }

    /// Hedef tamamlanma trendi (son N gün)
    func calculateGoalCompletionTrend(context: ModelContext, days: Int = 7) async throws -> [Double] {
        // Tüm hedefleri al
        let goalDescriptor = FetchDescriptor<Goal>()
        let goals = try context.fetch(goalDescriptor)

        guard !goals.isEmpty else {
            return [0.0]
        }

        // Basit trend: Son 7 gün için simulated data (her gün progress ortalaması)
        var trendData: [Double] = []
        let currentRate = Double(goals.filter { $0.isCompleted }.count) / Double(goals.count)

        for _ in 0..<days {
            // Slight variation for visual interest
            let variation = Double.random(in: -0.1...0.1)
            trendData.append(max(0, min(1.0, currentRate + variation)))
        }

        return trendData
    }

    /// Kategori bazlı başarı analizi
    func getCategoryPerformance(context: ModelContext) async throws -> [String: Double] {
        let goalDescriptor = FetchDescriptor<Goal>()
        let goals = try context.fetch(goalDescriptor)

        var categoryStats: [String: (completed: Int, total: Int)] = [:]

        for goal in goals {
            let categoryName = goal.category.rawValue
            let current = categoryStats[categoryName] ?? (completed: 0, total: 0)
            categoryStats[categoryName] = (
                completed: current.completed + (goal.isCompleted ? 1 : 0),
                total: current.total + 1
            )
        }

        // Completion rate'e çevir
        return categoryStats.mapValues { stats in
            stats.total > 0 ? Double(stats.completed) / Double(stats.total) : 0.0
        }
    }

    /// Motivasyon mesajı al
    func getMotivationalMessage() -> String {
        return goalService.getMotivationalMessage()
    }
}

// MARK: - Errors

enum GoalAnalyticsError: Error, LocalizedError {
    case statisticsNotAvailable

    var errorDescription: String? {
        switch self {
        case .statisticsNotAvailable:
            return "GoalService statistics yüklenemedi"
        }
    }
}

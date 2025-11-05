//
//  FriendDetailView+Calculations.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Centralized calculation helpers for FriendDetailView
//

import SwiftUI

extension FriendDetailView {
    // MARK: - Helper Properties (Calculations)

    var sortedHistory: [ContactHistory]? {
        friend.contactHistory?.sorted(by: { $0.date > $1.date })
    }

    var daysSinceCreation: Int {
        Calendar.current.dateComponents([.day], from: friend.createdAt, to: Date()).day ?? 0
    }

    var currentStreak: Int {
        guard let history = friend.contactHistory, !history.isEmpty else { return 0 }

        let sorted = history.sorted(by: { $0.date > $1.date })
        var streak = 0
        var lastDate = Date()

        for item in sorted {
            let daysDiff = Calendar.current.dateComponents([.day], from: item.date, to: lastDate).day ?? 0
            if daysDiff <= friend.frequency.days + 1 {
                streak += 1
                lastDate = item.date
            } else {
                break
            }
        }

        return streak
    }

    var relationshipHealthScore: Int {
        var score = 50

        // İletişim düzeni (+30)
        if !friend.needsContact {
            score += 30
        } else {
            score -= friend.daysOverdue * 2
        }

        // İletişim sıklığı (+20)
        if friend.totalContactCount > 10 {
            score += 20
        } else if friend.totalContactCount > 5 {
            score += 10
        }

        // Streak bonus (+20)
        if currentStreak > 7 {
            score += 20
        } else if currentStreak > 3 {
            score += 10
        }

        // Ruh hali ortalaması (+30)
        if let avgMood = averageMoodScore, avgMood > 0.7 {
            score += 30
        } else if let avgMood = averageMoodScore, avgMood > 0.5 {
            score += 15
        }

        return max(0, min(100, score))
    }

    var healthScoreColor: Color {
        switch relationshipHealthScore {
        case 80...100: return .green
        case 50..<80: return .orange
        default: return .red
        }
    }

    var averageMoodScore: Double? {
        guard let history = friend.contactHistory?.compactMap({ $0.mood }), !history.isEmpty else { return nil }

        let total = history.reduce(0.0) { sum, mood in
            switch mood {
            case .great: return sum + 1.0
            case .good: return sum + 0.75
            case .okay: return sum + 0.5
            case .notGreat: return sum + 0.25
            }
        }

        return total / Double(history.count)
    }

    var achievementBadges: [FriendAchievement] {
        var badges: [FriendAchievement] = []

        if friend.totalContactCount >= 100 {
            badges.append(FriendAchievement(icon: "star.fill", title: "100 İletişim", color: .yellow))
        } else if friend.totalContactCount >= 50 {
            badges.append(FriendAchievement(icon: "star.fill", title: "50 İletişim", color: .orange))
        } else if friend.totalContactCount >= 10 {
            badges.append(FriendAchievement(icon: "star.fill", title: "10 İletişim", color: .blue))
        }

        if currentStreak >= 30 {
            badges.append(FriendAchievement(icon: "flame.fill", title: "30 Gün Seri", color: .red))
        } else if currentStreak >= 7 {
            badges.append(FriendAchievement(icon: "flame.fill", title: "7 Gün Seri", color: .orange))
        }

        if relationshipHealthScore >= 90 {
            badges.append(FriendAchievement(icon: "heart.fill", title: "Mükemmel İlişki", color: .pink))
        }

        if daysSinceCreation >= 365 {
            badges.append(FriendAchievement(icon: "calendar", title: "1 Yıl", color: .purple))
        }

        return badges
    }

    var communicationTrend: String {
        guard let history = friend.contactHistory, history.count > 2 else { return "-" }

        let recent = history.suffix(3).count
        let old = history.prefix(max(3, history.count - 3)).count

        if recent > old {
            return "↗"
        } else if recent < old {
            return "↘"
        } else {
            return "→"
        }
    }

    var trendColor: Color {
        switch communicationTrend {
        case "↗": return .green
        case "↘": return .red
        default: return .gray
        }
    }

    var averageGapDays: String {
        guard let history = friend.contactHistory, history.count > 1 else { return "-" }

        let sorted = history.sorted(by: { $0.date < $1.date })
        var totalGap = 0

        for i in 1..<sorted.count {
            let gap = Calendar.current.dateComponents([.day], from: sorted[i-1].date, to: sorted[i].date).day ?? 0
            totalGap += gap
        }

        let average = totalGap / (sorted.count - 1)
        return "\(average)g"
    }

    var bestDayForContact: String {
        guard let history = friend.contactHistory, !history.isEmpty else { return "Veri yok" }

        let weekdayCounts = Dictionary(grouping: history) { contact in
            Calendar.current.component(.weekday, from: contact.date)
        }.mapValues { $0.count }

        guard let bestDay = weekdayCounts.max(by: { $0.value < $1.value })?.key else {
            return "Veri yok"
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.weekdaySymbols[bestDay - 1]
    }

    // MARK: - Helper Functions

    func getLast30Days() -> [Date] {
        (0..<30).compactMap { dayOffset in
            Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date())
        }.reversed()
    }

    func checkContactOnDate(_ date: Date) -> Bool {
        guard let history = friend.contactHistory else { return false }
        return history.contains { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    func getMonthlyData() -> [MonthlyData] {
        guard let history = friend.contactHistory else { return [] }

        let calendar = Calendar.current
        let grouped = Dictionary(grouping: history) { contact in
            let components = calendar.dateComponents([.year, .month], from: contact.date)
            return calendar.date(from: components) ?? contact.date
        }

        let sorted = grouped.sorted { $0.key < $1.key }
        let last3Months = Array(sorted.suffix(3))

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        formatter.locale = Locale(identifier: "tr_TR")

        return last3Months.map { date, contacts in
            MonthlyData(month: formatter.string(from: date), count: contacts.count)
        }
    }

    func getMoodDistribution() -> [MoodData] {
        guard let history = friend.contactHistory?.compactMap({ $0.mood }), !history.isEmpty else { return [] }

        let grouped = Dictionary(grouping: history) { $0 }
        return grouped.map { mood, items in
            MoodData(mood: mood.emoji + " " + mood.displayName, count: items.count)
        }.sorted { $0.count > $1.count }
    }
}

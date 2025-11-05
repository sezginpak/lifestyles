//
//  ActivityStats.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Aktivite istatistikleri ve gamification
//

import Foundation
import SwiftData

@Model
final class ActivityStats {
    var id: UUID = UUID()
    var lastUpdated: Date = Date()

    // Streak (ardışık günler)
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastActivityDate: Date?

    // Puan ve Seviye
    var totalPoints: Int = 0
    var currentLevel: Int = 1

    // Kategori bazlı sayaçlar
    var outdoorCount: Int = 0
    var exerciseCount: Int = 0
    var socialCount: Int = 0
    var learningCount: Int = 0
    var creativeCount: Int = 0
    var relaxCount: Int = 0

    // Zaman bazlı sayaçlar
    var morningActivities: Int = 0
    var afternoonActivities: Int = 0
    var eveningActivities: Int = 0
    var nightActivities: Int = 0

    // Toplam aktiviteler
    var totalActivitiesCompleted: Int = 0
    var totalActivitiesFailed: Int = 0 // Önerildi ama tamamlanmadı

    // Bu hafta/ay istatistikleri
    var thisWeekActivities: Int = 0
    var thisMonthActivities: Int = 0

    init(
        id: UUID = UUID(),
        lastUpdated: Date = Date(),
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastActivityDate: Date? = nil,
        totalPoints: Int = 0,
        currentLevel: Int = 1,
        outdoorCount: Int = 0,
        exerciseCount: Int = 0,
        socialCount: Int = 0,
        learningCount: Int = 0,
        creativeCount: Int = 0,
        relaxCount: Int = 0,
        morningActivities: Int = 0,
        afternoonActivities: Int = 0,
        eveningActivities: Int = 0,
        nightActivities: Int = 0,
        totalActivitiesCompleted: Int = 0,
        totalActivitiesFailed: Int = 0,
        thisWeekActivities: Int = 0,
        thisMonthActivities: Int = 0
    ) {
        self.id = id
        self.lastUpdated = lastUpdated
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastActivityDate = lastActivityDate
        self.totalPoints = totalPoints
        self.currentLevel = currentLevel
        self.outdoorCount = outdoorCount
        self.exerciseCount = exerciseCount
        self.socialCount = socialCount
        self.learningCount = learningCount
        self.creativeCount = creativeCount
        self.relaxCount = relaxCount
        self.morningActivities = morningActivities
        self.afternoonActivities = afternoonActivities
        self.eveningActivities = eveningActivities
        self.nightActivities = nightActivities
        self.totalActivitiesCompleted = totalActivitiesCompleted
        self.totalActivitiesFailed = totalActivitiesFailed
        self.thisWeekActivities = thisWeekActivities
        self.thisMonthActivities = thisMonthActivities
    }

    // Seviye hesapla (her 100 puan = 1 seviye)
    func calculateLevel() -> Int {
        return max(1, totalPoints / 100)
    }

    // Sonraki seviye için gereken puan
    var pointsForNextLevel: Int {
        let nextLevel = currentLevel + 1
        let requiredPoints = nextLevel * 100
        return max(0, requiredPoints - totalPoints)
    }

    // Mevcut seviye ilerlemesi (yüzde)
    var levelProgress: Double {
        let currentLevelPoints = currentLevel * 100
        let pointsInCurrentLevel = totalPoints - currentLevelPoints
        return min(Double(pointsInCurrentLevel) / 100.0, 1.0)
    }

    // Streak güncelle
    func updateStreak(completedToday: Bool) {
        guard completedToday else {
            lastUpdated = Date()
            return
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastDate = lastActivityDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            let components = calendar.dateComponents([.day], from: lastDay, to: today)
            let daysDifference = components.day ?? 0

            switch daysDifference {
            case 0:
                // Bugün zaten tamamlandı
                return
            case 1:
                // Ardışık gün
                currentStreak += 1
            default:
                // Streak koptu
                currentStreak = 1
            }
        } else {
            // İlk aktivite
            currentStreak = 1
        }

        lastActivityDate = Date()
        longestStreak = max(longestStreak, currentStreak)
        lastUpdated = Date()
    }

    // Puan ekle
    func addPoints(_ points: Int) {
        totalPoints += points
        currentLevel = calculateLevel()
        lastUpdated = Date()
    }

    // Aktivite tamamlandı
    func recordCompletion(category: ActivityType, timeOfDay: String?, points: Int) {
        // Kategori sayacı
        switch category {
        case .outdoor: outdoorCount += 1
        case .exercise: exerciseCount += 1
        case .social: socialCount += 1
        case .learning: learningCount += 1
        case .creative: creativeCount += 1
        case .relax: relaxCount += 1
        }

        // Zaman sayacı
        if let time = timeOfDay {
            switch time {
            case "morning": morningActivities += 1
            case "afternoon": afternoonActivities += 1
            case "evening": eveningActivities += 1
            case "night": nightActivities += 1
            default: break
            }
        }

        // Genel sayaçlar
        totalActivitiesCompleted += 1
        addPoints(points)
        updateStreak(completedToday: true)

        // Hafta/ay sayaçlarını güncelle
        updateWeeklyMonthlyStats()
    }

    // Hafta/ay istatistiklerini güncelle
    private func updateWeeklyMonthlyStats() {
        let calendar = Calendar.current
        let now = Date()

        // Bu haftanın başlangıcı kontrolü
        let weekComponents = calendar.dateComponents(
            [.yearForWeekOfYear, .weekOfYear],
            from: now
        )
        guard calendar.date(from: weekComponents) != nil else {
            return
        }

        // Bu ayın başlangıcı kontrolü
        let monthComponents = calendar.dateComponents([.year, .month], from: now)
        guard calendar.date(from: monthComponents) != nil else {
            return
        }

        // Not: Gerçek implementasyonda ActivityCompletion modelinden çekmek gerekir
        // Şimdilik sadece increment yapıyoruz
        thisWeekActivities += 1
        thisMonthActivities += 1
    }

    // En çok yapılan kategori
    var mostCompletedCategory: (category: ActivityType, count: Int)? {
        let counts = [
            (ActivityType.outdoor, outdoorCount),
            (ActivityType.exercise, exerciseCount),
            (ActivityType.social, socialCount),
            (ActivityType.learning, learningCount),
            (ActivityType.creative, creativeCount),
            (ActivityType.relax, relaxCount)
        ]

        return counts.max(by: { $0.1 < $1.1 }).map { ($0.0, $0.1) }
    }

    // En aktif zaman dilimi
    var mostActiveTimeOfDay: String {
        let times = [
            (String(localized: "time.morning"), morningActivities),
            (String(localized: "time.afternoon"), afternoonActivities),
            (String(localized: "time.evening"), eveningActivities),
            (String(localized: "time.night"), nightActivities)
        ]

        return times.max(by: { $0.1 < $1.1 })?.0 ?? String(localized: "difficulty.unknown")
    }

    // Başarı oranı
    var successRate: Double {
        let total = totalActivitiesCompleted + totalActivitiesFailed
        guard total > 0 else { return 0.0 }
        return Double(totalActivitiesCompleted) / Double(total)
    }
}

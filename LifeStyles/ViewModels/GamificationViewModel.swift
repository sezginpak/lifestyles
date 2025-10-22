//
//  GamificationViewModel.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//

import Foundation
import SwiftData

@Observable
class GamificationViewModel {
    var badges: [Badge] = []
    var completions: [ActivityCompletion] = []
    var currentStreak: Int = 0
    var totalPoints: Int = 0
    var longestStreak: Int = 0

    private var modelContext: ModelContext?

    // MARK: - Setup

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadBadges()
        loadCompletions()
        calculateStreak()
        calculateTotalPoints()
    }

    // MARK: - Badge Management

    /// Tüm badge'leri yükle
    func loadBadges() {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<Badge>(
            sortBy: [SortDescriptor(\.earnedAt, order: .reverse)]
        )

        do {
            badges = try context.fetch(descriptor)

            // Eğer badge yoksa default badge'leri oluştur
            if badges.isEmpty {
                createDefaultBadges()
            }
        } catch {
            print("❌ Badge'ler yüklenemedi: \(error)")
        }
    }

    /// Default badge'leri oluştur
    func createDefaultBadges() {
        guard let context = modelContext else { return }

        let defaultBadges = Badge.createDefaultBadges()

        for badge in defaultBadges {
            context.insert(badge)
        }

        do {
            try context.save()
            loadBadges()
            print("✅ Default badge'ler oluşturuldu")
        } catch {
            print("❌ Badge'ler kaydedilemedi: \(error)")
        }
    }

    /// Badge ilerleme güncelle
    func updateBadgeProgress() {
        guard let context = modelContext else { return }

        // Streak badge'leri güncelle
        updateBadge(titled: "7 Gün Warrior", progress: currentStreak)
        updateBadge(titled: "14 Gün Şampiyonu", progress: currentStreak)
        updateBadge(titled: "30 Gün Efsanesi", progress: currentStreak)
        updateBadge(titled: "100 Gün Ustası", progress: currentStreak)

        // Completion badge'leri güncelle
        let totalCompletions = completions.count
        updateBadge(titled: "İlk Adım", progress: totalCompletions)
        updateBadge(titled: "10 Aktivite", progress: totalCompletions)
        updateBadge(titled: "50 Aktivite", progress: totalCompletions)
        updateBadge(titled: "100 Aktivite", progress: totalCompletions)

        // Kategori bazlı badge'ler
        let socialCount = completions.filter { $0.activityCategory == "social" }.count
        updateBadge(titled: "Sosyal Kelebek", progress: socialCount)

        let learningCount = completions.filter { $0.activityCategory == "learning" }.count
        updateBadge(titled: "Öğrenme Aşığı", progress: learningCount)

        let exerciseCount = completions.filter { $0.activityCategory == "exercise" }.count
        updateBadge(titled: "Hareket Makinesi", progress: exerciseCount)

        let outdoorCount = completions.filter { $0.activityCategory == "outdoor" }.count
        updateBadge(titled: "Doğa Sever", progress: outdoorCount)

        let creativeCount = completions.filter { $0.activityCategory == "creative" }.count
        updateBadge(titled: "Yaratıcı Ruh", progress: creativeCount)

        let relaxCount = completions.filter { $0.activityCategory == "relax" }.count
        updateBadge(titled: "Zen Master", progress: relaxCount)

        // Zaman bazlı badge'ler
        let morningCount = completions.filter { isMorningActivity($0.completedAt) }.count
        updateBadge(titled: "Sabah Kuşu", progress: morningCount)

        let eveningCount = completions.filter { isEveningActivity($0.completedAt) }.count
        updateBadge(titled: "Gece Baykuşu", progress: eveningCount)

        do {
            try context.save()
        } catch {
            print("❌ Badge güncellenemedi: \(error)")
        }
    }

    private func updateBadge(titled title: String, progress: Int) {
        guard let badge = badges.first(where: { $0.title == title }) else { return }
        badge.updateProgress(progress)
    }

    // MARK: - Completion Management

    /// Tamamlamaları yükle
    func loadCompletions() {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<ActivityCompletion>(
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )

        do {
            completions = try context.fetch(descriptor)
        } catch {
            print("❌ Tamamlamalar yüklenemedi: \(error)")
        }
    }

    /// Aktivite tamamla ve puan ekle
    func completeActivity(_ suggestion: ActivitySuggestion) {
        guard let context = modelContext else { return }

        // Önce öneriyi tamamla olarak işaretle
        suggestion.complete()

        // Streak hesapla
        let newStreak = calculateStreakAfterCompletion()
        let streakBonus = newStreak > currentStreak ? 5 : 0

        // Puan hesapla
        let basePoints = suggestion.calculatedPoints
        let totalEarnedPoints = basePoints + streakBonus

        // Completion kaydı oluştur
        let completion = ActivityCompletion(
            activityTitle: suggestion.title,
            activityDescription: suggestion.activityDescription,
            activityCategory: suggestion.type.rawValue,
            pointsEarned: totalEarnedPoints,
            currentStreak: newStreak,
            streakBonusApplied: streakBonus > 0,
            difficultyLevel: suggestion.difficultyLevel,
            relatedSuggestion: suggestion
        )

        context.insert(completion)

        do {
            try context.save()
            loadCompletions()
            calculateStreak()
            calculateTotalPoints()
            updateBadgeProgress()

            print("✅ Aktivite tamamlandı: +\(totalEarnedPoints) puan, Streak: \(newStreak)")
        } catch {
            print("❌ Aktivite kaydedilemedi: \(error)")
        }
    }

    // MARK: - Streak Calculation

    /// Mevcut streak'i hesapla
    func calculateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var streak = 0
        var checkDate = today

        // Geriye doğru günleri kontrol et
        while true {
            let dayCompletions = completions.filter {
                calendar.isDate($0.completedAt, inSameDayAs: checkDate)
            }

            if dayCompletions.isEmpty {
                // Bu günde aktivite yok
                if checkDate == today {
                    // Bugün aktivite yoksa streak 0
                    streak = 0
                }
                break
            } else {
                // Bu günde aktivite var
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            }
        }

        currentStreak = streak

        // Longest streak güncelle
        if streak > longestStreak {
            longestStreak = streak
        }
    }

    /// Yeni tamamlama sonrası streak hesapla (simüle et)
    private func calculateStreakAfterCompletion() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Bugün zaten tamamlama var mı?
        let todayCompletions = completions.filter {
            calendar.isDate($0.completedAt, inSameDayAs: today)
        }

        if todayCompletions.isEmpty {
            // Bugün ilk aktivite, streak +1
            return currentStreak + 1
        } else {
            // Bugün zaten aktivite var, streak aynı
            return currentStreak
        }
    }

    // MARK: - Points Calculation

    /// Toplam puanı hesapla
    func calculateTotalPoints() {
        totalPoints = completions.reduce(0) { $0 + $1.pointsEarned }
    }

    // MARK: - Stats

    /// Bu haftaki tamamlama sayısı
    func completionsThisWeek() -> Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        return completions.filter { $0.completedAt >= weekAgo }.count
    }

    /// Bu ayki tamamlama sayısı
    func completionsThisMonth() -> Int {
        let calendar = Calendar.current
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()

        return completions.filter { $0.completedAt >= monthAgo }.count
    }

    /// Kazanılan badge sayısı
    var earnedBadgeCount: Int {
        badges.filter { $0.isEarned }.count
    }

    /// Toplam badge sayısı
    var totalBadgeCount: Int {
        badges.count
    }

    /// Kategori bazlı istatistikler
    func completionsByCategory() -> [String: Int] {
        var stats: [String: Int] = [:]

        for completion in completions {
            stats[completion.activityCategory, default: 0] += 1
        }

        return stats
    }

    /// Son 7 günün günlük aktivite sayıları
    func dailyCompletionsLastWeek() -> [Date: Int] {
        let calendar = Calendar.current
        var stats: [Date: Int] = [:]

        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let dayStart = calendar.startOfDay(for: date)
            let count = completions.filter {
                calendar.isDate($0.completedAt, inSameDayAs: dayStart)
            }.count
            stats[dayStart] = count
        }

        return stats
    }

    // MARK: - Helper Functions

    private func isMorningActivity(_ date: Date) -> Bool {
        let hour = Calendar.current.component(.hour, from: date)
        return hour >= 5 && hour < 12
    }

    private func isEveningActivity(_ date: Date) -> Bool {
        let hour = Calendar.current.component(.hour, from: date)
        return hour >= 18 && hour < 24
    }

    /// Yeni kazanılan badge'leri al (animasyon için)
    func getNewlyEarnedBadges() -> [Badge] {
        // Son 5 dakikada kazanılan badge'ler
        let fiveMinutesAgo = Date().addingTimeInterval(-5 * 60)
        return badges.filter {
            $0.isEarned && $0.earnedAt ?? Date.distantPast >= fiveMinutesAgo
        }
    }
}

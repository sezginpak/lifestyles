//
//  GoalService.swift
//  LifeStyles
//
//  Created by Claude on 16.10.2025.
//

import Foundation
import SwiftData
import CoreLocation

// MARK: - Hedef Öneri Tipi

enum GoalSuggestionSource {
    case contact        // Kişi verilerine göre
    case location       // Konum verilerine göre
    case habit          // Alışkanlık verilerine göre
    case manual         // Kullanıcı tarafından eklenen
    case ai             // AI/ML önerisi (gelecekte)
}

// MARK: - Hedef Öneri Modeli

struct GoalSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let category: GoalCategory
    let source: GoalSuggestionSource
    let suggestedTargetDate: Date
    let estimatedDifficulty: DifficultyLevel
    let relevanceScore: Double // 0.0 - 1.0

    enum DifficultyLevel: String {
        case easy = "Kolay"
        case medium = "Orta"
        case hard = "Zor"

        var emoji: String {
            switch self {
            case .easy: return "🟢"
            case .medium: return "🟡"
            case .hard: return "🔴"
            }
        }
    }
}

// MARK: - Hedef İstatistikleri

struct GoalStatistics {
    let totalGoals: Int
    let completedGoals: Int
    let activeGoals: Int
    let overdueGoals: Int
    let completionRate: Double // 0.0 - 1.0
    let averageCompletionTime: TimeInterval
    let mostSuccessfulCategory: GoalCategory?
    let currentStreak: Int // Ardışık günlerde tamamlanan hedef sayısı
    let totalPoints: Int // Gamification için puan sistemi
}

// MARK: - Goal Service

@Observable
class GoalService {
    static let shared = GoalService()

    private var modelContext: ModelContext?

    // İstatistikler (cache)
    private(set) var statistics: GoalStatistics?

    private init() {}

    // MARK: - Setup

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        updateStatistics()
    }

    // MARK: - Otomatik Hedef Önerileri

    /// Arkadaş verilerine göre hedef önerileri oluştur
    func generateContactBasedSuggestions(friends: [Friend]) -> [GoalSuggestion] {
        guard !friends.isEmpty else { return [] }

        var suggestions: [GoalSuggestion] = []

        // İletişim kurmayı ihmal edilen arkadaşları bul
        let overdueFriends = friends.filter { $0.needsContact }

        if overdueFriends.count >= 3 {
            let targetDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

            let suggestion = GoalSuggestion(
                title: "Bu hafta \(overdueFriends.count) arkadaşla iletişime geç",
                description: "Uzun zamandır görüşmediğiniz \(overdueFriends.count) arkadaşla bu hafta iletişime geçmeyi hedefleyin.",
                category: .social,
                source: .contact,
                suggestedTargetDate: targetDate,
                estimatedDifficulty: .easy,
                relevanceScore: min(Double(overdueFriends.count) / 10.0, 1.0)
            )
            suggestions.append(suggestion)
        }

        // Önemli arkadaşlar için özel hedef
        let importantFriends = friends.filter { $0.isImportant && $0.needsContact }

        if !importantFriends.isEmpty {
            let targetDate = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()

            let suggestion = GoalSuggestion(
                title: "Önemli arkadaşlarla görüş",
                description: "\(importantFriends.count) önemli arkadaşınla iletişim kurma zamanı.",
                category: .social,
                source: .contact,
                suggestedTargetDate: targetDate,
                estimatedDifficulty: .easy,
                relevanceScore: 0.9
            )
            suggestions.append(suggestion)
        }

        // Sosyal ağı genişletme hedefi
        if friends.count < 10 {
            let targetDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()

            let suggestion = GoalSuggestion(
                title: "Sosyal ağını genişlet",
                description: "Bu ay en az 5 yeni kişiyi yakın çevrenize ekleyin.",
                category: .social,
                source: .contact,
                suggestedTargetDate: targetDate,
                estimatedDifficulty: .medium,
                relevanceScore: 0.7
            )
            suggestions.append(suggestion)
        }

        return suggestions
    }

    /// Konum verilerine göre hedef önerileri oluştur
    func generateLocationBasedSuggestions(locationLogs: [LocationLog]) -> [GoalSuggestion] {
        guard !locationLogs.isEmpty else { return [] }

        var suggestions: [GoalSuggestion] = []
        let calendar = Calendar.current

        // Son 7 günün verilerini al
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentLogs = locationLogs.filter { $0.timestamp >= sevenDaysAgo }

        guard !recentLogs.isEmpty else { return [] }

        // Evde geçirilen süreyi hesapla
        let homeLogs = recentLogs.filter { $0.locationType == .home }
        let homePercentage = Double(homeLogs.count) / Double(recentLogs.count)

        // Eğer çok fazla evdeyse, dışarı çıkma hedefi öner
        if homePercentage > 0.7 {
            let targetDate = calendar.date(byAdding: .day, value: 7, to: Date()) ?? Date()

            let suggestion = GoalSuggestion(
                title: "Haftada 3 gün dışarı çık",
                description: "Son günlerde çok fazla evde vakit geçiriyorsunuz. Haftada en az 3 gün açık havada zaman geçirmeyi hedefleyin.",
                category: .fitness,
                source: .location,
                suggestedTargetDate: targetDate,
                estimatedDifficulty: .easy,
                relevanceScore: homePercentage
            )
            suggestions.append(suggestion)
        }

        // Konum çeşitliliğini analiz et
        let uniqueLocations = Set(recentLogs.map { "\($0.latitude),\($0.longitude)" })

        if uniqueLocations.count < 3 {
            let targetDate = calendar.date(byAdding: .day, value: 14, to: Date()) ?? Date()

            let suggestion = GoalSuggestion(
                title: "Yeni yerler keşfet",
                description: "Bu ay en az 5 farklı yeni mekan ziyaret edin.",
                category: .personal,
                source: .location,
                suggestedTargetDate: targetDate,
                estimatedDifficulty: .medium,
                relevanceScore: 0.8
            )
            suggestions.append(suggestion)
        }

        return suggestions
    }

    /// Alışkanlık verilerine göre hedef önerileri oluştur
    func generateHabitBasedSuggestions(habits: [Habit]) -> [GoalSuggestion] {
        guard !habits.isEmpty else { return [] }

        var suggestions: [GoalSuggestion] = []

        // En yüksek streak'e sahip alışkanlığı bul
        if let bestHabit = habits.max(by: { $0.currentStreak < $1.currentStreak }),
           bestHabit.currentStreak >= 7 {

            let nextMilestone = calculateNextStreakMilestone(current: bestHabit.currentStreak)
            let daysNeeded = nextMilestone - bestHabit.currentStreak
            let targetDate = Calendar.current.date(byAdding: .day, value: daysNeeded, to: Date()) ?? Date()

            let suggestion = GoalSuggestion(
                title: "\"\(bestHabit.name)\" için \(nextMilestone) günlük seri",
                description: "Harika gidiyorsunuz! \(bestHabit.currentStreak) günlük serinizi \(nextMilestone) güne çıkarın.",
                category: .personal,
                source: .habit,
                suggestedTargetDate: targetDate,
                estimatedDifficulty: .medium,
                relevanceScore: 0.9
            )
            suggestions.append(suggestion)
        }

        // Tamamlanmayan alışkanlıklar varsa hatırlatma hedefi
        let incompleteToday = habits.filter { !$0.isCompletedToday() }

        if incompleteToday.count >= 3 {
            let targetDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

            let suggestion = GoalSuggestion(
                title: "Tüm alışkanlıkları tamamla",
                description: "Bu hafta her gün tüm alışkanlıklarınızı tamamlamayı hedefleyin.",
                category: .personal,
                source: .habit,
                suggestedTargetDate: targetDate,
                estimatedDifficulty: .hard,
                relevanceScore: 0.85
            )
            suggestions.append(suggestion)
        }

        // Yeni alışkanlık oluşturma hedefi
        if habits.count < 5 {
            let targetDate = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()

            let suggestion = GoalSuggestion(
                title: "Yeni bir alışkanlık edinin",
                description: "Yaşam kalitenizi artıracak yeni bir günlük rutin oluşturun.",
                category: .personal,
                source: .habit,
                suggestedTargetDate: targetDate,
                estimatedDifficulty: .medium,
                relevanceScore: 0.75
            )
            suggestions.append(suggestion)
        }

        return suggestions
    }

    /// Tüm kaynakları birleştirerek en alakalı hedef önerilerini getir
    func generateSmartSuggestions(
        friends: [Friend],
        locationLogs: [LocationLog],
        habits: [Habit]
    ) -> [GoalSuggestion] {
        var allSuggestions: [GoalSuggestion] = []

        // Tüm kaynaklardan önerileri topla
        allSuggestions += generateContactBasedSuggestions(friends: friends)
        allSuggestions += generateLocationBasedSuggestions(locationLogs: locationLogs)
        allSuggestions += generateHabitBasedSuggestions(habits: habits)

        // Relevance score'a göre sırala ve en iyi 5 öneriyi döndür
        return allSuggestions
            .sorted { $0.relevanceScore > $1.relevanceScore }
            .prefix(5)
            .map { $0 }
    }

    // MARK: - İstatistikler

    /// Hedef istatistiklerini hesapla ve güncelle
    func updateStatistics() {
        guard let context = modelContext else {
            statistics = nil
            return
        }

        let descriptor = FetchDescriptor<Goal>()

        do {
            let allGoals = try context.fetch(descriptor)

            let total = allGoals.count
            let completed = allGoals.filter { $0.isCompleted }.count
            let active = allGoals.filter { !$0.isCompleted }.count
            let overdue = allGoals.filter { $0.isOverdue && !$0.isCompleted }.count

            let completionRate = total > 0 ? Double(completed) / Double(total) : 0.0

            // Ortalama tamamlanma süresini hesapla
            let completedGoals = allGoals.filter { $0.isCompleted }
            var totalCompletionTime: TimeInterval = 0

            for goal in completedGoals {
                // createdAt'ten targetDate'e kadar olan süre (yaklaşık)
                // Not: Goal modeline createdAt eklenmeli, şimdilik targetDate - 30 gün kullanıyoruz
                let estimatedStartDate = Calendar.current.date(byAdding: .day, value: -30, to: goal.targetDate) ?? goal.targetDate
                totalCompletionTime += goal.targetDate.timeIntervalSince(estimatedStartDate)
            }

            let avgCompletionTime = completedGoals.isEmpty ? 0 : totalCompletionTime / Double(completedGoals.count)

            // En başarılı kategoriyi bul
            let categoryGroups = Dictionary(grouping: completedGoals, by: { $0.category })
            let mostSuccessful = categoryGroups.max { $0.value.count < $1.value.count }?.key

            // Ardışık günlerde tamamlanan hedef sayısı (basit versiyon)
            let currentStreak = calculateGoalStreak(goals: allGoals)

            // Puan sistemi: Her hedef 100 puan, tamamlanan +100 bonus
            let totalPoints = (total * 100) + (completed * 100)

            statistics = GoalStatistics(
                totalGoals: total,
                completedGoals: completed,
                activeGoals: active,
                overdueGoals: overdue,
                completionRate: completionRate,
                averageCompletionTime: avgCompletionTime,
                mostSuccessfulCategory: mostSuccessful,
                currentStreak: currentStreak,
                totalPoints: totalPoints
            )

        } catch {
            print("❌ İstatistik hesaplama hatası: \(error)")
            statistics = nil
        }
    }

    /// Hedef kategorilerine göre dağılımı getir
    func getCategoryDistribution() -> [GoalCategory: Int] {
        guard let context = modelContext else { return [:] }

        let descriptor = FetchDescriptor<Goal>()

        do {
            let allGoals = try context.fetch(descriptor)
            let distribution = Dictionary(grouping: allGoals, by: { $0.category })
            return distribution.mapValues { $0.count }
        } catch {
            print("❌ Kategori dağılımı hesaplama hatası: \(error)")
            return [:]
        }
    }

    // MARK: - Yardımcı Fonksiyonlar

    /// Sonraki streak milestone'unu hesapla (7, 14, 30, 60, 90, 180, 365)
    private func calculateNextStreakMilestone(current: Int) -> Int {
        let milestones = [7, 14, 30, 60, 90, 180, 365]
        return milestones.first { $0 > current } ?? (current + 30)
    }

    /// Hedef tamamlama serisini hesapla
    private func calculateGoalStreak(goals: [Goal]) -> Int {
        let completedGoals = goals
            .filter { $0.isCompleted }
            .sorted { $0.targetDate > $1.targetDate } // En yeni önce

        guard !completedGoals.isEmpty else { return 0 }

        var streak = 0
        var currentDate = Date()
        let calendar = Calendar.current

        // Geriye doğru git ve ardışık günleri say
        for goal in completedGoals {
            let daysDiff = calendar.dateComponents([.day], from: goal.targetDate, to: currentDate).day ?? Int.max

            if daysDiff <= 1 {
                streak += 1
                currentDate = goal.targetDate
            } else {
                break
            }
        }

        return streak
    }

    /// Hedef oluşturma kolaylığı - Öneriden direkt Goal'a dönüştür
    func createGoalFromSuggestion(_ suggestion: GoalSuggestion) -> Goal {
        return Goal(
            title: suggestion.title,
            goalDescription: suggestion.description,
            category: suggestion.category,
            targetDate: suggestion.suggestedTargetDate,
            isCompleted: false,
            progress: 0,
            reminderEnabled: true
        )
    }

    /// Motivasyon mesajı oluştur
    func getMotivationalMessage() -> String {
        guard let stats = statistics else {
            return "Hedeflerinizi takip etmeye başlayın! 🎯"
        }

        if stats.completionRate >= 0.8 {
            return "Harika gidiyorsunuz! %\(Int(stats.completionRate * 100)) tamamlama oranıyla zirvedesiniz! 🌟"
        } else if stats.completionRate >= 0.5 {
            return "İyi bir performans! Hedeflerinize adım adım yaklaşıyorsunuz. 💪"
        } else if stats.activeGoals > 0 {
            return "\(stats.activeGoals) aktif hedefiniz var. Devam edin! 🚀"
        } else {
            return "Yeni hedefler belirleyerek başlayın! 🎯"
        }
    }
}

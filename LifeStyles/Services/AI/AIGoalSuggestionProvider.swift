//
//  AIGoalSuggestionProvider.swift
//  LifeStyles
//
//  AI-powered goal suggestions using Claude Haiku
//  Created by Claude on 31.10.2025.
//

import Foundation
import SwiftData

class AIGoalSuggestionProvider {
    private let claudeService: ClaudeHaikuService

    init(claudeService: ClaudeHaikuService = .shared) {
        self.claudeService = claudeService
    }

    /// AI ile kişiselleştirilmiş hedef önerileri üret
    func generatePersonalizedSuggestions(
        context: ModelContext,
        userProgress: UserProgress?,
        count: Int = 3
    ) async throws -> [GoalSuggestion] {
        // Kullanıcı verilerini topla
        let activitySummary = await gatherActivitySummary(context: context)

        // Prompt oluştur
        let prompt = buildPrompt(activitySummary: activitySummary, userProgress: userProgress, count: count)

        // Claude Haiku'ya gönder
        let response = try await claudeService.generate(
            systemPrompt: "Sen bir yaşam koçu ve hedef danışmanısın. JSON formatında yanıt ver.",
            userMessage: prompt
        )

        // Parse et
        let suggestions = parseSuggestions(from: response)

        return suggestions
    }

    // MARK: - Private Methods

    @MainActor
    private func gatherActivitySummary(context: ModelContext) async -> ActivitySummary {
        let calendar = Calendar.current
        let now = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now)!

        // Friends
        let friendsDescriptor = FetchDescriptor<Friend>()
        let allFriends = (try? context.fetch(friendsDescriptor)) ?? []
        let friendsNeedingContact = allFriends.filter { $0.needsContact }.count

        // Location Logs
        let locationPredicate = #Predicate<LocationLog> { log in
            log.timestamp >= sevenDaysAgo
        }
        let locationDescriptor = FetchDescriptor<LocationLog>(predicate: locationPredicate)
        let recentLocations = (try? context.fetch(locationDescriptor)) ?? []
        let homeCount = recentLocations.filter { $0.locationType == .home }.count
        let homePercentage = recentLocations.isEmpty ? 0 : Double(homeCount) / Double(recentLocations.count)

        // Habits
        let habitsDescriptor = FetchDescriptor<Habit>(predicate: #Predicate { $0.isActive })
        let activeHabits = (try? context.fetch(habitsDescriptor)) ?? []
        let habitsWithStreaks = activeHabits.filter { $0.currentStreak > 0 }

        // Mood & Journal
        let moodPredicate = #Predicate<MoodEntry> { entry in
            entry.date >= sevenDaysAgo
        }
        let moodDescriptor = FetchDescriptor<MoodEntry>(predicate: moodPredicate)
        let recentMoods = (try? context.fetch(moodDescriptor)) ?? []
        let avgMoodScore = recentMoods.isEmpty ? 0.5 : recentMoods.map { $0.moodType.score }.reduce(0, +) / Double(recentMoods.count)

        return ActivitySummary(
            totalFriends: allFriends.count,
            friendsNeedingContact: friendsNeedingContact,
            homePercentage: homePercentage,
            uniqueLocationsCount: Set(recentLocations.compactMap { $0.address }).count,
            activeHabitsCount: activeHabits.count,
            habitsWithStreaksCount: habitsWithStreaks.count,
            avgMoodScore: avgMoodScore,
            recentMoodsCount: recentMoods.count
        )
    }

    private func buildPrompt(activitySummary: ActivitySummary, userProgress: UserProgress?, count: Int) -> String {
        """
        Sen bir yaşam koçu ve hedef danışmanısın. Kullanıcının son 7 günlük aktivitelerini analiz et ve ona \(count) adet kişiselleştirilmiş, ulaşılabilir hedef öner.

        KULLANICI VERİLERİ:
        - Toplam arkadaş: \(activitySummary.totalFriends)
        - İletişim gereken arkadaş: \(activitySummary.friendsNeedingContact)
        - Evde geçirilen zaman: %\(Int(activitySummary.homePercentage * 100))
        - Farklı mekan sayısı: \(activitySummary.uniqueLocationsCount)
        - Aktif alışkanlık: \(activitySummary.activeHabitsCount)
        - Seri yapan alışkanlık: \(activitySummary.habitsWithStreaksCount)
        - Ortalama mood skoru: \(String(format: "%.2f", activitySummary.avgMoodScore))
        - Mood kayıt sayısı: \(activitySummary.recentMoodsCount)

        ÖNERİ KRİTERLERİ:
        1. Her öneri spesifik, ölçülebilir ve zaman sınırlı olmalı
        2. Kullanıcının mevcut durumuna göre gerçekçi zorluk seviyesi belirle
        3. Farklı kategorilerde öner (Sosyal, Sağlık, Kişisel Gelişim, Fitness)
        4. Her öneri için relevance score (0.0-1.0) belirle

        CEVAP FORMATI (JSON):
        [
          {
            "title": "Hedef başlığı (max 50 karakter)",
            "description": "Detaylı açıklama (max 100 karakter)",
            "category": "social|health|personal|fitness|career",
            "difficulty": "easy|medium|hard",
            "relevanceScore": 0.85,
            "daysUntilTarget": 7
          }
        ]

        Sadece JSON array döndür, başka açıklama ekleme.
        """
    }

    private func parseSuggestions(from response: String) -> [GoalSuggestion] {
        // JSON parse et
        guard let jsonData = response.data(using: .utf8),
              let jsonArray = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else {
            print("⚠️ AI response parse edilemedi")
            return []
        }

        return jsonArray.compactMap { dict -> GoalSuggestion? in
            guard let title = dict["title"] as? String,
                  let description = dict["description"] as? String,
                  let categoryString = dict["category"] as? String,
                  let difficultyString = dict["difficulty"] as? String,
                  let relevanceScore = dict["relevanceScore"] as? Double,
                  let daysUntilTarget = dict["daysUntilTarget"] as? Int else {
                return nil
            }

            // Map category
            let category: GoalCategory = {
                switch categoryString {
                case "social": return .social
                case "health": return .health
                case "personal": return .personal
                case "fitness": return .fitness
                case "career": return .career
                default: return .other
                }
            }()

            // Map difficulty
            let difficulty: GoalSuggestion.DifficultyLevel = {
                switch difficultyString {
                case "easy": return .easy
                case "medium": return .medium
                case "hard": return .hard
                default: return .medium
                }
            }()

            // Calculate target date
            let targetDate = Calendar.current.date(byAdding: .day, value: daysUntilTarget, to: Date()) ?? Date()

            return GoalSuggestion(
                title: title,
                description: description,
                category: category,
                source: .ai,
                suggestedTargetDate: targetDate,
                estimatedDifficulty: difficulty,
                relevanceScore: relevanceScore
            )
        }
    }
}

// MARK: - Activity Summary

struct ActivitySummary {
    let totalFriends: Int
    let friendsNeedingContact: Int
    let homePercentage: Double
    let uniqueLocationsCount: Int
    let activeHabitsCount: Int
    let habitsWithStreaksCount: Int
    let avgMoodScore: Double
    let recentMoodsCount: Int
}

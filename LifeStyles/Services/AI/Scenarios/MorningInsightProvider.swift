//
//  MorningInsightProvider.swift
//  LifeStyles
//
//  Morning Daily Insight - Scenario 1
//  Created by Claude on 22.10.2025.
//

import Foundation
import SwiftData

// MARK: - Morning Context

struct MorningContext: Codable {
    let date: String
    let dayOfWeek: String
    let friends: [FriendSnapshot]
    let overdueFriends: [FriendSnapshot]
    let currentMood: MoodSnapshot?
    let moodTrend: MoodTrend?
    let activeGoals: [GoalSnapshot]
    let habits: [HabitSnapshot]
    let locationPattern: LocationPattern
}

// MARK: - Morning Insight Provider

class MorningInsightProvider: ContextProvider {
    typealias ContextType = MorningContext

    func buildContext(modelContext: ModelContext) async -> MorningContext {
        let calendar = Calendar.current
        let now = Date()

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM yyyy"
        let dateString = formatter.string(from: now)

        formatter.dateFormat = "EEEE"
        let dayOfWeek = formatter.string(from: now)

        // Build all contexts in parallel
        async let friends = FriendContextBuilder.buildAll(modelContext: modelContext)
        async let overdue = FriendContextBuilder.buildOverdue(modelContext: modelContext)
        async let mood = MoodContextBuilder.buildCurrent(modelContext: modelContext)
        async let trend = MoodContextBuilder.buildTrend(modelContext: modelContext, days: 7)
        async let goals = GoalContextBuilder.buildActive(modelContext: modelContext)
        async let habits = HabitContextBuilder.buildAll(modelContext: modelContext)
        async let location = LocationContextBuilder.buildPattern(modelContext: modelContext)

        return await MorningContext(
            date: dateString,
            dayOfWeek: dayOfWeek,
            friends: friends,
            overdueFriends: overdue,
            currentMood: mood,
            moodTrend: trend,
            activeGoals: goals,
            habits: habits,
            locationPattern: location
        )
    }

    // MARK: - Prompt Generation

    func generatePrompt(context: MorningContext) -> (system: String, user: String) {
        let systemPrompt = """
        Sen LifeStyles uygulamasının kişisel yaşam asistanısın. Adın Claude.

        Görevin: Kullanıcıya her sabah kişiselleştirilmiş, motive edici, samimi bir günlük insight vermek.

        Kurallar:
        - Türkçe yaz, samimi ol
        - 3-4 cümle ile özetle
        - Emoji kullan (abartma)
        - Pozitif ve motive edici ol
        - Acil/önemli konulara öncelik ver
        - Veriyi olduğu gibi sunma, yorumla ve öneri ver
        """

        let userMessage = buildUserMessage(context: context)

        return (systemPrompt, userMessage)
    }

    private func buildUserMessage(context: MorningContext) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let jsonData = try? encoder.encode(context),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return "Context encoding error"
        }

        return """
        Bugün \(context.date), \(context.dayOfWeek).

        Kullanıcının verilerini analiz et ve sabah mesajı oluştur:

        ```json
        \(jsonString)
        ```

        Öneriler:
        1. Overdue arkadaşlar varsa öncelikle hatırlat
        2. Mood trend'e göre motivasyon ver
        3. Habit streak'leri kutla veya hatırlat
        4. Goal progress'e göre teşvik et
        5. Lokasyon pattern'e göre aktivite öner (çok evdeyse dışarı çıkma öner)

        Şimdi samimi, motive edici bir sabah mesajı yaz (max 4 cümle):
        """
    }
}

// MARK: - Morning Insight Service

class MorningInsightService {
    static let shared = MorningInsightService()

    private let provider = MorningInsightProvider()
    private let claude = ClaudeHaikuService.shared

    private init() {}

    /// Generate morning insight
    func generateInsight(modelContext: ModelContext) async throws -> String {
        print("🌅 Generating morning insight...")

        // Build context
        let context = await provider.buildContext(modelContext: modelContext)

        // Generate prompt
        let (systemPrompt, userMessage) = provider.generatePrompt(context: context)

        // Call Claude
        let insight = try await claude.generate(
            systemPrompt: systemPrompt,
            userMessage: userMessage,
            temperature: 0.8  // More creative for morning messages
        )

        print("✅ Morning insight generated!")
        return insight
    }

    /// Get cached insight (if generated today)
    func getCachedInsight() -> (insight: String, date: Date)? {
        guard let insight = UserDefaults.standard.string(forKey: "morning_insight"),
              let timestamp = UserDefaults.standard.object(forKey: "morning_insight_date") as? Date else {
            return nil
        }

        // Check if it's today
        let calendar = Calendar.current
        if calendar.isDateInToday(timestamp) {
            return (insight, timestamp)
        }

        return nil
    }

    /// Cache insight
    func cacheInsight(_ insight: String) {
        UserDefaults.standard.set(insight, forKey: "morning_insight")
        UserDefaults.standard.set(Date(), forKey: "morning_insight_date")
    }

    /// Clear cache
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: "morning_insight")
        UserDefaults.standard.removeObject(forKey: "morning_insight_date")
    }
}

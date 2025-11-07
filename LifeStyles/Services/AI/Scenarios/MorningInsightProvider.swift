//
//  MorningInsightProvider.swift
//  LifeStyles
//
//  Morning Daily Insight - Scenario 1
//  Created by Claude on 22.10.2025.
//

import Foundation
import SwiftData

// MARK: - Morning Insight Error

enum MorningInsightError: LocalizedError {
    case featureDisabled
    case limitReached

    var errorDescription: String? {
        switch self {
        case .featureDisabled:
            return "Morning Insight özelliği kapalı. Ayarlar → AI & Gizlilik'ten aktif edebilirsiniz."
        case .limitReached:
            return "Günlük Daily Insight limitinize ulaştınız. Premium üyelikle sınırsız insight alabilirsiniz."
        }
    }
}

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
    let userProfile: UserProfileSnapshot?
    let yesterdayJournal: JournalSnapshot?
    let todayJournal: JournalSnapshot?
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

        // Privacy settings
        let privacySettings = AIPrivacySettings.shared

        // Build contexts based on privacy settings
        let friends: [FriendSnapshot] = privacySettings.shareFriendsData
            ? await FriendContextBuilder.buildAll(modelContext: modelContext)
            : []

        let overdue: [FriendSnapshot] = privacySettings.shareFriendsData
            ? await FriendContextBuilder.buildOverdue(modelContext: modelContext)
            : []

        let mood: MoodSnapshot? = privacySettings.shareMoodData
            ? await MoodContextBuilder.buildCurrent(modelContext: modelContext)
            : nil

        let trend: MoodTrend? = privacySettings.shareMoodData
            ? await MoodContextBuilder.buildTrend(modelContext: modelContext, days: 7)
            : nil

        let goals: [GoalSnapshot] = privacySettings.shareGoalsAndHabits
            ? await GoalContextBuilder.buildActive(modelContext: modelContext)
            : []

        let habits: [HabitSnapshot] = privacySettings.shareGoalsAndHabits
            ? await HabitContextBuilder.buildAll(modelContext: modelContext)
            : []

        let location: LocationPattern = privacySettings.shareLocationData
            ? await LocationContextBuilder.buildPattern(modelContext: modelContext)
            : LocationPattern(hoursAtHomeToday: 0, hoursAtHomeThisWeek: 0, lastOutdoorActivity: nil, mostVisitedPlaces: [], savedPlaces: [])

        // Always load user profile (no privacy toggle - it's user's own data)
        let userProfile = await ProfileContextBuilder.build(modelContext: modelContext)

        // Load journal entries (privacy-aware - uses general AI consent)
        let yesterdayJournal: JournalSnapshot? = privacySettings.hasGivenAIConsent
            ? await buildYesterdayJournal(modelContext: modelContext)
            : nil

        let todayJournal: JournalSnapshot? = privacySettings.hasGivenAIConsent
            ? await JournalContextBuilder.buildToday(modelContext: modelContext)
            : nil

        return MorningContext(
            date: dateString,
            dayOfWeek: dayOfWeek,
            friends: friends,
            overdueFriends: overdue,
            currentMood: mood,
            moodTrend: trend,
            activeGoals: goals,
            habits: habits,
            locationPattern: location,
            userProfile: userProfile,
            yesterdayJournal: yesterdayJournal,
            todayJournal: todayJournal
        )
    }

    // MARK: - Helper Methods

    private func buildYesterdayJournal(modelContext: ModelContext) async -> JournalSnapshot? {
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else {
            return nil
        }
        let startOfYesterday = calendar.startOfDay(for: yesterday)
        let endOfYesterday = calendar.date(byAdding: .day, value: 1, to: startOfYesterday)!

        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { entry in
                entry.date >= startOfYesterday && entry.date < endOfYesterday
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        guard let entries = try? modelContext.fetch(descriptor),
              let latest = entries.first else {
            return nil
        }

        return JournalSnapshot(
            date: latest.date,
            title: latest.title,
            content: latest.content,
            type: latest.journalType.rawValue,
            tags: latest.tags,
            wordCount: latest.wordCount,
            isFavorite: latest.isFavorite
        )
    }

    // MARK: - Prompt Generation

    func generatePrompt(context: MorningContext) -> (system: String, user: String) {
        let systemPrompt = """
        Sen LifeStyles uygulamasının kişisel yaşam asistanısın. Adın Claude.

        Görevin: Kullanıcıya her sabah kişiselleştirilmiş, motive edici, samimi bir günlük insight vermek.

        Kurallar:
        - Respond in the user's language (Turkish, English, etc.), be friendly
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

        var additionalContext = ""

        // User profile context
        if let profile = context.userProfile, !profile.isEmpty {
            additionalContext += "\n\n👤 Kullanıcı Hakkında:"
            if let name = profile.name {
                additionalContext += "\n- İsim: \(name)"
            }
            if let age = profile.age {
                additionalContext += "\n- Yaş: \(age)"
            }
            if let occupation = profile.occupation {
                additionalContext += "\n- Meslek: \(occupation)"
            }
            if !profile.hobbies.isEmpty {
                additionalContext += "\n- Hobiler: \(profile.hobbies.joined(separator: ", "))"
            }
            if !profile.interests.isEmpty {
                additionalContext += "\n- İlgi Alanları: \(profile.interests.joined(separator: ", "))"
            }
        }

        // Yesterday's journal
        if let yesterday = context.yesterdayJournal {
            additionalContext += "\n\n📝 Dünkü Günlük:"
            if let title = yesterday.title {
                additionalContext += "\n- Başlık: \(title)"
            }
            additionalContext += "\n- Tip: \(yesterday.type)"
            additionalContext += "\n- İçerik: \(yesterday.content)"
        }

        // Today's journal (if already written)
        if let today = context.todayJournal {
            additionalContext += "\n\n📝 Bugünkü Günlük (erken yazılmış):"
            if let title = today.title {
                additionalContext += "\n- Başlık: \(title)"
            }
            additionalContext += "\n- İçerik: \(today.content)"
        }

        return """
        Bugün \(context.date), \(context.dayOfWeek).

        Kullanıcının verilerini analiz et ve sabah mesajı oluştur:

        ```json
        \(jsonString)
        ```
        \(additionalContext)

        Öneriler:
        1. Kullanıcı profili varsa ismiyle hitap et ve hobilerine uygun öneriler ver
        2. Dünkü günlük varsa ona göre bugün için motivasyon/öneri ver
        3. Overdue arkadaşlar varsa öncelikle hatırlat
        4. Mood trend'e göre motivasyon ver
        5. Habit streak'leri kutla veya hatırlat
        6. Goal progress'e göre teşvik et
        7. Lokasyon pattern'e göre aktivite öner (çok evdeyse dışarı çıkma öner)

        Şimdi samimi, motive edici, KİŞİSELLEŞTİRİLMİŞ bir sabah mesajı yaz (max 4 cümle):
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
        // Privacy check - Morning Insight enabled?
        let privacySettings = AIPrivacySettings.shared
        guard privacySettings.hasGivenAIConsent && privacySettings.morningInsightEnabled else {
            throw MorningInsightError.featureDisabled
        }

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

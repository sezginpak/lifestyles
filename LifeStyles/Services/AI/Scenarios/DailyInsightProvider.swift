//
//  DailyInsightProvider.swift
//  LifeStyles
//
//  Daily Insight - Sabah/Öğle/Akşam dinamik insight'lar
//  Created by Claude on 25.10.2025.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Time of Day

enum TimeOfDay: String, Codable {
    case morning   // 06:00-11:59
    case afternoon // 12:00-17:59
    case evening   // 18:00-23:59
    case night     // 00:00-05:59

    static var current: TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return .morning
        case 12..<18: return .afternoon
        case 18..<24: return .evening
        default: return .night
        }
    }

    var displayName: String {
        switch self {
        case .morning: return "Günaydın"
        case .afternoon: return "İyi Öğlenler"
        case .evening: return "İyi Akşamlar"
        case .night: return "İyi Geceler"
        }
    }

    var emoji: String {
        switch self {
        case .morning: return "🌅"
        case .afternoon: return "☀️"
        case .evening: return "🌆"
        case .night: return "🌙"
        }
    }

    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "sunset.fill"
        case .night: return "moon.stars.fill"
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .morning: return [Color(red: 1.0, green: 0.75, blue: 0.4), Color(red: 1.0, green: 0.85, blue: 0.6)]
        case .afternoon: return [Color(red: 1.0, green: 0.8, blue: 0.0), Color(red: 1.0, green: 0.6, blue: 0.0)]
        case .evening: return [Color(red: 0.9, green: 0.4, blue: 0.4), Color(red: 0.6, green: 0.3, blue: 0.7)]
        case .night: return [Color(red: 0.2, green: 0.2, blue: 0.5), Color(red: 0.3, green: 0.3, blue: 0.6)]
        }
    }
}

// MARK: - Daily Context

struct DailyContext: Codable {
    let timeOfDay: String
    let date: String
    let dayOfWeek: String
    let currentHour: Int
    let friends: [FriendSnapshot]
    let overdueFriends: [FriendSnapshot]
    let currentMood: MoodSnapshot?
    let todayMoods: [MoodSnapshot]  // Gün içindeki tüm mood'lar
    let moodTrend: MoodTrend?
    let activeGoals: [GoalSnapshot]
    let todayGoalProgress: Int
    let habits: [HabitSnapshot]
    let todayHabitCompletions: Int
    let locationPattern: LocationPattern
    let userProfile: UserProfileSnapshot?
    let todayJournal: JournalSnapshot?
    let recentActivity: String  // Son ne yaptı?
}

// MARK: - Daily Insight Provider

class DailyInsightProvider: ContextProvider {
    typealias ContextType = DailyContext

    func buildContext(modelContext: ModelContext) async -> DailyContext {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let timeOfDay = TimeOfDay.current

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM yyyy"
        let dateString = formatter.string(from: now)

        formatter.dateFormat = "EEEE"
        let dayOfWeek = formatter.string(from: now)

        // Privacy settings
        let privacySettings = AIPrivacySettings.shared

        // Build contexts
        let friends: [FriendSnapshot] = privacySettings.shareFriendsData
            ? await FriendContextBuilder.buildAll(modelContext: modelContext)
            : []

        let overdue: [FriendSnapshot] = privacySettings.shareFriendsData
            ? await FriendContextBuilder.buildOverdue(modelContext: modelContext)
            : []

        let currentMood: MoodSnapshot? = privacySettings.shareMoodData
            ? await MoodContextBuilder.buildCurrent(modelContext: modelContext)
            : nil

        let todayMoods: [MoodSnapshot] = privacySettings.shareMoodData
            ? await buildTodayMoods(modelContext: modelContext)
            : []

        let trend: MoodTrend? = privacySettings.shareMoodData
            ? await MoodContextBuilder.buildTrend(modelContext: modelContext, days: 7)
            : nil

        let goals: [GoalSnapshot] = privacySettings.shareGoalsAndHabits
            ? await GoalContextBuilder.buildActive(modelContext: modelContext)
            : []

        let todayProgress = privacySettings.shareGoalsAndHabits
            ? await calculateTodayGoalProgress(modelContext: modelContext)
            : 0

        let habits: [HabitSnapshot] = privacySettings.shareGoalsAndHabits
            ? await HabitContextBuilder.buildAll(modelContext: modelContext)
            : []

        let todayHabits = privacySettings.shareGoalsAndHabits
            ? await calculateTodayHabitCompletions(modelContext: modelContext)
            : 0

        let location: LocationPattern = privacySettings.shareLocationData
            ? await LocationContextBuilder.buildPattern(modelContext: modelContext)
            : LocationPattern(hoursAtHomeToday: 0, hoursAtHomeThisWeek: 0, lastOutdoorActivity: nil, mostVisitedPlaces: [], savedPlaces: [])

        let userProfile = await ProfileContextBuilder.build(modelContext: modelContext)

        let todayJournal: JournalSnapshot? = privacySettings.hasGivenAIConsent
            ? await JournalContextBuilder.buildToday(modelContext: modelContext)
            : nil

        let recentActivity = await buildRecentActivity(
            todayMoods: todayMoods,
            todayProgress: todayProgress,
            todayHabits: todayHabits,
            timeOfDay: timeOfDay
        )

        return DailyContext(
            timeOfDay: timeOfDay.rawValue,
            date: dateString,
            dayOfWeek: dayOfWeek,
            currentHour: hour,
            friends: friends,
            overdueFriends: overdue,
            currentMood: currentMood,
            todayMoods: todayMoods,
            moodTrend: trend,
            activeGoals: goals,
            todayGoalProgress: todayProgress,
            habits: habits,
            todayHabitCompletions: todayHabits,
            locationPattern: location,
            userProfile: userProfile,
            todayJournal: todayJournal,
            recentActivity: recentActivity
        )
    }

    // MARK: - Helper Methods

    private func buildTodayMoods(modelContext: ModelContext) async -> [MoodSnapshot] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!

        let descriptor = FetchDescriptor<MoodEntry>(
            predicate: #Predicate { entry in
                entry.date >= startOfToday && entry.date < endOfToday
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )

        guard let entries = try? modelContext.fetch(descriptor) else {
            return []
        }

        return entries.map { MoodSnapshot(from: $0) }
    }

    private func calculateTodayGoalProgress(modelContext: ModelContext) async -> Int {
        // Bugün tamamlanan milestone/goal sayısı
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())

        let descriptor = FetchDescriptor<Goal>(
            predicate: #Predicate { goal in
                goal.progress > 0
            }
        )

        guard let goals = try? modelContext.fetch(descriptor) else {
            return 0
        }

        // Bugün progress yapılan goal sayısı (basitleştirilmiş)
        return goals.filter { $0.progress > 0 }.count
    }

    private func calculateTodayHabitCompletions(modelContext: ModelContext) async -> Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!

        let descriptor = FetchDescriptor<HabitCompletion>(
            predicate: #Predicate { completion in
                completion.completedAt >= startOfToday && completion.completedAt < endOfToday
            }
        )

        guard let completions = try? modelContext.fetch(descriptor) else {
            return 0
        }

        return completions.count
    }

    private func buildRecentActivity(
        todayMoods: [MoodSnapshot],
        todayProgress: Int,
        todayHabits: Int,
        timeOfDay: TimeOfDay
    ) async -> String {
        var activities: [String] = []

        if !todayMoods.isEmpty {
            activities.append("\(todayMoods.count) mood kaydı")
        }

        if todayProgress > 0 {
            activities.append("\(todayProgress) hedefte ilerleme")
        }

        if todayHabits > 0 {
            activities.append("\(todayHabits) alışkanlık tamamlandı")
        }

        if activities.isEmpty {
            return timeOfDay == .morning ? "Yeni gün başlıyor" : "Henüz aktivite yok"
        }

        return activities.joined(separator: ", ")
    }

    // MARK: - Prompt Generation

    func generatePrompt(context: DailyContext) -> (system: String, user: String) {
        let timeOfDay = TimeOfDay(rawValue: context.timeOfDay) ?? .morning
        let systemPrompt = buildSystemPrompt(timeOfDay: timeOfDay)
        let userMessage = buildUserMessage(context: context, timeOfDay: timeOfDay)

        return (systemPrompt, userMessage)
    }

    private func buildSystemPrompt(timeOfDay: TimeOfDay) -> String {
        let basePrompt = """
        Sen LifeStyles uygulamasının kişisel yaşam asistanısın. Adın Claude.

        Kurallar:
        - Türkçe yaz, samimi ve sıcak ol
        - 3-4 cümle ile özetle
        - Emoji kullan (1-2 tane, abartma)
        - Pozitif ve motive edici ol
        - Veriyi yorumla ve anlamlı önerilerde bulun
        """

        let timeSpecific: String
        switch timeOfDay {
        case .morning:
            timeSpecific = """

            SABAH MESAJI:
            - Enerjik ve motive edici başla
            - Günün planı hakkında önerilerde bulun
            - Overdue arkadaşları ve bugünkü habit'leri hatırlat
            - Pozitif bir başlangıç için teşvik et
            """
        case .afternoon:
            timeSpecific = """

            ÖĞLE MESAJI:
            - Şimdiye kadar yapılanları kutla
            - Gün ortasında moral ver
            - Geri kalan gün için reminder ver
            - Dinlenme/mola öner
            """
        case .evening:
            timeSpecific = """

            AKŞAM MESAJI:
            - Günü değerlendir
            - Başarıları kutla
            - Eksikleri nazikçe hatırlat
            - Yarın için küçük hazırlık öner
            - Dinlenme ve self-care öner
            """
        case .night:
            timeSpecific = """

            GECE MESAJI:
            - Sakinleştirici ol
            - Günü pozitif not et
            - Uyku ve dinlenme öner
            - Yarına umutlu bak
            """
        }

        return basePrompt + timeSpecific
    }

    private func buildUserMessage(context: DailyContext, timeOfDay: TimeOfDay) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let jsonData = try? encoder.encode(context),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return "Context encoding error"
        }

        var additionalContext = ""

        // User profile
        if let profile = context.userProfile, !profile.isEmpty {
            additionalContext += "\n\n👤 Kullanıcı:"
            if let name = profile.name {
                additionalContext += "\n- İsim: \(name)"
            }
        }

        // Today's journal
        if let journal = context.todayJournal {
            additionalContext += "\n\n📝 Bugünkü Günlük:"
            if let title = journal.title {
                additionalContext += "\n- Başlık: \(title)"
            }
            additionalContext += "\n- İçerik: \(journal.content.prefix(200))..."
        }

        // Mood progression today
        if !context.todayMoods.isEmpty {
            additionalContext += "\n\n😊 Bugünkü Mood Geçmişi:"
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            timeFormatter.locale = Locale(identifier: "tr_TR")
            for mood in context.todayMoods {
                let time = timeFormatter.string(from: mood.date)
                let emoji = MoodType(rawValue: mood.type)?.emoji ?? "😊"
                additionalContext += "\n- \(time): \(emoji) \(mood.type)"
            }
        }

        let timeSpecificGuidance: String
        switch timeOfDay {
        case .morning:
            timeSpecificGuidance = """

            SABAH PRİORİTELERİ:
            1. Overdue arkadaşları hatırlat
            2. Bugünkü habit'leri öneren
            3. Aktif goal'lar için motivasyon ver
            4. Mood'a göre gün planı öner
            """
        case .afternoon:
            timeSpecificGuidance = """

            ÖĞLE DEĞERLENDİRMESİ:
            1. Sabahtan beri yapılanları kutla
            2. Tamamlanmayan habit'leri hatırlat
            3. Mood değişimi varsa yorumla
            4. Öğleden sonra için 1-2 öneri
            """
        case .evening:
            timeSpecificGuidance = """

            AKŞAM ÖZETİ:
            1. Günün başarılarını vurgula
            2. Eksik kalan şeyleri nazikçe hatırlat
            3. Mood pattern'i yorumla
            4. Yarın için küçük bir öneri
            5. Self-care hatırlat (uyku, dinlenme)
            """
        case .night:
            timeSpecificGuidance = """

            GECE RAHATLAMASI:
            1. Günü pozitif özetle
            2. Erken uyku öner
            3. Stresi azaltıcı aktivite öner
            4. Yarına umutla bak
            """
        }

        return """
        Saat \(context.currentHour):00, \(timeOfDay.displayName)! Bugün \(context.date), \(context.dayOfWeek).

        Kullanıcı verileri:
        ```json
        \(jsonString)
        ```
        \(additionalContext)
        \(timeSpecificGuidance)

        Şimdi samimi, kişiselleştirilmiş ve zaman diline uygun bir insight yaz (max 4 cümle):
        """
    }
}

// MARK: - Daily Insight Service

class DailyInsightService {
    static let shared = DailyInsightService()

    private let provider = DailyInsightProvider()
    private let claude = ClaudeHaikuService.shared

    private init() {}

    /// Generate time-aware insight
    func generateInsight(modelContext: ModelContext) async throws -> String {
        // Privacy check
        let privacySettings = AIPrivacySettings.shared
        guard privacySettings.hasGivenAIConsent && privacySettings.morningInsightEnabled else {
            throw MorningInsightError.featureDisabled
        }

        // Premium & Usage check
        let purchaseManager = PurchaseManager.shared
        let usageManager = AIUsageManager.shared
        let isPremium = purchaseManager.isPremium

        guard usageManager.canGenerateDailyInsight(isPremium: isPremium) else {
            throw MorningInsightError.limitReached
        }

        let timeOfDay = TimeOfDay.current
        print("\(timeOfDay.emoji) Generating \(timeOfDay.rawValue) insight...")

        // Build context
        let context = await provider.buildContext(modelContext: modelContext)

        // Generate prompt
        let (systemPrompt, userMessage) = provider.generatePrompt(context: context)

        // Call Claude
        let insight = try await claude.generate(
            systemPrompt: systemPrompt,
            userMessage: userMessage,
            temperature: 0.8
        )

        // Track usage
        usageManager.trackDailyInsight()

        print("✅ \(timeOfDay.rawValue.capitalized) insight generated!")
        return insight
    }

    /// Get cached insight (if generated in current time period)
    func getCachedInsight() -> (insight: String, timeOfDay: TimeOfDay, date: Date)? {
        guard let insight = UserDefaults.standard.string(forKey: "daily_insight"),
              let timeOfDayRaw = UserDefaults.standard.string(forKey: "daily_insight_time"),
              let timeOfDay = TimeOfDay(rawValue: timeOfDayRaw),
              let timestamp = UserDefaults.standard.object(forKey: "daily_insight_date") as? Date else {
            return nil
        }

        let calendar = Calendar.current
        let currentTimeOfDay = TimeOfDay.current

        // Cache valid ise: Aynı gün VE aynı zaman dilimi
        if calendar.isDateInToday(timestamp) && currentTimeOfDay == timeOfDay {
            return (insight, timeOfDay, timestamp)
        }

        return nil
    }

    /// Cache insight
    func cacheInsight(_ insight: String) {
        let timeOfDay = TimeOfDay.current
        UserDefaults.standard.set(insight, forKey: "daily_insight")
        UserDefaults.standard.set(timeOfDay.rawValue, forKey: "daily_insight_time")
        UserDefaults.standard.set(Date(), forKey: "daily_insight_date")
    }

    /// Clear cache
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: "daily_insight")
        UserDefaults.standard.removeObject(forKey: "daily_insight_time")
        UserDefaults.standard.removeObject(forKey: "daily_insight_date")
    }
}

// MARK: - MoodSnapshot Extension

extension MoodSnapshot {
    init(from entry: MoodEntry) {
        self.init(
            type: entry.moodType.rawValue,
            intensity: entry.intensity,
            date: entry.date,
            note: entry.note
        )
    }
}

//
//  ChatHaikuService.swift
//  LifeStyles
//
//  AI Chat with Claude Haiku - Context-aware & Personalized
//  Created by Claude on 22.10.2025.
//

import Foundation
import SwiftData

// MARK: - Chat Intent

enum ChatIntent {
    case friendsList          // "hangi arkadaşlarım var?"
    case contactAdvice        // "kiminle konuşmalıyım?"
    case general             // Diğer sorular
}

// MARK: - Chat Error

enum ChatError: LocalizedError {
    case aiDisabled

    var errorDescription: String? {
        switch self {
        case .aiDisabled:
            return "AI özellikleri kapalı. Lütfen Ayarlar → AI & Gizlilik'ten aktif edin."
        }
    }
}

// MARK: - Chat Context

struct ChatContext: Codable {
    // Friend bilgisi (specific friend chat için)
    let friend: FriendSnapshot?

    // TÜM arkadaşlar (genel chat için - sadece friendsList intent'inde)
    let allFriends: [FriendSnapshot]?

    // Overdue arkadaşlar (contactAdvice intent'inde)
    let overdueFriends: [FriendSnapshot]?

    // Chat modu
    let isGeneralMode: Bool

    // Son iletişim bilgisi
    let lastContactDays: Int?
    let totalContacts: Int?

    // Shared memories/notes
    let notes: String?
    let sharedInterests: String?

    // Life data (goals, habits, mood, location)
    let activeGoals: [GoalSnapshot]?
    let habits: [HabitSnapshot]?
    let currentMood: MoodSnapshot?
    let moodTrend: MoodTrend?
    let locationPattern: LocationPattern?

    // Journal entries
    let recentJournals: [JournalSnapshot]?
    let todayJournal: JournalSnapshot?

    // User profile
    let userProfile: UserProfileSnapshot?
}

// MARK: - Chat Haiku Service

class ChatHaikuService {
    static let shared = ChatHaikuService()

    // ✅ YENI: Abstraction layer - Backend migration için hazır
    // Gelecekte AIServiceType.current = .backend yapınca otomatik backend kullanacak
    private let aiService: AIServiceProtocol = AIServiceFactory.shared.getService()

    private init() {}

    // MARK: - Intent Detection

    private func detectIntent(question: String) -> ChatIntent {
        let lowercased = question.lowercased()

        // Friends list keywords
        let friendsListKeywords = [
            "hangi arkadaş", "arkadaşlarım", "arkadaş listesi",
            "kaç arkadaş", "kimler var", "kime eriş"
        ]
        if friendsListKeywords.contains(where: { lowercased.contains($0) }) {
            return .friendsList
        }

        // Contact advice keywords
        let contactAdviceKeywords = [
            "kiminle konuş", "kime mesaj", "kimi ara",
            "kimle iletişim", "unuttuğum", "konuşmam gereken"
        ]
        if contactAdviceKeywords.contains(where: { lowercased.contains($0) }) {
            return .contactAdvice
        }

        return .general
    }

    // MARK: - Main Chat Method

    /// Generate AI chat response with friend context
    func chat(
        friend: Friend?,
        question: String,
        chatHistory: [ChatMessage] = [],
        modelContext: ModelContext
    ) async throws -> String {

        // Privacy check - AI Chat enabled?
        let privacySettings = AIPrivacySettings.shared
        guard privacySettings.hasGivenAIConsent && privacySettings.aiChatEnabled else {
            throw ChatError.aiDisabled
        }

        // Detect intent (only for general mode)
        let intent: ChatIntent = friend == nil ? detectIntent(question: question) : .general

        // Build context with smart loading based on intent
        let context = await buildChatContext(
            friend: friend,
            intent: intent,
            modelContext: modelContext
        )

        // Track data usage for transparency
        trackDataUsage(context: context)

        // Generate prompts
        let (systemPrompt, userMessage) = await generateChatPrompt(
            context: context,
            question: question,
            chatHistory: chatHistory,
            modelContext: modelContext
        )

        // Call AI Service (abstraction layer - backend ready)
        let response = try await aiService.generate(
            systemPrompt: systemPrompt,
            userMessage: userMessage,
            temperature: 0.9,  // More creative for chat
            maxTokens: 1024
        )

        // YENI: Knowledge extraction (async, arka planda)
        Task.detached {
            await self.extractKnowledgeFromConversation(
                userMessage: question,
                aiResponse: response,
                chatHistory: chatHistory,
                modelContext: modelContext
            )
        }

        return response
    }

    // MARK: - Knowledge Extraction (NEW)

    /// Konuşmadan bilgi çıkar ve kaydet - Artık hem user hem entity knowledge
    private func extractKnowledgeFromConversation(
        userMessage: String,
        aiResponse: String,
        chatHistory: [ChatMessage],
        modelContext: ModelContext
    ) async {
        // Privacy check
        guard KnowledgePrivacyManager.shared.isLearningEnabled else {
            return
        }

        // Tüm user mesajlarını topla (son 10 mesaj - token limiti için)
        var allUserMessages: [ChatMessage] = []

        // Geçmiş konuşmalardan sadece user mesajları
        let recentHistory = chatHistory.suffix(10).filter { $0.isUser }
        allUserMessages.append(contentsOf: recentHistory)

        // Şimdiki mesaj
        allUserMessages.append(
            ChatMessage(id: UUID(), content: userMessage, isUser: true, timestamp: Date())
        )

        // 🚀 YENI: Tüm arkadaşları al (entity tanıma için)
        let availableFriends = (try? modelContext.fetch(FetchDescriptor<Friend>())) ?? []

        let extractor = KnowledgeExtractor.shared
        let _ = await extractor.extractKnowledge(
            from: allUserMessages,
            context: modelContext,
            conversationId: nil,
            availableFriends: availableFriends
        )
    }

    // MARK: - Data Usage Tracking

    private func trackDataUsage(context: ChatContext) {
        let friendsCount = (context.allFriends?.count ?? 0) + (context.overdueFriends?.count ?? 0) + (context.friend != nil ? 1 : 0)
        let goalsCount = context.activeGoals?.count ?? 0
        let habitsCount = context.habits?.count ?? 0
        let hasMood = context.currentMood != nil || context.moodTrend != nil
        let hasLocation = context.locationPattern != nil

        let dataCount = DataUsageCount(
            friendsCount: friendsCount,
            goalsCount: goalsCount,
            habitsCount: habitsCount,
            hasMoodData: hasMood,
            hasLocationData: hasLocation,
            timestamp: Date()
        )

        AIPrivacySettings.shared.lastRequestDataCount = dataCount
    }

    // MARK: - Context Building

    private func buildChatContext(
        friend: Friend?,
        intent: ChatIntent,
        modelContext: ModelContext
    ) async -> ChatContext {
        // Privacy settings
        let privacySettings = AIPrivacySettings.shared

        // Load life data based on privacy settings (for all chat modes)
        let goals: [GoalSnapshot]? = privacySettings.shareGoalsAndHabits
            ? await GoalContextBuilder.buildActive(modelContext: modelContext)
            : nil

        let habits: [HabitSnapshot]? = privacySettings.shareGoalsAndHabits
            ? await HabitContextBuilder.buildAll(modelContext: modelContext)
            : nil

        let mood: MoodSnapshot? = privacySettings.shareMoodData
            ? await MoodContextBuilder.buildCurrent(modelContext: modelContext)
            : nil

        let trend: MoodTrend? = privacySettings.shareMoodData
            ? await MoodContextBuilder.buildTrend(modelContext: modelContext, days: 7)
            : nil

        let location: LocationPattern? = privacySettings.shareLocationData
            ? await LocationContextBuilder.buildPattern(modelContext: modelContext)
            : nil

        // Load journal entries (privacy-aware - currently no specific privacy setting, uses general AI consent)
        let recentJournals: [JournalSnapshot]? = privacySettings.hasGivenAIConsent
            ? await JournalContextBuilder.buildRecent(modelContext: modelContext, days: 7)
            : nil

        let todayJournal: JournalSnapshot? = privacySettings.hasGivenAIConsent
            ? await JournalContextBuilder.buildToday(modelContext: modelContext)
            : nil

        // Always load user profile (no privacy toggle - it's user's own data)
        let userProfile = await ProfileContextBuilder.build(modelContext: modelContext)

        // Friend yoksa genel mod - intent'e göre arkadaş bilgisi yükle
        guard let friend = friend else {
            // Smart Context Loading based on intent AND privacy settings
            var allFriends: [FriendSnapshot]? = nil
            var overdueFriends: [FriendSnapshot]? = nil

            // Only load if user consented to share friends data
            if privacySettings.shareFriendsData {
                switch intent {
                case .friendsList:
                    // Kullanıcı arkadaş listesini soruyor - TÜM arkadaşları yükle
                    allFriends = await FriendContextBuilder.buildAll(modelContext: modelContext)

                case .contactAdvice:
                    // Kullanıcı kiminle konuşmalı diye soruyor - SADECE overdue arkadaşları yükle
                    overdueFriends = await FriendContextBuilder.buildOverdue(modelContext: modelContext)

                case .general:
                    // Genel soru - arkadaş bilgisi YÜKLEME (token tasarrufu)
                    break
                }
            }

            return ChatContext(
                friend: nil,
                allFriends: allFriends,
                overdueFriends: overdueFriends,
                isGeneralMode: true,
                lastContactDays: nil,
                totalContacts: nil,
                notes: nil,
                sharedInterests: nil,
                activeGoals: goals,
                habits: habits,
                currentMood: mood,
                moodTrend: trend,
                locationPattern: location,
                recentJournals: recentJournals,
                todayJournal: todayJournal,
                userProfile: userProfile
            )
        }

        // Friend snapshot oluştur
        let friendSnapshot = FriendSnapshot(
            name: friend.name,
            relationshipType: friend.relationshipType.rawValue,
            daysSinceLastContact: daysSince(friend.lastContactDate),
            isOverdue: friend.needsContact,
            communicationFrequency: friend.frequency.rawValue,
            notes: friend.notes,
            sharedInterests: friend.sharedInterests,
            isImportant: friend.isImportant
        )

        // İletişim geçmişi sayısı
        let totalContacts = friend.contactHistory?.count ?? 0

        return ChatContext(
            friend: friendSnapshot,
            allFriends: nil,  // Friend specific chat'te buna gerek yok
            overdueFriends: nil,
            isGeneralMode: false,
            lastContactDays: friendSnapshot.daysSinceLastContact,
            totalContacts: totalContacts,
            notes: friend.notes,
            sharedInterests: friend.sharedInterests,
            activeGoals: goals,
            habits: habits,
            currentMood: mood,
            moodTrend: trend,
            locationPattern: location,
            recentJournals: recentJournals,
            todayJournal: todayJournal,
            userProfile: userProfile
        )
    }

    private func daysSince(_ date: Date?) -> Int {
        guard let date = date else { return 999 }
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 999
        return max(0, days)
    }

    // MARK: - Prompt Generation

    private func generateChatPrompt(
        context: ChatContext,
        question: String,
        chatHistory: [ChatMessage],
        modelContext: ModelContext
    ) async -> (system: String, user: String) {

        let systemPrompt: String

        if context.isGeneralMode {
            // Genel mod - kişisel asistan (Smart Context)
            var contextInfo = ""

            // Smart Context: Intent'e göre farklı bilgi
            if let allFriends = context.allFriends, !allFriends.isEmpty {
                // friendsList intent - TÜM arkadaşlar
                contextInfo += "\n\n📱 Arkadaşlar (\(allFriends.count) kişi):\n"
                for friend in allFriends.prefix(10) { // İlk 10 arkadaş
                    contextInfo += "• \(friend.name) (\(friend.relationshipType))"
                    if friend.isOverdue {
                        contextInfo += " - ⚠️ \(friend.daysSinceLastContact) gündür iletişim yok"
                    }
                    contextInfo += "\n"
                }
                if allFriends.count > 10 {
                    contextInfo += "...ve \(allFriends.count - 10) kişi daha\n"
                }
            } else if let overdueFriends = context.overdueFriends, !overdueFriends.isEmpty {
                // contactAdvice intent - SADECE overdue arkadaşlar
                contextInfo += "\n\n⚠️ İletişim kurulması gereken arkadaşlar (\(overdueFriends.count) kişi):\n"
                for friend in overdueFriends.prefix(10) {
                    contextInfo += "• \(friend.name) (\(friend.relationshipType)) - \(friend.daysSinceLastContact) gündür iletişim yok\n"
                }
                if overdueFriends.count > 10 {
                    contextInfo += "...ve \(overdueFriends.count - 10) kişi daha\n"
                }
            }

            // Goals
            if let goals = context.activeGoals, !goals.isEmpty {
                contextInfo += "\n\n🎯 Aktif Hedefler (\(goals.count)):\n"
                for goal in goals.prefix(5) {
                    let progressPercent = Int(goal.progress * 100)
                    contextInfo += "• \(goal.title) - %\(progressPercent)"
                    if goal.isOverdue {
                        contextInfo += " ⚠️ Süre geçti"
                    }
                    contextInfo += "\n"
                }
            }

            // Habits
            if let habits = context.habits, !habits.isEmpty {
                contextInfo += "\n\n✓ Alışkanlıklar (\(habits.count)):\n"
                for habit in habits.prefix(5) {
                    contextInfo += "• \(habit.name) - Streak: \(habit.currentStreak)"
                    let rate = Int(habit.weeklyCompletionRate * 100)
                    contextInfo += " (%\(rate) haftalık)\n"
                }
            }

            // Mood
            if let mood = context.currentMood {
                contextInfo += "\n\n😊 Ruh Hali: \(mood.type) (\(mood.intensity)/5)"
                if let note = mood.note {
                    contextInfo += " - \(note)"
                }
                contextInfo += "\n"
            }

            if let trend = context.moodTrend {
                contextInfo += "   7 günlük ortalama: \(String(format: "%.1f", trend.averageIntensity))/5\n"
            }

            // Location
            if let location = context.locationPattern {
                contextInfo += "\n\n📍 Konum: Bugün \(String(format: "%.1f", location.hoursAtHomeToday)) saat evde"
                if let lastOut = location.lastOutdoorActivity {
                    let days = Calendar.current.dateComponents([.day], from: lastOut, to: Date()).day ?? 0
                    if days == 0 {
                        contextInfo += ", Bugün dışarı çıktı"
                    } else if days > 0 {
                        contextInfo += ", \(days) gündür dışarı çıkmadı"
                    }
                }
                contextInfo += "\n"

                // Saved places
                if !location.savedPlaces.isEmpty {
                    contextInfo += "\n🏠 Kayıtlı Yerler:\n"
                    for place in location.savedPlaces {
                        contextInfo += "   \(place.emoji) \(place.name) (\(place.category))"
                        if place.visitCount > 0 {
                            contextInfo += " - \(place.visitCount) ziyaret"
                        }
                        if let notes = place.notes, !notes.isEmpty {
                            contextInfo += " - Not: \(notes)"
                        }
                        contextInfo += "\n"
                    }
                }
            }

            // Journal context
            if let todayJournal = context.todayJournal {
                contextInfo += "\n\n📝 Bugünkü Günlük: \(todayJournal.type)"
                if let title = todayJournal.title {
                    contextInfo += " - \(title)"
                }
                contextInfo += "\n\(todayJournal.content)\n"
            }

            if let recentJournals = context.recentJournals, !recentJournals.isEmpty {
                contextInfo += "\n\n📖 Son Günlük Kayıtları (\(recentJournals.count) adet):\n"
                for (index, journal) in recentJournals.prefix(5).enumerated() {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.timeStyle = .none
                    formatter.locale = Locale(identifier: "tr_TR")
                    let dateStr = formatter.string(from: journal.date)

                    contextInfo += "• \(dateStr)"
                    if let title = journal.title {
                        contextInfo += " - \(title)"
                    }
                    contextInfo += " (\(journal.type))"
                    if journal.isFavorite {
                        contextInfo += " ⭐️"
                    }
                    contextInfo += "\n"
                }
                if recentJournals.count > 5 {
                    contextInfo += "...ve \(recentJournals.count - 5) kayıt daha\n"
                }
            }

            // User profile context
            var profileInfo = ""
            if let profile = context.userProfile, !profile.isEmpty {
                profileInfo += "\n\n👤 Kullanıcı Profili:"
                if let name = profile.name {
                    profileInfo += "\n- İsim: \(name)"
                }
                if let age = profile.age {
                    profileInfo += "\n- Yaş: \(age)"
                }
                if let occupation = profile.occupation {
                    profileInfo += "\n- Meslek: \(occupation)"
                }
                if !profile.hobbies.isEmpty {
                    profileInfo += "\n- Hobiler: \(profile.hobbies.joined(separator: ", "))"
                }
                if !profile.interests.isEmpty {
                    profileInfo += "\n- İlgi Alanları: \(profile.interests.joined(separator: ", "))"
                }
                if let bio = profile.bio {
                    profileInfo += "\n- Bio: \(bio)"
                }
            }

            // 🧠 YENI: AI Learned Knowledge Context (VECTOR SEARCH)
            // AI'ın önceki konuşmalardan öğrendiği bilgileri yükle
            if let allKnowledge = try? modelContext.fetch(
                FetchDescriptor<UserKnowledge>(
                    predicate: #Predicate { $0.isActive == true },
                    sortBy: [SortDescriptor(\.confidence, order: .reverse)]
                )
            ) {
                // 🚀 HYBRID SEARCH: Semantic + Keyword + Quality + Recency
                let relevantFacts = await SmartContextBuilder.shared.findRelevantFactsAsync(
                    question,
                    in: allKnowledge,
                    modelContext: modelContext
                )

                if !relevantFacts.isEmpty {
                    // Format facts for context
                    var knowledgeText = ""

                    // Group by category
                    let grouped = Dictionary(grouping: relevantFacts) { $0.categoryEnum }

                    for (category, facts) in grouped.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
                        knowledgeText += "\n\n\(category.localizedName):"
                        for fact in facts.prefix(5) { // Max 5 per category
                            knowledgeText += "\n• \(fact.key): \(fact.value)"
                        }
                    }

                    contextInfo += "\n\n🧠 ÖĞRENİLMİŞ BİLGİLER (Önceki konuşmalardan):\(knowledgeText)"
                }
            }

            systemPrompt = """
            Sen LifeStyles uygulamasının kişisel yaşam asistanısın. Adın Claude.

            Görevin: Kullanıcıya arkadaşlıkları, hedefleri, alışkanlıkları ve yaşam kalitesi hakkında yardımcı olmak.
            \(profileInfo)
            \(contextInfo)
            Kurallar:
            - ALWAYS respond in the SAME LANGUAGE as the user's message (Turkish, English, etc.)
            - Samimi ve doğal ol / Be friendly and natural
            - Kısa ve öz cevaplar ver (2-3 cümle ideal) / Keep answers concise (2-3 sentences ideal)
            - Emoji kullan (abartma, 1-2 emoji yeterli) / Use emojis moderately (1-2 emojis)
            - Yapıcı ve motive edici ol / Be constructive and motivating
            - Kullanıcının adını, yaşını, mesleğini kullanarak kişisel ol / Personalize with user's name, age, occupation
            - Hobiler ve ilgi alanlarına özel önerilerde bulun / Make suggestions based on hobbies and interests
            - Context bilgilerini kullanarak kişiselleştirilmiş önerilerde bulun / Use context for personalized recommendations
            - Önceki konuşmalardan öğrendiğin bilgileri (🧠 işaretli) mutlaka dikkate al / Consider learned knowledge (🧠 marked)
            - Hedef/alışkanlık/mood verilerini analiz ederek tavsiye ver / Analyze goals/habits/mood data for advice
            - Gerekirse soru sor, daha fazla detay iste / Ask questions when needed

            Tarzın: Arkadaş canlısı, destekleyici, anlayışlı, motive edici / Friendly, supportive, understanding, motivating
            """
        } else {
            // Friend modu - kişiselleştirilmiş asistan
            let friendName = context.friend?.name ?? "arkadaşın"
            let relationship = context.friend?.relationshipType ?? "friend"

            var contextInfo = ""

            if let lastContactDays = context.lastContactDays {
                if lastContactDays == 0 {
                    contextInfo += "\n- Bugün \(friendName) ile iletişim kurdunuz"
                } else if lastContactDays == 1 {
                    contextInfo += "\n- Dün \(friendName) ile iletişim kurdunuz"
                } else if lastContactDays < 7 {
                    contextInfo += "\n- \(lastContactDays) gün önce \(friendName) ile iletişim kurdunuz"
                } else {
                    contextInfo += "\n- \(lastContactDays) gündür \(friendName) ile iletişim kurmadınız"
                }
            }

            if let notes = context.notes, !notes.isEmpty {
                contextInfo += "\n- Notlarınız: \(notes)"
            }

            if let interests = context.sharedInterests, !interests.isEmpty {
                contextInfo += "\n- Ortak ilgi alanları: \(interests)"
            }

            // User's life context (if available)
            var lifeContext = ""

            if let goals = context.activeGoals, !goals.isEmpty {
                lifeContext += "\n\nKullanıcının hedefleri: "
                lifeContext += goals.prefix(3).map { $0.title }.joined(separator: ", ")
            }

            if let mood = context.currentMood {
                lifeContext += "\nMevcut ruh hali: \(mood.type) (\(mood.intensity)/5)"
            }

            // User profile
            var userInfo = ""
            if let profile = context.userProfile {
                if let name = profile.name {
                    userInfo += "\nKullanıcının adı: \(name)"
                }
                if let age = profile.age {
                    userInfo += ", \(age) yaşında"
                }
                if !profile.interests.isEmpty {
                    userInfo += "\nİlgi alanları: \(profile.interests.joined(separator: ", "))"
                }
            }

            // 🧠 YENI: AI Learned Knowledge Context (Friend mode için de - VECTOR SEARCH)
            // AI'ın önceki konuşmalardan öğrendiği bilgileri yükle
            var knowledgeContext = ""
            if let allKnowledge = try? modelContext.fetch(
                FetchDescriptor<UserKnowledge>(
                    predicate: #Predicate { $0.isActive == true },
                    sortBy: [SortDescriptor(\.confidence, order: .reverse)]
                )
            ) {
                // 🚀 HYBRID SEARCH: Semantic + Keyword + Quality + Recency
                let relevantFacts = await SmartContextBuilder.shared.findRelevantFactsAsync(
                    question,
                    in: allKnowledge,
                    modelContext: modelContext
                )

                if !relevantFacts.isEmpty {
                    // Format facts for context
                    var knowledgeText = ""

                    // Group by category
                    let grouped = Dictionary(grouping: relevantFacts) { $0.categoryEnum }

                    for (category, facts) in grouped.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
                        knowledgeText += "\n\n\(category.localizedName):"
                        for fact in facts.prefix(5) { // Max 5 per category
                            knowledgeText += "\n• \(fact.key): \(fact.value)"
                        }
                    }

                    knowledgeContext = "\n\n🧠 Kullanıcı hakkında öğrendiğim bilgiler:\(knowledgeText)"
                }
            }

            systemPrompt = """
            Sen LifeStyles uygulamasının kişisel asistanısın. Adın Claude.

            Şu anda kullanıcı \(friendName) hakkında konuşuyor.
            İlişki türü: \(relationship)
            \(userInfo)
            \(contextInfo)
            \(lifeContext)
            \(knowledgeContext)

            Görevin: Kullanıcıya \(friendName) ile ilişkisini güçlendirmede yardımcı olmak.

            Kurallar:
            - ALWAYS respond in the SAME LANGUAGE as the user's message (Turkish, English, etc.)
            - Samimi ve doğal ol / Be friendly and natural
            - Kısa ve öz cevaplar ver (2-3 cümle) / Keep answers concise (2-3 sentences)
            - Emoji kullan (1-2 emoji yeterli) / Use emojis moderately (1-2 emojis)
            - Yapıcı öneriler sun / Provide constructive suggestions
            - Kullanıcının context bilgisini kullan ama tekrar etme / Use context but don't repeat it
            - Öğrendiğin bilgileri (🧠 işaretli) kullanarak kişiselleştirilmiş öneriler yap / Use learned knowledge (🧠) for personalized suggestions
            - İlişkiyi güçlendirici fikirler ver / Give relationship-strengthening ideas
            - Kullanıcının ruh hali ve hedeflerini dikkate al / Consider user's mood and goals

            Konuşabileceğin konular / Topics you can discuss:
            - Mesaj önerileri / Message suggestions ("\(friendName)'a ne mesaj atsam?" / "What should I message \(friendName)?")
            - İletişim fikirleri / Communication ideas ("Ne yapabilirim?" / "What can I do?")
            - Aktivite önerileri / Activity suggestions ("Nereye gidelim?" / "Where should we go?")
            - İlişki tavsiyeleri / Relationship advice

            Tarzın: Empatik, destekleyici, yaratıcı / Empathetic, supportive, creative
            """
        }

        // User message with chat history
        var userMessage = ""

        // Chat history varsa ekle (son 6 mesaj)
        if !chatHistory.isEmpty {
            userMessage += "Önceki konuşma:\n"
            for message in chatHistory.suffix(6) {
                let role = message.isUser ? "Kullanıcı" : "Claude"
                userMessage += "\(role): \(message.content)\n"
            }
            userMessage += "\n"
        }

        // Yeni soru
        userMessage += "Kullanıcının yeni sorusu:\n\(question)"

        return (systemPrompt, userMessage)
    }
}

//
//  QuickQuestionGenerator.swift
//  LifeStyles
//
//  Created by Claude on 2025-01-05.
//  AI ile dinamik hızlı sorular üretimi
//

import Foundation
import SwiftData

/// AI kullanarak dinamik hızlı sorular üreten servis
@Observable
class QuickQuestionGenerator {
    static let shared = QuickQuestionGenerator()

    private let aiService: AIServiceProtocol = AIServiceFactory.shared.getService()
    private let smartContext = SmartContextBuilder.shared

    private init() {}

    // MARK: - Main Generation Method

    /// AI ile dinamik hızlı sorular üret
    func generateQuestions(
        for category: QuickQuestionCategory,
        friend: Friend? = nil,
        chatHistory: [ChatMessage] = [],
        modelContext: ModelContext
    ) async throws -> [QuickQuestion] {

        // Privacy check
        guard AIPrivacySettings.shared.hasGivenAIConsent && AIPrivacySettings.shared.aiChatEnabled else {
            // Fallback to rule-based questions
            return QuickQuestion.defaultQuestions(for: category)
        }

        // Build context
        let context = await buildQuestionContext(
            category: category,
            friend: friend,
            chatHistory: chatHistory,
            modelContext: modelContext
        )

        // Generate system prompt
        let systemPrompt = generateSystemPrompt(category: category, friend: friend)

        // Generate user message
        let userMessage = generateUserMessage(category: category, context: context)

        // Call AI
        do {
            let response = try await aiService.generate(
                systemPrompt: systemPrompt,
                userMessage: userMessage,
                temperature: 0.8, // Yaratıcı ama tutarlı
                maxTokens: 800
            )

            // Parse JSON response
            let questions = try parseAIResponse(response, category: category, friend: friend)

            // Başarılı AI üretimi
            print("✅ AI ile \(questions.count) hızlı soru üretildi")
            return questions

        } catch {
            print("⚠️ AI hızlı soru üretimi başarısız: \(error.localizedDescription)")
            // Fallback to rule-based
            return QuickQuestion.defaultQuestions(for: category)
        }
    }

    // MARK: - Context Building

    /// Hızlı sorular için özelleştirilmiş context oluştur
    private func buildQuestionContext(
        category: QuickQuestionCategory,
        friend: Friend?,
        chatHistory: [ChatMessage],
        modelContext: ModelContext
    ) async -> QuestionContext {

        var context = QuestionContext()

        // Privacy settings
        let privacySettings = AIPrivacySettings.shared

        // 1. Friend bilgisi (eğer varsa)
        if let friend = friend {
            let calendar = Calendar.current
            let lastContact = friend.lastContactDate ?? Date()
            let daysSince = calendar.dateComponents([.day], from: lastContact, to: Date()).day ?? 0

            context.friend = FriendSnapshot(
                name: friend.name,
                relationshipType: friend.relationshipType.rawValue,
                daysSinceLastContact: daysSince,
                isOverdue: daysSince > friend.frequency.days,
                communicationFrequency: "\(friend.frequency.days) days",
                notes: friend.notes,
                sharedInterests: friend.sharedInterests,
                isImportant: friend.isImportant
            )
        }

        // 2. Son sohbet konuları (son 3 mesaj)
        if !chatHistory.isEmpty {
            let recent = chatHistory.suffix(3).map { message in
                RecentChatSnapshot(
                    role: message.isUser ? "user" : "assistant",
                    content: String(message.content.prefix(100)), // İlk 100 karakter
                    timestamp: message.timestamp
                )
            }
            context.recentChats = Array(recent)
        }

        // 3. Overdue arkadaşlar (genel mod için)
        if friend == nil && privacySettings.shareFriendsData {
            context.overdueFriends = await FriendContextBuilder.buildOverdue(modelContext: modelContext)
        }

        // 4. Aktif hedefler
        if privacySettings.shareGoalsAndHabits {
            context.activeGoals = await GoalContextBuilder.buildActive(modelContext: modelContext)
        }

        // 5. Mood trend
        if privacySettings.shareMoodData {
            context.moodTrend = await MoodContextBuilder.buildTrend(modelContext: modelContext)
        }

        // 6. Konum pattern (sadece gerekiyorsa)
        if category == .locationBased && privacySettings.shareLocationData {
            context.locationPattern = await LocationContextBuilder.buildPattern(modelContext: modelContext)
        }

        // 7. Bugünkü journal
        if privacySettings.shareMoodData { // Journal için ayrı bir setting yok, mood ile paylaşılıyor
            context.todayJournal = await JournalContextBuilder.buildToday(modelContext: modelContext)
        }

        // 8. Time of day
        context.timeOfDay = QuickQuestionTrigger.TimeOfDay.current

        return context
    }

    // MARK: - Prompt Generation

    private func generateSystemPrompt(category: QuickQuestionCategory, friend: Friend?) -> String {
        let mode = friend != nil ? "arkadaş özel" : "genel"

        return """
        Sen bir yaşam koçu asistanısın. Kullanıcıya hızlı, akıllı ve ilgili sorular öner.

        Görevin: \(category.displayName) kategorisi için \(mode) modda 4-6 hızlı soru üret.

        KURALLAR:
        1. Sorular kısa, net ve eyleme dönük olmalı (max 40 karakter)
        2. Her soru kullanıcının mevcut durumuna göre kişiselleştirilmiş olmalı
        3. Tekrar eden sorular olmamalı
        4. Soruların prompt kısmı daha detaylı olmalı (AI'ya gönderilecek)
        5. İkonlar SF Symbols kütüphanesinden seç
        6. Gradient renkleri hex formatında ver (başlangıç ve bitiş)

        ÇIKTI FORMATI (JSON):
        {
          "questions": [
            {
              "question": "Kısa soru metni",
              "prompt": "AI'ya gönderilecek detaylı prompt",
              "icon": "sf_symbol_name",
              "gradientStart": "HEX_RENK",
              "gradientEnd": "HEX_RENK",
              "priority": 1-10
            }
          ]
        }

        ÖRNEK İKONLAR:
        - message.fill, heart.fill, calendar.badge.clock, lightbulb.fill
        - sparkles, target, chart.bar.fill, map.fill
        - person.3.fill, gift.fill, exclamationmark.bubble.fill

        ÖRNEK RENKLER:
        - Mavi-Cyan: 4A90E2 → 50C9CE
        - Turuncu-Sarı: FF9F43 → FFC837
        - Mor-Pembe: A55EEA → F78FB3
        - Kırmızı-Turuncu: FF6B6B → FF9F43
        - Yeşil-Mint: 26DE81 → 20D9B3
        """
    }

    private func generateUserMessage(category: QuickQuestionCategory, context: QuestionContext) -> String {
        var message = "Kategori: \(category.displayName)\n\n"

        // Zaman bilgisi
        message += "Zaman: \(context.timeOfDay?.rawValue.capitalized ?? "unknown")\n\n"

        // Friend context
        if let friend = context.friend {
            message += "ARKADAŞ BİLGİSİ:\n"
            message += "- İsim: \(friend.name)\n"
            message += "- İlişki: \(friend.relationshipType.capitalized)\n"
            message += "- Son iletişim: \(friend.daysSinceLastContact) gün önce\n"

            if friend.isOverdue {
                message += "- DURUM: İletişim gerekli! ⚠️\n"
            }

            if let sharedInterests = friend.sharedInterests, !sharedInterests.isEmpty {
                message += "- Ortak ilgi: \(sharedInterests)\n"
            }

            message += "\n"
        }

        // Recent chat topics
        if let recentChats = context.recentChats, !recentChats.isEmpty {
            message += "SON SOHBET KONULARI:\n"
            for chat in recentChats {
                let preview = String(chat.content.prefix(60))
                message += "- \(chat.role == "user" ? "👤" : "🤖"): \(preview)...\n"
            }
            message += "\n"
        }

        // Overdue friends
        if let overdue = context.overdueFriends, !overdue.isEmpty {
            message += "İLETİŞİM GEREKLİ ARKADAŞLAR: \(overdue.count) kişi\n"
            let topFriends = overdue.prefix(3).map { $0.name }.joined(separator: ", ")
            message += "Öncelikli: \(topFriends)\n\n"
        }

        // Active goals
        if let goals = context.activeGoals, !goals.isEmpty {
            message += "AKTİF HEDEFLER:\n"
            for goal in goals.prefix(3) {
                message += "- \(goal.title) (\(Int(goal.progress * 100))% tamamlandı)\n"
            }
            message += "\n"
        }

        // Mood trend
        if let mood = context.moodTrend {
            message += "RUH HALİ TRENDİ:\n"
            message += "- Ortalama: \(String(format: "%.1f", mood.averageIntensity))/5\n"
            message += "- Baskın ruh hali: \(mood.dominantMood)\n"
            message += "- Trend: \(mood.moodVariance)\n\n"
        }

        // Today's journal
        if let journal = context.todayJournal {
            message += "BUGÜNKÜ GÜNLÜK:\n"
            message += "- Başlık: \(journal.title)\n\n"
        }

        message += "Yukarıdaki bilgilere göre kullanıcıya yararlı ve ilgili hızlı sorular üret."

        return message
    }

    // MARK: - Response Parsing

    private func parseAIResponse(
        _ response: String,
        category: QuickQuestionCategory,
        friend: Friend?
    ) throws -> [QuickQuestion] {

        // JSON parse et
        guard let jsonData = extractJSON(from: response)?.data(using: .utf8) else {
            throw NSError(domain: "QuickQuestionGenerator", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "JSON parse edilemedi"
            ])
        }

        struct AIResponse: Codable {
            struct QuestionData: Codable {
                let question: String
                let prompt: String
                let icon: String
                let gradientStart: String
                let gradientEnd: String
                let priority: Int?
            }
            let questions: [QuestionData]
        }

        let decoder = JSONDecoder()
        let aiResponse = try decoder.decode(AIResponse.self, from: jsonData)

        // QuickQuestion objelerine dönüştür
        let questions = aiResponse.questions.enumerated().map { index, data in
            QuickQuestion(
                question: data.question,
                icon: data.icon,
                gradientStartHex: data.gradientStart,
                gradientEndHex: data.gradientEnd,
                category: category,
                prompt: data.prompt,
                priority: data.priority ?? (10 - index), // Varsayılan priority
                expiresAt: Date().addingTimeInterval(3600), // 1 saat
                requiresFriend: friend != nil,
                generatedByAI: true
            )
        }

        return questions
    }

    /// Response'tan JSON bloğunu çıkar (eğer markdown ile sarılmışsa)
    private func extractJSON(from text: String) -> String? {
        // ```json ... ``` formatını tespit et
        if let range = text.range(of: "```json\\s*\\n([\\s\\S]*?)\\n```", options: .regularExpression) {
            let jsonBlock = String(text[range])
            return jsonBlock
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Direkt JSON'sa
        if text.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("{") {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return nil
    }
}

// MARK: - Supporting Structs

/// Hızlı soru üretimi için context
private struct QuestionContext {
    var friend: FriendSnapshot?
    var recentChats: [RecentChatSnapshot]?
    var overdueFriends: [FriendSnapshot]?
    var activeGoals: [GoalSnapshot]?
    var moodTrend: MoodTrend?
    var locationPattern: LocationPattern?
    var todayJournal: JournalSnapshot?
    var timeOfDay: QuickQuestionTrigger.TimeOfDay?
}

/// Son sohbet snapshot
private struct RecentChatSnapshot {
    let role: String
    let content: String
    let timestamp: Date
}

// MARK: - Batch Generation

extension QuickQuestionGenerator {
    /// Birden fazla kategori için sorular üret (paralel)
    func generateMultipleCategories(
        categories: [QuickQuestionCategory],
        friend: Friend? = nil,
        chatHistory: [ChatMessage] = [],
        modelContext: ModelContext
    ) async -> [QuickQuestion] {

        var allQuestions: [QuickQuestion] = []

        // Paralel üretim
        await withTaskGroup(of: [QuickQuestion].self) { group in
            for category in categories {
                group.addTask {
                    do {
                        return try await self.generateQuestions(
                            for: category,
                            friend: friend,
                            chatHistory: chatHistory,
                            modelContext: modelContext
                        )
                    } catch {
                        print("❌ Kategori \(category.rawValue) için üretim hatası: \(error)")
                        return QuickQuestion.defaultQuestions(for: category)
                    }
                }
            }

            for await questions in group {
                allQuestions.append(contentsOf: questions)
            }
        }

        return allQuestions
    }
}

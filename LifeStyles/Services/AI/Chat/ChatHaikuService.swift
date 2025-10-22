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
}

// MARK: - Chat Haiku Service

class ChatHaikuService {
    static let shared = ChatHaikuService()

    private let claude = ClaudeHaikuService.shared

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
        let (systemPrompt, userMessage) = generateChatPrompt(
            context: context,
            question: question,
            chatHistory: chatHistory
        )

        // Call Claude Haiku
        let response = try await claude.generate(
            systemPrompt: systemPrompt,
            userMessage: userMessage,
            temperature: 0.9  // More creative for chat
        )

        return response
    }

    // MARK: - Data Usage Tracking

    private func trackDataUsage(context: ChatContext) {
        let friendsCount = (context.allFriends?.count ?? 0) + (context.overdueFriends?.count ?? 0) + (context.friend != nil ? 1 : 0)

        let dataCount = DataUsageCount(
            friendsCount: friendsCount,
            goalsCount: 0,  // Chat doesn't use goals/habits yet
            habitsCount: 0,
            hasMoodData: false,
            hasLocationData: false,
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
                sharedInterests: nil
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
            sharedInterests: friend.sharedInterests
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
        chatHistory: [ChatMessage]
    ) -> (system: String, user: String) {

        let systemPrompt: String

        if context.isGeneralMode {
            // Genel mod - kişisel asistan (Smart Context)
            var contextInfo = ""

            // Smart Context: Intent'e göre farklı bilgi
            if let allFriends = context.allFriends, !allFriends.isEmpty {
                // friendsList intent - TÜM arkadaşlar
                contextInfo += "\n\nKullanıcının arkadaşları (\(allFriends.count) kişi):\n"
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
                contextInfo += "\n\nİletişim kurulması gereken arkadaşlar (\(overdueFriends.count) kişi):\n"
                for friend in overdueFriends.prefix(10) {
                    contextInfo += "• \(friend.name) (\(friend.relationshipType)) - ⚠️ \(friend.daysSinceLastContact) gündür iletişim yok\n"
                }
                if overdueFriends.count > 10 {
                    contextInfo += "...ve \(overdueFriends.count - 10) kişi daha\n"
                }
            } else {
                // general intent - minimal context (token tasarrufu)
                contextInfo += "\n\n(Arkadaş bilgisi yüklenmedi - genel soru modu)"
            }

            systemPrompt = """
            Sen LifeStyles uygulamasının kişisel yaşam asistanısın. Adın Claude.

            Görevin: Kullanıcıya arkadaşlıkları, hedefleri, alışkanlıkları ve yaşam kalitesi hakkında yardımcı olmak.
            \(contextInfo)
            Kurallar:
            - Türkçe yaz, samimi ve doğal ol
            - Kısa ve öz cevaplar ver (2-3 cümle ideal)
            - Emoji kullan (abartma, 1-2 emoji yeterli)
            - Yapıcı ve motive edici ol
            - Kullanıcının sorularını anlamaya çalış
            - Arkadaş bilgisi varsa spesifik önerilerde bulun
            - Gerekirse soru sor, daha fazla detay iste

            Tarzın: Arkadaş canlısı, destekleyici, anlayışlı
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

            systemPrompt = """
            Sen LifeStyles uygulamasının kişisel asistanısın. Adın Claude.

            Şu anda kullanıcı \(friendName) hakkında konuşuyor.
            İlişki türü: \(relationship)
            \(contextInfo)

            Görevin: Kullanıcıya \(friendName) ile ilişkisini güçlendirmede yardımcı olmak.

            Kurallar:
            - Türkçe yaz, samimi ve doğal ol
            - Kısa ve öz cevaplar ver (2-3 cümle)
            - Emoji kullan (1-2 emoji yeterli)
            - Yapıcı öneriler sun
            - Kullanıcının context bilgisini kullan ama tekrar etme
            - İlişkiyi güçlendirici fikirler ver

            Konuşabileceğin konular:
            - Mesaj önerileri ("\(friendName)'a ne mesaj atsam?")
            - İletişim fikirleri ("Ne yapabilirim?", "Nasıl yaklaşmalıyım?")
            - Aktivite önerileri ("Nereye gidelim?", "Ne yapsak?")
            - İlişki tavsiyeleri

            Tarzın: Empatik, destekleyici, yaratıcı
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

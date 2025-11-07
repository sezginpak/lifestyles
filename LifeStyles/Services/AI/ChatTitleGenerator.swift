//
//  ChatTitleGenerator.swift
//  LifeStyles
//
//  Created by Claude on 25.10.2025.
//  AI-powered chat title generation with Claude Haiku
//

import Foundation
import SwiftData

class ChatTitleGenerator {
    static let shared = ChatTitleGenerator()

    private let claude = ClaudeHaikuService.shared
    private var titleCache: [UUID: String] = [:]

    private init() {}

    // MARK: - Public Methods

    /// Generate AI-powered title for conversation
    /// - Parameter conversation: The conversation to generate title for
    /// - Returns: Short, descriptive title (5-6 words)
    func generateTitle(from conversation: ChatConversation) async -> String {
        // Check cache first
        if let cached = titleCache[conversation.id] {
            return cached
        }

        // Check if conversation has messages
        guard let messages = conversation.messages, !messages.isEmpty else {
            return "Yeni Sohbet"
        }

        // Privacy check - AI enabled?
        let privacySettings = AIPrivacySettings.shared
        guard privacySettings.hasGivenAIConsent && privacySettings.aiChatEnabled else {
            return fallbackTitle(from: messages)
        }

        do {
            // Generate AI title
            let title = try await generateAITitle(from: messages, conversation: conversation)

            // Cache it
            titleCache[conversation.id] = title

            return title
        } catch {
            print("❌ ChatTitleGenerator error: \(error)")
            // Fallback to first message
            return fallbackTitle(from: messages)
        }
    }

    /// Clear cache for a specific conversation
    func clearCache(for conversationId: UUID) {
        titleCache.removeValue(forKey: conversationId)
    }

    /// Clear all cache
    func clearAllCache() {
        titleCache.removeAll()
    }

    // MARK: - Private Methods

    private func generateAITitle(from messages: [ChatMessage], conversation: ChatConversation) async throws -> String {
        // Build conversation summary (last 6-8 messages)
        let recentMessages = messages.sorted(by: { $0.timestamp < $1.timestamp }).suffix(8)

        var conversationText = ""
        for message in recentMessages {
            let role = message.isUser ? "Kullanıcı" : "AI"
            // Limit each message to 80 characters
            let content = message.content.count > 80
                ? String(message.content.prefix(80)) + "..."
                : message.content
            conversationText += "\(role): \(content)\n"
        }

        // System prompt for title generation
        let systemPrompt = """
        Sen bir sohbet başlık üreticisisin.

        Görevin: Verilen sohbet metninden 5-6 kelimelik kısa, öz ve açıklayıcı bir başlık oluştur.

        Kurallar:
        - Respond in the conversation's language (Turkish, English, etc.)
        - 5-6 kelime, maksimum 40 karakter
        - Sohbetin ana konusunu yakala
        - Emoji kullanma
        - Sadece başlığı yaz, açıklama ekleme
        - Başlıkta noktalama işareti kullanma

        Örnekler:
        ✅ "Arkadaşlarla iletişim tavsiyeleri"
        ✅ "Haftalık hedef planlaması"
        ✅ "Ali ile buluşma fikirleri"
        ✅ "Ruh hali ve motivasyon"
        ❌ "Bu sohbet arkadaşlık hakkında" (çok uzun)
        ❌ "Sohbet 🎯" (emoji var)
        """

        // Context info
        var contextInfo = ""
        if !conversation.isGeneralMode, let friendName = conversation.friendName {
            contextInfo = "\nBu sohbet \(friendName) hakkında."
        }

        let userMessage = """
        Sohbet metni:
        \(conversationText)
        \(contextInfo)

        Başlık:
        """

        // Call Claude Haiku
        let response = try await claude.generate(
            systemPrompt: systemPrompt,
            userMessage: userMessage,
            temperature: 0.7  // Balanced creativity
        )

        // Clean response
        let cleanedTitle = cleanTitle(response)

        return cleanedTitle
    }

    private func fallbackTitle(from messages: [ChatMessage]) -> String {
        guard let firstUserMessage = messages.first(where: { $0.isUser }) else {
            return "Yeni Sohbet"
        }

        let content = firstUserMessage.content

        // Take first 30-35 characters
        if content.count > 35 {
            return String(content.prefix(35)) + "..."
        }

        return content
    }

    private func cleanTitle(_ raw: String) -> String {
        var cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove quotes if present
        cleaned = cleaned.replacingOccurrences(of: "\"", with: "")
        cleaned = cleaned.replacingOccurrences(of: "'", with: "")

        // Remove trailing punctuation
        while cleaned.last == "." || cleaned.last == "!" || cleaned.last == "?" || cleaned.last == "," {
            cleaned.removeLast()
        }

        // Limit to 40 characters
        if cleaned.count > 40 {
            cleaned = String(cleaned.prefix(40)) + "..."
        }

        // Capitalize first letter
        if let firstChar = cleaned.first {
            cleaned = firstChar.uppercased() + cleaned.dropFirst()
        }

        return cleaned.isEmpty ? "Yeni Sohbet" : cleaned
    }

    // MARK: - Batch Title Generation

    /// Generate titles for multiple conversations in parallel (for migration/bulk operations)
    func generateTitles(for conversations: [ChatConversation]) async -> [UUID: String] {
        var results: [UUID: String] = [:]

        await withTaskGroup(of: (UUID, String).self) { group in
            for conversation in conversations {
                group.addTask {
                    let title = await self.generateTitle(from: conversation)
                    return (conversation.id, title)
                }
            }

            for await (id, title) in group {
                results[id] = title
            }
        }

        return results
    }
}

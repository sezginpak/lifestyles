//
//  KnowledgeExtractor.swift
//  LifeStyles
//
//  Created by AI Assistant on 04.11.2025.
//  AI öğrenen chat sistemi - Knowledge extraction engine
//

import Foundation
import SwiftData

/// Konuşmalardan bilgi çıkaran ve kaydeden ana servis
@Observable
class KnowledgeExtractor {
    static let shared = KnowledgeExtractor()

    private let patternMatcher = PatternMatcher.shared
    private let haikuService = ClaudeHaikuService.shared

    // Extraction durumu
    var isExtracting = false
    var lastExtractionDate: Date?

    private init() {}

    // MARK: - Public Methods

    /// Konuşmadan bilgi çıkar (hybrid: regex + AI)
    func extractKnowledge(
        from conversation: [ChatMessage],
        context: ModelContext,
        conversationId: String? = nil
    ) async -> [UserKnowledge] {
        guard !conversation.isEmpty else { return [] }

        isExtracting = true
        defer { isExtracting = false }

        var extractedFacts: [UserKnowledge] = []

        // 1. Son 5 mesajı al (son konuşma context'i)
        let recentMessages = Array(conversation.suffix(5))
        let conversationText = recentMessages.map { $0.content }.joined(separator: "\n")

        // 2. Önce pattern matching dene (bedava ve hızlı)
        let regexFacts = patternMatcher.extract(from: conversationText)

        // 3. Regex'ten gelen fact'leri UserKnowledge'a çevir
        for fact in regexFacts {
            let knowledge = fact.toUserKnowledge(conversationId: conversationId)
            extractedFacts.append(knowledge)
        }

        // 4. Eğer regex yeterli değilse, AI ile çıkar
        // (Regex < 2 fact bulduysa veya mesaj > 50 kelime)
        let wordCount = conversationText.split(separator: " ").count
        if regexFacts.count < 2 || wordCount > 50 {
            do {
                let aiFacts = try await extractWithAI(conversationText)

                for fact in aiFacts {
                    let knowledge = fact.toUserKnowledge(conversationId: conversationId)
                    extractedFacts.append(knowledge)
                }
            } catch {
                print("⚠️ AI extraction hatası: \(error.localizedDescription)")
                // Regex results varsa onları kullan, yoksa boş döner
            }
        }

        // 5. Duplicate'leri filtrele ve kaydet
        let uniqueFacts = deduplicateFacts(extractedFacts, context: context)
        for fact in uniqueFacts {
            saveFact(fact, to: context)
        }

        lastExtractionDate = Date()

        print("✅ \(uniqueFacts.count) yeni bilgi öğrenildi")
        return uniqueFacts
    }

    /// Tek mesajdan hızlı bilgi çıkar (sadece regex)
    func quickExtract(from message: String, context: ModelContext) -> [UserKnowledge] {
        guard !message.isEmpty else { return [] }

        let facts = patternMatcher.extract(from: message)
        var knowledge: [UserKnowledge] = []

        for fact in facts {
            let k = fact.toUserKnowledge()
            saveFact(k, to: context)
            knowledge.append(k)
        }

        return knowledge
    }

    // MARK: - AI Extraction

    /// Haiku API ile bilgi çıkar
    private func extractWithAI(_ text: String) async throws -> [ExtractedFact] {
        let prompt = buildExtractionPrompt(text)

        let response = try await haikuService.generate(
            systemPrompt: prompt,
            userMessage: text,
            temperature: 0.3,  // Daha deterministik
            maxTokens: 800
        )

        return parseAIResponse(response)
    }

    /// AI extraction prompt'u oluştur
    private func buildExtractionPrompt(_ text: String) -> String {
        return """
        Extract user facts from the conversation below. Return ONLY valid JSON, no explanations.

        CATEGORIES:
        - personalInfo: name, age, job, city, etc
        - relationships: family, friends, partner
        - lifestyle: habits, routines
        - values: beliefs, priorities
        - fears: worries, anxieties
        - goals: aspirations, targets
        - preferences: likes, dislikes
        - memories: past events
        - experiences: recent activities
        - challenges: problems, difficulties
        - habits: regular behaviors
        - triggers: sensitivities
        - currentSituation: current state
        - recentEvents: recent happenings
        - other: miscellaneous

        RULES:
        ❌ NO guessing - only extract explicitly stated facts
        ❌ NO general statements - "drinking coffee" ≠ likes_coffee
        ✅ SPECIFIC facts only - "I love coffee" = likes_coffee
        ✅ HIGH confidence only - >= 0.8

        JSON FORMAT:
        {
          "facts": [
            {
              "category": "personalInfo",
              "key": "job",
              "value": "software developer",
              "confidence": 0.9,
              "source": "user_told"
            }
          ]
        }

        CRITICAL JSON RULES:
        - "value" MUST ALWAYS BE A STRING (not boolean, not number)
        - For boolean facts: use "true" or "false" as string
        - For numbers: use string like "28" not 28
        - Example: {"key": "has_partner", "value": "true"} ✅
        - Example: {"key": "has_partner", "value": true} ❌

        IMPORTANT:
        - Return empty array if no facts
        - confidence must be >= 0.8
        - source: "user_told" or "inferred"
        - Support Turkish and English

        CONVERSATION:
        \(text)

        JSON OUTPUT (no markdown, no explanation):
        """
    }

    /// AI response'u parse et
    private func parseAIResponse(_ response: String) -> [ExtractedFact] {
        // JSON extract et
        guard let jsonString = extractJSON(from: response) else {
            return []
        }

        // Parse JSON
        guard let data = jsonString.data(using: .utf8) else {
            return []
        }

        do {
            let json = try JSONDecoder().decode(AIExtractionResponse.self, from: data)
            return json.facts
        } catch {
            return []
        }
    }

    /// Response'dan JSON çıkar
    private func extractJSON(from text: String) -> String? {
        // ```json ile wrap edilmişse temizle
        var clean = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // İlk { ve son } arasını al
        if let startIndex = clean.firstIndex(of: "{"),
           let endIndex = clean.lastIndex(of: "}") {
            clean = String(clean[startIndex...endIndex])
        }

        return clean.isEmpty ? nil : clean
    }

    // MARK: - Duplicate Detection & Merge

    /// Duplicate fact'leri birleştir
    private func deduplicateFacts(_ facts: [UserKnowledge], context: ModelContext) -> [UserKnowledge] {
        var unique: [UserKnowledge] = []

        for fact in facts {
            // Aynı key'e sahip fact var mı kontrol et
            if let existing = findExisting(fact, in: context) {
                // Varsa güncelle
                updateExisting(existing, with: fact)
            } else {
                // Yoksa yeni ekle
                unique.append(fact)
            }
        }

        return unique
    }

    /// Mevcut fact'i bul
    private func findExisting(_ fact: UserKnowledge, in context: ModelContext) -> UserKnowledge? {
        // Predicate macro içinde kullanmak için değerleri capture et
        let category = fact.category
        let key = fact.key

        let descriptor = FetchDescriptor<UserKnowledge>(
            predicate: #Predicate { knowledge in
                knowledge.category == category &&
                knowledge.key == key &&
                knowledge.isActive == true
            }
        )

        return try? context.fetch(descriptor).first
    }

    /// Mevcut fact'i güncelle
    private func updateExisting(_ existing: UserKnowledge, with new: UserKnowledge) {
        // Aynı değer mi?
        if existing.value == new.value {
            // Güven artır
            existing.increaseConfidence()
            existing.incrementUsage()
        } else {
            // Farklı değer - güven azalt (conflict)
            existing.decreaseConfidence(by: 0.2)

            // Eğer güven çok düştüyse, yeni fact'i kabul et
            if existing.confidence < 0.3 {
                existing.value = new.value
                existing.confidence = new.confidence
                existing.source = new.source
            }
        }

        // Conversation ID ekle
        if !new.conversationIds.isEmpty {
            for convId in new.conversationIds {
                existing.addConversationId(convId)
            }
        }
    }

    /// Fact'i kaydet
    private func saveFact(_ fact: UserKnowledge, to context: ModelContext) {
        context.insert(fact)

        do {
            try context.save()
        } catch {
            print("⚠️ UserKnowledge kayıt hatası: \(error)")
        }
    }
}

// MARK: - AI Response Models

/// AI extraction response
struct AIExtractionResponse: Codable {
    let facts: [ExtractedFact]
}

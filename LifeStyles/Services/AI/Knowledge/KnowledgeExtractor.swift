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
    private let embeddingService = EmbeddingService.shared

    // Extraction durumu
    var isExtracting = false
    var lastExtractionDate: Date?

    private init() {}

    // MARK: - Public Methods

    /// Konuşmadan bilgi çıkar (hybrid: regex + AI)
    /// Artık hem UserKnowledge hem EntityKnowledge çıkarır
    func extractKnowledge(
        from conversation: [ChatMessage],
        context: ModelContext,
        conversationId: String? = nil,
        availableFriends: [Friend] = []
    ) async -> (userKnowledge: [UserKnowledge], entityKnowledge: [EntityKnowledge]) {
        guard !conversation.isEmpty else { return ([], []) }

        isExtracting = true
        defer { isExtracting = false }

        var extractedUserFacts: [UserKnowledge] = []
        var extractedEntityFacts: [EntityKnowledge] = []

        // 1. Son 5 mesajı al (son konuşma context'i)
        let recentMessages = Array(conversation.suffix(5))
        let conversationText = recentMessages.map { $0.content }.joined(separator: "\n")

        // 2. Önce pattern matching dene (bedava ve hızlı - sadece user facts)
        let regexFacts = patternMatcher.extract(from: conversationText)

        // 3. Regex'ten gelen fact'leri UserKnowledge'a çevir
        for fact in regexFacts {
            let knowledge = fact.toUserKnowledge(conversationId: conversationId)
            extractedUserFacts.append(knowledge)
        }

        // 4. Eğer regex yeterli değilse, AI ile çıkar
        // (Regex < 2 fact bulduysa veya mesaj > 50 kelime)
        let wordCount = conversationText.split(separator: " ").count
        if regexFacts.count < 2 || wordCount > 50 {
            do {
                // 🚀 YENI: AI'dan hem user hem entity facts al
                let (aiFacts, aiEntityFacts) = try await extractWithAI(
                    conversationText,
                    availableFriends: availableFriends,
                    context: context
                )

                // User facts
                for fact in aiFacts {
                    let knowledge = fact.toUserKnowledge(conversationId: conversationId)
                    extractedUserFacts.append(knowledge)
                }

                // Entity facts
                for fact in aiEntityFacts {
                    let knowledge = fact.toEntityKnowledge(conversationId: conversationId)
                    extractedEntityFacts.append(knowledge)
                }
            } catch {
                print("⚠️ AI extraction hatası: \(error.localizedDescription)")
                // Regex results varsa onları kullan, yoksa boş döner
            }
        }

        // 5. Duplicate'leri filtrele ve kaydet - USER
        let uniqueUserFacts = deduplicateFacts(extractedUserFacts, context: context)
        for fact in uniqueUserFacts {
            saveFact(fact, to: context)
        }

        // 6. Duplicate'leri filtrele ve kaydet - ENTITY
        let uniqueEntityFacts = deduplicateEntityFacts(extractedEntityFacts, context: context)
        for fact in uniqueEntityFacts {
            saveEntityFact(fact, to: context)
        }

        // 7. 🚀 Background'da embedding'leri oluştur (Phase 2)
        if !uniqueUserFacts.isEmpty {
            let factIds = uniqueUserFacts.map { $0.id }
            let modelContainer = context.container

            Task.detached {
                await self.generateEmbeddingsInBackground(
                    factIds: factIds,
                    modelContainer: modelContainer
                )
            }
        }

        if !uniqueEntityFacts.isEmpty {
            let factIds = uniqueEntityFacts.map { $0.id }
            let modelContainer = context.container

            Task.detached {
                await self.generateEntityEmbeddingsInBackground(
                    factIds: factIds,
                    modelContainer: modelContainer
                )
            }
        }

        lastExtractionDate = Date()

        let totalCount = uniqueUserFacts.count + uniqueEntityFacts.count
        print("✅ \(totalCount) yeni bilgi öğrenildi (\(uniqueUserFacts.count) kullanıcı + \(uniqueEntityFacts.count) varlık)")

        return (uniqueUserFacts, uniqueEntityFacts)
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

        // 🚀 YENI: Background'da embedding'leri oluştur
        if !knowledge.isEmpty {
            let factIds = knowledge.map { $0.id }
            let modelContainer = context.container

            Task.detached {
                await self.generateEmbeddingsInBackground(
                    factIds: factIds,
                    modelContainer: modelContainer
                )
            }
        }

        return knowledge
    }

    // MARK: - AI Extraction

    /// Haiku API ile bilgi çıkar - Hem user hem entity facts
    private func extractWithAI(
        _ text: String,
        availableFriends: [Friend],
        context: ModelContext
    ) async throws -> (userFacts: [ExtractedFact], entityFacts: [ExtractedEntityFact]) {
        let prompt = buildExtractionPrompt(text, availableFriends: availableFriends)

        let response = try await haikuService.generate(
            systemPrompt: prompt,
            userMessage: text,
            temperature: 0.3,  // Daha deterministik
            maxTokens: 1200    // Daha fazla token (entity facts için)
        )

        return parseAIResponse(response, availableFriends: availableFriends, context: context)
    }

    /// AI extraction prompt'u oluştur - Hem user hem entity facts için
    private func buildExtractionPrompt(_ text: String, availableFriends: [Friend]) -> String {
        // Arkadaş listesi (entity tanıma için)
        var friendContext = ""
        if !availableFriends.isEmpty {
            friendContext = "\n\nKNOWN FRIENDS (for entity recognition):\n"
            for friend in availableFriends.prefix(20) {
                friendContext += "- \(friend.name) (id: \(friend.id))\n"
            }
        }

        return """
        Extract both USER facts and ENTITY facts from the conversation. Return ONLY valid JSON.

        USER CATEGORIES:
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

        ENTITY TYPES:
        - person: Friends, family members (Ömer, Ali, vb.)
        - place: Locations (cafe, park, office)
        - activity: Hobbies, activities (yoga, reading)
        - object: Items (books, movies, music)
        - other: Miscellaneous\(friendContext)

        RULES:
        ❌ NO guessing - only extract explicitly stated facts
        ❌ NO general statements
        ✅ SPECIFIC facts only
        ✅ HIGH confidence only - >= 0.8
        ✅ Match friend names to their IDs when available

        JSON FORMAT:
        {
          "userFacts": [
            {
              "category": "personalInfo",
              "key": "job",
              "value": "software developer",
              "confidence": 0.9,
              "source": "user_told"
            }
          ],
          "entityFacts": [
            {
              "entityType": "person",
              "entityId": "UUID-HERE-IF-KNOWN",
              "entityName": "Ömer",
              "category": "personalInfo",
              "key": "occupation",
              "value": "hukuk okuyor",
              "confidence": 0.95,
              "source": "user_told"
            }
          ]
        }

        CRITICAL JSON RULES:
        - "value" MUST ALWAYS BE A STRING (not boolean, not number)
        - For boolean facts: use "true" or "false" as string
        - For numbers: use string like "28" not 28
        - entityId: Use UUID from KNOWN FRIENDS list if name matches, otherwise null
        - entityName: Always include the entity's name

        IMPORTANT:
        - Return empty arrays if no facts
        - confidence must be >= 0.8
        - source: "user_told" or "inferred"
        - Support Turkish and English

        CONVERSATION:
        \(text)

        JSON OUTPUT (no markdown, no explanation):
        """
    }

    /// AI response'u parse et - Hem user hem entity facts
    private func parseAIResponse(
        _ response: String,
        availableFriends: [Friend],
        context: ModelContext
    ) -> (userFacts: [ExtractedFact], entityFacts: [ExtractedEntityFact]) {
        // JSON extract et
        guard let jsonString = extractJSON(from: response) else {
            return ([], [])
        }

        // Parse JSON
        guard let data = jsonString.data(using: .utf8) else {
            return ([], [])
        }

        do {
            let json = try JSONDecoder().decode(AIExtractionResponseV2.self, from: data)

            // Entity facts için friend matching yap
            var processedEntityFacts: [ExtractedEntityFact] = []
            for entityFact in json.entityFacts {
                var fact = entityFact

                // Eğer entityType person ise ve entityId nil ise, friend listesinden bul
                if fact.entityType == .person, fact.entityId == nil, let name = fact.entityName {
                    if let matchedFriend = availableFriends.first(where: {
                        $0.name.lowercased() == name.lowercased()
                    }) {
                        // Friend bulundu, ID'sini ekle
                        fact = ExtractedEntityFact(
                            entityType: fact.entityType,
                            entityId: matchedFriend.id,
                            entityName: fact.entityName,
                            category: fact.category,
                            key: fact.key,
                            value: fact.value,
                            confidence: fact.confidence,
                            source: fact.source
                        )
                    }
                }

                processedEntityFacts.append(fact)
            }

            return (json.userFacts, processedEntityFacts)
        } catch {
            print("⚠️ JSON parse hatası: \(error)")
            return ([], [])
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

    // MARK: - Entity Knowledge Methods

    /// Entity duplicate fact'leri birleştir
    private func deduplicateEntityFacts(_ facts: [EntityKnowledge], context: ModelContext) -> [EntityKnowledge] {
        var unique: [EntityKnowledge] = []

        for fact in facts {
            // Aynı entity + key kombinasyonu var mı kontrol et
            if let existing = findExistingEntity(fact, in: context) {
                // Varsa güncelle
                updateExistingEntity(existing, with: fact)
            } else {
                // Yoksa yeni ekle
                unique.append(fact)
            }
        }

        return unique
    }

    /// Mevcut entity fact'i bul
    private func findExistingEntity(_ fact: EntityKnowledge, in context: ModelContext) -> EntityKnowledge? {
        let entityType = fact.entityType
        let entityId = fact.entityId
        let category = fact.category
        let key = fact.key

        let descriptor = FetchDescriptor<EntityKnowledge>(
            predicate: #Predicate { knowledge in
                knowledge.entityType == entityType &&
                knowledge.entityId == entityId &&
                knowledge.category == category &&
                knowledge.key == key &&
                knowledge.isActive == true
            }
        )

        return try? context.fetch(descriptor).first
    }

    /// Mevcut entity fact'i güncelle
    private func updateExistingEntity(_ existing: EntityKnowledge, with new: EntityKnowledge) {
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

    /// Entity fact'i kaydet
    private func saveEntityFact(_ fact: EntityKnowledge, to context: ModelContext) {
        // Eğer entityId varsa, ilişkili entity'yi bul ve bağla
        if let entityId = fact.entityId {
            if fact.entityTypeEnum == .person {
                // Friend ara
                let descriptor = FetchDescriptor<Friend>(
                    predicate: #Predicate { $0.id == entityId }
                )
                if let friend = try? context.fetch(descriptor).first {
                    fact.friend = friend
                }
            }
        }

        context.insert(fact)

        do {
            try context.save()
        } catch {
            print("⚠️ EntityKnowledge kayıt hatası: \(error)")
        }
    }

    // MARK: - Embedding Generation (Phase 2)

    /// Background'da embedding'leri oluştur (thread-safe)
    private func generateEmbeddingsInBackground(
        factIds: [UUID],
        modelContainer: ModelContainer
    ) async {
        // Background context oluştur (thread-safe)
        let backgroundContext = ModelContext(modelContainer)

        for factId in factIds {
            // Fact'i background context'te bul
            let descriptor = FetchDescriptor<UserKnowledge>(
                predicate: #Predicate { $0.id == factId }
            )

            guard let fact = try? backgroundContext.fetch(descriptor).first else {
                continue
            }

            // Embedding oluştur
            do {
                let embedding = try await embeddingService.generateEmbeddingForFact(fact)
                fact.updateEmbedding(embedding, model: "simple-tfidf-v1")

                // Kaydet
                try backgroundContext.save()
                print("✅ Embedding oluşturuldu: \(fact.key)")
            } catch {
                print("⚠️ Embedding generation hatası (\(fact.key)): \(error)")
            }
        }
    }

    /// Background'da entity embedding'leri oluştur (thread-safe)
    private func generateEntityEmbeddingsInBackground(
        factIds: [UUID],
        modelContainer: ModelContainer
    ) async {
        // Background context oluştur (thread-safe)
        let backgroundContext = ModelContext(modelContainer)

        for factId in factIds {
            // Fact'i background context'te bul
            let descriptor = FetchDescriptor<EntityKnowledge>(
                predicate: #Predicate { $0.id == factId }
            )

            guard let fact = try? backgroundContext.fetch(descriptor).first else {
                continue
            }

            // Embedding oluştur (aynı service kullanıyoruz)
            do {
                // EntityKnowledge için text oluştur
                let text = "\(fact.entityName ?? ""): \(fact.key) = \(fact.value)"
                let embedding = try await embeddingService.generateEmbedding(for: text)
                fact.updateEmbedding(embedding, model: "simple-tfidf-v1")

                // Kaydet
                try backgroundContext.save()
                print("✅ Entity embedding oluşturuldu: \(fact.entityName ?? "unknown") - \(fact.key)")
            } catch {
                print("⚠️ Entity embedding generation hatası (\(fact.key)): \(error)")
            }
        }
    }
}

// MARK: - AI Response Models

/// AI extraction response (legacy - v1)
struct AIExtractionResponse: Codable {
    let facts: [ExtractedFact]
}

/// AI extraction response v2 - Hem user hem entity facts
struct AIExtractionResponseV2: Codable {
    let userFacts: [ExtractedFact]
    let entityFacts: [ExtractedEntityFact]
}

//
//  SmartContextBuilder.swift
//  LifeStyles
//
//  Created by AI Assistant on 04.11.2025.
//  AI öğrenen chat sistemi - Smart context builder (token optimization)
//

import Foundation
import SwiftData

/// Mesaja göre relevantları seçip optimize edilmiş context oluşturur
@Observable
class SmartContextBuilder {
    static let shared = SmartContextBuilder()

    // Context limits
    private let maxTokens = 300          // Hedef: 300 token
    private let maxFacts = 15            // Max 15 fact
    private let recentDays = 7           // Son 7 gün = güncel

    // Services (singleton references)
    private let vectorSearch = VectorSearchService.shared
    private let qualityTracker = QualityTracker.shared

    // Hybrid scoring weights
    private let semanticWeight = 0.6
    private let keywordWeight = 0.2
    private let qualityWeight = 0.1
    private let recencyWeight = 0.1

    private init() {}

    // MARK: - Public Methods

    /// Mesaja göre smart context oluştur
    func buildContext(
        for message: String,
        from knowledgeBase: [UserKnowledge]
    ) -> String {
        guard !knowledgeBase.isEmpty else {
            return ""
        }

        var context = ""
        var tokenCount = 0

        // 1. ALWAYS INCLUDE: Basic Info (her zaman dahil et)
        let basics = getBasicInfo(from: knowledgeBase)
        if !basics.isEmpty {
            let formatted = formatSection(String(localized: "section.kişisel.bilgiler"), facts: basics)
            context += formatted
            tokenCount += estimateTokens(formatted)
        }

        // 2. MESSAGE-RELEVANT: Mesaja relevantları ekle
        let relevant = findRelevantFacts(message, in: knowledgeBase)
        if !relevant.isEmpty && tokenCount < maxTokens {
            let formatted = formatSection(String(localized: "section.ilgili.bilgiler"), facts: relevant)
            let tokens = estimateTokens(formatted)

            if tokenCount + tokens <= maxTokens {
                context += formatted
                tokenCount += tokens
            }
        }

        // 3. RECENT CONTEXT: Güncel durum (son 7 gün)
        if tokenCount < maxTokens {
            let recent = getRecentContext(from: knowledgeBase)
            if !recent.isEmpty {
                let formatted = formatSection(String(localized: "section.güncel.durum"), facts: recent)
                let tokens = estimateTokens(formatted)

                if tokenCount + tokens <= maxTokens {
                    context += formatted
                    tokenCount += tokens
                }
            }
        }

        // 4. HIGH CONFIDENCE: Yüksek güvenilirlik (eğer yer varsa)
        if tokenCount < maxTokens - 50 {
            let highConfidence = getHighConfidenceFacts(from: knowledgeBase)
            if !highConfidence.isEmpty {
                let formatted = formatSection(String(localized: "section.kanitlanmiş.bilgiler"), facts: highConfidence)
                let tokens = estimateTokens(formatted)

                if tokenCount + tokens <= maxTokens {
                    context += formatted
                    tokenCount += tokens
                }
            }
        }

        return context
    }

    /// Compact context (daha az detay, daha fazla fact)
    func buildCompactContext(
        for message: String,
        from knowledgeBase: [UserKnowledge]
    ) -> String {
        guard !knowledgeBase.isEmpty else {
            return ""
        }

        // Compact format: Sadece key-value, kategori yok
        var lines: [String] = []

        // Basics
        let basics = getBasicInfo(from: knowledgeBase)
        for fact in basics.prefix(5) {
            lines.append("• \(fact.key): \(fact.value)")
        }

        // Relevants
        let relevant = findRelevantFacts(message, in: knowledgeBase)
        for fact in relevant.prefix(10) {
            lines.append("• \(fact.key): \(fact.value)")
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Fact Selectors

    /// Temel bilgiler (isim, yaş, meslek, şehir)
    private func getBasicInfo(from knowledge: [UserKnowledge]) -> [UserKnowledge] {
        let basicKeys = ["name", "age", "job", "city", "occupation", "profession"]

        return knowledge.filter { fact in
            fact.categoryEnum == .personalInfo &&
            basicKeys.contains(where: { fact.key.lowercased().contains($0) }) &&
            fact.confidence > 0.7
        }
        .sorted { $0.confidence > $1.confidence }
        .prefix(4)
        .map { $0 }
    }

    /// Mesaja relevant fact'ler (Hybrid: Semantic + Keyword + Quality + Recency)
    private func findRelevantFacts(
        _ message: String,
        in knowledge: [UserKnowledge]
    ) -> [UserKnowledge] {
        // Fallback to keyword-only scoring (sync)
        // Async version için findRelevantFactsAsync kullan
        return findRelevantFactsKeywordOnly(message, in: knowledge)
    }

    /// ASYNC: Hybrid scoring ile relevant fact'ler bul
    func findRelevantFactsAsync(
        _ message: String,
        in knowledge: [UserKnowledge],
        modelContext: ModelContext
    ) async -> [UserKnowledge] {
        guard !knowledge.isEmpty else { return [] }

        // Try semantic search (may fail if embeddings not ready)
        var semanticScores: [UUID: Double] = [:]

        do {
            let scoredFacts = try await vectorSearch.findSimilarFactsHybrid(
                to: message,
                modelContext: modelContext,
                limit: 20 // Get more for reranking
            )

            for scored in scoredFacts {
                semanticScores[scored.fact.id] = scored.semanticScore
            }
        } catch {
            // Semantic search failed, will use keyword-only
            print("Semantic search failed, falling back to keyword: \(error)")
        }

        // Calculate hybrid scores
        var scored: [(fact: UserKnowledge, score: Double)] = []

        for fact in knowledge {
            var finalScore = 0.0

            // 1. Semantic score (if available)
            let semanticScore = semanticScores[fact.id] ?? 0.0
            finalScore += semanticScore * semanticWeight

            // 2. Keyword matching
            let keywordScore = calculateKeywordScore(message, fact: fact)
            finalScore += keywordScore * keywordWeight

            // 3. Quality score (confidence + accuracy)
            finalScore += fact.qualityScore * qualityWeight

            // 4. Recency score
            let recencyScore = calculateRecencyScore(fact)
            finalScore += recencyScore * recencyWeight

            if finalScore > 0.2 { // Lower threshold for hybrid
                scored.append((fact, finalScore))
            }
        }

        // Sort by final score, return top 10
        return scored
            .sorted { $0.score > $1.score }
            .prefix(10)
            .map { $0.fact }
    }

    /// Keyword-only scoring (fallback için)
    private func findRelevantFactsKeywordOnly(
        _ message: String,
        in knowledge: [UserKnowledge]
    ) -> [UserKnowledge] {
        var scored: [(fact: UserKnowledge, score: Double)] = []

        for fact in knowledge {
            var score = 0.0

            // 1. Keyword matching
            score += calculateKeywordScore(message, fact: fact) * 1.5

            // 2. Category relevance
            let categoryScore = calculateCategoryRelevance(fact.categoryEnum, for: message)
            score += categoryScore

            // 3. Recency bonus
            score += calculateRecencyScore(fact) * 0.5

            // 4. Confidence weighting
            score *= fact.confidence

            // 5. Usage frequency bonus
            if fact.timesReferenced > 3 {
                score += 0.3
            }

            if score > 0.3 {
                scored.append((fact, score))
            }
        }

        return scored
            .sorted { $0.score > $1.score }
            .prefix(10)
            .map { $0.fact }
    }

    // MARK: - Scoring Helpers

    /// Keyword matching score hesapla
    private func calculateKeywordScore(_ message: String, fact: UserKnowledge) -> Double {
        let normalized = message.lowercased()
        var score = 0.0

        // Key match
        if normalized.contains(fact.key.lowercased()) {
            score += 0.6
        }

        // Value match
        if normalized.contains(fact.value.lowercased()) {
            score += 0.4
        }

        // Category keyword match
        let categoryScore = calculateCategoryRelevance(fact.categoryEnum, for: message)
        score += categoryScore * 0.3

        return min(score, 1.0) // Cap at 1.0
    }

    /// Recency score hesapla
    private func calculateRecencyScore(_ fact: UserKnowledge) -> Double {
        let daysSince = Date().timeIntervalSince(fact.createdAt) / 86400

        if daysSince < 7 {
            return (7 - daysSince) / 7 // 1.0 for today, 0.0 for 7 days ago
        } else if daysSince < 30 {
            return 0.5 // Medium recency
        }

        return 0.2 // Old but still some value
    }

    /// Kategori relevance hesapla
    private func calculateCategoryRelevance(
        _ category: KnowledgeCategory,
        for message: String
    ) -> Double {
        let normalized = message.lowercased()

        // Keyword patterns per category
        let patterns: [KnowledgeCategory: [String]] = [
            .personalInfo: ["ben", "benim", "kendim", "i am", "my"],
            .relationships: ["arkadaş", "aile", "eş", "partner", "friend", "family"],
            .lifestyle: ["yaşam", "hayat", "rutin", "lifestyle", "daily"],
            .values: ["önem", "değer", "inanç", "value", "belief"],
            .fears: ["korku", "endişe", "kaygı", "fear", "worry", "anxiety"],
            .goals: ["hedef", "istek", "yapmak istiyorum", "goal", "want to", "wish"],
            .preferences: ["sever", "sevmem", "beğen", "like", "dislike", "prefer"],
            .memories: ["hatırla", "eskiden", "geçmişte", "remember", "past", "memory"],
            .habits: ["her gün", "genelde", "always", "usually", "habit"],
            .triggers: ["stres", "sinir", "stress", "trigger", "upset"],
            .currentSituation: ["şimdi", "şu an", "bugün", "now", "currently", "today"],
            .recentEvents: ["dün", "geçen hafta", "recently", "yesterday", "last week"]
        ]

        if let keywords = patterns[category] {
            for keyword in keywords {
                if normalized.contains(keyword) {
                    return 1.0
                }
            }
        }

        return 0.0
    }

    /// Güncel context (son 7 gün)
    private func getRecentContext(from knowledge: [UserKnowledge]) -> [UserKnowledge] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -recentDays, to: Date()) ?? Date()

        return knowledge.filter { fact in
            (fact.categoryEnum == .currentSituation || fact.categoryEnum == .recentEvents) &&
            fact.createdAt > cutoffDate &&
            fact.confidence > 0.6
        }
        .sorted { $0.createdAt > $1.createdAt }
        .prefix(5)
        .map { $0 }
    }

    /// Yüksek güvenilirlik fact'ler
    private func getHighConfidenceFacts(from knowledge: [UserKnowledge]) -> [UserKnowledge] {
        return knowledge.filter { fact in
            fact.confidence >= 0.9 &&
            fact.timesReferenced >= 2  // En az 2 kez kullanılmış
        }
        .sorted { $0.confidence > $1.confidence }
        .prefix(5)
        .map { $0 }
    }

    // MARK: - Formatting

    /// Section formatla
    private func formatSection(_ title: String, facts: [UserKnowledge]) -> String {
        guard !facts.isEmpty else { return "" }

        var text = "\n\(title):\n"
        for fact in facts {
            text += "• \(fact.key): \(fact.value)"

            // Güven düşükse işaretle
            if fact.confidence < 0.7 {
                text += " (düşük güven)"
            }

            text += "\n"
        }

        return text
    }

    // MARK: - Token Estimation

    /// Token sayısını tahmin et (yaklaşık: 1 token ≈ 4 karakter)
    private func estimateTokens(_ text: String) -> Int {
        return text.count / 4
    }

    // MARK: - Statistics

    /// Context istatistikleri
    func getContextStats(
        for message: String,
        from knowledgeBase: [UserKnowledge]
    ) -> ContextStats {
        let context = buildContext(for: message, from: knowledgeBase)

        return ContextStats(
            totalFacts: knowledgeBase.count,
            usedFacts: context.components(separatedBy: "•").count - 1,
            estimatedTokens: estimateTokens(context),
            categories: Set(knowledgeBase.map { $0.categoryEnum }).count
        )
    }
}

// MARK: - Context Statistics

struct ContextStats {
    let totalFacts: Int         // Toplam fact sayısı
    let usedFacts: Int          // Kullanılan fact sayısı
    let estimatedTokens: Int    // Tahmini token
    let categories: Int         // Kategori çeşitliliği

    var compressionRatio: Double {
        guard totalFacts > 0 else { return 0 }
        return Double(usedFacts) / Double(totalFacts)
    }

    var description: String {
        """
        📊 Context Stats:
        • Total Facts: \(totalFacts)
        • Used Facts: \(usedFacts) (\(Int(compressionRatio * 100))%)
        • Est. Tokens: \(estimatedTokens)
        • Categories: \(categories)
        """
    }
}

//
//  VectorSearchService.swift
//  LifeStyles
//
//  Created by AI Assistant on 05.11.2025.
//  Vector similarity search servisi
//  Semantic search için embedding'lere göre en alakalı fact'leri bulur
//

import Foundation
import SwiftData

/// Vector similarity search servisi
@Observable
class VectorSearchService {
    static let shared = VectorSearchService()

    private let embeddingService = EmbeddingService.shared

    // Simple cache for query embeddings
    private var queryCache: [String: ([Float], Date)] = [:]
    private let cacheExpirationMinutes: Double = 30

    private init() {}

    // MARK: - Similarity Search

    /// Query'ye en benzer fact'leri bul (semantic search)
    func findSimilarFacts(
        to query: String,
        modelContext: ModelContext,
        limit: Int = 15,
        minSimilarity: Float = 0.3
    ) async throws -> [ScoredFact] {
        // 1. Query için embedding oluştur (cached)
        let queryEmbedding = try await getOrCreateQueryEmbedding(query)

        // 2. Tüm aktif fact'leri çek
        let descriptor = FetchDescriptor<UserKnowledge>(
            predicate: #Predicate { $0.isActive == true }
        )

        guard let facts = try? modelContext.fetch(descriptor) else {
            throw VectorSearchError.fetchFailed
        }

        // 3. Embedding'i olmayanları filtrele veya oluştur
        var scoredFacts: [ScoredFact] = []

        for fact in facts {
            // Embedding yoksa oluştur
            if !fact.hasValidEmbedding {
                do {
                    let embedding = try await embeddingService.generateEmbeddingForFact(fact)
                    fact.updateEmbedding(embedding, model: "simple-tfidf-v1")
                } catch {
                    continue // Skip this fact
                }
            }

            guard let factEmbedding = fact.embedding else { continue }

            // 4. Similarity hesapla
            let similarity = embeddingService.cosineSimilarity(queryEmbedding, factEmbedding)

            // 5. Minimum threshold kontrolü
            if similarity >= minSimilarity {
                scoredFacts.append(ScoredFact(
                    fact: fact,
                    semanticScore: Double(similarity),
                    keywordScore: 0.0, // Will be calculated later if needed
                    finalScore: Double(similarity)
                ))
            }
        }

        // 6. Score'a göre sırala ve limit uygula
        scoredFacts.sort { $0.semanticScore > $1.semanticScore }

        return Array(scoredFacts.prefix(limit))
    }

    /// Hybrid search: Semantic + keyword matching
    func findSimilarFactsHybrid(
        to query: String,
        modelContext: ModelContext,
        limit: Int = 15,
        semanticWeight: Double = 0.6,
        keywordWeight: Double = 0.4
    ) async throws -> [ScoredFact] {
        // 1. Semantic search
        var scoredFacts = try await findSimilarFacts(
            to: query,
            modelContext: modelContext,
            limit: limit * 2, // Get more for reranking
            minSimilarity: 0.2
        )

        // 2. Keyword matching score ekle
        let keywords = extractKeywords(from: query)

        for i in 0..<scoredFacts.count {
            let keywordScore = calculateKeywordScore(
                fact: scoredFacts[i].fact,
                keywords: keywords
            )

            // Hybrid score hesapla
            let finalScore = (scoredFacts[i].semanticScore * semanticWeight) +
                           (keywordScore * keywordWeight)

            scoredFacts[i].keywordScore = keywordScore
            scoredFacts[i].finalScore = finalScore
        }

        // 3. Final score'a göre sırala ve limit uygula
        scoredFacts.sort { $0.finalScore > $1.finalScore }

        return Array(scoredFacts.prefix(limit))
    }

    /// Fact'e benzer fact'leri bul (related facts için)
    func findRelatedFacts(
        to fact: UserKnowledge,
        modelContext: ModelContext,
        limit: Int = 5
    ) async throws -> [ScoredFact] {
        guard let factEmbedding = fact.embedding else {
            throw VectorSearchError.missingEmbedding
        }

        // Tüm aktif fact'leri çek
        let descriptor = FetchDescriptor<UserKnowledge>(
            predicate: #Predicate { $0.isActive == true }
        )

        guard var facts = try? modelContext.fetch(descriptor) else {
            throw VectorSearchError.fetchFailed
        }

        // Kendisini manuel filter et (Predicate macro captured variable desteklemiyor)
        facts = facts.filter { $0.id != fact.id }

        var scoredFacts: [ScoredFact] = []

        for otherFact in facts {
            guard let otherEmbedding = otherFact.embedding else { continue }

            let similarity = embeddingService.cosineSimilarity(factEmbedding, otherEmbedding)

            if similarity >= 0.4 { // Higher threshold for related facts
                scoredFacts.append(ScoredFact(
                    fact: otherFact,
                    semanticScore: Double(similarity),
                    keywordScore: 0.0,
                    finalScore: Double(similarity)
                ))
            }
        }

        scoredFacts.sort { $0.semanticScore > $1.semanticScore }

        return Array(scoredFacts.prefix(limit))
    }

    // MARK: - Helper Methods

    private func getOrCreateQueryEmbedding(_ query: String) async throws -> [Float] {
        // Check cache
        if let cached = queryCache[query] {
            let expirationDate = cached.1.addingTimeInterval(cacheExpirationMinutes * 60)
            if Date() < expirationDate {
                return cached.0
            }
        }

        // Generate new embedding
        let embedding = try await embeddingService.generateEmbedding(for: query)

        // Cache it
        queryCache[query] = (embedding, Date())

        // Cleanup old cache entries
        cleanupCache()

        return embedding
    }

    private func cleanupCache() {
        let expirationThreshold = Date().addingTimeInterval(-cacheExpirationMinutes * 60)

        queryCache = queryCache.filter { _, value in
            value.1 > expirationThreshold
        }
    }

    private func extractKeywords(from text: String) -> [String] {
        let normalized = text.lowercased()
        let words = normalized.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty && $0.count > 2 }

        // Remove stop words
        let stopWords = Set([
            "bir", "bu", "şu", "o", "ve", "veya", "ile", "için",
            "a", "the", "and", "or", "in", "on", "at", "to"
        ])

        return words.filter { !stopWords.contains($0) }
    }

    private func calculateKeywordScore(fact: UserKnowledge, keywords: [String]) -> Double {
        guard !keywords.isEmpty else { return 0.0 }

        let factText = "\(fact.key) \(fact.value)".lowercased()
        var matches = 0

        for keyword in keywords {
            if factText.contains(keyword) {
                matches += 1
            }
        }

        return Double(matches) / Double(keywords.count)
    }

    /// Cache'i temizle
    func clearCache() {
        queryCache.removeAll()
    }
}

// MARK: - Supporting Types

/// Scored fact (similarity score ile birlikte)
struct ScoredFact: Identifiable {
    let fact: UserKnowledge
    var semanticScore: Double      // Embedding similarity (0-1)
    var keywordScore: Double       // Keyword matching (0-1)
    var finalScore: Double         // Hybrid score

    var id: UUID { fact.id }

    /// Score display için formatted
    var scorePercentage: Int {
        Int(finalScore * 100)
    }
}

// MARK: - Errors

enum VectorSearchError: LocalizedError {
    case fetchFailed
    case missingEmbedding
    case invalidQuery

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "Failed to fetch facts from database"
        case .missingEmbedding:
            return "Fact does not have an embedding"
        case .invalidQuery:
            return "Invalid search query"
        }
    }
}

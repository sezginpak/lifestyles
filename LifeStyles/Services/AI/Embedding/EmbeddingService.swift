//
//  EmbeddingService.swift
//  LifeStyles
//
//  Created by AI Assistant on 05.11.2025.
//  Text embedding generation servisi
//  Semantic search için text'leri vector representation'a çevirir
//

import Foundation
import SwiftData

/// Text embedding generation servisi
@Observable
class EmbeddingService {
    static let shared = EmbeddingService()

    private init() {}

    // MARK: - Embedding Generation

    /// Text'i embedding vector'üne çevir
    /// Şimdilik basit TF-IDF benzeri yaklaşım, sonra Claude/OpenAI API'ye geçilebilir
    func generateEmbedding(for text: String) async throws -> [Float] {
        // Normalize text
        let normalized = normalizeText(text)

        // Tokenize
        let tokens = tokenize(normalized)

        // Simple word embedding (bag of words with hashing)
        return await createSimpleEmbedding(from: tokens)
    }

    /// Batch embedding generation (birden fazla text için)
    func generateBatchEmbeddings(for texts: [String]) async throws -> [[Float]] {
        var embeddings: [[Float]] = []

        for text in texts {
            let embedding = try await generateEmbedding(for: text)
            embeddings.append(embedding)
        }

        return embeddings
    }

    /// UserKnowledge için embedding oluştur
    func generateEmbeddingForFact(_ fact: UserKnowledge) async throws -> [Float] {
        // Fact'in tüm içeriğini birleştir
        let fullText = "\(fact.categoryEnum.localizedName) \(fact.key) \(fact.value)"
        return try await generateEmbedding(for: fullText)
    }

    /// Tüm fact'ler için embedding oluştur (batch)
    func generateEmbeddingsForAllFacts(
        modelContext: ModelContext,
        forceRegenerate: Bool = false
    ) async throws -> Int {
        let descriptor = FetchDescriptor<UserKnowledge>(
            predicate: #Predicate { $0.isActive == true }
        )

        guard let facts = try? modelContext.fetch(descriptor) else {
            throw EmbeddingError.fetchFailed
        }

        var generatedCount = 0

        for fact in facts {
            // Eğer zaten embedding varsa ve force regenerate değilse skip
            if !forceRegenerate && fact.hasValidEmbedding {
                continue
            }

            do {
                let embedding = try await generateEmbeddingForFact(fact)
                fact.updateEmbedding(embedding, model: "simple-tfidf-v1")
                generatedCount += 1
            } catch {
                print("Failed to generate embedding for fact \(fact.id): \(error)")
            }
        }

        try? modelContext.save()
        return generatedCount
    }

    // MARK: - Text Processing

    private func normalizeText(_ text: String) -> String {
        // Lowercase
        var normalized = text.lowercased()

        // Remove punctuation
        let punctuation = CharacterSet.punctuationCharacters
        normalized = normalized.components(separatedBy: punctuation).joined(separator: " ")

        // Remove extra whitespace
        normalized = normalized.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return normalized
    }

    private func tokenize(_ text: String) -> [String] {
        // Split into words
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }

        // Remove stop words (Turkish + English)
        let stopWords = Set([
            // Turkish
            "bir", "bu", "şu", "o", "ve", "veya", "ile", "için", "da", "de",
            "den", "dan", "i", "ı", "u", "ü", "mi", "mı", "mu", "mü",
            // English
            "a", "an", "the", "and", "or", "but", "in", "on", "at", "to",
            "for", "of", "with", "by", "from", "is", "are", "was", "were"
        ])

        return words.filter { !stopWords.contains($0) }
    }

    private func createSimpleEmbedding(from tokens: [String]) async -> [Float] {
        // Fixed embedding dimension
        let dimension = 128
        var embedding = [Float](repeating: 0.0, count: dimension)

        // Simple hashing-based embedding
        for (index, token) in tokens.enumerated() {
            let hash = abs(token.hashValue)
            let position = hash % dimension

            // Add weighted value (earlier words get higher weight)
            let weight = 1.0 / Float(index + 1)
            embedding[position] += weight
        }

        // Normalize to unit vector
        let magnitude = sqrt(embedding.reduce(0.0) { $0 + $1 * $1 })

        if magnitude > 0 {
            embedding = embedding.map { $0 / magnitude }
        }

        return embedding
    }

    // MARK: - Similarity Calculation

    /// Cosine similarity between two embeddings
    func cosineSimilarity(_ vector1: [Float], _ vector2: [Float]) -> Float {
        guard vector1.count == vector2.count else {
            return 0.0
        }

        let dotProduct = zip(vector1, vector2).reduce(0.0) { $0 + $1.0 * $1.1 }
        let magnitude1 = sqrt(vector1.reduce(0.0) { $0 + $1 * $1 })
        let magnitude2 = sqrt(vector2.reduce(0.0) { $0 + $1 * $1 })

        guard magnitude1 > 0 && magnitude2 > 0 else {
            return 0.0
        }

        return dotProduct / (magnitude1 * magnitude2)
    }
}

// MARK: - Errors

enum EmbeddingError: LocalizedError {
    case fetchFailed
    case generationFailed(String)
    case invalidDimension

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "Failed to fetch facts from database"
        case .generationFailed(let reason):
            return "Embedding generation failed: \(reason)"
        case .invalidDimension:
            return "Invalid embedding dimension"
        }
    }
}

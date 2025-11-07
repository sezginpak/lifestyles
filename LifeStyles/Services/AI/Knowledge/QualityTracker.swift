//
//  QualityTracker.swift
//  LifeStyles
//
//  Created by AI Assistant on 05.11.2025.
//  UserKnowledge kalite takibi ve decay yönetimi
//

import Foundation
import SwiftData

/// Knowledge quality tracking servisi
@Observable
class QualityTracker {
    static let shared = QualityTracker()

    private init() {}

    // MARK: - Quality Metrics

    /// Tüm fact'lerin ortalama kalite skoru
    func calculateAverageQuality(modelContext: ModelContext) async -> Double {
        let descriptor = FetchDescriptor<UserKnowledge>(
            predicate: #Predicate { $0.isActive == true }
        )

        guard let facts = try? modelContext.fetch(descriptor) else {
            return 0.0
        }

        guard !facts.isEmpty else { return 0.0 }

        let totalQuality = facts.reduce(0.0) { $0 + $1.qualityScore }
        return totalQuality / Double(facts.count)
    }

    /// Kategori bazlı kalite skorları
    func calculateQualityByCategory(modelContext: ModelContext) async -> [KnowledgeCategory: Double] {
        let descriptor = FetchDescriptor<UserKnowledge>(
            predicate: #Predicate { $0.isActive == true }
        )

        guard let facts = try? modelContext.fetch(descriptor) else {
            return [:]
        }

        var categoryScores: [KnowledgeCategory: (total: Double, count: Int)] = [:]

        for fact in facts {
            let category = fact.categoryEnum
            let current = categoryScores[category] ?? (0.0, 0)
            categoryScores[category] = (current.total + fact.qualityScore, current.count + 1)
        }

        return categoryScores.mapValues { $0.total / Double($0.count) }
    }

    /// Düşük kaliteli fact'leri bul
    func findLowQualityFacts(
        modelContext: ModelContext,
        threshold: Double = 0.3
    ) async -> [UserKnowledge] {
        let descriptor = FetchDescriptor<UserKnowledge>(
            predicate: #Predicate { fact in
                fact.isActive == true
            }
        )

        guard let facts = try? modelContext.fetch(descriptor) else {
            return []
        }

        return facts.filter { $0.qualityScore < threshold }
    }

    /// Kullanılmayan (stale) fact'leri bul
    func findStaleFacts(
        modelContext: ModelContext,
        daysThreshold: Int = 90
    ) async -> [UserKnowledge] {
        let descriptor = FetchDescriptor<UserKnowledge>(
            predicate: #Predicate { $0.isActive == true }
        )

        guard let facts = try? modelContext.fetch(descriptor) else {
            return []
        }

        let thresholdDate = Date().addingTimeInterval(-Double(daysThreshold) * 86400)

        return facts.filter { fact in
            if let lastUsed = fact.lastUsedAt {
                return lastUsed < thresholdDate
            } else {
                return fact.createdAt < thresholdDate
            }
        }
    }

    // MARK: - Decay Management

    /// Tüm fact'lere decay uygula
    func applyDecayToAll(
        modelContext: ModelContext,
        decayDays: Int = 90
    ) async -> Int {
        let descriptor = FetchDescriptor<UserKnowledge>(
            predicate: #Predicate { $0.isActive == true }
        )

        guard let facts = try? modelContext.fetch(descriptor) else {
            return 0
        }

        var decayedCount = 0

        for fact in facts {
            let decayedConfidence = fact.calculateDecayedConfidence(decayDays: decayDays)

            // Eğer decay uygulandıysa güncelle
            if decayedConfidence < fact.confidence {
                fact.confidence = decayedConfidence
                decayedCount += 1

                // Çok düşükse deaktive et
                if decayedConfidence < 0.2 {
                    fact.deactivate()
                }
            }
        }

        try? modelContext.save()
        return decayedCount
    }

    /// Belirli bir fact'e decay uygula
    func applyDecay(
        to fact: UserKnowledge,
        decayDays: Int = 90
    ) -> Bool {
        let decayedConfidence = fact.calculateDecayedConfidence(decayDays: decayDays)

        if decayedConfidence < fact.confidence {
            fact.confidence = decayedConfidence

            // Çok düşükse deaktive et
            if decayedConfidence < 0.2 {
                fact.deactivate()
            }

            return true
        }

        return false
    }

    // MARK: - Auto Cleanup

    /// Otomatik temizlik: Düşük kaliteli ve eski fact'leri temizle
    func autoCleanup(
        modelContext: ModelContext,
        qualityThreshold: Double = 0.2,
        staleDaysThreshold: Int = 180
    ) async -> CleanupResult {
        var result = CleanupResult()

        // 1. Çok düşük kaliteli fact'leri deaktive et
        let lowQuality = await findLowQualityFacts(
            modelContext: modelContext,
            threshold: qualityThreshold
        )

        for fact in lowQuality {
            if fact.confidence < qualityThreshold {
                fact.deactivate()
                result.lowQualityRemoved += 1
            }
        }

        // 2. Çok eski ve kullanılmayan fact'leri deaktive et
        let stale = await findStaleFacts(
            modelContext: modelContext,
            daysThreshold: staleDaysThreshold
        )

        for fact in stale {
            if !lowQuality.contains(where: { $0.id == fact.id }) {
                fact.deactivate()
                result.staleRemoved += 1
            }
        }

        // 3. Negative feedback alan fact'leri deaktive et
        let descriptor = FetchDescriptor<UserKnowledge>(
            predicate: #Predicate { fact in
                fact.isActive == true &&
                fact.userFeedback != nil
            }
        )

        if let facts = try? modelContext.fetch(descriptor) {
            for fact in facts {
                if fact.userFeedback == UserFeedback.incorrect.rawValue ||
                   fact.userFeedback == UserFeedback.outdated.rawValue {
                    fact.deactivate()
                    result.negativeFeedbackRemoved += 1
                }
            }
        }

        try? modelContext.save()
        return result
    }

    // MARK: - Quality Stats

    /// Detaylı kalite istatistikleri
    func generateQualityStats(modelContext: ModelContext) async -> QualityStats {
        let descriptor = FetchDescriptor<UserKnowledge>(
            predicate: #Predicate { $0.isActive == true }
        )

        guard let facts = try? modelContext.fetch(descriptor) else {
            return QualityStats()
        }

        var stats = QualityStats()
        stats.totalFacts = facts.count

        // Quality distribution
        for fact in facts {
            let quality = fact.qualityScore
            if quality >= 0.8 {
                stats.highQuality += 1
            } else if quality >= 0.5 {
                stats.mediumQuality += 1
            } else {
                stats.lowQuality += 1
            }

            // Accuracy stats
            let totalUses = fact.successfulUses + fact.failedUses
            if totalUses > 0 {
                stats.totalAccuracyChecks += totalUses
                stats.successfulUses += fact.successfulUses
            }

            // Feedback stats
            if fact.userFeedback != nil {
                stats.withFeedback += 1
            }

            // Version stats
            stats.totalVersions += fact.versionCount
        }

        // Calculate averages
        stats.averageQuality = await calculateAverageQuality(modelContext: modelContext)
        stats.categoryQuality = await calculateQualityByCategory(modelContext: modelContext)

        if stats.totalAccuracyChecks > 0 {
            stats.overallAccuracy = Double(stats.successfulUses) / Double(stats.totalAccuracyChecks)
        }

        return stats
    }
}

// MARK: - Supporting Types

/// Cleanup sonuçları
struct CleanupResult {
    var lowQualityRemoved: Int = 0
    var staleRemoved: Int = 0
    var negativeFeedbackRemoved: Int = 0

    var totalRemoved: Int {
        lowQualityRemoved + staleRemoved + negativeFeedbackRemoved
    }
}

/// Kalite istatistikleri
struct QualityStats {
    var totalFacts: Int = 0
    var highQuality: Int = 0      // >= 0.8
    var mediumQuality: Int = 0    // 0.5-0.8
    var lowQuality: Int = 0       // < 0.5

    var averageQuality: Double = 0.0
    var categoryQuality: [KnowledgeCategory: Double] = [:]

    var totalAccuracyChecks: Int = 0
    var successfulUses: Int = 0
    var overallAccuracy: Double = 0.0

    var withFeedback: Int = 0
    var totalVersions: Int = 0

    var highQualityPercentage: Int {
        guard totalFacts > 0 else { return 0 }
        return Int((Double(highQuality) / Double(totalFacts)) * 100)
    }

    var lowQualityPercentage: Int {
        guard totalFacts > 0 else { return 0 }
        return Int((Double(lowQuality) / Double(totalFacts)) * 100)
    }
}

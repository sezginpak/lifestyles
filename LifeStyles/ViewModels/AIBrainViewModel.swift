//
//  AIBrainViewModel.swift
//  LifeStyles
//
//  Created by AI Assistant on 04.11.2025.
//  AI Brain - Knowledge management ViewModel
//

import Foundation
import SwiftData

/// AI Brain view model
@Observable
class AIBrainViewModel {
    // State
    var knowledge: [UserKnowledge] = []
    var filteredKnowledge: [UserKnowledge] = []
    var searchText: String = "" {
        didSet {
            applyFilters()
        }
    }
    var selectedCategory: KnowledgeCategory? = nil {
        didSet {
            applyFilters()
        }
    }
    var sortOrder: SortOrder = .recentFirst {
        didSet {
            applySort()
        }
    }

    // Loading states
    var isLoading = false
    var error: String?

    // Statistics
    var stats: KnowledgeStats = .empty

    // Services
    private let privacyManager = KnowledgePrivacyManager.shared

    // MARK: - Data Loading

    /// Tüm knowledge'ları yükle
    func loadKnowledge(context: ModelContext) {
        isLoading = true
        error = nil

        do {
            let descriptor = FetchDescriptor<UserKnowledge>(
                predicate: #Predicate { $0.isActive == true },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )

            knowledge = try context.fetch(descriptor)
            filteredKnowledge = knowledge

            // Privacy filter uygula
            if !privacyManager.isLearningEnabled {
                filteredKnowledge = []
            } else {
                filteredKnowledge = privacyManager.filterKnowledge(filteredKnowledge)
            }

            applyFilters()
            calculateStats()

            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    /// Refresh
    func refresh(context: ModelContext) {
        loadKnowledge(context: context)
    }

    // MARK: - Filtering & Search

    /// Filtreleri uygula
    private func applyFilters() {
        var results = knowledge

        // Privacy filter
        results = privacyManager.filterKnowledge(results)

        // Category filter
        if let category = selectedCategory {
            results = results.filter { $0.categoryEnum == category }
        }

        // Search filter
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            results = results.filter { fact in
                fact.key.lowercased().contains(searchLower) ||
                fact.value.lowercased().contains(searchLower) ||
                fact.categoryEnum.localizedName.lowercased().contains(searchLower)
            }
        }

        filteredKnowledge = results
        applySort()
    }

    /// Sıralama uygula
    private func applySort() {
        switch sortOrder {
        case .recentFirst:
            filteredKnowledge.sort { $0.createdAt > $1.createdAt }
        case .oldestFirst:
            filteredKnowledge.sort { $0.createdAt < $1.createdAt }
        case .highConfidence:
            filteredKnowledge.sort { $0.confidence > $1.confidence }
        case .lowConfidence:
            filteredKnowledge.sort { $0.confidence < $1.confidence }
        case .mostUsed:
            filteredKnowledge.sort { $0.timesReferenced > $1.timesReferenced }
        case .alphabetical:
            filteredKnowledge.sort { $0.key.lowercased() < $1.key.lowercased() }
        }
    }

    // MARK: - Category Grouping

    /// Kategoriye göre grupla
    func groupedByCategory() -> [KnowledgeCategory: [UserKnowledge]] {
        var grouped: [KnowledgeCategory: [UserKnowledge]] = [:]

        for fact in filteredKnowledge {
            if grouped[fact.categoryEnum] == nil {
                grouped[fact.categoryEnum] = []
            }
            grouped[fact.categoryEnum]?.append(fact)
        }

        return grouped
    }

    /// Kategori için count
    func count(for category: KnowledgeCategory) -> Int {
        filteredKnowledge.filter { $0.categoryEnum == category }.count
    }

    // MARK: - CRUD Operations

    /// Knowledge sil
    func delete(_ knowledge: UserKnowledge, context: ModelContext) {
        // Soft delete (deactivate)
        knowledge.deactivate()

        do {
            try context.save()
            loadKnowledge(context: context)
        } catch {
            self.error = "Silme hatası: \(error.localizedDescription)"
        }
    }

    /// Knowledge onayla (güven artır)
    func confirm(_ knowledge: UserKnowledge, context: ModelContext) {
        knowledge.increaseConfidence()

        do {
            try context.save()
            loadKnowledge(context: context)
        } catch {
            self.error = "Onaylama hatası: \(error.localizedDescription)"
        }
    }

    /// Knowledge'ı düzenle
    func update(
        _ knowledge: UserKnowledge,
        newValue: String,
        context: ModelContext
    ) {
        knowledge.value = newValue
        knowledge.lastConfirmedAt = Date()

        do {
            try context.save()
            loadKnowledge(context: context)
        } catch {
            self.error = "Güncelleme hatası: \(error.localizedDescription)"
        }
    }

    /// Tümünü sil
    func deleteAll(context: ModelContext) {
        do {
            // Tüm active knowledge'ları al
            let descriptor = FetchDescriptor<UserKnowledge>(
                predicate: #Predicate { $0.isActive == true }
            )

            let allKnowledge = try context.fetch(descriptor)

            // Soft delete
            for fact in allKnowledge {
                fact.deactivate()
            }

            try context.save()
            loadKnowledge(context: context)
        } catch {
            self.error = "Toplu silme hatası: \(error.localizedDescription)"
        }
    }

    /// Auto cleanup (eski kayıtları temizle)
    func performAutoCleanup(context: ModelContext) {
        do {
            let descriptor = FetchDescriptor<UserKnowledge>(
                predicate: #Predicate { $0.isActive == true }
            )

            let allKnowledge = try context.fetch(descriptor)
            var cleanedCount = 0

            for fact in allKnowledge {
                if privacyManager.shouldAutoCleanup(for: fact) {
                    fact.deactivate()
                    cleanedCount += 1
                }
            }

            if cleanedCount > 0 {
                try context.save()
                loadKnowledge(context: context)
            }

            print("🗑️ Auto cleanup: \(cleanedCount) fact temizlendi")
        } catch {
            self.error = "Auto cleanup hatası: \(error.localizedDescription)"
        }
    }

    // MARK: - Statistics

    /// İstatistikleri hesapla
    private func calculateStats() {
        let total = knowledge.count
        let active = filteredKnowledge.count

        // Confidence average
        let avgConfidence = knowledge.isEmpty ? 0.0 :
            knowledge.reduce(0.0) { $0 + $1.confidence } / Double(knowledge.count)

        // Category diversity
        let categories = Set(knowledge.map { $0.categoryEnum })

        // Most used
        let mostUsed = knowledge.max(by: { $0.timesReferenced < $1.timesReferenced })

        // Recent (last 7 days)
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentCount = knowledge.filter { $0.createdAt > sevenDaysAgo }.count

        stats = KnowledgeStats(
            totalFacts: total,
            activeFacts: active,
            averageConfidence: avgConfidence,
            categoryCount: categories.count,
            mostUsedKey: mostUsed?.key,
            mostUsedCount: mostUsed?.timesReferenced ?? 0,
            recentFactsCount: recentCount
        )
    }

    /// Kategori bazlı stats
    func getCategoryStats() -> [CategoryStat] {
        var stats: [CategoryStat] = []

        for category in KnowledgeCategory.allCases {
            let facts = knowledge.filter { $0.categoryEnum == category }

            if !facts.isEmpty {
                let avgConfidence = facts.reduce(0.0) { $0 + $1.confidence } / Double(facts.count)

                stats.append(CategoryStat(
                    category: category,
                    count: facts.count,
                    averageConfidence: avgConfidence
                ))
            }
        }

        return stats.sorted { $0.count > $1.count }
    }

    // MARK: - Export

    /// JSON olarak export et
    func exportToJSON() -> String? {
        let exportData = knowledge.map { fact in
            [
                "id": fact.id.uuidString,
                "category": fact.category,
                "key": fact.key,
                "value": fact.value,
                "confidence": fact.confidence,
                "source": fact.source,
                "createdAt": ISO8601DateFormatter().string(from: fact.createdAt),
                "timesReferenced": fact.timesReferenced
            ]
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }

        return jsonString
    }
}

// MARK: - Supporting Types

enum SortOrder: String, CaseIterable {
    case recentFirst = "En Yeni"
    case oldestFirst = "En Eski"
    case highConfidence = "Yüksek Güven"
    case lowConfidence = "Düşük Güven"
    case mostUsed = "En Çok Kullanılan"
    case alphabetical = "Alfabetik"

    var systemImage: String {
        switch self {
        case .recentFirst: return "arrow.down"
        case .oldestFirst: return "arrow.up"
        case .highConfidence: return "star.fill"
        case .lowConfidence: return "star"
        case .mostUsed: return "chart.bar.fill"
        case .alphabetical: return "textformat"
        }
    }
}

struct KnowledgeStats {
    let totalFacts: Int
    let activeFacts: Int
    let averageConfidence: Double
    let categoryCount: Int
    let mostUsedKey: String?
    let mostUsedCount: Int
    let recentFactsCount: Int

    static var empty: KnowledgeStats {
        KnowledgeStats(
            totalFacts: 0,
            activeFacts: 0,
            averageConfidence: 0,
            categoryCount: 0,
            mostUsedKey: nil,
            mostUsedCount: 0,
            recentFactsCount: 0
        )
    }

    var confidencePercentage: Int {
        Int(averageConfidence * 100)
    }

    var description: String {
        """
        📊 Knowledge Stats:
        • Total: \(totalFacts) facts
        • Active: \(activeFacts) facts
        • Avg Confidence: \(confidencePercentage)%
        • Categories: \(categoryCount)
        • Most Used: \(mostUsedKey ?? "N/A") (\(mostUsedCount)x)
        • Recent (7d): \(recentFactsCount)
        """
    }
}

struct CategoryStat {
    let category: KnowledgeCategory
    let count: Int
    let averageConfidence: Double

    var confidencePercentage: Int {
        Int(averageConfidence * 100)
    }
}

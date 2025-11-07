//
//  ConflictResolver.swift
//  LifeStyles
//
//  Created by AI Assistant on 05.11.2025.
//  Çelişen fact'leri tespit edip çözümler
//

import Foundation
import SwiftData

/// Fact conflict detection ve resolution servisi
@Observable
class ConflictResolver {
    static let shared = ConflictResolver()

    private init() {}

    // MARK: - Conflict Detection

    /// Çelişen fact'leri bul
    func detectConflicts(modelContext: ModelContext) async -> [FactConflict] {
        let descriptor = FetchDescriptor<UserKnowledge>(
            predicate: #Predicate { $0.isActive == true }
        )

        guard let facts = try? modelContext.fetch(descriptor) else {
            return []
        }

        var conflicts: [FactConflict] = []

        // Aynı key'e sahip farklı value'lar
        let groupedByKey = Dictionary(grouping: facts) { $0.key }

        for (key, factsWithKey) in groupedByKey where factsWithKey.count > 1 {
            // Farklı value'lar var mı?
            let uniqueValues = Set(factsWithKey.map { $0.value })

            if uniqueValues.count > 1 {
                let conflict = FactConflict(
                    key: key,
                    conflictingFacts: factsWithKey,
                    conflictType: .differentValues
                )
                conflicts.append(conflict)
            }
        }

        // Zıt tercihler (likes vs dislikes)
        conflicts.append(contentsOf: detectPreferenceConflicts(facts: facts))

        return conflicts
    }

    /// Tercih çelişkilerini bul (likes vs dislikes)
    private func detectPreferenceConflicts(facts: [UserKnowledge]) -> [FactConflict] {
        var conflicts: [FactConflict] = []

        let preferences = facts.filter { $0.categoryEnum == .preferences }

        // "likes_X" vs "dislikes_X" kontrolü
        for likeFact in preferences where likeFact.key.hasPrefix("likes_") {
            let item = likeFact.key.replacingOccurrences(of: "likes_", with: "")
            let dislikeKey = "dislikes_\(item)"

            if let dislikeFact = preferences.first(where: { $0.key == dislikeKey }) {
                let conflict = FactConflict(
                    key: item,
                    conflictingFacts: [likeFact, dislikeFact],
                    conflictType: .oppositePreferences
                )
                conflicts.append(conflict)
            }
        }

        return conflicts
    }

    // MARK: - Conflict Resolution

    /// Çelişkiyi çöz (en yüksek quality score kazanır)
    func resolveConflict(
        _ conflict: FactConflict,
        resolution: ConflictResolution,
        modelContext: ModelContext
    ) async {
        switch resolution {
        case .keepHighestQuality:
            // En yüksek quality score'a sahip olanı tut, diğerlerini deaktive et
            let sorted = conflict.conflictingFacts.sorted {
                $0.qualityScore > $1.qualityScore
            }

            guard let winner = sorted.first else { return }

            for fact in sorted.dropFirst() {
                fact.deactivate()
            }

            // Winner'ı confirm et
            winner.increaseConfidence(by: 0.1)

        case .keepMostRecent:
            // En son oluşturulanı tut
            let sorted = conflict.conflictingFacts.sorted {
                $0.createdAt > $1.createdAt
            }

            guard let winner = sorted.first else { return }

            for fact in sorted.dropFirst() {
                // Eski fact'i version olarak kaydet
                winner.createVersion(
                    oldValue: fact.value,
                    modelContext: modelContext
                )
                fact.deactivate()
            }

        case .merge:
            // Fact'leri birleştir (value'ları concat)
            guard let first = conflict.conflictingFacts.first else { return }

            let mergedValue = conflict.conflictingFacts
                .map { $0.value }
                .joined(separator: " / ")

            // İlkini güncelle
            first.value = mergedValue
            first.increaseConfidence(by: 0.1)

            // Diğerlerini deaktive et
            for fact in conflict.conflictingFacts.dropFirst() {
                fact.deactivate()
            }

        case .keepBoth:
            // Her ikisini de tut (kullanıcı manuel çözecek)
            break
        }

        try? modelContext.save()
    }

    /// Otomatik çözümleme (tüm conflict'leri quality-based çöz)
    func autoResolveAll(modelContext: ModelContext) async -> Int {
        let conflicts = await detectConflicts(modelContext: modelContext)

        for conflict in conflicts {
            await resolveConflict(
                conflict,
                resolution: .keepHighestQuality,
                modelContext: modelContext
            )
        }

        return conflicts.count
    }
}

// MARK: - Supporting Types

/// Fact çelişkisi
struct FactConflict: Identifiable {
    let id = UUID()
    let key: String
    let conflictingFacts: [UserKnowledge]
    let conflictType: ConflictType

    var description: String {
        switch conflictType {
        case .differentValues:
            let values = conflictingFacts.map { "\"\($0.value)\"" }.joined(separator: " vs ")
            return "\(key): \(values)"

        case .oppositePreferences:
            return "Zıt tercihler: \(key)"
        }
    }
}

/// Çelişki tipi
enum ConflictType {
    case differentValues       // Aynı key, farklı value
    case oppositePreferences   // likes vs dislikes

    var localizedName: String {
        switch self {
        case .differentValues:
            return "Farklı Değerler"
        case .oppositePreferences:
            return "Zıt Tercihler"
        }
    }
}

/// Çelişki çözüm stratejisi
enum ConflictResolution {
    case keepHighestQuality    // En yüksek quality score
    case keepMostRecent        // En yeni
    case merge                 // Birleştir
    case keepBoth              // İkisini de tut

    var localizedName: String {
        switch self {
        case .keepHighestQuality:
            return "En Güveniliri Tut"
        case .keepMostRecent:
            return "En Yeniyi Tut"
        case .merge:
            return "Birleştir"
        case .keepBoth:
            return "İkisini de Tut"
        }
    }
}

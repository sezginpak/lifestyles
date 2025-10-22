//
//  TagSuggestionService.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Journal tag önerileri ve analitik
//

import Foundation
import SwiftData

@Observable
class TagSuggestionService {
    static let shared = TagSuggestionService()

    private init() {}

    // MARK: - Predefined Tags

    /// Journal type'a göre önceden tanımlı tag'ler
    static let predefinedTags: [JournalType: [String]] = [
        .general: [
            "düşünceler", "günlük", "refleksyon", "anılar",
            "planlama", "hedefler", "fikirler", "notlar"
        ],
        .gratitude: [
            "minnettarlık", "şükür", "pozitif", "mutluluk",
            "aile", "arkadaşlar", "başarı", "sağlık"
        ],
        .achievement: [
            "başarı", "hedef", "tamamlandı", "gurur",
            "öğrenme", "gelişim", "ilerleme", "kazanım"
        ],
        .lesson: [
            "öğrenme", "ders", "tecrübe", "bilgi",
            "hata", "gelişim", "farkındalık", "kavrayış"
        ]
    ]

    // MARK: - Suggestion Generation

    /// Journal type ve mevcut tag'lere göre öneri üret
    func suggestTags(
        for journalType: JournalType,
        existingTags: [String],
        allEntries: [JournalEntry]
    ) -> [String] {
        var suggestions: [String] = []

        // 1. Journal type'a özel predefined tag'ler
        let typeTags = Self.predefinedTags[journalType] ?? []
        suggestions.append(contentsOf: typeTags.filter { !existingTags.contains($0) })

        // 2. Sık kullanılan tag'ler (bu type için)
        let typeEntries = allEntries.filter { $0.journalType == journalType }
        let frequentTags = getMostFrequentTags(from: typeEntries, limit: 5)
        suggestions.append(contentsOf: frequentTags.filter { !existingTags.contains($0) && !suggestions.contains($0) })

        // 3. Genel popüler tag'ler
        let popularTags = getMostFrequentTags(from: allEntries, limit: 3)
        suggestions.append(contentsOf: popularTags.filter { !existingTags.contains($0) && !suggestions.contains($0) })

        // Benzersiz yap ve ilk 10'u al
        return Array(Set(suggestions)).prefix(10).map { $0 }
    }

    /// En sık kullanılan tag'leri bul
    func getMostFrequentTags(from entries: [JournalEntry], limit: Int = 10) -> [String] {
        var tagCounts: [String: Int] = [:]

        // Tag'leri say
        for entry in entries {
            for tag in entry.tags {
                let normalizedTag = tag.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                tagCounts[normalizedTag, default: 0] += 1
            }
        }

        // Sıklığa göre sırala
        return tagCounts
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
    }

    // MARK: - Tag Statistics

    /// Tag istatistikleri hesapla
    func calculateTagStats(from entries: [JournalEntry]) -> [TagStat] {
        var tagCounts: [String: TagStat] = [:]

        for entry in entries {
            for tag in entry.tags {
                let normalizedTag = tag.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

                if var stat = tagCounts[normalizedTag] {
                    stat.count += 1
                    stat.lastUsed = max(stat.lastUsed, entry.date)
                    stat.entries.append(entry)
                    tagCounts[normalizedTag] = stat
                } else {
                    tagCounts[normalizedTag] = TagStat(
                        tag: normalizedTag,
                        count: 1,
                        lastUsed: entry.date,
                        entries: [entry]
                    )
                }
            }
        }

        return tagCounts.values.sorted { $0.count > $1.count }
    }

    // MARK: - Tag Cloud Data

    /// Tag cloud için veri hazırla (font size ile)
    func generateTagCloudData(from entries: [JournalEntry]) -> [TagCloudItem] {
        let stats = calculateTagStats(from: entries)
        guard !stats.isEmpty else { return [] }

        let maxCount = stats.first?.count ?? 1
        let minCount = stats.last?.count ?? 1

        return stats.map { stat in
            // Normalize size: 12-32 pt arası
            let normalizedSize = normalizeSize(
                count: stat.count,
                min: minCount,
                max: maxCount,
                targetMin: 12,
                targetMax: 32
            )

            return TagCloudItem(
                tag: stat.tag,
                count: stat.count,
                fontSize: normalizedSize,
                color: getColorForFrequency(count: stat.count, max: maxCount)
            )
        }
    }

    /// Size normalize et
    private func normalizeSize(count: Int, min: Int, max: Int, targetMin: Double, targetMax: Double) -> Double {
        guard max > min else { return targetMin }

        let normalized = Double(count - min) / Double(max - min)
        return targetMin + (normalized * (targetMax - targetMin))
    }

    /// Frekansa göre renk
    private func getColorForFrequency(count: Int, max: Int) -> String {
        let ratio = Double(count) / Double(max)

        if ratio > 0.7 {
            return "E74C3C" // Kırmızı (çok sık)
        } else if ratio > 0.4 {
            return "F39C12" // Turuncu (sık)
        } else if ratio > 0.2 {
            return "3498DB" // Mavi (orta)
        } else {
            return "95A5A6" // Gri (az)
        }
    }

    // MARK: - Smart Suggestions (Context Aware)

    /// İçerik bazlı akıllı tag önerisi (basit keyword matching)
    func suggestTagsFromContent(_ content: String) -> [String] {
        var suggestions: [String] = []

        let lowercased = content.lowercased()

        // Keyword mapping
        let keywords: [String: String] = [
            "aile": "aile",
            "anne": "aile",
            "baba": "aile",
            "iş": "iş",
            "çalış": "iş",
            "proje": "iş",
            "spor": "sağlık",
            "egzersiz": "sağlık",
            "yürü": "sağlık",
            "arkadaş": "sosyal",
            "buluş": "sosyal",
            "görüş": "sosyal",
            "öğren": "öğrenme",
            "kitap": "öğrenme",
            "ders": "öğrenme",
            "mutlu": "duygu",
            "üzgün": "duygu",
            "heyecan": "duygu",
            "seyahat": "seyahat",
            "tatil": "seyahat",
            "gezi": "seyahat"
        ]

        for (keyword, tag) in keywords {
            if lowercased.contains(keyword) && !suggestions.contains(tag) {
                suggestions.append(tag)
            }
        }

        return suggestions
    }
}

// MARK: - Supporting Structs

/// Tag istatistiği
struct TagStat: Identifiable {
    var id: String { tag }
    var tag: String
    var count: Int
    var lastUsed: Date
    var entries: [JournalEntry]

    /// Son kullanım formatı
    var lastUsedText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.localizedString(for: lastUsed, relativeTo: Date())
    }
}

/// Tag cloud item
struct TagCloudItem: Identifiable {
    var id: String { tag }
    var tag: String
    var count: Int
    var fontSize: Double
    var color: String
}

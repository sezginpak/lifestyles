//
//  JournalService.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Journal CRUD ve utility fonksiyonları
//

import Foundation
import SwiftData

@Observable
class JournalService {
    static let shared = JournalService()

    private init() {}

    // MARK: - CRUD Operations

    /// Journal entry oluştur
    func createEntry(
        content: String,
        journalType: JournalType,
        title: String? = nil,
        tags: [String] = [],
        moodEntry: MoodEntry? = nil,
        context: ModelContext
    ) {
        let entry = JournalEntry(
            title: title,
            content: content,
            journalType: journalType,
            tags: tags,
            moodEntry: moodEntry
        )

        context.insert(entry)

        do {
            try context.save()
            print("✅ Journal entry created: \(journalType.displayName)")
        } catch {
            print("❌ Failed to create journal entry: \(error)")
        }
    }

    /// Journal entry güncelle
    func updateEntry(
        _ entry: JournalEntry,
        content: String? = nil,
        title: String? = nil,
        tags: [String]? = nil,
        context: ModelContext
    ) {
        if let content = content {
            entry.content = content
        }
        if let title = title {
            entry.title = title
        }
        if let tags = tags {
            entry.tags = tags
        }

        entry.touch() // updatedAt güncelle

        do {
            try context.save()
            print("✅ Journal entry updated")
        } catch {
            print("❌ Failed to update journal entry: \(error)")
        }
    }

    /// Journal entry sil
    func deleteEntry(_ entry: JournalEntry, context: ModelContext) {
        context.delete(entry)

        do {
            try context.save()
            print("✅ Journal entry deleted")
        } catch {
            print("❌ Failed to delete journal entry: \(error)")
        }
    }

    // MARK: - Query Operations

    /// Tüm journal entry'leri çek
    func fetchAllEntries(context: ModelContext) -> [JournalEntry] {
        let descriptor = FetchDescriptor<JournalEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            print("❌ Failed to fetch journal entries: \(error)")
            return []
        }
    }

    /// Belirli bir type'daki entry'leri çek
    func fetchEntriesByType(_ type: JournalType, context: ModelContext) -> [JournalEntry] {
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { $0.journalTypeRaw == type.rawValue },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            print("❌ Failed to fetch journal entries by type: \(error)")
            return []
        }
    }

    /// Favori entry'leri çek
    func fetchFavoriteEntries(context: ModelContext) -> [JournalEntry] {
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { $0.isFavorite },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            print("❌ Failed to fetch favorite entries: \(error)")
            return []
        }
    }

    /// Arama (content, title, tags)
    func searchEntries(query: String, context: ModelContext) -> [JournalEntry] {
        let allEntries = fetchAllEntries(context: context)
        let lowercasedQuery = query.lowercased()

        return allEntries.filter { entry in
            entry.content.lowercased().contains(lowercasedQuery) ||
            (entry.title?.lowercased().contains(lowercasedQuery) ?? false) ||
            entry.tags.contains(where: { $0.lowercased().contains(lowercasedQuery) })
        }
    }

    // MARK: - Statistics

    /// Toplam entry sayısı
    func getTotalEntryCount(context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<JournalEntry>()
        return (try? context.fetchCount(descriptor)) ?? 0
    }

    /// Type'a göre sayı
    func getEntryCountByType(_ type: JournalType, context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { $0.journalTypeRaw == type.rawValue }
        )
        return (try? context.fetchCount(descriptor)) ?? 0
    }

    /// Bu hafta yazılan entry sayısı
    func getEntriesThisWeek(context: ModelContext) -> Int {
        let allEntries = fetchAllEntries(context: context)
        return allEntries.filter { $0.isThisWeek }.count
    }

    /// Toplam kelime sayısı
    func getTotalWordCount(context: ModelContext) -> Int {
        let allEntries = fetchAllEntries(context: context)
        return allEntries.reduce(0) { $0 + $1.wordCount }
    }

    // MARK: - Export

    /// Entry'leri text olarak export et
    func exportAsText(entries: [JournalEntry]) -> String {
        var text = "# LifeStyles Journal Export\n\n"
        text += "Export Date: \(Date().formatted())\n"
        text += "Total Entries: \(entries.count)\n\n"
        text += "---\n\n"

        for entry in entries.sorted(by: { $0.date > $1.date }) {
            text += "## \(entry.journalType.emoji) \(entry.title ?? entry.journalType.displayName)\n"
            text += "Date: \(entry.formattedDate)\n"
            text += "Type: \(entry.journalType.displayName)\n"
            if !entry.tags.isEmpty {
                text += "Tags: \(entry.tags.joined(separator: ", "))\n"
            }
            text += "\n\(entry.content)\n\n"
            text += "---\n\n"
        }

        return text
    }
}

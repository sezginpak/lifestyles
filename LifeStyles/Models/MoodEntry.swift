//
//  MoodEntry.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Günlük mood kayıtları
//

import Foundation
import SwiftData

@Model
final class MoodEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    var moodTypeRaw: String = "neutral"
    var intensity: Int = 3 // 1-5 arası (düşük-yüksek)
    var note: String? // Kısa not (optional)
    var createdAt: Date = Date()

    // İlişkiler
    @Relationship(deleteRule: .nullify, inverse: \Goal.relatedMoods)
    var relatedGoals: [Goal]?

    @Relationship(deleteRule: .nullify, inverse: \Friend.relatedMoods)
    var relatedFriends: [Friend]?

    @Relationship(deleteRule: .nullify, inverse: \LocationLog.relatedMood)
    var relatedLocation: LocationLog?

    @Relationship(deleteRule: .cascade, inverse: \JournalEntry.moodEntry)
    var journalEntry: JournalEntry?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        moodType: MoodType,
        intensity: Int = 3,
        note: String? = nil,
        createdAt: Date = Date(),
        relatedGoals: [Goal]? = nil,
        relatedFriends: [Friend]? = nil,
        relatedLocation: LocationLog? = nil
    ) {
        self.id = id
        self.date = date
        self.moodTypeRaw = moodType.rawValue
        self.intensity = intensity
        self.note = note
        self.createdAt = createdAt
        self.relatedGoals = relatedGoals
        self.relatedFriends = relatedFriends
        self.relatedLocation = relatedLocation
    }

    var moodType: MoodType {
        get { MoodType(rawValue: moodTypeRaw) ?? .neutral }
        set { moodTypeRaw = newValue.rawValue }
    }

    /// Günün başlangıcı (date'i normalize et)
    var dayStart: Date {
        Calendar.current.startOfDay(for: date)
    }

    /// Mood skoru (-2 ile +2 arası)
    var score: Double {
        moodType.score * (Double(intensity) / 3.0) // Intensity ile çarp
    }

    /// Formatlanmış tarih
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }

    /// Bugün mü?
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    /// Bu hafta mı?
    var isThisWeek: Bool {
        Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
    }

    /// Bu ay mı?
    var isThisMonth: Bool {
        Calendar.current.isDate(date, equalTo: Date(), toGranularity: .month)
    }
}

@Model
final class JournalEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    var title: String?
    var content: String = ""
    var journalTypeRaw: String = "general"
    var tags: [String] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var isFavorite: Bool = false

    // NEW: Image support
    var imageData: Data?
    var imageCaption: String?
    var imageThumbnailData: Data? // Compressed thumbnail

    // NEW: Markdown support
    var markdownContent: String?
    var hasMarkdown: Bool = false

    // NEW: Template support
    var templateId: UUID?

    // NEW: Sticker support (JSON encoded)
    var stickersData: Data?

    // İlişkiler
    @Relationship
    var moodEntry: MoodEntry?

    @Relationship(deleteRule: .nullify, inverse: \JournalTemplate.journals)
    var template: JournalTemplate?

    @Relationship(deleteRule: .nullify, inverse: \Memory.journalEntry)
    var memory: Memory?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        title: String? = nil,
        content: String,
        journalType: JournalType,
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isFavorite: Bool = false,
        moodEntry: MoodEntry? = nil,
        imageData: Data? = nil,
        imageCaption: String? = nil,
        imageThumbnailData: Data? = nil,
        markdownContent: String? = nil,
        hasMarkdown: Bool = false,
        templateId: UUID? = nil,
        template: JournalTemplate? = nil
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.content = content
        self.journalTypeRaw = journalType.rawValue
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isFavorite = isFavorite
        self.moodEntry = moodEntry
        self.imageData = imageData
        self.imageCaption = imageCaption
        self.imageThumbnailData = imageThumbnailData
        self.markdownContent = markdownContent
        self.hasMarkdown = hasMarkdown
        self.templateId = templateId
        self.template = template
    }

    var journalType: JournalType {
        get { JournalType(rawValue: journalTypeRaw) ?? .general }
        set { journalTypeRaw = newValue.rawValue }
    }

    /// Formatlanmış tarih
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }

    /// Kelime sayısı
    var wordCount: Int {
        content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }

    /// Okuma süresi (tahmini, dakika)
    var estimatedReadingTime: Int {
        max(1, wordCount / 200) // Ortalama 200 kelime/dakika
    }

    /// Preview metni (ilk 100 karakter)
    var preview: String {
        if content.count <= 100 {
            return content
        }
        return String(content.prefix(100)) + "..."
    }

    /// Bugün mü?
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    /// Bu hafta mı?
    var isThisWeek: Bool {
        Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
    }

    /// Bu ay mı?
    var isThisMonth: Bool {
        Calendar.current.isDate(date, equalTo: Date(), toGranularity: .month)
    }

    /// Toggle favorite
    func toggleFavorite() {
        isFavorite.toggle()
    }

    /// Update timestamp
    func touch() {
        updatedAt = Date()
    }

    /// Has image?
    var hasImage: Bool {
        imageData != nil
    }

    /// Has template?
    var hasTemplate: Bool {
        template != nil
    }

    /// Content to render (markdown varsa onu, yoksa plain text)
    var renderableContent: String {
        hasMarkdown ? (markdownContent ?? content) : content
    }

    /// Sticker'ları decode et
    var stickers: [StickerData] {
        get {
            guard let data = stickersData else { return [] }
            return (try? JSONDecoder().decode([StickerData].self, from: data)) ?? []
        }
        set {
            stickersData = try? JSONEncoder().encode(newValue)
        }
    }

    /// Has stickers?
    var hasStickers: Bool {
        !stickers.isEmpty
    }

    /// Add sticker
    func addSticker(_ sticker: StickerData) {
        var current = stickers
        guard current.count < 5 else { return } // Max 5 sticker
        current.append(sticker)
        stickers = current
        touch()
    }

    /// Remove sticker
    func removeSticker(id: UUID) {
        var current = stickers
        current.removeAll { $0.id == id }
        stickers = current
        touch()
    }
}

// MARK: - Sticker Data Model

/// Sticker data for journal entries
struct StickerData: Codable, Identifiable, Hashable {
    var id: UUID
    var emoji: String
    var position: CGPoint // Normalized (0.0 - 1.0)
    var scale: CGFloat    // 0.5 - 2.0
    var rotation: Double  // Degrees (0 - 360)

    init(
        id: UUID = UUID(),
        emoji: String,
        position: CGPoint = CGPoint(x: 0.5, y: 0.5),
        scale: CGFloat = 1.0,
        rotation: Double = 0.0
    ) {
        self.id = id
        self.emoji = emoji
        self.position = position
        self.scale = scale
        self.rotation = rotation
    }
}

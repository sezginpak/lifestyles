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
    var id: UUID
    var date: Date
    var moodTypeRaw: String
    var intensity: Int // 1-5 arası (düşük-yüksek)
    var note: String? // Kısa not (optional)
    var createdAt: Date

    // İlişkiler
    @Relationship(deleteRule: .nullify)
    var relatedGoals: [Goal]?

    @Relationship(deleteRule: .nullify)
    var relatedFriends: [Friend]?

    @Relationship(deleteRule: .nullify)
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
    var id: UUID
    var date: Date
    var title: String?
    var content: String
    var journalTypeRaw: String
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date
    var isFavorite: Bool

    // İlişkiler
    @Relationship
    var moodEntry: MoodEntry?

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
        moodEntry: MoodEntry? = nil
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
}

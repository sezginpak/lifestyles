//
//  ContactTag.swift
//  LifeStyles
//
//  Created by Claude on 03.11.2025.
//  Contact tagging system for categorizing interactions
//

import Foundation
import SwiftData

// MARK: - Contact Tag Model

@Model
final class ContactTag {
    var id: UUID = UUID()
    var name: String = ""
    var emoji: String? // Emoji gösterimi
    var colorRaw: String = "blue" // SF Symbols color name
    var categoryRaw: String = "general" // TagCategory enum
    var createdAt: Date = Date()
    var usageCount: Int = 0 // Kaç kez kullanıldı (analytics için)

    // Many-to-many relationship with ContactHistory
    @Relationship(deleteRule: .nullify)
    var contactHistories: [ContactHistory]?

    var category: TagCategory {
        get { TagCategory(rawValue: categoryRaw) ?? .general }
        set { categoryRaw = newValue.rawValue }
    }

    var color: String {
        get { colorRaw }
        set { colorRaw = newValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        emoji: String? = nil,
        color: String = "blue",
        category: TagCategory = .general,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.colorRaw = color
        self.categoryRaw = category.rawValue
        self.createdAt = createdAt
    }

    // Increment usage count
    func incrementUsage() {
        usageCount += 1
    }
}

// MARK: - Tag Category Enum

enum TagCategory: String, Codable, CaseIterable {
    case general = "general"
    case topic = "topic"         // Konuşulan konu (iş, aile, hobiler)
    case mood = "mood"           // Ruh hali (eğlenceli, ciddi, duygusal)
    case activity = "activity"   // Aktivite (kahve, yemek, spor)
    case priority = "priority"   // Öncelik (acil, önemli, rutin)
    case occasion = "occasion"   // Olay (kutlama, taziye, destek)

    var displayName: String {
        switch self {
        case .general: return String(localized: "tag.category.general", comment: "General")
        case .topic: return String(localized: "tag.category.topic", comment: "Topic")
        case .mood: return String(localized: "tag.category.mood", comment: "Mood")
        case .activity: return String(localized: "tag.category.activity", comment: "Activity")
        case .priority: return String(localized: "tag.category.priority", comment: "Priority")
        case .occasion: return String(localized: "tag.category.occasion", comment: "Occasion")
        }
    }

    var icon: String {
        switch self {
        case .general: return "tag.fill"
        case .topic: return "bubble.left.and.bubble.right.fill"
        case .mood: return "face.smiling"
        case .activity: return "figure.walk"
        case .priority: return "exclamationmark.triangle.fill"
        case .occasion: return "gift.fill"
        }
    }

    var color: String {
        switch self {
        case .general: return "gray"
        case .topic: return "blue"
        case .mood: return "purple"
        case .activity: return "green"
        case .priority: return "red"
        case .occasion: return "pink"
        }
    }
}

// MARK: - Predefined Tags Helper

extension ContactTag {
    // Önceden tanımlı tag'leri oluşturmak için helper
    static func createPredefinedTags() -> [ContactTag] {
        return [
            // Topic Tags
            ContactTag(name: "İş", emoji: "💼", color: "blue", category: .topic),
            ContactTag(name: "Aile", emoji: "👨‍👩‍👧‍👦", color: "blue", category: .topic),
            ContactTag(name: "Hobiler", emoji: "🎨", color: "blue", category: .topic),
            ContactTag(name: "Seyahat", emoji: "✈️", color: "blue", category: .topic),
            ContactTag(name: "Sağlık", emoji: "🏥", color: "blue", category: .topic),

            // Mood Tags
            ContactTag(name: "Eğlenceli", emoji: "😄", color: "purple", category: .mood),
            ContactTag(name: "Ciddi", emoji: "🧐", color: "purple", category: .mood),
            ContactTag(name: "Duygusal", emoji: "🥺", color: "purple", category: .mood),
            ContactTag(name: "Motivasyon", emoji: "💪", color: "purple", category: .mood),
            ContactTag(name: "Destekleyici", emoji: "🤗", color: "purple", category: .mood),

            // Activity Tags
            ContactTag(name: "Kahve", emoji: "☕", color: "green", category: .activity),
            ContactTag(name: "Yemek", emoji: "🍽️", color: "green", category: .activity),
            ContactTag(name: "Spor", emoji: "⚽", color: "green", category: .activity),
            ContactTag(name: "Sinema", emoji: "🎬", color: "green", category: .activity),
            ContactTag(name: "Müzik", emoji: "🎵", color: "green", category: .activity),

            // Priority Tags
            ContactTag(name: "Acil", emoji: "🚨", color: "red", category: .priority),
            ContactTag(name: "Önemli", emoji: "⭐", color: "red", category: .priority),
            ContactTag(name: "Rutin", emoji: "📅", color: "red", category: .priority),

            // Occasion Tags
            ContactTag(name: "Doğum Günü", emoji: "🎂", color: "pink", category: .occasion),
            ContactTag(name: "Kutlama", emoji: "🎉", color: "pink", category: .occasion),
            ContactTag(name: "Destek", emoji: "🤲", color: "pink", category: .occasion),
            ContactTag(name: "Taziye", emoji: "🕊️", color: "pink", category: .occasion)
        ]
    }
}

//
//  FriendEnums.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Refactored from Friend.swift - Supporting enums and types
//

//
//  Friend.swift
//  LifeStyles
//
//  Created by Claude on 15.10.2025.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Relationship Type

enum RelationshipType: String, CaseIterable, Codable {
    case friend = "friend"
    case partner = "partner"
    case family = "family"
    case colleague = "colleague"

    var displayName: String {
        switch self {
        case .friend: return String(localized: "relationship.type.friend", comment: "Friend relationship type")
        case .partner: return String(localized: "relationship.type.partner", comment: "Partner/romantic relationship type")
        case .family: return String(localized: "relationship.type.family", comment: "Family relationship type")
        case .colleague: return String(localized: "relationship.type.colleague", comment: "Colleague/work relationship type")
        }
    }

    var emoji: String {
        switch self {
        case .friend: return "👥"
        case .partner: return "💑"
        case .family: return "👨‍👩‍👧‍👦"
        case .colleague: return "💼"
        }
    }

    var color: String {
        switch self {
        case .friend: return "blue"
        case .partner: return "pink"
        case .family: return "green"
        case .colleague: return "purple"
        }
    }

    var accentColor: Color {
        switch self {
        case .friend: return .blue
        case .partner: return .pink
        case .family: return .green
        case .colleague: return .purple
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .partner:
            return [
                Color.pink.opacity(0.4),
                Color.red.opacity(0.3),
                Color.purple.opacity(0.2),
                Color.clear
            ]
        case .family:
            return [
                Color.green.opacity(0.4),
                Color.mint.opacity(0.3),
                Color.teal.opacity(0.2),
                Color.clear
            ]
        case .colleague:
            return [
                Color.purple.opacity(0.4),
                Color.indigo.opacity(0.3),
                Color.blue.opacity(0.2),
                Color.clear
            ]
        case .friend:
            return [
                Color.blue.opacity(0.4),
                Color.cyan.opacity(0.3),
                Color.teal.opacity(0.2),
                Color.clear
            ]
        }
    }
}

// MARK: - Love Language

enum LoveLanguage: String, CaseIterable, Codable {
    case wordsOfAffirmation = "words"
    case qualityTime = "time"
    case receivingGifts = "gifts"
    case actsOfService = "service"
    case physicalTouch = "touch"

    var displayName: String {
        switch self {
        case .wordsOfAffirmation: return String(localized: "love.language.words", comment: "Words of affirmation love language")
        case .qualityTime: return String(localized: "love.language.time", comment: "Quality time love language")
        case .receivingGifts: return String(localized: "love.language.gifts", comment: "Receiving gifts love language")
        case .actsOfService: return String(localized: "love.language.service", comment: "Acts of service love language")
        case .physicalTouch: return String(localized: "love.language.touch", comment: "Physical touch love language")
        }
    }

    var emoji: String {
        switch self {
        case .wordsOfAffirmation: return "💬"
        case .qualityTime: return "⏰"
        case .receivingGifts: return "🎁"
        case .actsOfService: return "🤝"
        case .physicalTouch: return "🤗"
        }
    }

    var description: String {
        switch self {
        case .wordsOfAffirmation: return String(localized: "love.language.words.description")
        case .qualityTime: return String(localized: "love.language.time.description")
        case .receivingGifts: return String(localized: "love.language.gifts.description")
        case .actsOfService: return String(localized: "love.language.service.description")
        case .physicalTouch: return String(localized: "love.language.touch.description")
        }
    }

    var detailedDescription: String {
        switch self {
        case .wordsOfAffirmation:
            return String(localized: "love.language.words.detailed")
        case .qualityTime:
            return String(localized: "love.language.time.detailed")
        case .receivingGifts:
            return String(localized: "love.language.gifts.detailed")
        case .actsOfService:
            return String(localized: "love.language.service.detailed")
        case .physicalTouch:
            return String(localized: "love.language.touch.detailed")
        }
    }

    var tips: [String] {
        switch self {
        case .wordsOfAffirmation:
            return [
                "💬 Her gün 'Seni seviyorum' deyin",
                "⭐ Başarılarını övün ve kutlayın",
                "📝 Sevgi notları yazın",
                "🎤 Herkese karşı övgüyle bahsedin",
                "💝 Nedensiz iltifat edin"
            ]
        case .qualityTime:
            return [
                "📱 Telefonu kapatın, tam odaklanın",
                "🚶‍♂️ Birlikte yürüyüşe çıkın",
                "☕ Kahve içerken sohbet edin",
                "🎮 Ortak aktiviteler yapın",
                "👀 Konuşurken göz teması kurun"
            ]
        case .receivingGifts:
            return [
                "🎁 Küçük sürprizler yapın",
                "🌹 Nedensiz çiçek alın",
                "📚 Sevdiği kitabı hediye edin",
                "🍫 En sevdiği atıştırmalıktan alın",
                "💍 Anlamlı hediyeler seçin"
            ]
        case .actsOfService:
            return [
                "☕ Kahve hazırlayın",
                "🧹 Ev işlerine yardım edin",
                "🍳 Yemek yapın",
                "🚗 Arabasını yıkayın",
                "📦 İşlerini halletmeye yardım edin"
            ]
        case .physicalTouch:
            return [
                "🤗 Sık sık sarılın",
                "✋ El ele tutuşun",
                "💆 Masaj yapın",
                "💋 Öpücük verin",
                "🛋️ Yakın oturun"
            ]
        }
    }
}

// MARK: - Partner Note Category

enum NoteCategory: String, CaseIterable, Codable {
    case favorite = "favorite"
    case hobby = "hobby"
    case dislike = "dislike"
    case important = "important"
    case other = "other"

    var displayName: String {
        switch self {
        case .favorite: return String(localized: "note.category.favorite", comment: "Favorite things category")
        case .hobby: return String(localized: "note.category.hobby", comment: "Hobbies category")
        case .dislike: return String(localized: "note.category.dislike", comment: "Dislikes category")
        case .important: return String(localized: "note.category.important", comment: "Important notes category")
        case .other: return String(localized: "note.category.other", comment: "Other notes category")
        }
    }

    var emoji: String {
        switch self {
        case .favorite: return "⭐"
        case .hobby: return "🎯"
        case .dislike: return "❌"
        case .important: return "❗"
        case .other: return "📝"
        }
    }

    var color: String {
        switch self {
        case .favorite: return "yellow"
        case .hobby: return "purple"
        case .dislike: return "red"
        case .important: return "orange"
        case .other: return "gray"
        }
    }
}

// MARK: - Partner Note

struct PartnerNote: Codable, Identifiable, Hashable {
    var id: UUID
    var category: NoteCategory
    var content: String
    var createdAt: Date

    init(id: UUID = UUID(), category: NoteCategory, content: String, createdAt: Date = Date()) {
        self.id = id
        self.category = category
        self.content = content
        self.createdAt = createdAt
    }
}

// MARK: - Contact Frequency

enum ContactFrequency: String, CaseIterable, Codable {
    case daily = "daily"           // Her gün
    case twoDays = "twoDays"       // 2 günde bir
    case threeDays = "threeDays"   // 3 günde bir
    case weekly = "weekly"         // Haftada bir
    case biweekly = "biweekly"     // 2 haftada bir
    case monthly = "monthly"       // Ayda bir
    case quarterly = "quarterly"   // 3 ayda bir
    case yearly = "yearly"         // Yılda bir

    var displayName: String {
        switch self {
        case .daily: return String(localized: "contact.frequency.daily", comment: "Contact frequency: every day")
        case .twoDays: return String(localized: "contact.frequency.twoDays", comment: "Contact frequency: every 2 days")
        case .threeDays: return String(localized: "contact.frequency.threeDays", comment: "Contact frequency: every 3 days")
        case .weekly: return String(localized: "contact.frequency.weekly", comment: "Contact frequency: weekly")
        case .biweekly: return String(localized: "contact.frequency.biweekly", comment: "Contact frequency: every 2 weeks")
        case .monthly: return String(localized: "contact.frequency.monthly", comment: "Contact frequency: monthly")
        case .quarterly: return String(localized: "contact.frequency.quarterly", comment: "Contact frequency: every 3 months")
        case .yearly: return String(localized: "contact.frequency.yearly", comment: "Contact frequency: yearly")
        }
    }

    var days: Int {
        switch self {
        case .daily: return 1
        case .twoDays: return 2
        case .threeDays: return 3
        case .weekly: return 7
        case .biweekly: return 14
        case .monthly: return 30
        case .quarterly: return 90
        case .yearly: return 365
        }
    }
    
    /// Sıklık kategorisine göre renk
    var color: String {
        switch self {
        case .daily, .twoDays: return "red"
        case .threeDays, .weekly: return "orange"
        case .biweekly, .monthly: return "blue"
        case .quarterly, .yearly: return "purple"
        }
    }
    
    /// Sıklık açıklaması
    var description: String {
        switch self {
        case .daily: return String(localized: "contact.frequency.daily.description")
        case .twoDays: return String(localized: "contact.frequency.twoDays.description")
        case .threeDays: return String(localized: "contact.frequency.threeDays.description")
        case .weekly: return String(localized: "contact.frequency.weekly.description")
        case .biweekly: return String(localized: "contact.frequency.biweekly.description")
        case .monthly: return String(localized: "contact.frequency.monthly.description")
        case .quarterly: return String(localized: "contact.frequency.quarterly.description")
        case .yearly: return String(localized: "contact.frequency.yearly.description")
        }
    }
    
    /// Kısa açıklama
    var shortDescription: String {
        switch self {
        case .daily: return String(localized: "contact.frequency.daily.short")
        case .twoDays: return String(localized: "contact.frequency.twoDays.short")
        case .threeDays: return String(localized: "contact.frequency.threeDays.short")
        case .weekly: return String(localized: "contact.frequency.weekly.short")
        case .biweekly: return String(localized: "contact.frequency.biweekly.short")
        case .monthly: return String(localized: "contact.frequency.monthly.short")
        case .quarterly: return String(localized: "contact.frequency.quarterly.short")
        case .yearly: return String(localized: "contact.frequency.yearly.short")
        }
    }
    
    /// Önerilen sıklıklar (en yaygın olanlar)
    static var recommended: [ContactFrequency] {
        return [.weekly, .biweekly, .monthly, .threeDays]
    }
    
    /// Tüm sıklıklar sıralı halde
    static var orderedCases: [ContactFrequency] {
        return [.daily, .twoDays, .threeDays, .weekly, .biweekly, .monthly, .quarterly, .yearly]
    }
}


//
//  ActivitySuggestion.swift
//  LifeStyles
//
//  Created by Claude on 15.10.2025.
//

import Foundation
import SwiftData

enum ActivityType: String, Codable {
    case outdoor = "outdoor"        // Dışarı çık
    case exercise = "exercise"      // Egzersiz yap
    case social = "social"          // Sosyalleş
    case learning = "learning"      // Öğren
    case creative = "creative"      // Yaratıcı
    case relax = "relax"           // Dinlen

    var displayName: String {
        switch self {
        case .outdoor: return String(localized: "activity.type.outdoor")
        case .exercise: return String(localized: "activity.type.exercise")
        case .social: return String(localized: "activity.type.social")
        case .learning: return String(localized: "activity.type.learning")
        case .creative: return String(localized: "activity.type.creative")
        case .relax: return String(localized: "activity.type.relax")
        }
    }

    var emoji: String {
        switch self {
        case .outdoor: return "🌳"
        case .exercise: return "🏃"
        case .social: return "👥"
        case .learning: return "📚"
        case .creative: return "🎨"
        case .relax: return "🧘"
        }
    }
}

// Aktivite önerisi kaynağı
enum ActivitySourceType: String, Codable {
    case ai = "ai"              // AI öneri
    case ruleBased = "rule"     // Kural bazlı (manuel)
    case friendBased = "friend" // Arkadaş bazlı
    case goalBased = "goal"     // Hedef bazlı
    case locationBased = "location" // Konum bazlı

    var displayName: String {
        switch self {
        case .ai: return String(localized: "activity.source.ai")
        case .ruleBased: return String(localized: "activity.source.ruleBased")
        case .friendBased: return String(localized: "activity.source.friendBased")
        case .goalBased: return String(localized: "activity.source.goalBased")
        case .locationBased: return String(localized: "activity.source.locationBased")
        }
    }

    var iconName: String {
        switch self {
        case .ai: return "sparkles"
        case .ruleBased: return "lightbulb.fill"
        case .friendBased: return "person.2.fill"
        case .goalBased: return "target"
        case .locationBased: return "location.fill"
        }
    }
}

@Model
final class ActivitySuggestion {
    var id: UUID
    var title: String
    var activityDescription: String
    var typeRaw: String
    var isCompleted: Bool
    var suggestedAt: Date
    var completedAt: Date?

    // Gamification özellikleri
    var completionPoints: Int
    var sourceTypeRaw: String
    var difficultyLevel: String // "easy", "medium", "hard"

    // Ek bilgiler
    var estimatedDuration: String?
    var scientificReason: String? // Bilgilendirici ton için

    // Yeni özellikler
    var isFavorite: Bool
    var timeOfDay: String? // "morning", "afternoon", "evening", "night"
    var viewCount: Int
    var lastViewedAt: Date?

    // İlişkiler
    @Relationship
    var relatedGoal: Goal?

    // Friend ilişkisi yerine UUID kullan (tip belirsizliği sorunu nedeniyle)
    var relatedFriendID: UUID?

    init(
        id: UUID = UUID(),
        title: String,
        activityDescription: String,
        type: ActivityType,
        isCompleted: Bool = false,
        suggestedAt: Date = Date(),
        completedAt: Date? = nil,
        completionPoints: Int = 10,
        sourceType: ActivitySourceType = .ruleBased,
        difficultyLevel: String = "easy",
        estimatedDuration: String? = nil,
        scientificReason: String? = nil,
        isFavorite: Bool = false,
        timeOfDay: String? = nil,
        viewCount: Int = 0,
        lastViewedAt: Date? = nil,
        relatedGoal: Goal? = nil,
        relatedFriendID: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.activityDescription = activityDescription
        self.typeRaw = type.rawValue
        self.isCompleted = isCompleted
        self.suggestedAt = suggestedAt
        self.completedAt = completedAt
        self.completionPoints = completionPoints
        self.sourceTypeRaw = sourceType.rawValue
        self.difficultyLevel = difficultyLevel
        self.estimatedDuration = estimatedDuration
        self.scientificReason = scientificReason
        self.isFavorite = isFavorite
        self.timeOfDay = timeOfDay
        self.viewCount = viewCount
        self.lastViewedAt = lastViewedAt
        self.relatedGoal = relatedGoal
        self.relatedFriendID = relatedFriendID
    }

    var type: ActivityType {
        get { ActivityType(rawValue: typeRaw) ?? .outdoor }
        set { typeRaw = newValue.rawValue }
    }

    var sourceType: ActivitySourceType {
        get { ActivitySourceType(rawValue: sourceTypeRaw) ?? .ruleBased }
        set { sourceTypeRaw = newValue.rawValue }
    }

    // Puan hesaplama (zorluk seviyesine göre)
    var calculatedPoints: Int {
        switch difficultyLevel {
        case "easy": return 10
        case "medium": return 25
        case "hard": return 50
        default: return 10
        }
    }

    // Zorluk emoji
    var difficultyEmoji: String {
        switch difficultyLevel {
        case "easy": return "⭐"
        case "medium": return "⭐⭐"
        case "hard": return "⭐⭐⭐"
        default: return "⭐"
        }
    }

    // Zorluk türkçe
    var difficultyDisplayName: String {
        switch difficultyLevel {
        case "easy": return "Kolay"
        case "medium": return "Orta"
        case "hard": return "Zor"
        default: return "Bilinmiyor"
        }
    }

    // Formatlanmış süre metni
    var formattedDuration: String {
        estimatedDuration ?? "Belirsiz"
    }

    // Aktiviteyi tamamla
    func complete() {
        isCompleted = true
        completedAt = Date()
    }

    // Favori toggle
    func toggleFavorite() {
        isFavorite.toggle()
    }

    // Görüntülenme kaydet
    func markAsViewed() {
        viewCount += 1
        lastViewedAt = Date()
    }

    // Zaman dilimi emoji
    var timeOfDayEmoji: String {
        switch timeOfDay {
        case "morning": return "🌅"
        case "afternoon": return "☀️"
        case "evening": return "🌙"
        case "night": return "✨"
        default: return ""
        }
    }

    // Zaman dilimi display
    var timeOfDayDisplay: String {
        switch timeOfDay {
        case "morning": return "Sabah"
        case "afternoon": return "Öğle"
        case "evening": return "Akşam"
        case "night": return "Gece"
        default: return ""
        }
    }
}

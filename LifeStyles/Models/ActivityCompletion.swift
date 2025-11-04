//
//  ActivityCompletion.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//

import Foundation
import SwiftData

@Model
final class ActivityCompletion {
    var id: UUID = UUID()
    var completedAt: Date = Date()
    var activityTitle: String = ""
    var activityDescription: String = ""
    var activityCategory: String = "other"
    var pointsEarned: Int = 0
    var currentStreak: Int = 0
    var streakBonusApplied: Bool = false
    var difficultyLevel: String = "easy"
    var notes: String?

    // İlişkili aktivite önerisi (opsiyonel)
    @Relationship(inverse: \ActivitySuggestion.completions)
    var relatedSuggestion: ActivitySuggestion?

    init(
        id: UUID = UUID(),
        completedAt: Date = Date(),
        activityTitle: String,
        activityDescription: String,
        activityCategory: String,
        pointsEarned: Int,
        currentStreak: Int = 0,
        streakBonusApplied: Bool = false,
        difficultyLevel: String = "easy",
        notes: String? = nil,
        relatedSuggestion: ActivitySuggestion? = nil
    ) {
        self.id = id
        self.completedAt = completedAt
        self.activityTitle = activityTitle
        self.activityDescription = activityDescription
        self.activityCategory = activityCategory
        self.pointsEarned = pointsEarned
        self.currentStreak = currentStreak
        self.streakBonusApplied = streakBonusApplied
        self.difficultyLevel = difficultyLevel
        self.notes = notes
        self.relatedSuggestion = relatedSuggestion
    }

    // Tamamlama günü
    var completionDay: Date {
        Calendar.current.startOfDay(for: completedAt)
    }

    // Formatlanmış tarih
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: completedAt)
    }

    // Kategori emoji
    var categoryEmoji: String {
        switch activityCategory {
        case "outdoor": return "🌳"
        case "exercise": return "🏃"
        case "social": return "👥"
        case "learning": return "📚"
        case "creative": return "🎨"
        case "relax": return "🧘"
        default: return "✨"
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

    // Zorluk türkçe isim
    var difficultyDisplayName: String {
        switch difficultyLevel {
        case "easy": return String(localized: "difficulty.easy")
        case "medium": return String(localized: "difficulty.medium")
        case "hard": return String(localized: "difficulty.hard")
        default: return String(localized: "difficulty.unknown")
        }
    }
}

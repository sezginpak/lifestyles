//
//  Goal.swift
//  LifeStyles
//
//  Created by Claude on 15.10.2025.
//

import Foundation
import SwiftData
import SwiftUI

enum GoalCategory: String, Codable {
    case health = "health"          // Sağlık
    case social = "social"          // Sosyal İlişkiler
    case career = "career"          // Kariyer
    case personal = "personal"      // Kişisel Gelişim
    case fitness = "fitness"        // Fitness
    case other = "other"

    var displayName: String {
        switch self {
        case .health: return String(localized: "goal.category.health", comment: "Health goal category")
        case .social: return String(localized: "goal.category.social", comment: "Social relationships goal category")
        case .career: return String(localized: "goal.category.career", comment: "Career goal category")
        case .personal: return String(localized: "goal.category.personal", comment: "Personal development goal category")
        case .fitness: return String(localized: "goal.category.fitness", comment: "Fitness goal category")
        case .other: return String(localized: "goal.category.other", comment: "Other goal category")
        }
    }

    var emoji: String {
        switch self {
        case .health: return "❤️"
        case .social: return "👥"
        case .career: return "💼"
        case .personal: return "🌱"
        case .fitness: return "🏃"
        case .other: return "📌"
        }
    }

    /// Ring progress için kategori rengi
    var ringColor: String {
        switch self {
        case .health: return "FF6B6B"       // Kırmızı
        case .social: return "4ECDC4"       // Turkuaz
        case .career: return "9B59B6"       // Mor
        case .personal: return "2ECC71"     // Yeşil
        case .fitness: return "FF9F43"      // Turuncu
        case .other: return "95A5A6"        // Gri
        }
    }

    /// SwiftUI Color objesi
    var color: Color {
        Color(hex: ringColor)
    }
}

enum GoalPriority: String, Codable {
    case high = "high"
    case medium = "medium"
    case low = "low"

    var displayName: String {
        switch self {
        case .high: return "Yüksek"
        case .medium: return "Orta"
        case .low: return "Düşük"
        }
    }

    var emoji: String {
        switch self {
        case .high: return "🔴"
        case .medium: return "🟡"
        case .low: return "🟢"
        }
    }
}

@Model
final class Goal {
    var id: UUID = UUID()
    var title: String = ""
    var goalDescription: String = ""
    var categoryRaw: String = "personal"
    var priorityRaw: String = "medium"
    var targetDate: Date = Date()
    var createdAt: Date = Date()
    var isCompleted: Bool = false
    var progress: Double = 0.0 // 0.0 - 1.0 arası
    var reminderEnabled: Bool = true
    var emoji: String? // Kullanıcı seçebilir (opsiyonel)

    @Relationship(deleteRule: .cascade)
    var milestones: [GoalMilestone]?

    @Relationship(deleteRule: .nullify)
    var relatedMoods: [MoodEntry]?

    @Relationship(deleteRule: .nullify)
    var relatedSuggestions: [ActivitySuggestion]?

    init(
        id: UUID = UUID(),
        title: String,
        goalDescription: String = "",
        category: GoalCategory = .personal,
        priority: GoalPriority = .medium,
        targetDate: Date,
        createdAt: Date = Date(),
        isCompleted: Bool = false,
        progress: Double = 0.0,
        reminderEnabled: Bool = true,
        emoji: String? = nil
    ) {
        self.id = id
        self.title = title
        self.goalDescription = goalDescription
        self.categoryRaw = category.rawValue
        self.priorityRaw = priority.rawValue
        self.targetDate = targetDate
        self.createdAt = createdAt
        self.isCompleted = isCompleted
        self.progress = progress
        self.reminderEnabled = reminderEnabled
        self.emoji = emoji
    }

    var category: GoalCategory {
        get { GoalCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var priority: GoalPriority {
        get { GoalPriority(rawValue: priorityRaw) ?? .medium }
        set { priorityRaw = newValue.rawValue }
    }

    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
    }

    var isOverdue: Bool {
        !isCompleted && targetDate < Date()
    }

    var progressPercentage: Int {
        Int(progress * 100)
    }

    /// Tamamlanan milestone sayısı
    var completedMilestonesCount: Int {
        milestones?.filter { $0.isCompleted }.count ?? 0
    }

    /// Toplam milestone sayısı
    var totalMilestonesCount: Int {
        milestones?.count ?? 0
    }

    /// Milestone bazlı progress (milestones varsa buna göre hesapla)
    var milestoneProgress: Double {
        guard let milestones = milestones, !milestones.isEmpty else {
            return progress
        }
        return Double(completedMilestonesCount) / Double(totalMilestonesCount)
    }

    /// Today's focus için öncelik sırası
    var focusScore: Int {
        var score = 0

        // Priority (30 puan)
        switch priority {
        case .high: score += 30
        case .medium: score += 15
        case .low: score += 5
        }

        // Deadline yakınlığı (40 puan)
        if daysRemaining <= 0 {
            score += 40 // Overdue
        } else if daysRemaining <= 3 {
            score += 30 // 3 gün kaldı
        } else if daysRemaining <= 7 {
            score += 20 // 1 hafta kaldı
        } else if daysRemaining <= 14 {
            score += 10 // 2 hafta kaldı
        }

        // Progress (30 puan - az ilerlemiş olanlara öncelik)
        if progress < 0.25 {
            score += 30
        } else if progress < 0.5 {
            score += 20
        } else if progress < 0.75 {
            score += 10
        }

        return score
    }
}

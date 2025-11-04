//
//  AcceptedSuggestion.swift
//  LifeStyles
//
//  Kabul edilen önerilerin takibi için model
//  Created by Claude on 31.10.2025.
//

import Foundation
import SwiftData

@Model
final class AcceptedSuggestion {
    var id: UUID
    var suggestionTitle: String
    var suggestionDescription: String
    var categoryRaw: String
    var acceptedDate: Date
    var convertedGoalId: UUID?
    var progress: Double // 0.0-1.0
    var isCompleted: Bool
    var isDismissed: Bool
    var lastProgressUpdate: Date

    init(
        id: UUID = UUID(),
        suggestionTitle: String,
        suggestionDescription: String,
        categoryRaw: String,
        acceptedDate: Date = Date(),
        convertedGoalId: UUID? = nil,
        progress: Double = 0.0,
        isCompleted: Bool = false,
        isDismissed: Bool = false,
        lastProgressUpdate: Date = Date()
    ) {
        self.id = id
        self.suggestionTitle = suggestionTitle
        self.suggestionDescription = suggestionDescription
        self.categoryRaw = categoryRaw
        self.acceptedDate = acceptedDate
        self.convertedGoalId = convertedGoalId
        self.progress = progress
        self.isCompleted = isCompleted
        self.isDismissed = isDismissed
        self.lastProgressUpdate = lastProgressUpdate
    }

    // Helper methods
    func updateProgress(_ newProgress: Double) {
        progress = min(max(newProgress, 0.0), 1.0)
        lastProgressUpdate = Date()

        if progress >= 1.0 {
            isCompleted = true
        }
    }

    func markCompleted() {
        progress = 1.0
        isCompleted = true
        lastProgressUpdate = Date()
    }

    func dismiss() {
        isDismissed = true
    }

    var category: GoalCategory {
        get { GoalCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
}

// MARK: - Convenience Init from GoalSuggestion

extension AcceptedSuggestion {
    convenience init(from suggestion: GoalSuggestion, convertedGoalId: UUID? = nil) {
        self.init(
            suggestionTitle: suggestion.title,
            suggestionDescription: suggestion.description,
            categoryRaw: suggestion.category.rawValue,
            convertedGoalId: convertedGoalId
        )
    }
}

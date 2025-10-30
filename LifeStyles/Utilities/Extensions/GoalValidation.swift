//
//  GoalValidation.swift
//  LifeStyles
//
//  Created by Claude on 25.10.2025.
//  Goal form validation helpers
//

import Foundation

struct GoalValidation {

    /// Validates goal title
    /// Returns nil if valid, error message if invalid
    static func validateTitle(_ title: String) -> String? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return String(localized: "goal.error.title.empty", comment: "Title cannot be empty")
        }

        if trimmed.count < 3 {
            return String(localized: "goal.error.title.too.short", comment: "Title must be at least 3 characters")
        }

        if trimmed.count > 100 {
            return String(localized: "goal.error.title.too.long", comment: "Title cannot exceed 100 characters")
        }

        return nil
    }

    /// Validates goal description
    /// Returns nil if valid, error message if invalid
    static func validateDescription(_ description: String) -> String? {
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.count > 500 {
            return String(localized: "goal.error.description.too.long", comment: "Description cannot exceed 500 characters")
        }

        return nil
    }

    /// Validates goal target date
    /// Returns nil if valid, error message if invalid
    static func validateDate(_ date: Date) -> String? {
        let today = Calendar.current.startOfDay(for: Date())
        let targetDay = Calendar.current.startOfDay(for: date)

        if targetDay < today {
            return String(localized: "goal.error.date.past", comment: "Target date cannot be in the past")
        }

        // Optional: Maximum date limit (e.g., 10 years from now)
        if let maxDate = Calendar.current.date(byAdding: .year, value: 10, to: today),
           targetDay > maxDate {
            return String(localized: "goal.error.date.too.far", comment: "Target date is too far in the future")
        }

        return nil
    }
}

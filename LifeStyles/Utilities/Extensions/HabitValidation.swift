//
//  HabitValidation.swift
//  LifeStyles
//
//  Created by Claude on 25.10.2025.
//  Habit form validation helpers
//

import Foundation

struct HabitValidation {

    /// Validates habit name
    /// Returns nil if valid, error message if invalid
    static func validateName(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return String(localized: "habit.error.name.empty", comment: "Name cannot be empty")
        }

        if trimmed.count < 2 {
            return String(localized: "habit.error.name.too.short", comment: "Name must be at least 2 characters")
        }

        if trimmed.count > 50 {
            return String(localized: "habit.error.name.too.long", comment: "Name cannot exceed 50 characters")
        }

        return nil
    }

    /// Validates habit target count
    /// Returns nil if valid, error message if invalid
    static func validateTargetCount(_ count: Int) -> String? {
        if count < 1 {
            return String(localized: "habit.error.target.too.low", comment: "Target must be at least 1")
        }

        if count > 1000 {
            return String(localized: "habit.error.target.too.high", comment: "Target cannot exceed 1000")
        }

        return nil
    }

    /// Validates habit description
    /// Returns nil if valid, error message if invalid
    static func validateDescription(_ description: String) -> String? {
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.count > 200 {
            return String(localized: "habit.error.description.too.long", comment: "Description cannot exceed 200 characters")
        }

        return nil
    }
}

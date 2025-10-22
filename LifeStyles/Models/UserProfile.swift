//
//  UserProfile.swift
//  LifeStyles
//
//  User Profile for Personalized AI Interactions
//  Created by Claude on 22.10.2025.
//

import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date

    // Basic Info
    var name: String?
    var age: Int?
    var occupation: String?

    // Personal Details
    var bio: String?
    var hobbies: [String]
    var interests: [String]

    // Lifestyle
    var workSchedule: String? // "9-5", "Flexible", "Night shift", etc.
    var livingArrangement: String? // "Alone", "With family", "Roommates", etc.

    // Goals & Values
    var lifeGoals: String? // Long-term aspirations
    var coreValues: [String] // "Family", "Career", "Health", etc.

    init(
        id: UUID = UUID(),
        name: String? = nil,
        age: Int? = nil,
        occupation: String? = nil,
        bio: String? = nil,
        hobbies: [String] = [],
        interests: [String] = [],
        workSchedule: String? = nil,
        livingArrangement: String? = nil,
        lifeGoals: String? = nil,
        coreValues: [String] = []
    ) {
        self.id = id
        self.createdAt = Date()
        self.updatedAt = Date()
        self.name = name
        self.age = age
        self.occupation = occupation
        self.bio = bio
        self.hobbies = hobbies
        self.interests = interests
        self.workSchedule = workSchedule
        self.livingArrangement = livingArrangement
        self.lifeGoals = lifeGoals
        self.coreValues = coreValues
    }

    // MARK: - Helper Methods

    var isComplete: Bool {
        name != nil && age != nil && occupation != nil
    }

    var completionPercentage: Double {
        var filledFields = 0
        let totalFields = 10

        if name != nil && !name!.isEmpty { filledFields += 1 }
        if age != nil { filledFields += 1 }
        if occupation != nil && !occupation!.isEmpty { filledFields += 1 }
        if bio != nil && !bio!.isEmpty { filledFields += 1 }
        if !hobbies.isEmpty { filledFields += 1 }
        if !interests.isEmpty { filledFields += 1 }
        if workSchedule != nil && !workSchedule!.isEmpty { filledFields += 1 }
        if livingArrangement != nil && !livingArrangement!.isEmpty { filledFields += 1 }
        if lifeGoals != nil && !lifeGoals!.isEmpty { filledFields += 1 }
        if !coreValues.isEmpty { filledFields += 1 }

        return Double(filledFields) / Double(totalFields)
    }

    func updateTimestamp() {
        self.updatedAt = Date()
    }
}

// MARK: - User Profile Snapshot (for AI Context)

struct UserProfileSnapshot: Codable {
    let name: String?
    let age: Int?
    let occupation: String?
    let bio: String?
    let hobbies: [String]
    let interests: [String]
    let workSchedule: String?
    let livingArrangement: String?
    let lifeGoals: String?
    let coreValues: [String]

    init(from profile: UserProfile) {
        self.name = profile.name
        self.age = profile.age
        self.occupation = profile.occupation
        self.bio = profile.bio
        self.hobbies = profile.hobbies
        self.interests = profile.interests
        self.workSchedule = profile.workSchedule
        self.livingArrangement = profile.livingArrangement
        self.lifeGoals = profile.lifeGoals
        self.coreValues = profile.coreValues
    }

    var isEmpty: Bool {
        name == nil &&
        age == nil &&
        occupation == nil &&
        bio == nil &&
        hobbies.isEmpty &&
        interests.isEmpty &&
        workSchedule == nil &&
        livingArrangement == nil &&
        lifeGoals == nil &&
        coreValues.isEmpty
    }

    var summary: String {
        var parts: [String] = []

        if let name = name, !name.isEmpty {
            parts.append("İsim: \(name)")
        }
        if let age = age {
            parts.append("\(age) yaşında")
        }
        if let occupation = occupation, !occupation.isEmpty {
            parts.append("Meslek: \(occupation)")
        }

        return parts.isEmpty ? "Profil boş" : parts.joined(separator: ", ")
    }
}

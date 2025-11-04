//
//  UserActivityState.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//

import Foundation
import SwiftData

// Kullanıcı enerji seviyesi
enum UserEnergyLevel: String, Codable {
    case energetic = "energetic"    // Enerjik
    case normal = "normal"          // Normal
    case tired = "tired"            // Yorgun

    var displayName: String {
        switch self {
        case .energetic: return String(localized: "energy.energetic")
        case .normal: return String(localized: "energy.normal")
        case .tired: return String(localized: "energy.tired")
        }
    }

    var emoji: String {
        switch self {
        case .energetic: return "⚡"
        case .normal: return "😊"
        case .tired: return "😴"
        }
    }
}

// Kullanıcı ruh hali
enum UserMood: String, Codable {
    case happy = "happy"
    case neutral = "neutral"
    case stressed = "stressed"
    case sad = "sad"

    var displayName: String {
        switch self {
        case .happy: return String(localized: "mood.happy")
        case .neutral: return String(localized: "mood.neutral")
        case .stressed: return String(localized: "mood.stressed")
        case .sad: return String(localized: "mood.sad")
        }
    }

    var emoji: String {
        switch self {
        case .happy: return "😊"
        case .neutral: return "😐"
        case .stressed: return "😰"
        case .sad: return "😢"
        }
    }
}

@Model
final class UserActivityState {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var energyLevelRaw: String = "normal"
    var moodRaw: String?
    var lastActivityTime: Date?
    var notes: String?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        energyLevel: UserEnergyLevel = .normal,
        mood: UserMood? = nil,
        lastActivityTime: Date? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.energyLevelRaw = energyLevel.rawValue
        self.moodRaw = mood?.rawValue
        self.lastActivityTime = lastActivityTime
        self.notes = notes
    }

    var energyLevel: UserEnergyLevel {
        get { UserEnergyLevel(rawValue: energyLevelRaw) ?? .normal }
        set { energyLevelRaw = newValue.rawValue }
    }

    var mood: UserMood? {
        get {
            guard let raw = moodRaw else { return nil }
            return UserMood(rawValue: raw)
        }
        set { moodRaw = newValue?.rawValue }
    }

    // Enerji seviyesine göre önerilen aktivite sayısı
    var recommendedActivityCount: Int {
        switch energyLevel {
        case .energetic: return 3
        case .normal: return 2
        case .tired: return 1
        }
    }

    // Son aktiviteden beri geçen süre (saat)
    var hoursSinceLastActivity: Double? {
        guard let lastActivity = lastActivityTime else { return nil }
        return Date().timeIntervalSince(lastActivity) / 3600
    }
}

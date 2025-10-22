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
        case .energetic: return "Enerjik"
        case .normal: return "Normal"
        case .tired: return "Yorgun"
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
        case .happy: return "Mutlu"
        case .neutral: return "Normal"
        case .stressed: return "Stresli"
        case .sad: return "Üzgün"
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
    var id: UUID
    var timestamp: Date
    var energyLevelRaw: String
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

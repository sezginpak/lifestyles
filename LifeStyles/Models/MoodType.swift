//
//  MoodType.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Mood tracking için duygusal durumlar
//

import Foundation
import SwiftUI

/// Kullanıcının duygusal durumu
enum MoodType: String, Codable, CaseIterable {
    case veryHappy = "very_happy"
    case happy = "happy"
    case neutral = "neutral"
    case sad = "sad"
    case angry = "angry"
    case anxious = "anxious"
    case excited = "excited"
    case tired = "tired"
    case grateful = "grateful"
    case stressed = "stressed"

    /// Emoji gösterimi
    var emoji: String {
        switch self {
        case .veryHappy: return "😄"
        case .happy: return "😊"
        case .neutral: return "😐"
        case .sad: return "😔"
        case .angry: return "😠"
        case .anxious: return "😰"
        case .excited: return "🤩"
        case .tired: return "😴"
        case .grateful: return "🙏"
        case .stressed: return "😫"
        }
    }

    /// Türkçe isim
    var displayName: String {
        switch self {
        case .veryHappy: return "Çok Mutlu"
        case .happy: return "Mutlu"
        case .neutral: return "Normal"
        case .sad: return "Üzgün"
        case .angry: return "Kızgın"
        case .anxious: return "Endişeli"
        case .excited: return "Heyecanlı"
        case .tired: return "Yorgun"
        case .grateful: return "Minnettar"
        case .stressed: return "Stresli"
        }
    }

    /// Renk kodu (hex)
    var colorHex: String {
        switch self {
        case .veryHappy: return "10B981"   // Parlak yeşil
        case .happy: return "84CC16"       // Lime
        case .neutral: return "94A3B8"     // Gri
        case .sad: return "3B82F6"         // Mavi
        case .angry: return "EF4444"       // Kırmızı
        case .anxious: return "F59E0B"     // Turuncu
        case .excited: return "EC4899"     // Pembe
        case .tired: return "6366F1"       // İndigo
        case .grateful: return "8B5CF6"    // Mor
        case .stressed: return "DC2626"    // Koyu kırmızı
        }
    }

    /// SwiftUI Color
    var color: Color {
        Color(hex: colorHex) ?? .gray
    }

    /// Numerik skor (analytics için: -2 ile +2 arası)
    var score: Double {
        switch self {
        case .veryHappy: return 2.0
        case .happy: return 1.5
        case .excited: return 1.0
        case .grateful: return 1.0
        case .neutral: return 0.0
        case .tired: return -0.5
        case .anxious: return -1.0
        case .sad: return -1.5
        case .stressed: return -1.5
        case .angry: return -2.0
        }
    }

    /// Pozitif mi?
    var isPositive: Bool {
        score > 0
    }

    /// Negatif mi?
    var isNegative: Bool {
        score < 0
    }
}

/// Journal entry tipleri
enum JournalType: String, Codable, CaseIterable {
    case general = "general"
    case gratitude = "gratitude"
    case achievement = "achievement"
    case lesson = "lesson"

    var displayName: String {
        switch self {
        case .general: return "Genel"
        case .gratitude: return "Minnettar"
        case .achievement: return "Başarı"
        case .lesson: return "Ders"
        }
    }

    var icon: String {
        switch self {
        case .general: return "pencil"
        case .gratitude: return "hands.sparkles"
        case .achievement: return "trophy.fill"
        case .lesson: return "lightbulb.fill"
        }
    }

    var emoji: String {
        switch self {
        case .general: return "📝"
        case .gratitude: return "🙏"
        case .achievement: return "🏆"
        case .lesson: return "💡"
        }
    }

    var colorHex: String {
        switch self {
        case .general: return "6366F1"      // İndigo
        case .gratitude: return "8B5CF6"    // Mor
        case .achievement: return "F59E0B"  // Amber
        case .lesson: return "10B981"       // Yeşil
        }
    }

    var color: Color {
        Color(hex: colorHex) ?? .blue
    }

    /// AI prompt'u
    var aiPrompt: String {
        switch self {
        case .general:
            return "Bugünü bir kelime ile özetlersen ne olurdu?"
        case .gratitude:
            return "Bugün minnettar olduğun 3 şey nedir?"
        case .achievement:
            return "Bugün başardığın en önemli şey neydi?"
        case .lesson:
            return "Bugün ne öğrendin?"
        }
    }
}

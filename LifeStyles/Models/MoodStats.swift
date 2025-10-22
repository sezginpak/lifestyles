//
//  MoodStats.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Mood analytics ve korelasyon struct'ları
//

import Foundation

/// Mood istatistikleri
struct MoodStats {
    var averageMood: Double // Ortalama mood skoru
    var moodDistribution: [MoodType: Int] // Her mood'dan kaç tane var
    var moodTrend: TrendType // Yükseliş/düşüş/sabit
    var bestDay: Date? // En iyi gün
    var worstDay: Date? // En kötü gün
    var positiveCount: Int // Pozitif mood sayısı
    var negativeCount: Int // Negatif mood sayısı
    var totalEntries: Int // Toplam kayıt

    /// Pozitif mood oranı (%)
    var positivePercentage: Double {
        guard totalEntries > 0 else { return 0 }
        return (Double(positiveCount) / Double(totalEntries)) * 100
    }

    /// Negatif mood oranı (%)
    var negativePercentage: Double {
        guard totalEntries > 0 else { return 0 }
        return (Double(negativeCount) / Double(totalEntries)) * 100
    }

    /// En sık görülen mood
    var mostFrequentMood: MoodType? {
        moodDistribution.max(by: { $0.value < $1.value })?.key
    }

    /// Boş durum
    static func empty() -> MoodStats {
        MoodStats(
            averageMood: 0,
            moodDistribution: [:],
            moodTrend: .neutral,
            bestDay: nil,
            worstDay: nil,
            positiveCount: 0,
            negativeCount: 0,
            totalEntries: 0
        )
    }
}

/// Trend tipi
enum TrendType: String {
    case improving = "improving"    // İyileşiyor ↗️
    case declining = "declining"    // Kötüleşiyor ↘️
    case neutral = "neutral"        // Sabit →

    var emoji: String {
        switch self {
        case .improving: return "↗️"
        case .declining: return "↘️"
        case .neutral: return "→"
        }
    }

    var displayName: String {
        switch self {
        case .improving: return "İyileşiyor"
        case .declining: return "Kötüleşiyor"
        case .neutral: return "Sabit"
        }
    }

    var color: String {
        switch self {
        case .improving: return "10B981" // Yeşil
        case .declining: return "EF4444" // Kırmızı
        case .neutral: return "94A3B8"   // Gri
        }
    }
}

/// Mood-Goal korelasyon
struct MoodGoalCorrelation: Identifiable {
    var id: UUID { goal.id }
    var goal: Goal
    var correlationScore: Double // -1.0 ile +1.0 arası
    var sampleSize: Int // Kaç veri noktası

    /// Korelasyon güçlü mü?
    var isStrong: Bool {
        abs(correlationScore) > 0.5
    }

    /// Pozitif korelasyon mu?
    var isPositive: Bool {
        correlationScore > 0
    }

    /// Formatlanmış skor
    var formattedScore: String {
        let percentage = Int(abs(correlationScore) * 100)
        return isPositive ? "+\(percentage)%" : "-\(percentage)%"
    }

    /// Açıklama metni
    var description: String {
        if isPositive {
            return "Bu hedefi tamamladığınızda mood'unuz artıyor"
        } else {
            return "Bu hedef stres yaratabilir"
        }
    }
}

/// Mood-Friend korelasyon
struct MoodFriendCorrelation: Identifiable {
    var id: UUID { friend.id }
    var friend: Friend
    var correlationScore: Double // -1.0 ile +1.0 arası
    var sampleSize: Int

    /// Korelasyon güçlü mü?
    var isStrong: Bool {
        abs(correlationScore) > 0.5
    }

    /// Pozitif korelasyon mu?
    var isPositive: Bool {
        correlationScore > 0
    }

    /// Formatlanmış skor
    var formattedScore: String {
        let percentage = Int(abs(correlationScore) * 100)
        return isPositive ? "+\(percentage)%" : "-\(percentage)%"
    }

    /// Açıklama metni
    var description: String {
        if isPositive {
            return "\(friend.name) ile görüştükten sonra mood'unuz artıyor"
        } else {
            return "Bu kişiyle görüşmeler stresli olabilir"
        }
    }
}

/// Mood korelasyon wrapper
struct MoodCorrelation {
    var goalCorrelations: [MoodGoalCorrelation]
    var friendCorrelations: [MoodFriendCorrelation]

    /// En yüksek pozitif goal korelasyonu
    var topPositiveGoal: MoodGoalCorrelation? {
        goalCorrelations
            .filter { $0.isPositive }
            .max(by: { $0.correlationScore < $1.correlationScore })
    }

    /// En yüksek pozitif friend korelasyonu
    var topPositiveFriend: MoodFriendCorrelation? {
        friendCorrelations
            .filter { $0.isPositive }
            .max(by: { $0.correlationScore < $1.correlationScore })
    }

    /// Boş durum
    static func empty() -> MoodCorrelation {
        MoodCorrelation(
            goalCorrelations: [],
            friendCorrelations: []
        )
    }
}

/// Heatmap için günlük veri
struct MoodDayData: Identifiable {
    var id: Date { date }
    var date: Date
    var moodType: MoodType?
    var averageScore: Double? // Birden fazla kayıt varsa ortalama

    /// Günün başlangıcı
    var dayStart: Date {
        Calendar.current.startOfDay(for: date)
    }

    /// Gün adı (Pazartesi, Salı, ...)
    var weekdayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }

    /// Kısa gün adı (Pzt, Sal, ...)
    var shortWeekdayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }

    /// Gün numarası
    var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }

    /// Bugün mü?
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

/// AI insight
struct MoodAIInsight {
    var summary: String // Kısa özet
    var analysis: String // Detaylı analiz
    var suggestions: [String] // Öneriler
    var generatedAt: Date

    /// Boş durum
    static func empty() -> MoodAIInsight {
        MoodAIInsight(
            summary: "",
            analysis: "",
            suggestions: [],
            generatedAt: Date()
        )
    }
}

/// Streak bilgisi
struct StreakData {
    var currentStreak: Int // Mevcut ardışık gün
    var longestStreak: Int // Şimdiye kadarki en uzun streak
    var lastMoodDate: Date? // Son mood kaydı tarihi
    var streakBadges: [StreakBadge] // Kazanılan badge'ler
    var isActive: Bool // Bugün kaydedildi mi?

    /// Streak aktif mi? (bugün veya dün kaydedilmiş mi)
    var isStreakActive: Bool {
        guard let lastDate = lastMoodDate else { return false }
        let calendar = Calendar.current
        let daysDiff = calendar.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        return daysDiff <= 1
    }

    /// Sonraki badge'e kalan gün
    var daysToNextBadge: Int? {
        let milestones = [7, 14, 30, 60, 100, 365]
        for milestone in milestones {
            if currentStreak < milestone {
                return milestone - currentStreak
            }
        }
        return nil
    }

    /// Boş durum
    static func empty() -> StreakData {
        StreakData(
            currentStreak: 0,
            longestStreak: 0,
            lastMoodDate: nil,
            streakBadges: [],
            isActive: false
        )
    }
}

/// Streak badge
struct StreakBadge: Identifiable {
    var id: String { "\(days)-day-streak" }
    var days: Int
    var earnedDate: Date
    var emoji: String

    var title: String {
        "\(days) Günlük Streak"
    }

    var description: String {
        switch days {
        case 7: return "İlk hafta tamamlandı!"
        case 14: return "İki hafta streak!"
        case 30: return "Bir ay boyunca düzenli!"
        case 60: return "İki ay streak - harikasın!"
        case 100: return "100 gün! İnanılmaz!"
        case 365: return "Tam bir yıl streak - efsane!"
        default: return "\(days) gün streak!"
        }
    }

    static func getBadgeForStreak(_ days: Int) -> String {
        switch days {
        case 7: return "🔥"
        case 14: return "🔥🔥"
        case 30: return "⭐"
        case 60: return "✨"
        case 100: return "💎"
        case 365: return "👑"
        default: return "🎯"
        }
    }
}

// MARK: - StreakBadge Codable

extension StreakBadge: Codable {
    enum CodingKeys: String, CodingKey {
        case days
        case earnedDate
        case emoji
    }
}

/// Mood-Location korelasyon
struct MoodLocationCorrelation: Identifiable {
    var id: String { location.address ?? location.id.uuidString }
    var location: LocationLog
    var averageMoodScore: Double // Bu lokasyondaki ortalama mood
    var visitCount: Int // Kaç kez ziyaret edildi
    var moodDistribution: [MoodType: Int] // Mood dağılımı

    /// Bu lokasyon pozitif mi?
    var isPositive: Bool {
        averageMoodScore > 0.5
    }

    /// En sık görülen mood
    var dominantMood: MoodType? {
        moodDistribution.max(by: { $0.value < $1.value })?.key
    }

    /// Formatlanmış skor
    var formattedScore: String {
        let percentage = Int(abs(averageMoodScore) * 100)
        return isPositive ? "+\(percentage)%" : "-\(percentage)%"
    }

    /// Açıklama metni
    var description: String {
        if isPositive {
            return "Bu lokasyonda ruh haliniz genelde iyi oluyor"
        } else {
            return "Bu lokasyon stres yaratabilir"
        }
    }
}

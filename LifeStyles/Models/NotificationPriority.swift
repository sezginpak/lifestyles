//
//  NotificationPriority.swift
//  LifeStyles
//
//  Notification priority system models
//  Bildirimleri önem derecesine göre sıralar ve optimize eder
//

import Foundation

// MARK: - Priority Level

enum PriorityLevel: String, Codable, Comparable {
    case critical   // Kritik (streak warnings, urgent reminders)
    case high       // Yüksek (VIP contacts, important goals)
    case normal     // Normal (regular reminders)
    case low        // Düşük (motivation messages, suggestions)
    case minimal    // Minimal (background updates)

    var score: Double {
        switch self {
        case .critical: return 1.0
        case .high: return 0.75
        case .normal: return 0.5
        case .low: return 0.25
        case .minimal: return 0.1
        }
    }

    var interruptLevel: String {
        switch self {
        case .critical: return "timeSensitive"
        case .high: return "active"
        case .normal: return "active"
        case .low: return "passive"
        case .minimal: return "passive"
        }
    }

    var soundLevel: SoundLevel {
        switch self {
        case .critical: return .critical
        case .high: return .loud
        case .normal: return .normal
        case .low: return .soft
        case .minimal: return .silent
        }
    }

    static func < (lhs: PriorityLevel, rhs: PriorityLevel) -> Bool {
        return lhs.score < rhs.score
    }
}

enum SoundLevel: String, Codable {
    case critical   // Sessize alınmış bile olsa çalar
    case loud       // Yüksek ses
    case normal     // Normal ses
    case soft       // Düşük ses
    case silent     // Sessiz
}

// MARK: - Priority Factor

enum PriorityFactor: String, Codable {
    // Contact-related
    case vipContact             // VIP kişi
    case daysOverdue            // Gecikme günü sayısı
    case relationshipImportance // İlişki önem derecesi
    case contactFrequency       // İletişim sıklığı

    // Time-related
    case timeSensitive          // Zamana duyarlı
    case deadline               // Son tarih yakın
    case streakAtRisk           // Streak tehlikede

    // User-related
    case userEngagement         // Kullanıcı katılımı yüksek
    case historicalResponse     // Geçmiş yanıt oranı iyi
    case userPreference         // Kullanıcı tercihi

    // Context-related
    case optimalTime            // Optimal zaman
    case locationRelevant       // Konuma uygun
    case contextAppropriate     // Context uygun

    // Achievement-related
    case milestoneAchieved      // Milestone başarıldı
    case goalProgress           // Hedef ilerlemesi iyi
    case habitStreak            // Habit streak yüksek

    var weight: Double {
        switch self {
        case .vipContact: return 0.3
        case .daysOverdue: return 0.25
        case .relationshipImportance: return 0.2
        case .contactFrequency: return 0.15

        case .timeSensitive: return 0.35
        case .deadline: return 0.3
        case .streakAtRisk: return 0.35

        case .userEngagement: return 0.25
        case .historicalResponse: return 0.2
        case .userPreference: return 0.25

        case .optimalTime: return 0.2
        case .locationRelevant: return 0.15
        case .contextAppropriate: return 0.15

        case .milestoneAchieved: return 0.3
        case .goalProgress: return 0.2
        case .habitStreak: return 0.25
        }
    }
}

// MARK: - Notification Priority

struct NotificationPriority: Codable {
    let level: PriorityLevel
    let score: Double // 0.0 - 1.0
    let factors: [PriorityFactorScore]
    let expiresAt: Date?
    let createdAt: Date

    init(
        level: PriorityLevel,
        score: Double,
        factors: [PriorityFactorScore],
        expiresAt: Date? = nil
    ) {
        self.level = level
        self.score = min(1.0, max(0.0, score))
        self.factors = factors
        self.expiresAt = expiresAt
        self.createdAt = Date()
    }

    /// Öncelik geçerli mi? (expire olmamış)
    var isValid: Bool {
        if let expiry = expiresAt {
            return Date() < expiry
        }
        return true
    }

    /// Öncelik skoru (0-100)
    var priorityScore: Double {
        return score * 100
    }

    /// Weighted total score
    var weightedScore: Double {
        let factorScore = factors.reduce(0.0) { $0 + $1.contribution }
        return (score * 0.6) + (factorScore * 0.4)
    }
}

struct PriorityFactorScore: Codable {
    let factor: PriorityFactor
    let value: Double // 0.0 - 1.0
    let weight: Double

    var contribution: Double {
        return value * weight
    }

    var description: String {
        return "\(factor.rawValue): \(String(format: "%.2f", value * 100))%"
    }
}

// MARK: - Priority Calculator

class PriorityCalculator {

    /// Contact reminder için priority hesapla
    static func calculateContactPriority(
        isVIP: Bool,
        daysOverdue: Int,
        frequency: ContactFrequency,
        lastEngagement: Double
    ) -> NotificationPriority {

        var factors: [PriorityFactorScore] = []

        // VIP factor
        if isVIP {
            factors.append(PriorityFactorScore(
                factor: .vipContact,
                value: 1.0,
                weight: PriorityFactor.vipContact.weight
            ))
        }

        // Days overdue factor
        let overdueScore = min(1.0, Double(daysOverdue) / 14.0) // 14 gün = max
        factors.append(PriorityFactorScore(
            factor: .daysOverdue,
            value: overdueScore,
            weight: PriorityFactor.daysOverdue.weight
        ))

        // Frequency factor
        let frequencyScore = frequency.priorityScore
        factors.append(PriorityFactorScore(
            factor: .contactFrequency,
            value: frequencyScore,
            weight: PriorityFactor.contactFrequency.weight
        ))

        // Engagement factor
        factors.append(PriorityFactorScore(
            factor: .userEngagement,
            value: lastEngagement,
            weight: PriorityFactor.userEngagement.weight
        ))

        // Calculate total score
        let totalScore = factors.reduce(0.0) { $0 + $1.contribution }

        // Determine level
        let level: PriorityLevel
        if isVIP && daysOverdue > 7 {
            level = .high
        } else if daysOverdue > 10 {
            level = .high
        } else if daysOverdue > 5 {
            level = .normal
        } else {
            level = .low
        }

        return NotificationPriority(
            level: level,
            score: totalScore,
            factors: factors,
            expiresAt: Date().addingTimeInterval(86400) // 24 saat geçerli
        )
    }

    /// Goal reminder için priority hesapla
    static func calculateGoalPriority(
        daysUntilDeadline: Int,
        progress: Double,
        isImportant: Bool
    ) -> NotificationPriority {

        var factors: [PriorityFactorScore] = []

        // Deadline factor
        let deadlineScore: Double
        if daysUntilDeadline <= 3 {
            deadlineScore = 1.0
        } else if daysUntilDeadline <= 7 {
            deadlineScore = 0.7
        } else if daysUntilDeadline <= 14 {
            deadlineScore = 0.5
        } else {
            deadlineScore = 0.3
        }

        factors.append(PriorityFactorScore(
            factor: .deadline,
            value: deadlineScore,
            weight: PriorityFactor.deadline.weight
        ))

        // Progress factor
        factors.append(PriorityFactorScore(
            factor: .goalProgress,
            value: progress,
            weight: PriorityFactor.goalProgress.weight
        ))

        // Calculate total
        let totalScore = factors.reduce(0.0) { $0 + $1.contribution }

        // Determine level
        let level: PriorityLevel
        if daysUntilDeadline <= 3 {
            level = .high
        } else if daysUntilDeadline <= 7 {
            level = .normal
        } else {
            level = .low
        }

        return NotificationPriority(
            level: level,
            score: totalScore,
            factors: factors,
            expiresAt: Date().addingTimeInterval(86400)
        )
    }

    /// Habit/Streak warning için priority hesapla
    static func calculateStreakPriority(
        currentStreak: Int,
        hoursRemaining: Int
    ) -> NotificationPriority {

        var factors: [PriorityFactorScore] = []

        // Streak value factor
        let streakScore = min(1.0, Double(currentStreak) / 30.0) // 30 gün = max değer
        factors.append(PriorityFactorScore(
            factor: .habitStreak,
            value: streakScore,
            weight: PriorityFactor.habitStreak.weight
        ))

        // Time urgency factor
        let urgencyScore = hoursRemaining <= 3 ? 1.0 : 0.6
        factors.append(PriorityFactorScore(
            factor: .timeSensitive,
            value: urgencyScore,
            weight: PriorityFactor.timeSensitive.weight
        ))

        let totalScore = factors.reduce(0.0) { $0 + $1.contribution }

        // Streak warnings are always critical if streak > 7
        let level: PriorityLevel = currentStreak > 7 ? .critical : .high

        return NotificationPriority(
            level: level,
            score: totalScore,
            factors: factors,
            expiresAt: Date().addingTimeInterval(Double(hoursRemaining * 3600))
        )
    }

    /// Motivation/Activity suggestion için priority hesapla
    static func calculateSuggestionPriority(
        contextScore: Double,
        lastShownHoursAgo: Int
    ) -> NotificationPriority {

        var factors: [PriorityFactorScore] = []

        // Context appropriateness
        factors.append(PriorityFactorScore(
            factor: .contextAppropriate,
            value: contextScore,
            weight: PriorityFactor.contextAppropriate.weight
        ))

        // Freshness (ne kadar zaman geçti)
        let freshnessScore = min(1.0, Double(lastShownHoursAgo) / 24.0)
        factors.append(PriorityFactorScore(
            factor: .optimalTime,
            value: freshnessScore,
            weight: PriorityFactor.optimalTime.weight
        ))

        let totalScore = factors.reduce(0.0) { $0 + $1.contribution }

        // Suggestions are always low priority
        return NotificationPriority(
            level: .low,
            score: totalScore,
            factors: factors,
            expiresAt: Date().addingTimeInterval(7200) // 2 saat geçerli
        )
    }
}

// MARK: - Contact Frequency Extension
// ContactFrequency enum FriendEnums.swift'te tanımlı, buraya priority özellikleri ekliyoruz

extension ContactFrequency {
    var priorityScore: Double {
        switch self {
        case .daily: return 1.0
        case .twoDays: return 0.95
        case .threeDays: return 0.9
        case .weekly: return 0.8
        case .biweekly: return 0.6
        case .monthly: return 0.4
        case .quarterly: return 0.2
        case .yearly: return 0.1
        }
    }
}

// MARK: - Priority Queue Item

struct PriorityQueueItem: Identifiable, Comparable, Equatable {
    let id: UUID
    let notificationId: String
    let priority: NotificationPriority
    let scheduledTime: Date
    let category: String

    init(
        notificationId: String,
        priority: NotificationPriority,
        scheduledTime: Date,
        category: String,
        userInfo: [String: Any] = [:]
    ) {
        self.id = UUID()
        self.notificationId = notificationId
        self.priority = priority
        self.scheduledTime = scheduledTime
        self.category = category
    }

    /// Karşılaştırma (yüksek öncelik önce gelir)
    static func < (lhs: PriorityQueueItem, rhs: PriorityQueueItem) -> Bool {
        // Önce priority level karşılaştır
        if lhs.priority.level != rhs.priority.level {
            return lhs.priority.level > rhs.priority.level
        }

        // Sonra weighted score karşılaştır
        if lhs.priority.weightedScore != rhs.priority.weightedScore {
            return lhs.priority.weightedScore > rhs.priority.weightedScore
        }

        // Son olarak zaman karşılaştır (önce scheduled olanlar önce gelir)
        return lhs.scheduledTime < rhs.scheduledTime
    }

    static func == (lhs: PriorityQueueItem, rhs: PriorityQueueItem) -> Bool {
        return lhs.id == rhs.id
    }
}

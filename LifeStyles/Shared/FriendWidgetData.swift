//
//  FriendWidgetData.swift
//  LifeStyles
//
//  Shared data model for Friends Widget
//  Used by both main app and widget extension
//
//  Created by Claude on 04.11.2025.
//

import Foundation

/// Lightweight data model for Friend widget
/// Codable for easy serialization, Hashable for widget timeline comparison
struct FriendWidgetData: Codable, Hashable, Identifiable {
    // MARK: - Basic Info
    let id: String
    let name: String
    let emoji: String
    let phoneNumber: String?

    // MARK: - Contact Info
    let isImportant: Bool
    let daysOverdue: Int
    let daysRemaining: Int
    let nextContactDate: Date
    let lastContactDate: Date?
    let needsContact: Bool

    // MARK: - Relationship
    let relationshipType: String
    let frequency: String

    // MARK: - Stats
    let totalContactCount: Int

    // MARK: - Transaction (Borç/Alacak)
    let hasDebt: Bool
    let hasCredit: Bool
    let balance: String?

    // MARK: - Computed Properties

    /// Durum renk kategorisi
    var statusCategory: FriendStatus {
        if daysOverdue > 0 {
            return .overdue
        } else if daysRemaining <= 2 {
            return .upcoming
        } else {
            return .onTime
        }
    }

    /// Durum metni
    var statusText: String {
        if daysOverdue > 0 {
            return daysOverdue == 1 ? "1 gün geçti" : "\(daysOverdue) gün geçti"
        } else if daysRemaining == 0 {
            return "Bugün ara!"
        } else if daysRemaining == 1 {
            return "Yarın ara"
        } else {
            return "\(daysRemaining) gün kaldı"
        }
    }

    /// Durum ikonu
    var statusIcon: String {
        switch statusCategory {
        case .overdue:
            return "exclamationmark.triangle.fill"
        case .upcoming:
            return "clock.fill"
        case .onTime:
            return "checkmark.circle.fill"
        }
    }

    /// İlişki ikonu
    var relationshipIcon: String {
        switch relationshipType {
        case "partner":
            return "heart.fill"
        case "family":
            return "house.fill"
        case "colleague":
            return "briefcase.fill"
        case "friend":
            return "person.2.fill"
        default:
            return "person.fill"
        }
    }

    /// İletişim sıklığı metni
    var frequencyText: String {
        switch frequency {
        case "daily":
            return "Her gün"
        case "weekly":
            return "Haftada bir"
        case "biweekly":
            return "2 haftada bir"
        case "monthly":
            return "Ayda bir"
        case "quarterly":
            return "3 ayda bir"
        case "biannual":
            return "6 ayda bir"
        case "yearly":
            return "Yılda bir"
        default:
            return "Belirsiz"
        }
    }
}

/// Friend durum kategorisi
enum FriendStatus: String, Codable {
    case overdue = "overdue"       // Gecikmiş (kırmızı)
    case upcoming = "upcoming"     // Yaklaşıyor (turuncu)
    case onTime = "onTime"         // Zamanında (yeşil)
}

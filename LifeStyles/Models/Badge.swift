//
//  Badge.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//

import Foundation
import SwiftData

// Badge kategorisi
enum BadgeCategory: String, Codable, CaseIterable {
    case streak = "streak"          // Streak rozetleri
    case completion = "completion"  // Tamamlama rozetleri
    case time = "time"              // Zaman bazlı rozetler (sabah, akşam)
    case category = "category"      // Kategori bazlı rozetler
    case special = "special"        // Özel rozetler

    var displayName: String {
        switch self {
        case .streak: return "Devamlılık"
        case .completion: return "Başarım"
        case .time: return "Zaman"
        case .category: return "Kategori"
        case .special: return "Özel"
        }
    }
}

@Model
final class Badge {
    var id: UUID = UUID()
    var title: String = ""
    var badgeDescription: String = ""
    var categoryRaw: String = "special"
    var iconName: String = "star.fill" // SF Symbol name
    var earnedAt: Date?
    var isEarned: Bool = false
    var requirement: Int = 1 // Gerekli sayı (örn: 7 gün streak için 7)
    var currentProgress: Int = 0 // Mevcut ilerleme

    init(
        id: UUID = UUID(),
        title: String,
        badgeDescription: String,
        category: BadgeCategory,
        iconName: String,
        earnedAt: Date? = nil,
        isEarned: Bool = false,
        requirement: Int,
        currentProgress: Int = 0
    ) {
        self.id = id
        self.title = title
        self.badgeDescription = badgeDescription
        self.categoryRaw = category.rawValue
        self.iconName = iconName
        self.earnedAt = earnedAt
        self.isEarned = isEarned
        self.requirement = requirement
        self.currentProgress = currentProgress
    }

    var category: BadgeCategory {
        get { BadgeCategory(rawValue: categoryRaw) ?? .special }
        set { categoryRaw = newValue.rawValue }
    }

    // İlerleme yüzdesi
    var progressPercentage: Double {
        guard requirement > 0 else { return 0 }
        return min(Double(currentProgress) / Double(requirement), 1.0)
    }

    // İlerleme metni
    var progressText: String {
        "\(currentProgress)/\(requirement)"
    }

    // Formatlanmış kazanma tarihi
    var formattedEarnedDate: String? {
        guard let date = earnedAt else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }

    // Badge'i kazan
    func earn() {
        isEarned = true
        earnedAt = Date()
        currentProgress = requirement
    }

    // İlerleme güncelle
    func updateProgress(_ value: Int) {
        currentProgress = value
        if currentProgress >= requirement && !isEarned {
            earn()
        }
    }
}

// MARK: - Predefined Badges

extension Badge {
    // Tüm badge'leri oluştur
    static func createDefaultBadges() -> [Badge] {
        return [
            // Streak Badges
            Badge(
                title: "İlk Adım",
                badgeDescription: "İlk aktivitenizi tamamladınız",
                category: .completion,
                iconName: "flag.fill",
                requirement: 1
            ),
            Badge(
                title: "7 Gün Warrior",
                badgeDescription: "7 gün üst üste aktivite tamamladınız",
                category: .streak,
                iconName: "flame.fill",
                requirement: 7
            ),
            Badge(
                title: "14 Gün Şampiyonu",
                badgeDescription: "2 hafta boyunca devamlılık gösterdiniz",
                category: .streak,
                iconName: "bolt.fill",
                requirement: 14
            ),
            Badge(
                title: "30 Gün Efsanesi",
                badgeDescription: "1 ay boyunca her gün aktivite yaptınız",
                category: .streak,
                iconName: "star.fill",
                requirement: 30
            ),
            Badge(
                title: "100 Gün Ustası",
                badgeDescription: "100 gün streak! İnanılmaz bir başarı!",
                category: .streak,
                iconName: "crown.fill",
                requirement: 100
            ),

            // Completion Badges
            Badge(
                title: "10 Aktivite",
                badgeDescription: "10 aktivite tamamladınız",
                category: .completion,
                iconName: "10.circle.fill",
                requirement: 10
            ),
            Badge(
                title: "50 Aktivite",
                badgeDescription: "50 aktivite tamamladınız",
                category: .completion,
                iconName: "50.circle.fill",
                requirement: 50
            ),
            Badge(
                title: "100 Aktivite",
                badgeDescription: "100 aktivite tamamladınız!",
                category: .completion,
                iconName: "trophy.fill",
                requirement: 100
            ),

            // Time Badges
            Badge(
                title: "Sabah Kuşu",
                badgeDescription: "10 sabah aktivitesi tamamladınız",
                category: .time,
                iconName: "sunrise.fill",
                requirement: 10
            ),
            Badge(
                title: "Gece Baykuşu",
                badgeDescription: "10 akşam aktivitesi tamamladınız",
                category: .time,
                iconName: "moon.stars.fill",
                requirement: 10
            ),

            // Category Badges
            Badge(
                title: "Sosyal Kelebek",
                badgeDescription: "20 sosyal aktivite tamamladınız",
                category: .category,
                iconName: "person.3.fill",
                requirement: 20
            ),
            Badge(
                title: "Öğrenme Aşığı",
                badgeDescription: "20 öğrenme aktivitesi tamamladınız",
                category: .category,
                iconName: "book.fill",
                requirement: 20
            ),
            Badge(
                title: "Hareket Makinesi",
                badgeDescription: "30 egzersiz aktivitesi tamamladınız",
                category: .category,
                iconName: "figure.run",
                requirement: 30
            ),
            Badge(
                title: "Doğa Sever",
                badgeDescription: "25 açık hava aktivitesi tamamladınız",
                category: .category,
                iconName: "leaf.fill",
                requirement: 25
            ),
            Badge(
                title: "Yaratıcı Ruh",
                badgeDescription: "15 yaratıcı aktivite tamamladınız",
                category: .category,
                iconName: "paintbrush.fill",
                requirement: 15
            ),
            Badge(
                title: "Zen Master",
                badgeDescription: "20 dinlenme/meditasyon aktivitesi tamamladınız",
                category: .category,
                iconName: "sparkles",
                requirement: 20
            )
        ]
    }
}

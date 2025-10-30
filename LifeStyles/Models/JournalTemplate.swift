//
//  JournalTemplate.swift
//  LifeStyles
//
//  Created by Claude on 25.10.2025.
//  Journal şablonları - Guided writing experience
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class JournalTemplate {
    var id: UUID
    var name: String
    var templateDescription: String
    var icon: String
    var emoji: String
    var colorHex: String
    var categoryRaw: String
    var prompts: [String] // Sıralı prompt listesi
    var placeholderText: String
    var isBuiltIn: Bool // Varsayılan şablonlar
    var usageCount: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        icon: String,
        emoji: String,
        colorHex: String,
        category: TemplateCategory,
        prompts: [String],
        placeholderText: String,
        isBuiltIn: Bool = false,
        usageCount: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.templateDescription = description
        self.icon = icon
        self.emoji = emoji
        self.colorHex = colorHex
        self.categoryRaw = category.rawValue
        self.prompts = prompts
        self.placeholderText = placeholderText
        self.isBuiltIn = isBuiltIn
        self.usageCount = usageCount
        self.createdAt = createdAt
    }

    var category: TemplateCategory {
        get { TemplateCategory(rawValue: categoryRaw) ?? .productivity }
        set { categoryRaw = newValue.rawValue }
    }

    var color: Color {
        Color(hex: colorHex)
    }

    /// Şablonu kullan
    func incrementUsage() {
        usageCount += 1
    }
}

enum TemplateCategory: String, Codable, CaseIterable {
    case productivity = "productivity"
    case wellness = "wellness"
    case reflection = "reflection"
    case creativity = "creativity"

    var displayName: String {
        switch self {
        case .productivity: return "Verimlilik"
        case .wellness: return "Sağlık & İyilik"
        case .reflection: return "Düşünce & Yansıma"
        case .creativity: return "Yaratıcılık"
        }
    }

    var icon: String {
        switch self {
        case .productivity: return "chart.bar.fill"
        case .wellness: return "heart.fill"
        case .reflection: return "brain.head.profile"
        case .creativity: return "paintbrush.fill"
        }
    }
}

// MARK: - Built-in Templates

extension JournalTemplate {
    /// Varsayılan şablonları yükle
    static func createDefaultTemplates(context: ModelContext) {
        let templates = [
            // 1. Daily Routine
            JournalTemplate(
                name: "Günlük Rutin",
                description: "Günlük planlamanı yap ve değerlendir",
                icon: "sun.max.fill",
                emoji: "☀️",
                colorHex: "F59E0B",
                category: .productivity,
                prompts: [
                    "Bugün neler yapacaksın?",
                    "En önemli 3 görevin nedir?",
                    "Bugün kendini nasıl hissetmek istiyorsun?",
                    "Bugün neler başardın?"
                ],
                placeholderText: "Bugünü planla ve değerlendir...",
                isBuiltIn: true
            ),

            // 2. Gratitude Journal
            JournalTemplate(
                name: "Minnettarlık Günlüğü",
                description: "Minnettar olduğun şeyleri kaydet",
                icon: "hands.sparkles",
                emoji: "🙏",
                colorHex: "8B5CF6",
                category: .wellness,
                prompts: [
                    "Bugün minnettar olduğun 3 şey nedir?",
                    "Seni mutlu eden küçük bir an?",
                    "Hayatında kimi takdir ediyorsun?",
                    "Bugün ne güzel bir şey oldu?"
                ],
                placeholderText: "Minnettar olduğun şeyleri yaz...",
                isBuiltIn: true
            ),

            // 3. Dream Journal
            JournalTemplate(
                name: "Rüya Günlüğü",
                description: "Rüyalarını ve yorumlarını kaydet",
                icon: "moon.stars.fill",
                emoji: "🌙",
                colorHex: "6366F1",
                category: .reflection,
                prompts: [
                    "Hangi rüyayı gördün?",
                    "Rüyanda neler oldu?",
                    "Rüyanda kim vardı?",
                    "Rüya sana ne hissettirdi?",
                    "Rüyanın anlamı ne olabilir?"
                ],
                placeholderText: "Rüyanı anlat...",
                isBuiltIn: true
            ),

            // 4. Weekly Review
            JournalTemplate(
                name: "Haftalık Değerlendirme",
                description: "Haftanı değerlendir ve planla",
                icon: "calendar.badge.clock",
                emoji: "📅",
                colorHex: "3B82F6",
                category: .productivity,
                prompts: [
                    "Bu hafta neler başardın?",
                    "Ne öğrendin?",
                    "Neyi farklı yapabilirdin?",
                    "Gelecek hafta hedeflerin neler?",
                    "Kendine not bırak"
                ],
                placeholderText: "Haftanı değerlendir...",
                isBuiltIn: true
            ),

            // 5. Creative Writing
            JournalTemplate(
                name: "Yaratıcı Yazı",
                description: "Fikirlerini ve hayallerini yaz",
                icon: "pencil.and.scribble",
                emoji: "✍️",
                colorHex: "EC4899",
                category: .creativity,
                prompts: [
                    "Bugün aklındaki fikir nedir?",
                    "Yaratıcı bir proje hayal et",
                    "Kendini hayal gücünle ifade et"
                ],
                placeholderText: "Yaratıcılığını serbest bırak...",
                isBuiltIn: true
            ),

            // 6. Self-Care Check
            JournalTemplate(
                name: "Öz Bakım Kontrolü",
                description: "Kendine nasıl baktığını değerlendir",
                icon: "heart.circle.fill",
                emoji: "💖",
                colorHex: "10B981",
                category: .wellness,
                prompts: [
                    "Bugün kendine nasıl baktın?",
                    "Enerji seviyeni değerlendir (1-10)",
                    "Ne yapmak seni mutlu eder?",
                    "Yarın kendine nasıl bakacaksın?"
                ],
                placeholderText: "Kendine nasıl bakıyorsun?",
                isBuiltIn: true
            )
        ]

        // Insert all templates
        for template in templates {
            context.insert(template)
        }

        do {
            try context.save()
            print("✅ \(templates.count) default journal templates created")
        } catch {
            print("❌ Failed to create templates: \(error)")
        }
    }

    /// Varsayılan şablon var mı kontrol et
    static func hasDefaultTemplates(context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<JournalTemplate>(
            predicate: #Predicate { $0.isBuiltIn }
        )

        do {
            let count = try context.fetchCount(descriptor)
            return count >= 6
        } catch {
            return false
        }
    }
}

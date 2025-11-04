//
//  UserKnowledge.swift
//  LifeStyles
//
//  Created by AI Assistant on 04.11.2025.
//  AI öğrenen chat sistemi - Kullanıcı hakkında öğrenilen bilgiler
//

import Foundation
import SwiftData

/// Kullanıcı hakkında AI'ın öğrendiği bilgiler
@Model
final class UserKnowledge {
    var id: UUID = UUID()
    var category: String                 // KnowledgeCategory.rawValue
    var key: String                      // "favorite_color", "job", "fear_of_heights"
    var value: String                    // "mavi", "yazılımcı", "true"
    var confidence: Double               // 0.0-1.0 (ne kadar emin?)
    var source: String                   // KnowledgeSource.rawValue
    var createdAt: Date = Date()
    var lastConfirmedAt: Date?           // Son onaylama tarihi
    var timesReferenced: Int = 0         // Kaç kez kullanıldı
    var isActive: Bool = true            // Hala geçerli mi?

    // Related data
    var conversationIds: [String] = []   // Hangi konuşmalardan öğrenildi
    var relatedFactKeys: [String] = []   // İlişkili diğer bilgiler

    // Optional: İlişki tanımı (ileride kullanmak için)
    // @Relationship(deleteRule: .nullify)
    // var conversations: [ChatConversation]?

    init(
        id: UUID = UUID(),
        category: KnowledgeCategory,
        key: String,
        value: String,
        confidence: Double,
        source: KnowledgeSource,
        conversationIds: [String] = [],
        relatedFactKeys: [String] = []
    ) {
        self.id = id
        self.category = category.rawValue
        self.key = key
        self.value = value
        self.confidence = min(max(confidence, 0.0), 1.0) // Clamp 0-1
        self.source = source.rawValue
        self.conversationIds = conversationIds
        self.relatedFactKeys = relatedFactKeys
    }
}

// MARK: - Computed Properties

extension UserKnowledge {
    /// Enum olarak category
    var categoryEnum: KnowledgeCategory {
        get { KnowledgeCategory(rawValue: category) ?? .other }
        set { category = newValue.rawValue }
    }

    /// Enum olarak source
    var sourceEnum: KnowledgeSource {
        get { KnowledgeSource(rawValue: source) ?? .inferred }
        set { source = newValue.rawValue }
    }

    /// Güven seviyesi metni
    var confidenceLevel: String {
        switch confidence {
        case 0.8...1.0:
            return String(localized: "knowledge.confidence.high", defaultValue: "Yüksek", comment: "High confidence level")
        case 0.5..<0.8:
            return String(localized: "knowledge.confidence.medium", defaultValue: "Orta", comment: "Medium confidence level")
        default:
            return String(localized: "knowledge.confidence.low", defaultValue: "Düşük", comment: "Low confidence level")
        }
    }

    /// Güven yüzdesi
    var confidencePercentage: Int {
        Int(confidence * 100)
    }

    /// Ne kadar süre önce öğrenildi
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale.current
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    /// Kaynak metni (lokalize)
    var sourceText: String {
        switch sourceEnum {
        case .userTold:
            return String(localized: "knowledge.source.userTold", defaultValue: "Direkt söyledin", comment: "User directly stated")
        case .inferred:
            return String(localized: "knowledge.source.inferred", defaultValue: "Çıkarım", comment: "Inferred from context")
        case .pattern:
            return String(localized: "knowledge.source.pattern", defaultValue: "Davranış pattern'i", comment: "Behavior pattern")
        case .aiExtracted:
            return String(localized: "knowledge.source.aiExtracted", defaultValue: "AI analizi", comment: "AI extracted")
        }
    }
}

// MARK: - Helper Methods

extension UserKnowledge {
    /// Güven seviyesini artır
    func increaseConfidence(by amount: Double = 0.1) {
        confidence = min(1.0, confidence + amount)
        lastConfirmedAt = Date()
    }

    /// Güven seviyesini azalt
    func decreaseConfidence(by amount: Double = 0.1) {
        confidence = max(0.0, confidence - amount)
    }

    /// Kullanım sayısını artır
    func incrementUsage() {
        timesReferenced += 1
    }

    /// Konuşma ID'si ekle
    func addConversationId(_ conversationId: String) {
        if !conversationIds.contains(conversationId) {
            conversationIds.append(conversationId)
        }
    }

    /// İlişkili fact ekle
    func addRelatedFact(_ factKey: String) {
        if !relatedFactKeys.contains(factKey) {
            relatedFactKeys.append(factKey)
        }
    }

    /// Deaktive et (sil yerine)
    func deactivate() {
        isActive = false
    }

    /// Tekrar aktive et
    func reactivate() {
        isActive = true
        lastConfirmedAt = Date()
    }
}

// MARK: - Knowledge Category

enum KnowledgeCategory: String, Codable, CaseIterable {
    // Kişisel Bilgiler
    case personalInfo = "personalInfo"           // İsim, yaş, meslek
    case relationships = "relationships"          // Aile, partner, arkadaşlar
    case lifestyle = "lifestyle"                  // Hobiler, rutinler

    // Duygusal
    case values = "values"                        // Neye önem verir
    case fears = "fears"                          // Korkular, endişeler
    case goals = "goals"                          // Ne istiyor
    case preferences = "preferences"              // Sevdiği/sevmediği

    // Geçmiş & Deneyim
    case memories = "memories"                    // Önemli olaylar
    case experiences = "experiences"              // Geçmiş tecrübeler
    case challenges = "challenges"                // Başa çıktığı sorunlar

    // Davranış Patternleri
    case habits = "habits"                        // Ne yapar
    case triggers = "triggers"                    // Ne onu etkiler

    // Context
    case currentSituation = "currentSituation"    // Güncel durum
    case recentEvents = "recentEvents"            // Son olaylar

    // Diğer
    case other = "other"

    /// Lokalize kategori adı
    var localizedName: String {
        switch self {
        case .personalInfo:
            return String(localized: "knowledge.category.personalInfo", defaultValue: "Kişisel Bilgiler", comment: "Personal info category")
        case .relationships:
            return String(localized: "knowledge.category.relationships", defaultValue: "İlişkiler", comment: "Relationships category")
        case .lifestyle:
            return String(localized: "knowledge.category.lifestyle", defaultValue: "Yaşam Tarzı", comment: "Lifestyle category")
        case .values:
            return String(localized: "knowledge.category.values", defaultValue: "Değerler", comment: "Values category")
        case .fears:
            return String(localized: "knowledge.category.fears", defaultValue: "Korkular", comment: "Fears category")
        case .goals:
            return String(localized: "knowledge.category.goals", defaultValue: "Hedefler", comment: "Goals category")
        case .preferences:
            return String(localized: "knowledge.category.preferences", defaultValue: "Tercihler", comment: "Preferences category")
        case .memories:
            return String(localized: "knowledge.category.memories", defaultValue: "Anılar", comment: "Memories category")
        case .experiences:
            return String(localized: "knowledge.category.experiences", defaultValue: "Deneyimler", comment: "Experiences category")
        case .challenges:
            return String(localized: "knowledge.category.challenges", defaultValue: "Zorluklar", comment: "Challenges category")
        case .habits:
            return String(localized: "knowledge.category.habits", defaultValue: "Alışkanlıklar", comment: "Habits category")
        case .triggers:
            return String(localized: "knowledge.category.triggers", defaultValue: "Tetikleyiciler", comment: "Triggers category")
        case .currentSituation:
            return String(localized: "knowledge.category.currentSituation", defaultValue: "Şu An", comment: "Current situation category")
        case .recentEvents:
            return String(localized: "knowledge.category.recentEvents", defaultValue: "Son Olaylar", comment: "Recent events category")
        case .other:
            return String(localized: "knowledge.category.other", defaultValue: "Diğer", comment: "Other category")
        }
    }

    /// Kategori icon'u
    var icon: String {
        switch self {
        case .personalInfo: return "person.fill"
        case .relationships: return "person.2.fill"
        case .lifestyle: return "house.fill"
        case .values: return "heart.fill"
        case .fears: return "exclamationmark.triangle.fill"
        case .goals: return "target"
        case .preferences: return "star.fill"
        case .memories: return "photo.on.rectangle.angled"
        case .experiences: return "book.fill"
        case .challenges: return "mountain.2.fill"
        case .habits: return "repeat.circle.fill"
        case .triggers: return "bolt.fill"
        case .currentSituation: return "clock.fill"
        case .recentEvents: return "calendar"
        case .other: return "ellipsis.circle.fill"
        }
    }

    /// Kategori rengi (hex)
    var colorHex: String {
        switch self {
        case .personalInfo: return "3498DB"     // Mavi
        case .relationships: return "E74C3C"     // Kırmızı
        case .lifestyle: return "2ECC71"         // Yeşil
        case .values: return "9B59B6"            // Mor
        case .fears: return "E67E22"             // Turuncu
        case .goals: return "667EEA"             // İndigo
        case .preferences: return "F39C12"       // Sarı
        case .memories: return "1ABC9C"          // Turkuaz
        case .experiences: return "34495E"       // Koyu gri
        case .challenges: return "C0392B"        // Koyu kırmızı
        case .habits: return "16A085"            // Deniz yeşili
        case .triggers: return "D35400"          // Koyu turuncu
        case .currentSituation: return "95A5A6"  // Gri
        case .recentEvents: return "7F8C8D"      // Koyu gri
        case .other: return "BDC3C7"             // Açık gri
        }
    }
}

// MARK: - Knowledge Source

enum KnowledgeSource: String, Codable {
    case userTold = "user_told"          // Direkt söyledi
    case inferred = "inferred"           // Çıkarım yapıldı
    case pattern = "pattern"             // Davranış pattern'inden
    case aiExtracted = "ai_extracted"    // AI ile çıkarıldı
}

// MARK: - Extracted Fact (Temporary DTO)

/// Extraction sırasında kullanılan geçici veri yapısı
struct ExtractedFact: Codable {
    let category: KnowledgeCategory
    let key: String
    let value: String
    let confidence: Double
    let source: KnowledgeSource

    /// Normal init (PatternMatcher için)
    init(
        category: KnowledgeCategory,
        key: String,
        value: String,
        confidence: Double,
        source: KnowledgeSource
    ) {
        self.category = category
        self.key = key
        self.value = value
        self.confidence = confidence
        self.source = source
    }

    /// Custom decoder - boolean veya number'ı string'e çevir
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        category = try container.decode(KnowledgeCategory.self, forKey: .category)
        key = try container.decode(String.self, forKey: .key)
        confidence = try container.decode(Double.self, forKey: .confidence)
        source = try container.decode(KnowledgeSource.self, forKey: .source)

        // Value'yu flexible decode et (string, bool, number hepsini kabul et)
        if let stringValue = try? container.decode(String.self, forKey: .value) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self, forKey: .value) {
            value = String(boolValue) // true -> "true"
        } else if let intValue = try? container.decode(Int.self, forKey: .value) {
            value = String(intValue) // 28 -> "28"
        } else if let doubleValue = try? container.decode(Double.self, forKey: .value) {
            value = String(doubleValue) // 3.14 -> "3.14"
        } else {
            throw DecodingError.typeMismatch(
                String.self,
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Value must be string, bool, or number"
                )
            )
        }
    }

    /// UserKnowledge'a dönüştür
    func toUserKnowledge(conversationId: String? = nil) -> UserKnowledge {
        let knowledge = UserKnowledge(
            category: category,
            key: key,
            value: value,
            confidence: confidence,
            source: source
        )

        if let convId = conversationId {
            knowledge.addConversationId(convId)
        }

        return knowledge
    }
}

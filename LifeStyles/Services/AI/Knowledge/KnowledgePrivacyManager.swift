//
//  KnowledgePrivacyManager.swift
//  LifeStyles
//
//  Created by AI Assistant on 04.11.2025.
//  AI öğrenen chat sistemi - Privacy manager
//

import Foundation

/// Knowledge öğrenme gizlilik ayarlarını yönetir
@Observable
class KnowledgePrivacyManager {
    static let shared = KnowledgePrivacyManager()

    // Privacy settings keys
    private let allowedCategoriesKey = "knowledge_allowed_categories"
    private let autoCleanupDaysKey = "knowledge_auto_cleanup_days"
    private let knowledgeLearningEnabledKey = "knowledge_learning_enabled"

    // Defaults
    private let defaultCategories: Set<KnowledgeCategory> = [
        .personalInfo,
        .relationships,
        .lifestyle,
        .preferences,
        .goals,
        .habits
    ]

    private init() {}

    // MARK: - Learning Control

    /// Öğrenme aktif mi?
    var isLearningEnabled: Bool {
        get {
            UserDefaults.standard.object(forKey: knowledgeLearningEnabledKey) as? Bool ?? true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: knowledgeLearningEnabledKey)
        }
    }

    // MARK: - Category Permissions

    /// İzin verilen kategoriler
    var allowedCategories: Set<KnowledgeCategory> {
        get {
            guard let saved = UserDefaults.standard.stringArray(forKey: allowedCategoriesKey) else {
                // İlk kullanım - default kategorileri kaydet
                setAllowedCategories(defaultCategories)
                return defaultCategories
            }

            return Set(saved.compactMap { KnowledgeCategory(rawValue: $0) })
        }
        set {
            setAllowedCategories(newValue)
        }
    }

    /// Kategorileri kaydet
    private func setAllowedCategories(_ categories: Set<KnowledgeCategory>) {
        let rawValues = categories.map { $0.rawValue }
        UserDefaults.standard.set(rawValues, forKey: allowedCategoriesKey)
    }

    /// Belirli kategori izinli mi?
    func isCategoryAllowed(_ category: KnowledgeCategory) -> Bool {
        guard isLearningEnabled else { return false }
        return allowedCategories.contains(category)
    }

    /// Kategori iznini değiştir
    func toggleCategory(_ category: KnowledgeCategory) {
        var current = allowedCategories

        if current.contains(category) {
            current.remove(category)
        } else {
            current.insert(category)
        }

        allowedCategories = current
    }

    /// Tüm kategorileri aç
    func enableAllCategories() {
        allowedCategories = Set(KnowledgeCategory.allCases)
    }

    /// Tüm kategorileri kapat
    func disableAllCategories() {
        allowedCategories = []
    }

    /// Default kategorilere dön
    func resetToDefaults() {
        allowedCategories = defaultCategories
    }

    // MARK: - Fact Filtering

    /// Fact'i kaydetmeden önce filtrele
    func shouldAllow(_ fact: ExtractedFact) -> Bool {
        // Öğrenme kapalı mı?
        guard isLearningEnabled else {
            return false
        }

        // Kategori izinli mi?
        guard isCategoryAllowed(fact.category) else {
            return false
        }

        // Hassas bilgi içeriyor mu?
        if containsSensitiveData(fact.value) {
            return false
        }

        return true
    }

    /// UserKnowledge filtreleme
    func shouldAllow(_ knowledge: UserKnowledge) -> Bool {
        guard isLearningEnabled else { return false }
        guard isCategoryAllowed(knowledge.categoryEnum) else { return false }
        guard !containsSensitiveData(knowledge.value) else { return false }

        return true
    }

    /// Knowledge listesini filtrele
    func filterKnowledge(_ knowledge: [UserKnowledge]) -> [UserKnowledge] {
        return knowledge.filter { shouldAllow($0) }
    }

    // MARK: - Sensitive Data Detection

    /// Hassas bilgi içeriyor mu?
    private func containsSensitiveData(_ text: String) -> Bool {
        let normalized = text.lowercased()

        // Hassas keyword'ler
        let sensitiveKeywords = [
            // Finansal
            "kredi kartı", "credit card", "cvv", "kart numarası",
            "iban", "hesap numarası", "account number",

            // Kimlik
            "tc kimlik", "tc no", "kimlik numarası", "passport",
            "ehliyet", "license number", "social security",

            // Sağlık
            "hastalık", "disease", "ilaç", "medication", "reçete",
            "prescription", "doktor", "doctor", "hospital",

            // Şifre
            "şifre", "password", "pin", "parola",

            // Adres detay
            "apartman", "apartment", "daire no", "unit number"
        ]

        for keyword in sensitiveKeywords {
            if normalized.contains(keyword) {
                return true
            }
        }

        // Email pattern
        if isEmail(text) {
            return true
        }

        // Phone pattern (10-11 digit)
        if isPhoneNumber(text) {
            return true
        }

        // Credit card pattern (16 digits)
        if isCreditCard(text) {
            return true
        }

        return false
    }

    // MARK: - Pattern Detection

    /// Email pattern
    private func isEmail(_ text: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: text)
    }

    /// Phone number pattern
    private func isPhoneNumber(_ text: String) -> Bool {
        // 10-11 basamaklı sayılar
        let phoneRegex = "\\d{10,11}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return predicate.evaluate(with: text)
    }

    /// Credit card pattern
    private func isCreditCard(_ text: String) -> Bool {
        // 16 basamaklı sayılar (space/dash ile)
        let cleaned = text.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
        return cleaned.count == 16 && cleaned.allSatisfy { $0.isNumber }
    }

    // MARK: - Data Sanitization

    /// API'ye gönderilecek context'i temizle
    func sanitizeForAPI(_ context: String) -> String {
        var clean = context

        // Email'leri maskele
        guard let emailRegex = try? NSRegularExpression(
            pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}",
            options: []
        ) else { return clean }

        clean = emailRegex.stringByReplacingMatches(
            in: clean,
            options: [],
            range: NSRange(clean.startIndex..., in: clean),
            withTemplate: "[EMAIL]"
        )

        // Telefon numaralarını maskele
        guard let phoneRegex = try? NSRegularExpression(
            pattern: "\\b\\d{10,11}\\b",
            options: []
        ) else { return clean }

        clean = phoneRegex.stringByReplacingMatches(
            in: clean,
            options: [],
            range: NSRange(clean.startIndex..., in: clean),
            withTemplate: "[PHONE]"
        )

        // Kredi kartı numaralarını maskele (16 digit)
        guard let cardRegex = try? NSRegularExpression(
            pattern: "\\b\\d{4}[\\s-]?\\d{4}[\\s-]?\\d{4}[\\s-]?\\d{4}\\b",
            options: []
        ) else { return clean }

        clean = cardRegex.stringByReplacingMatches(
            in: clean,
            options: [],
            range: NSRange(clean.startIndex..., in: clean),
            withTemplate: "[CARD]"
        )

        return clean
    }

    // MARK: - Auto Cleanup

    /// Otomatik temizlik süresi (gün)
    var autoCleanupDays: Int {
        get {
            UserDefaults.standard.object(forKey: autoCleanupDaysKey) as? Int ?? 90
        }
        set {
            UserDefaults.standard.set(newValue, forKey: autoCleanupDaysKey)
        }
    }

    /// Otomatik temizlik yapılmalı mı?
    func shouldAutoCleanup(for knowledge: UserKnowledge) -> Bool {
        guard autoCleanupDays > 0 else { return false }

        let cutoffDate = Calendar.current.date(
            byAdding: .day,
            value: -autoCleanupDays,
            to: Date()
        ) ?? Date()

        return knowledge.createdAt < cutoffDate
    }

    // MARK: - Statistics

    /// Privacy istatistikleri
    func getPrivacyStats() -> PrivacyStats {
        return PrivacyStats(
            learningEnabled: isLearningEnabled,
            allowedCategoriesCount: allowedCategories.count,
            totalCategoriesCount: KnowledgeCategory.allCases.count,
            autoCleanupDays: autoCleanupDays
        )
    }
}

// MARK: - Privacy Statistics

struct PrivacyStats {
    let learningEnabled: Bool
    let allowedCategoriesCount: Int
    let totalCategoriesCount: Int
    let autoCleanupDays: Int

    var categoryPercentage: Double {
        Double(allowedCategoriesCount) / Double(totalCategoriesCount)
    }

    var description: String {
        """
        🔒 Privacy Stats:
        • Learning: \(learningEnabled ? "Enabled" : "Disabled")
        • Allowed Categories: \(allowedCategoriesCount)/\(totalCategoriesCount) (\(Int(categoryPercentage * 100))%)
        • Auto Cleanup: \(autoCleanupDays > 0 ? "\(autoCleanupDays) days" : "Disabled")
        """
    }
}

// MARK: - Privacy Presets

extension KnowledgePrivacyManager {
    /// Privacy presets
    enum PrivacyPreset {
        case strict      // Sadece basic info
        case balanced    // Default
        case open        // Hepsi

        var categories: Set<KnowledgeCategory> {
            switch self {
            case .strict:
                return [.personalInfo, .preferences]

            case .balanced:
                return [
                    .personalInfo,
                    .relationships,
                    .lifestyle,
                    .preferences,
                    .goals,
                    .habits
                ]

            case .open:
                return Set(KnowledgeCategory.allCases)
            }
        }

        var localizedName: String {
            switch self {
            case .strict:
                return String(localized: "privacy.preset.strict", defaultValue: "Katı", comment: "Strict privacy preset")
            case .balanced:
                return String(localized: "privacy.preset.balanced", defaultValue: "Dengeli", comment: "Balanced privacy preset")
            case .open:
                return String(localized: "privacy.preset.open", defaultValue: "Açık", comment: "Open privacy preset")
            }
        }
    }

    /// Preset uygula
    func applyPreset(_ preset: PrivacyPreset) {
        allowedCategories = preset.categories
    }
}

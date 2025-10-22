//
//  ChatIntentDetector.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Intent detection for AI chat optimization
//

import Foundation

/// Kullanıcı sorusunu analiz edip kategorize eder
struct ChatIntentDetector {

    /// Soru intent'i
    enum Intent {
        case messageTemplate    // Mesaj taslağı isteniyor
        case lastContact       // Son iletişim bilgisi
        case contactAdvice     // Ne zaman iletişime geçmeli
        case relationshipAdvice // İlişki geliştirme önerisi
        case contactHistory    // İletişim geçmişi
        case partnerInfo       // Partner özel bilgiler
        case fullSummary       // Tüm bilgiler
        case general           // Genel soru

        var needsMinimalData: Bool {
            switch self {
            case .messageTemplate, .lastContact:
                return true
            default:
                return false
            }
        }

        var needsHistory: Bool {
            switch self {
            case .contactHistory, .fullSummary, .relationshipAdvice:
                return true
            default:
                return false
            }
        }

        var needsPartnerData: Bool {
            switch self {
            case .partnerInfo, .fullSummary:
                return true
            default:
                return false
            }
        }
    }

    /// Soruyu analiz et ve intent belirle
    static func detect(question: String) -> Intent {
        // Noktalama işaretlerini kaldır
        let cleaned = question
            .components(separatedBy: CharacterSet.punctuationCharacters)
            .joined(separator: " ")

        let q = cleaned.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current) // Türkçe karakter normalize
            .trimmingCharacters(in: .whitespaces)

        // Mesaj taslağı
        if containsAny(q, keywords: ["mesaj", "taslak", "yaz", "söyle", "de"]) {
            return .messageTemplate
        }

        // Son iletişim
        if containsAny(q, keywords: ["son", "en son", "ne zaman görüş", "kaç gün"]) &&
           !containsAny(q, keywords: ["sonraki", "gelecek"]) {
            return .lastContact
        }

        // Zamanlama önerisi
        if containsAny(q, keywords: ["ne zaman ara", "ne zaman görüş", "ne zaman mesaj", "zaman"]) {
            return .contactAdvice
        }

        // İletişim geçmişi
        if containsAny(q, keywords: ["geçmiş", "tarihçe", "önceki", "eski"]) {
            return .contactHistory
        }

        // Partner özel
        if containsAny(q, keywords: ["partner", "sevgili", "yıldönüm", "sevgi dil", "romantik"]) {
            return .partnerInfo
        }

        // İlişki önerisi
        if containsAny(q, keywords: ["nasıl gelişti", "öneri", "tavsiye", "iyileştir", "geliştir"]) {
            return .relationshipAdvice
        }

        // Tam özet
        if containsAny(q, keywords: ["tüm", "hepsi", "her şey", "sırala", "liste", "bildik", "neler"]) {
            return .fullSummary
        }

        // Varsayılan
        return .general
    }

    /// Birden fazla keyword'den en az birini içeriyor mu?
    private static func containsAny(_ text: String, keywords: [String]) -> Bool {
        keywords.contains { text.contains($0) }
    }

    /// Intent'e göre maksimum prompt uzunluğu (kelime)
    static func maxPromptWords(for intent: Intent) -> Int {
        switch intent {
        case .messageTemplate, .lastContact:
            return 30
        case .contactAdvice, .general:
            return 50
        case .relationshipAdvice, .contactHistory:
            return 80
        case .partnerInfo:
            return 60
        case .fullSummary:
            return 100
        }
    }

    /// Intent'e göre maksimum response uzunluğu (kelime)
    static func maxResponseWords(for intent: Intent) -> Int {
        switch intent {
        case .messageTemplate:
            return 40
        case .lastContact, .contactAdvice:
            return 50
        case .general:
            return 80
        case .relationshipAdvice, .contactHistory:
            return 120
        case .partnerInfo, .fullSummary:
            return 150
        }
    }

    /// Intent için system instruction
    static func systemInstruction(for intent: Intent) -> String {
        let maxWords = maxResponseWords(for: intent)

        switch intent {
        case .messageTemplate:
            return """
            Türkçe mesaj taslağı yaz.
            Maksimum \(maxWords) kelime.
            Samimi ve doğal ol.
            1 emoji max.
            """

        case .lastContact, .contactAdvice:
            return """
            Türkçe kısa cevap ver.
            Maksimum \(maxWords) kelime.
            Net ve öz ol.
            Tarih/zaman bilgisi ver.
            """

        case .relationshipAdvice:
            return """
            Türkçe yapıcı öneri ver.
            Maksimum \(maxWords) kelime.
            2-3 madde yeterli.
            Uygulanabilir öneriler.
            """

        case .contactHistory:
            return """
            Türkçe özet liste yap.
            Maksimum \(maxWords) kelime.
            Tarihleri belirt.
            Madde madde yaz.
            """

        case .partnerInfo:
            return """
            Türkçe partner bilgisi ver.
            Maksimum \(maxWords) kelime.
            Duygusal ve samimi ol.
            İlgili detayları paylaş.
            """

        case .fullSummary:
            return """
            Türkçe kategorize özet ver.
            Maksimum \(maxWords) kelime.
            Başlıklar kullan (📋).
            Sadece önemli bilgiler.
            """

        case .general:
            return """
            Türkçe net cevap ver.
            Maksimum \(maxWords) kelime.
            Soruya odaklan.
            Gereksiz detay yok.
            """
        }
    }
}

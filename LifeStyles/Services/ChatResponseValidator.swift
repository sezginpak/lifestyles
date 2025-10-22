//
//  ChatResponseValidator.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Response validation for AI chat quality control
//

import Foundation

/// AI response'larını validate eder
struct ChatResponseValidator {

    /// Validation sonucu
    struct ValidationResult {
        let isValid: Bool
        let issues: [ValidationIssue]

        static let valid = ValidationResult(isValid: true, issues: [])

        static func invalid(_ issues: ValidationIssue...) -> ValidationResult {
            ValidationResult(isValid: false, issues: issues)
        }
    }

    /// Validation sorunları
    enum ValidationIssue: String {
        case tooShort = "Cevap çok kısa"
        case tooLong = "Cevap çok uzun"
        case hasRepetition = "Tekrar içeriyor"
        case wrongName = "İsim yanlış"
        case irrelevant = "Soruyla alakasız"
        case emptyResponse = "Boş cevap"
    }

    /// Response'u validate et
    static func validate(
        response: String,
        question: String,
        friendName: String,
        intent: ChatIntentDetector.Intent
    ) -> ValidationResult {
        var issues: [ValidationIssue] = []

        // Boş kontrol
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return .invalid(.emptyResponse)
        }

        // Uzunluk kontrolü
        let wordCount = trimmed.split(separator: " ").count
        let maxWords = ChatIntentDetector.maxResponseWords(for: intent)

        if wordCount < 5 {
            issues.append(.tooShort)
        }

        if wordCount > maxWords + 50 {
            issues.append(.tooLong)
        }

        // Tekrar kontrolü
        if hasRepetition(response) {
            issues.append(.hasRepetition)
        }

        // İsim kontrolü (sadece genel mesaj değilse)
        if intent != .general && intent != .fullSummary {
            if !response.localizedCaseInsensitiveContains(friendName) {
                issues.append(.wrongName)
            }
        }

        // Soruyla ilgili mi?
        if !isRelevant(response: response, question: question) {
            issues.append(.irrelevant)
        }

        return ValidationResult(
            isValid: issues.isEmpty,
            issues: issues
        )
    }

    /// Tekrar var mı kontrol et
    private static func hasRepetition(_ text: String) -> Bool {
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.count > 10 }

        // Aynı cümle 2 kez tekrar ediyor mu?
        for i in 0..<sentences.count {
            for j in (i+1)..<sentences.count {
                let similarity = calculateSimilarity(sentences[i], sentences[j])
                if similarity > 0.8 { // %80'den fazla benzer
                    return true
                }
            }
        }

        return false
    }

    /// İki string arası benzerlik (0-1)
    private static func calculateSimilarity(_ s1: String, _ s2: String) -> Double {
        let words1 = Set(s1.lowercased().split(separator: " "))
        let words2 = Set(s2.lowercased().split(separator: " "))

        guard !words1.isEmpty && !words2.isEmpty else { return 0 }

        let intersection = words1.intersection(words2).count
        let union = words1.union(words2).count

        return Double(intersection) / Double(union)
    }

    /// Response soruyla alakalı mı?
    private static func isRelevant(response: String, question: String) -> Bool {
        // Basit keyword matching
        let questionWords = Set(
            question.lowercased()
                .folding(options: .diacriticInsensitive, locale: .current)
                .split(separator: " ")
                .filter { $0.count > 3 } // Kısa kelimeleri atla
                .map { String($0) } // Substring -> String
        )

        let responseWords = Set(
            response.lowercased()
                .folding(options: .diacriticInsensitive, locale: .current)
                .split(separator: " ")
                .map { String($0) } // Substring -> String
        )

        // En az 1 ortak kelime olmalı (veya question çok kısa)
        if questionWords.isEmpty {
            return true // Question çok kısa, skip
        }

        let commonWords = questionWords.intersection(responseWords)
        return !commonWords.isEmpty
    }

    /// Response'u temizle ve düzelt
    static func sanitize(_ response: String) -> String {
        var cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)

        // Çok fazla satır break varsa düzelt
        while cleaned.contains("\n\n\n") {
            cleaned = cleaned.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }

        // Baştaki/sondaki gereksiz punctuation
        cleaned = cleaned.trimmingCharacters(in: CharacterSet(charactersIn: ".,;:!?"))

        return cleaned
    }
}

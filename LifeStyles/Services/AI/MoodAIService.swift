//
//  MoodAIService.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  AI-powered mood analizi (iOS 26+)
//

import Foundation
import SwiftData

#if canImport(FoundationModels)
import FoundationModels
#endif

@Observable
class MoodAIService {
    static let shared = MoodAIService()

    private init() {}

    // MARK: - Haftalık Mood Analizi

    /// Bu hafta ruh hali analizi
    @available(iOS 26.0, *)
    func analyzeWeeklyMood(entries: [MoodEntry], context: ModelContext) async -> MoodAIInsight {
        guard !entries.isEmpty else {
            return .empty()
        }

        // Son 7 günü filtrele
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weekEntries = entries.filter { $0.date >= weekAgo }

        guard !weekEntries.isEmpty else {
            return MoodAIInsight(
                summary: "Bu hafta mood kaydı yok",
                analysis: "Mood takibine başlamak için her gün nasıl hissettiğinizi kaydedin.",
                suggestions: ["Her sabah mood'unuzu kaydedin"],
                generatedAt: Date()
            )
        }

        // Prompt oluştur
        let prompt = buildWeeklyAnalysisPrompt(entries: weekEntries, context: context)

        do {
            let session = LanguageModelSession(
                model: SystemLanguageModel.default,
                instructions: {
                    """
                    Sen bir yaşam koçu asistanısın. Kullanıcının haftalık mood verilerini analiz et.

                    KURALL AR:
                    - Maksimum 150 kelime
                    - Empatik ve yapıcı ol
                    - Somut gözlemler paylaş
                    - 2-3 öneri ver
                    - Türkçe yaz
                    - Motivasyonel tonla konuş
                    """
                }
            )

            let response = try await session.respond(to: prompt)

            // Response'u parse et
            return parseMoodAnalysis(response.content)

        } catch {
            print("❌ AI mood analysis error: \(error)")
            return generateFallbackInsight(entries: weekEntries)
        }
    }

    // MARK: - Prompt Builder

    private func buildWeeklyAnalysisPrompt(entries: [MoodEntry], context: ModelContext) -> String {
        var prompt = "Son 7 günün mood kayıtları:\n\n"

        // Mood'ları gün gün listele
        let calendar = Calendar.current
        let groupedByDay = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.date) }

        for (date, dayEntries) in groupedByDay.sorted(by: { $0.key < $1.key }) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            formatter.locale = Locale(identifier: "tr_TR")
            let dayName = formatter.string(from: date)

            let moods = dayEntries.map { $0.moodType.emoji }.joined(separator: " ")
            prompt += "• \(dayName): \(moods)\n"

            // Not varsa ekle
            if let note = dayEntries.first?.note, !note.isEmpty {
                prompt += "  Not: \(note)\n"
            }
        }

        // İlişkili goal'lar
        let relatedGoals = entries.compactMap { $0.relatedGoals }.flatMap { $0 }
        if !relatedGoals.isEmpty {
            let uniqueGoals = Set(relatedGoals.map { $0.title })
            prompt += "\nTamamlanan hedefler: \(uniqueGoals.joined(separator: ", "))\n"
        }

        // İlişkili friend'ler
        let relatedFriends = entries.compactMap { $0.relatedFriends }.flatMap { $0 }
        if !relatedFriends.isEmpty {
            let uniqueFriends = Set(relatedFriends.map { $0.name })
            prompt += "Görüşülen kişiler: \(uniqueFriends.joined(separator: ", "))\n"
        }

        prompt += "\nSoru: Bu hafta kullanıcının ruh hali nasıldı ve neden? Ne önerirsin?"

        return prompt
    }

    // MARK: - Response Parser

    private func parseMoodAnalysis(_ content: String) -> MoodAIInsight {
        // Basit parsing - ilk paragraf summary, geri kalanı analysis
        let paragraphs = content.components(separatedBy: "\n\n")

        let summary = paragraphs.first ?? content
        let analysis = paragraphs.count > 1 ? paragraphs[1...].joined(separator: "\n\n") : content

        // Önerileri çıkar (• veya - ile başlayanlar)
        let lines = content.components(separatedBy: "\n")
        let suggestions = lines.filter {
            $0.trimmingCharacters(in: .whitespaces).hasPrefix("•") ||
            $0.trimmingCharacters(in: .whitespaces).hasPrefix("-")
        }.map {
            $0.trimmingCharacters(in: CharacterSet(charactersIn: "•- "))
        }

        return MoodAIInsight(
            summary: String(summary.prefix(200)),
            analysis: analysis,
            suggestions: suggestions.isEmpty ? ["Mood takibine devam edin"] : suggestions,
            generatedAt: Date()
        )
    }

    // MARK: - Fallback

    private func generateFallbackInsight(entries: [MoodEntry]) -> MoodAIInsight {
        let avgScore = entries.reduce(0.0) { $0 + $1.score } / Double(entries.count)
        let positiveCount = entries.filter { $0.moodType.isPositive }.count
        let negativeCount = entries.filter { $0.moodType.isNegative }.count

        var summary: String
        var suggestions: [String] = []

        if avgScore > 0.5 {
            summary = "Bu hafta genelde iyi bir ruh halindesiniz! 🌟"
            suggestions = [
                "Bu pozitif enerjiyi korumak için düzenli uyku",
                "Sevdiklerinizle vakit geçirmeye devam edin"
            ]
        } else if avgScore < -0.5 {
            summary = "Bu hafta biraz zorlanıyor gibisiniz."
            suggestions = [
                "Kendinize zaman ayırın",
                "Güvendiğiniz biriyle konuşun",
                "Küçük hedeflerle başlayın"
            ]
        } else {
            summary = "Bu hafta dengeli bir hafta geçirdiniz."
            suggestions = [
                "Mood takibine devam edin",
                "Pozitif anları not alın"
            ]
        }

        let analysis = "Son 7 günde \(positiveCount) pozitif, \(negativeCount) negatif mood kaydettiniz."

        return MoodAIInsight(
            summary: summary,
            analysis: analysis,
            suggestions: suggestions,
            generatedAt: Date()
        )
    }

    // MARK: - Journal Prompt Generation

    /// Journal yazmak için AI prompt üret
    @available(iOS 26.0, *)
    func generateJournalPrompt(journalType: JournalType) async -> String {
        // Her tip için önceden tanımlı promptlar var
        return journalType.aiPrompt
    }
}

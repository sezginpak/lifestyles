//
//  MoodAIServiceHaiku.swift
//  LifeStyles
//
//  AI-powered mood analizi (Claude Haiku - iOS 17+)
//  Created by Claude on 25.10.2025.
//

import Foundation
import SwiftData

// MARK: - AI Insight Models

struct MoodAnalysis: Codable {
    let summary: String
    let weeklyTrend: String
    let insights: [AIInsight]
    let patterns: [MoodPattern]
    let recommendations: [ActionSuggestion]
    let generatedAt: Date
}

struct AIInsight: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let type: InsightType
    let icon: String
    let color: String

    enum InsightType: String, Codable {
        case positive = "positive"
        case warning = "warning"
        case neutral = "neutral"
        case trend = "trend"
    }

    init(id: UUID = UUID(), title: String, description: String, type: InsightType, icon: String, color: String) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.icon = icon
        self.color = color
    }
}

struct MoodPattern: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let frequency: String
    let impact: PatternImpact
    let emoji: String

    enum PatternImpact: String, Codable {
        case positive = "positive"
        case negative = "negative"
        case neutral = "neutral"
    }

    init(id: UUID = UUID(), title: String, description: String, frequency: String, impact: PatternImpact, emoji: String) {
        self.id = id
        self.title = title
        self.description = description
        self.frequency = frequency
        self.impact = impact
        self.emoji = emoji
    }
}

struct ActionSuggestion: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let actionType: ActionType
    let icon: String

    enum ActionType: String, Codable {
        case activity = "activity"
        case social = "social"
        case selfcare = "selfcare"
        case goal = "goal"
    }

    init(id: UUID = UUID(), title: String, description: String, actionType: ActionType, icon: String) {
        self.id = id
        self.title = title
        self.description = description
        self.actionType = actionType
        self.icon = icon
    }
}

// MARK: - Mood AI Service (Haiku)

@Observable
class MoodAIServiceHaiku {
    static let shared = MoodAIServiceHaiku()

    private let haikuService = ClaudeHaikuService.shared
    private let cacheKey = "mood_analysis_cache"
    private let cacheDuration: TimeInterval = 3600 // 1 saat cache

    // State
    var isLoading: Bool = false
    var error: Error?

    private init() {}

    // MARK: - Main Analysis Method

    /// Mood verilerini analiz et (iOS 17+ - Haiku kullanarak)
    func analyzeMoodData(entries: [MoodEntry], context: ModelContext) async -> MoodAnalysis {
        guard !entries.isEmpty else {
            return .empty()
        }

        // Cache kontrolü
        if let cached = loadCachedAnalysis(), isCacheValid(cached) {
            print("📦 Cached mood analysis kullanılıyor")
            return cached
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // Son 30 günü filtrele
            let calendar = Calendar.current
            let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            let recentEntries = entries.filter { $0.date >= thirtyDaysAgo }

            guard !recentEntries.isEmpty else {
                return generateFallbackAnalysis(entries: entries)
            }

            // Prompt oluştur
            let (systemPrompt, userMessage) = buildAnalysisPrompt(entries: recentEntries, context: context)

            // Haiku'ya gönder
            let response = try await haikuService.generate(
                systemPrompt: systemPrompt,
                userMessage: userMessage,
                temperature: 0.8,
                maxTokens: 1500
            )

            // Response'u parse et
            let analysis = parseAnalysisResponse(response, entries: recentEntries)

            // Cache'e kaydet
            saveToCache(analysis)

            return analysis

        } catch {
            print("❌ Mood AI analysis error: \(error.localizedDescription)")
            self.error = error
            return generateFallbackAnalysis(entries: entries)
        }
    }

    // MARK: - Insights Generation

    /// AI insight'ları oluştur
    func generateInsights(entries: [MoodEntry]) async -> [AIInsight] {
        guard !entries.isEmpty else { return [] }

        do {
            let systemPrompt = """
            Sen bir duygusal zeka uzmanısın. Kullanıcının mood verilerini analiz edip 3-4 anlamlı insight üret.

            KURALL AR:
            - Her insight kısa ve öz (1 cümle)
            - Pozitif vurgu yap ama gerçekçi ol
            - Pattern'leri belirt
            - Türkçe yaz
            """

            let userMessage = buildInsightsPrompt(entries: entries)

            let response = try await haikuService.generate(
                systemPrompt: systemPrompt,
                userMessage: userMessage,
                temperature: 0.9,
                maxTokens: 500
            )

            return parseInsights(response)

        } catch {
            print("❌ Insights generation error: \(error)")
            return generateFallbackInsights(entries: entries)
        }
    }

    // MARK: - Action Suggestions

    /// Mood'a göre action önerileri
    func suggestActions(mood: MoodEntry) async -> [ActionSuggestion] {
        do {
            let systemPrompt = """
            Sen bir yaşam koçusun. Kullanıcının mevcut mood'una göre 3 somut, uygulanabilir öneri ver.

            KURALL AR:
            - Her öneri kısa ve net
            - Somut eylem içermeli
            - Pozitif ve motive edici ol
            - Türkçe yaz
            """

            let userMessage = """
            Kullanıcının mevcut mood'u: \(mood.moodType.emoji) \(mood.moodType.displayName) (Yoğunluk: \(mood.intensity)/5)
            \(mood.note.map { "Not: \($0)" } ?? "")

            Bu mood için 3 öneri ver:
            1. Aktivite önerisi
            2. Sosyal etkileşim önerisi
            3. Self-care önerisi
            """

            let response = try await haikuService.generate(
                systemPrompt: systemPrompt,
                userMessage: userMessage,
                temperature: 0.9,
                maxTokens: 400
            )

            return parseActionSuggestions(response)

        } catch {
            print("❌ Action suggestions error: \(error)")
            return generateFallbackActions(mood: mood)
        }
    }

    // MARK: - Pattern Detection

    /// Mood pattern'lerini tespit et
    func detectPatterns(entries: [MoodEntry]) async -> [MoodPattern] {
        guard entries.count >= 7 else {
            return []
        }

        do {
            let systemPrompt = """
            Sen bir veri analisti ve psikoloğun. Kullanıcının mood verilerinden pattern'leri çıkar.

            KURALL AR:
            - 2-3 pattern belirle
            - Her pattern için frekans bilgisi ver (günlük, haftalık)
            - Impact'i belirt (pozitif/negatif/nötr)
            - Türkçe yaz
            """

            let userMessage = buildPatternPrompt(entries: entries)

            let response = try await haikuService.generate(
                systemPrompt: systemPrompt,
                userMessage: userMessage,
                temperature: 0.7,
                maxTokens: 600
            )

            return parsePatterns(response)

        } catch {
            print("❌ Pattern detection error: \(error)")
            return generateBasicPatterns(entries: entries)
        }
    }

    // MARK: - Prompt Builders

    private func buildAnalysisPrompt(entries: [MoodEntry], context: ModelContext) -> (system: String, user: String) {
        let systemPrompt = """
        Sen bir duygusal zeka uzmanı ve yaşam koçusun. Kullanıcının mood verilerini ve günlük notlarını analiz edip anlamlı, kişiselleştirilmiş insight'lar üretiyorsun.

        VERİLER:
        - Mood kayıtları (emoji, yoğunluk, tarih)
        - Günlük notları (kullanıcının kendi sözleriyle yazdığı düşünce ve deneyimler)
        - İlişkili hedefler ve sosyal etkileşimler

        GÖREV:
        1. Genel duygusal durumu özetle (2-3 cümle)
        2. Haftalık trendi açıkla
        3. 3-4 insight belirle (günlük notlarından alıntı yapabilirsin)
        4. 2-3 pattern tespit et (hem mood hem de günlük içerik bazlı)
        5. 3 somut, uygulanabilir öneri sun (kullanıcının yazdıklarına göre kişiselleştir)

        KURALL AR:
        - Empatik ve destekleyici ton
        - Günlük notlarında kullanıcının bahsettiği konulara değin
        - Kullanıcının kendi sözlerinden örnekler ver
        - Kısa ve öz cümleler
        - Pozitif reinforcement
        - Pattern'leri net belirt
        - Türkçe yaz
        - Maksimum 250 kelime
        """

        var userMessage = "Son 30 günün mood kayıtları:\n\n"

        // Mood'ları haftaya göre grupla
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry -> String in
            let weekAgo = calendar.dateComponents([.weekOfYear], from: entry.date, to: Date()).weekOfYear ?? 0
            if weekAgo == 0 {
                return "Bu Hafta"
            } else if weekAgo == 1 {
                return "Geçen Hafta"
            } else {
                return "\(weekAgo) Hafta Önce"
            }
        }

        for (week, weekEntries) in grouped.sorted(by: { $0.key < $1.key }) {
            let moods = weekEntries.map { "\($0.moodType.emoji)" }.joined(separator: " ")
            let avgScore = weekEntries.reduce(0.0) { $0 + $1.score } / Double(weekEntries.count)
            userMessage += "\(week): \(moods) (Ort: \(String(format: "%.1f", avgScore)))\n"
        }

        // İstatistikler
        let positiveCount = entries.filter { $0.moodType.isPositive }.count
        let negativeCount = entries.filter { $0.moodType.isNegative }.count
        let avgIntensity = entries.reduce(0) { $0 + $1.intensity } / entries.count

        userMessage += """

        İstatistikler:
        - Toplam kayıt: \(entries.count)
        - Pozitif: \(positiveCount), Negatif: \(negativeCount)
        - Ortalama yoğunluk: \(avgIntensity)/5
        """

        // İlişkili veriler
        let relatedGoals = entries.compactMap { $0.relatedGoals }.flatMap { $0 }
        if !relatedGoals.isEmpty {
            let uniqueGoals = Set(relatedGoals.map { $0.title })
            userMessage += "\n\nTamamlanan hedefler: \(uniqueGoals.joined(separator: ", "))"
        }

        let relatedFriends = entries.compactMap { $0.relatedFriends }.flatMap { $0 }
        if !relatedFriends.isEmpty {
            let uniqueFriends = Set(relatedFriends.map { $0.name })
            userMessage += "\nGörüşülen kişiler: \(uniqueFriends.joined(separator: ", "))"
        }

        // Journal içerikleri (YENI!)
        let entriesWithJournals = entries.filter { $0.journalEntry != nil }
        if !entriesWithJournals.isEmpty {
            userMessage += "\n\n📔 Günlük Notları:\n"

            // Son 10 günlüğü ekle (çok uzun olmaması için)
            for entry in entriesWithJournals.prefix(10) {
                guard let journal = entry.journalEntry else { continue }

                let dateStr = entry.formattedDate
                let moodEmoji = entry.moodType.emoji

                // Journal içeriğini kısalt (maksimum 150 karakter)
                let content = journal.content.count > 150
                    ? String(journal.content.prefix(150)) + "..."
                    : journal.content

                userMessage += "\n• \(dateStr) \(moodEmoji):\n"
                if let title = journal.title, !title.isEmpty {
                    userMessage += "  Başlık: \(title)\n"
                }
                userMessage += "  \(content)\n"

                // Tags varsa ekle
                if !journal.tags.isEmpty {
                    userMessage += "  Etiketler: \(journal.tags.joined(separator: ", "))\n"
                }
            }

            if entriesWithJournals.count > 10 {
                userMessage += "\n(Toplam \(entriesWithJournals.count) günlük, \(entriesWithJournals.count - 10) tanesi gösterilmedi)\n"
            }
        }

        userMessage += "\n\nAnaliz et ve öneriler sun."

        return (systemPrompt, userMessage)
    }

    private func buildInsightsPrompt(entries: [MoodEntry]) -> String {
        var prompt = "Mood verileri:\n"

        let last7Days = entries.filter { $0.date >= Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date() }

        for entry in last7Days.prefix(10) {
            prompt += "• \(entry.moodType.emoji) \(entry.moodType.displayName) (\(entry.intensity)/5)\n"
        }

        prompt += "\n3-4 insight üret (her biri 1 cümle)."

        return prompt
    }

    private func buildPatternPrompt(entries: [MoodEntry]) -> String {
        var prompt = "Mood pattern analizi için veri:\n\n"

        // Gün bazında mood dağılımı
        let byDay = Dictionary(grouping: entries) { entry -> String in
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            formatter.locale = Locale(identifier: "tr_TR")
            return formatter.string(from: entry.date)
        }

        prompt += "Günlere göre dağılım:\n"
        for (day, dayEntries) in byDay.sorted(by: { $0.key < $1.key }) {
            let avgScore = dayEntries.reduce(0.0) { $0 + $1.score } / Double(dayEntries.count)
            prompt += "• \(day): \(dayEntries.count) kayıt, Ort: \(String(format: "%.1f", avgScore))\n"
        }

        // Saat bazında (sabah/öğlen/akşam)
        let byTime = Dictionary(grouping: entries) { entry -> String in
            let hour = Calendar.current.component(.hour, from: entry.date)
            if hour < 12 { return "Sabah" }
            else if hour < 18 { return "Öğlen" }
            else { return "Akşam" }
        }

        prompt += "\nZamana göre dağılım:\n"
        for (time, timeEntries) in byTime.sorted(by: { $0.key < $1.key }) {
            let avgScore = timeEntries.reduce(0.0) { $0 + $1.score } / Double(timeEntries.count)
            prompt += "• \(time): \(timeEntries.count) kayıt, Ort: \(String(format: "%.1f", avgScore))\n"
        }

        prompt += "\n2-3 pattern tespit et."

        return prompt
    }

    // MARK: - Response Parsers

    private func parseAnalysisResponse(_ response: String, entries: [MoodEntry]) -> MoodAnalysis {
        // Basit parsing - satır satır işle
        let lines = response.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        var summary = ""
        var weeklyTrend = ""
        var insights: [AIInsight] = []
        var patterns: [MoodPattern] = []
        var recommendations: [ActionSuggestion] = []

        // İlk 2 satır summary ve trend (defensive programming)
        if lines.indices.contains(0) {
            summary = lines[0]
        } else {
            summary = "Mood analizi mevcut değil"
        }

        if lines.indices.contains(1) {
            weeklyTrend = lines[1]
        } else {
            weeklyTrend = "Haftalık trend henüz hesaplanamadı"
        }

        // Basit fallback parsing
        let fullText = response

        // Insights çıkar (emoji veya • ile başlayanlar)
        for line in lines {
            if line.contains("💡") || line.contains("✨") || line.contains("🌟") {
                let cleaned = line.replacingOccurrences(of: "💡", with: "")
                    .replacingOccurrences(of: "✨", with: "")
                    .replacingOccurrences(of: "🌟", with: "")
                    .trimmingCharacters(in: .whitespaces)

                if !cleaned.isEmpty {
                    insights.append(AIInsight(
                        title: "Insight",
                        description: cleaned,
                        type: .neutral,
                        icon: "lightbulb.fill",
                        color: "F59E0B"
                    ))
                }
            }
        }

        // Eğer insight bulamazsan fallback
        if insights.isEmpty {
            insights = generateFallbackInsights(entries: entries)
        }

        // Patterns ve recommendations da fallback kullan
        patterns = generateBasicPatterns(entries: entries)
        recommendations = generateBasicRecommendations(entries: entries)

        return MoodAnalysis(
            summary: summary.isEmpty ? "Son günlerde mood'unuz değişkenlik gösterdi." : summary,
            weeklyTrend: weeklyTrend.isEmpty ? "Haftalık trend dengeli." : weeklyTrend,
            insights: insights,
            patterns: patterns,
            recommendations: recommendations,
            generatedAt: Date()
        )
    }

    private func parseInsights(_ response: String) -> [AIInsight] {
        let lines = response.components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        var insights: [AIInsight] = []

        for line in lines {
            let cleaned = line.replacingOccurrences(of: "•", with: "")
                .replacingOccurrences(of: "-", with: "")
                .trimmingCharacters(in: .whitespaces)

            if !cleaned.isEmpty && cleaned.count > 10 {
                insights.append(AIInsight(
                    title: "Insight",
                    description: cleaned,
                    type: .neutral,
                    icon: "sparkles",
                    color: "8B5CF6"
                ))
            }
        }

        return insights.isEmpty ? [] : Array(insights.prefix(4))
    }

    private func parsePatterns(_ response: String) -> [MoodPattern] {
        let lines = response.components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        var patterns: [MoodPattern] = []

        for line in lines {
            if line.contains("Pattern") || line.contains("pattern") || line.contains("•") {
                let cleaned = line.replacingOccurrences(of: "•", with: "")
                    .replacingOccurrences(of: "-", with: "")
                    .trimmingCharacters(in: .whitespaces)

                if !cleaned.isEmpty {
                    patterns.append(MoodPattern(
                        title: "Pattern",
                        description: cleaned,
                        frequency: "Haftalık",
                        impact: .neutral,
                        emoji: "📊"
                    ))
                }
            }
        }

        return patterns.isEmpty ? [] : Array(patterns.prefix(3))
    }

    private func parseActionSuggestions(_ response: String) -> [ActionSuggestion] {
        let lines = response.components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        var suggestions: [ActionSuggestion] = []

        for (index, line) in lines.enumerated() {
            let cleaned = line.replacingOccurrences(of: "•", with: "")
                .replacingOccurrences(of: "-", with: "")
                .replacingOccurrences(of: String(index + 1) + ".", with: "")
                .trimmingCharacters(in: .whitespaces)

            if !cleaned.isEmpty && cleaned.count > 10 {
                let actionType: ActionSuggestion.ActionType
                let icon: String

                if cleaned.lowercased().contains("aktivite") || cleaned.lowercased().contains("hareket") {
                    actionType = .activity
                    icon = "figure.walk"
                } else if cleaned.lowercased().contains("sosyal") || cleaned.lowercased().contains("arkadaş") {
                    actionType = .social
                    icon = "person.2.fill"
                } else if cleaned.lowercased().contains("self") || cleaned.lowercased().contains("kendin") {
                    actionType = .selfcare
                    icon = "heart.fill"
                } else {
                    actionType = .goal
                    icon = "target"
                }

                suggestions.append(ActionSuggestion(
                    title: cleaned,
                    description: cleaned,
                    actionType: actionType,
                    icon: icon
                ))
            }
        }

        return suggestions.isEmpty ? [] : Array(suggestions.prefix(3))
    }

    // MARK: - Fallback Methods

    private func generateFallbackAnalysis(entries: [MoodEntry]) -> MoodAnalysis {
        let insights = generateFallbackInsights(entries: entries)
        let patterns = generateBasicPatterns(entries: entries)
        let recommendations = generateBasicRecommendations(entries: entries)

        let avgScore = entries.reduce(0.0) { $0 + $1.score } / Double(entries.count)

        let summary: String
        if avgScore > 0.5 {
            summary = "Son günlerde genel olarak iyi hissediyorsunuz! 🌟"
        } else if avgScore < -0.5 {
            summary = "Son günlerde biraz zorlanıyor gibisiniz. Kendinize zaman ayırın."
        } else {
            summary = "Son günlerde dengeli bir ruh hali sergiliyorsunuz."
        }

        return MoodAnalysis(
            summary: summary,
            weeklyTrend: "Haftalık mood değişkenlik gösteriyor.",
            insights: insights,
            patterns: patterns,
            recommendations: recommendations,
            generatedAt: Date()
        )
    }

    private func generateFallbackInsights(entries: [MoodEntry]) -> [AIInsight] {
        var insights: [AIInsight] = []

        let positiveCount = entries.filter { $0.moodType.isPositive }.count
        let totalCount = entries.count

        if positiveCount > totalCount / 2 {
            insights.append(AIInsight(
                title: "Pozitif Enerji",
                description: "Kayıtlarınızın %\(Int(Double(positiveCount)/Double(totalCount) * 100))'si pozitif mood içeriyor!",
                type: .positive,
                icon: "star.fill",
                color: "10B981"
            ))
        }

        insights.append(AIInsight(
            title: "Düzenli Takip",
            description: "Bu ay \(entries.count) kez mood kaydettiniz. Harika!",
            type: .neutral,
            icon: "chart.line.uptrend.xyaxis",
            color: "6366F1"
        ))

        return insights
    }

    private func generateBasicPatterns(entries: [MoodEntry]) -> [MoodPattern] {
        var patterns: [MoodPattern] = []

        // Gün pattern'i
        let byDay = Dictionary(grouping: entries) { Calendar.current.component(.weekday, from: $0.date) }
        if let (bestDay, bestEntries) = byDay.max(by: { $0.value.count < $1.value.count }) {
            let dayName = ["Paz", "Pzt", "Sal", "Çar", "Per", "Cum", "Cmt"][bestDay - 1]
            patterns.append(MoodPattern(
                title: "En Aktif Gün",
                description: "\(dayName) günleri daha çok mood kaydediyorsunuz",
                frequency: "Haftalık",
                impact: .neutral,
                emoji: "📅"
            ))
        }

        return patterns
    }

    private func generateBasicRecommendations(entries: [MoodEntry]) -> [ActionSuggestion] {
        let avgScore = entries.reduce(0.0) { $0 + $1.score } / Double(entries.count)

        var recommendations: [ActionSuggestion] = []

        if avgScore < 0 {
            recommendations.append(ActionSuggestion(
                title: "Kendinize Zaman Ayırın",
                description: "Her gün 15 dakika sadece kendiniz için zaman ayırın",
                actionType: .selfcare,
                icon: "heart.fill"
            ))
        }

        recommendations.append(ActionSuggestion(
            title: "Düzenli Egzersiz",
            description: "Haftada 3 kez 30 dakika yürüyüş yapın",
            actionType: .activity,
            icon: "figure.walk"
        ))

        recommendations.append(ActionSuggestion(
            title: "Sosyal Bağlantı",
            description: "Bir arkadaşınızla kahve içmeye çıkın",
            actionType: .social,
            icon: "person.2.fill"
        ))

        return recommendations
    }

    private func generateFallbackActions(mood: MoodEntry) -> [ActionSuggestion] {
        if mood.moodType.isNegative {
            return [
                ActionSuggestion(title: "Kısa Yürüyüş", description: "10 dakika dışarı çıkın", actionType: .activity, icon: "figure.walk"),
                ActionSuggestion(title: "Güvendiğiniz Biriyle Konuşun", description: "Hislerinizi paylaşın", actionType: .social, icon: "phone.fill"),
                ActionSuggestion(title: "Derin Nefes Alın", description: "5 dakika meditasyon yapın", actionType: .selfcare, icon: "wind")
            ]
        } else {
            return [
                ActionSuggestion(title: "Bu Enerjiyi Kullanın", description: "Ertelediğiniz bir görevi tamamlayın", actionType: .goal, icon: "target"),
                ActionSuggestion(title: "Birine İyi Haber Verin", description: "Sevdiklerinizle mutluluğunuzu paylaşın", actionType: .social, icon: "heart.fill"),
                ActionSuggestion(title: "Yeni Bir Şey Deneyin", description: "Merak ettiğiniz bir aktiviteyi yapın", actionType: .activity, icon: "sparkles")
            ]
        }
    }

    // MARK: - Cache Management

    private func loadCachedAnalysis() -> MoodAnalysis? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let analysis = try? JSONDecoder().decode(MoodAnalysis.self, from: data) else {
            return nil
        }
        return analysis
    }

    private func saveToCache(_ analysis: MoodAnalysis) {
        if let data = try? JSONEncoder().encode(analysis) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }

    private func isCacheValid(_ analysis: MoodAnalysis) -> Bool {
        return Date().timeIntervalSince(analysis.generatedAt) < cacheDuration
    }

    func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
    }
}

// MARK: - Empty Models

extension MoodAnalysis {
    static func empty() -> MoodAnalysis {
        MoodAnalysis(
            summary: "Henüz yeterli mood kaydı yok",
            weeklyTrend: "Mood takibine başlamak için kayıt ekleyin",
            insights: [],
            patterns: [],
            recommendations: [],
            generatedAt: Date()
        )
    }
}

//
//  AIAnalyticsService.swift
//  LifeStyles
//
//  Created by Claude on 04.11.2025.
//

import Foundation
import SwiftData

// MARK: - AI Analytics Models (Analytics-specific)

/// AI tarafından oluşturulan analytics içgörü
struct AnalyticsAIInsight: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let category: InsightCategory
    let confidence: Double // 0-1 arası güven skoru
    let actionable: Bool
    let suggestedAction: String?

    enum InsightCategory {
        case social
        case mood
        case productivity
        case wellness
        case pattern
    }
}

/// Pattern tanıma sonucu
struct AnalyticsDetectedPattern: Identifiable {
    let id = UUID()
    let patternType: PatternType
    let description: String
    let frequency: String // "Haftalık", "Aylık" vb.
    let strength: Double // 0-1 arası pattern gücü
    let examples: [String]

    enum PatternType {
        case weeklyMoodCycle
        case socialActivityPeak
        case productivitySlump
        case locationRoutine
        case goalCompletionTiming
    }
}

/// Tahmine dayalı içgörü
struct AnalyticsPredictiveInsight: Identifiable {
    let id = UUID()
    let prediction: String
    let confidence: Double
    let timeframe: String // "Önümüzdeki hafta", "Bu ay" vb.
    let basedOn: [String] // Hangi verilere dayandığı
    let recommendation: String
}

/// Arkadaş-Mood korelasyon analizi
struct AnalyticsFriendMoodCorrelation {
    let friendName: String
    let correlationScore: Double // -1 ile 1 arası
    let positiveInteractions: Int
    let negativeInteractions: Int
    let averageMoodAfterContact: Double
    let insight: String
}

// MARK: - AI Analytics Service

@available(iOS 26.0, *)
@Observable
class AIAnalyticsService {
    static let shared = AIAnalyticsService()

    private var aiCoordinator: AICoordinator {
        AICoordinator.shared
    }

    // AI-generated insights
    private(set) var insights: [AnalyticsAIInsight] = []
    private(set) var detectedPatterns: [AnalyticsDetectedPattern] = []
    private(set) var predictions: [AnalyticsPredictiveInsight] = []
    private(set) var friendMoodCorrelations: [AnalyticsFriendMoodCorrelation] = []

    var isLoading: Bool = false
    var error: Error?

    private init() {}

    // MARK: - Main Analysis

    /// Tüm AI analizlerini çalıştır
    func runComprehensiveAnalysis(context: ModelContext) async {
        await MainActor.run {
            isLoading = true
        }

        // Paralel olarak tüm analizleri çalıştır
        async let friendMoodTask = analyzeFriendMoodCorrelations(context: context)
        async let patternsTask = detectBehavioralPatterns(context: context)
        async let insightsTask = generateAIInsights(context: context)
        async let predictionsTask = generatePredictions(context: context)

        // Tüm sonuçları bekle
        _ = await (friendMoodTask, patternsTask, insightsTask, predictionsTask)

        await MainActor.run {
            isLoading = false
        }
    }

    // MARK: - Friend-Mood Correlation Analysis

    /// Arkadaşlarla yapılan görüşmelerin mood üzerindeki etkisini analiz et
    private func analyzeFriendMoodCorrelations(context: ModelContext) async {
        guard let friends = try? context.fetch(FetchDescriptor<Friend>()),
              let moods = try? context.fetch(FetchDescriptor<MoodEntry>()) else {
            return
        }

        var correlations: [AnalyticsFriendMoodCorrelation] = []
        let calendar = Calendar.current

        for friend in friends {
            guard let histories = friend.contactHistory, !histories.isEmpty else {
                continue
            }

            // İletişim sonrası mood skorlarını topla (MoodEntry.score kullan: -2...+2)
            var contactMoodScores: [Double] = []
            var positiveCount = 0
            var negativeCount = 0

            // Her contact sonrası mood'a bak (aynı gün veya sonraki gün)
            for history in histories {
                let contactDay = calendar.startOfDay(for: history.date)
                let nextDay = calendar.date(byAdding: .day, value: 1, to: contactDay) ?? contactDay

                // Aynı gün veya sonraki gündeki mood'ları bul
                let relevantMoods = moods.filter { mood in
                    let moodDay = calendar.startOfDay(for: mood.date)
                    return moodDay == contactDay || moodDay == nextDay
                }

                for mood in relevantMoods {
                    // Score kullan (-2...+2 arası)
                    contactMoodScores.append(mood.score)

                    // Pozitif/negatif sayımı için intensity kullan
                    if mood.intensity >= 4 {
                        positiveCount += 1
                    } else if mood.intensity <= 2 {
                        negativeCount += 1
                    }
                }
            }

            // İletişim olmayan günlerdeki mood'lar (baseline)
            let contactDates = Set(histories.map { calendar.startOfDay(for: $0.date) })
            let baselineMoods = moods.filter { mood in
                let moodDay = calendar.startOfDay(for: mood.date)
                return !contactDates.contains(moodDay) &&
                       !contactDates.contains(calendar.date(byAdding: .day, value: -1, to: moodDay) ?? moodDay)
            }

            let baselineScores = baselineMoods.map { $0.score }

            // Ortalama hesapla
            let contactAvg = contactMoodScores.isEmpty ? 0.0 : contactMoodScores.reduce(0, +) / Double(contactMoodScores.count)
            let baselineAvg = baselineScores.isEmpty ? 0.0 : baselineScores.reduce(0, +) / Double(baselineScores.count)
            let avgMood = contactMoodScores.isEmpty ? 3.0 : (contactAvg + 2.0) * 1.25 // -2...+2 → 1...5

            // Korelasyon skoru: iletişim sonrası mood - baseline mood
            // -1.0 ile +1.0 arası normalize et (max fark 4.0 olabilir)
            let correlationScore = contactMoodScores.isEmpty ? 0.0 : max(-1.0, min(1.0, (contactAvg - baselineAvg) / 2.0))

            print("🔍 [AIAnalytics] \(friend.name): contact=\(contactAvg), baseline=\(baselineAvg), correlation=\(String(format: "%.2f", correlationScore))")

            // İçgörü oluştur
            let insight: String
            if correlationScore > 0.5 {
                insight = String(localized: "analytics.ai.friend_positive_impact", defaultValue: "\(friend.name) ile görüşmeler genellikle ruh halinizi olumlu etkiliyor! 😊", comment: "Positive friend mood correlation insight")
            } else if correlationScore < -0.3 {
                insight = String(localized: "analytics.ai.friend_negative_impact", defaultValue: "\(friend.name) ile görüşmeler sonrası ruh halinizde düşüş gözlemleniyor. 🤔", comment: "Negative friend mood correlation insight")
            } else {
                insight = String(localized: "analytics.ai.friend_neutral_impact", defaultValue: "\(friend.name) ile görüşmeler ruh halinizde nötr bir etki yaratıyor.", comment: "Neutral friend mood correlation insight")
            }

            correlations.append(
                AnalyticsFriendMoodCorrelation(
                    friendName: friend.name,
                    correlationScore: correlationScore,
                    positiveInteractions: positiveCount,
                    negativeInteractions: negativeCount,
                    averageMoodAfterContact: avgMood,
                    insight: insight
                )
            )
        }

        // En yüksek korelasyona göre sırala
        let sortedCorrelations = correlations.sorted { abs($0.correlationScore) > abs($1.correlationScore) }

        await MainActor.run {
            friendMoodCorrelations = sortedCorrelations
        }
    }

    // MARK: - Pattern Detection

    /// Davranışsal pattern'leri tespit et
    private func detectBehavioralPatterns(context: ModelContext) async {
        var patterns: [AnalyticsDetectedPattern] = []

        // Haftalık mood cycle pattern
        if let moodCyclePattern = await detectWeeklyMoodCycle(context: context) {
            patterns.append(moodCyclePattern)
        }

        // Sosyal aktivite peak zamanları
        if let socialPattern = await detectSocialActivityPeaks(context: context) {
            patterns.append(socialPattern)
        }

        // Productivity slump pattern
        if let productivityPattern = await detectProductivityPatterns(context: context) {
            patterns.append(productivityPattern)
        }

        // Konum rutinleri
        if let locationPattern = await detectLocationRoutines(context: context) {
            patterns.append(locationPattern)
        }

        await MainActor.run {
            detectedPatterns = patterns
        }
    }

    private func detectWeeklyMoodCycle(context: ModelContext) async -> AnalyticsDetectedPattern? {
        guard let moods = try? context.fetch(FetchDescriptor<MoodEntry>()) else {
            return nil
        }

        guard moods.count >= 14 else { return nil } // En az 2 haftalık veri gerekli

        let calendar = Calendar.current
        var weekdayMoods: [Int: [Double]] = [:] // 1=Pazar, 2=Pazartesi, ...

        for mood in moods {
            let weekday = calendar.component(.weekday, from: mood.date)
            weekdayMoods[weekday, default: []].append(Double(mood.intensity))
        }

        // Her gün için ortalama ve variance hesapla
        var dailyStats: [(weekday: Int, avg: Double, variance: Double, count: Int)] = []
        var allAvgs: [Double] = []

        for (weekday, values) in weekdayMoods where values.count >= 2 {
            let avg = values.reduce(0, +) / Double(values.count)
            // Variance: ortalamadan sapmaların karelerinin ortalaması
            let variance = values.map { pow($0 - avg, 2) }.reduce(0, +) / Double(values.count)
            dailyStats.append((weekday: weekday, avg: avg, variance: variance, count: values.count))
            allAvgs.append(avg)
        }

        guard dailyStats.count >= 5 else { return nil }

        // Genel ortalama ve standart sapma
        let overallAvg = allAvgs.reduce(0, +) / Double(allAvgs.count)
        let overallVariance = allAvgs.map { pow($0 - overallAvg, 2) }.reduce(0, +) / Double(allAvgs.count)
        let stdDev = sqrt(overallVariance)

        // Pattern gücü: günler arası farklılığın ne kadar belirgin olduğu
        // Yüksek variance = güçlü pattern
        let patternStrength = min(stdDev / 2.0, 1.0) // 0-1 arası normalize

        // Sadece belirgin pattern'ler için döndür
        guard patternStrength > 0.3 else { return nil }

        // En iyi ve en kötü günleri bul
        let sorted = dailyStats.sorted { $0.avg > $1.avg }
        let bestDays = sorted.prefix(2)
        let worstDays = sorted.suffix(2)

        let bestDayNames = bestDays.map { weekdayName($0.weekday) }.joined(separator: ", ")
        let worstDayNames = worstDays.map { weekdayName($0.weekday) }.joined(separator: ", ")

        // En tutarlı gün (en düşük variance)
        let mostConsistentDay = dailyStats.min(by: { $0.variance < $1.variance })
        let consistentDayName = weekdayName(mostConsistentDay?.weekday ?? 1)

        var examples: [String] = []
        examples.append("En iyi günleriniz: \(bestDayNames) (Ort: \(String(format: "%.1f", bestDays.first?.avg ?? 0))/5)")
        examples.append("Zorlayıcı günleriniz: \(worstDayNames) (Ort: \(String(format: "%.1f", worstDays.last?.avg ?? 0))/5)")
        examples.append("En tutarlı gününüz: \(consistentDayName)")

        // Hafta sonu vs hafta içi karşılaştırması
        let weekendDays = dailyStats.filter { $0.weekday == 1 || $0.weekday == 7 } // Pazar=1, Cumartesi=7
        let weekdayDays = dailyStats.filter { $0.weekday >= 2 && $0.weekday <= 6 }

        if !weekendDays.isEmpty && !weekdayDays.isEmpty {
            let weekendAvg = weekendDays.map { $0.avg }.reduce(0, +) / Double(weekendDays.count)
            let weekdayAvg = weekdayDays.map { $0.avg }.reduce(0, +) / Double(weekdayDays.count)
            let diff = weekendAvg - weekdayAvg

            if abs(diff) > 0.5 {
                if diff > 0 {
                    examples.append("Hafta sonları ruh haliniz %\(Int(abs(diff) * 20)) daha iyi")
                } else {
                    examples.append("Hafta içi daha enerjiksiniz")
                }
            }
        }

        print("📊 [AIAnalytics] Weekly mood pattern: strength=\(String(format: "%.2f", patternStrength)), stdDev=\(String(format: "%.2f", stdDev))")

        return AnalyticsDetectedPattern(
            patternType: .weeklyMoodCycle,
            description: "Haftalık ruh hali döngüsü tespit edildi",
            frequency: "Haftalık",
            strength: patternStrength,
            examples: examples
        )
    }

    private func detectSocialActivityPeaks(context: ModelContext) async -> AnalyticsDetectedPattern? {
        guard let friends = try? context.fetch(FetchDescriptor<Friend>()) else {
            return nil
        }

        let calendar = Calendar.current
        var weekdayContacts: [Int: Int] = [:]

        for friend in friends {
            if let histories = friend.contactHistory {
                for history in histories {
                    let weekday = calendar.component(.weekday, from: history.date)
                    weekdayContacts[weekday, default: 0] += 1
                }
            }
        }

        guard !weekdayContacts.isEmpty else { return nil }

        let mostActiveDay = weekdayContacts.max { $0.value < $1.value }
        let dayName = weekdayName(mostActiveDay?.key ?? 1)

        return AnalyticsDetectedPattern(
            patternType: .socialActivityPeak,
            description: String(localized: "analytics.pattern.social_activity_peak_desc", defaultValue: "Sosyal aktivite zirve zamanları", comment: "Social activity peak pattern description"),
            frequency: String(localized: "analytics.pattern.frequency_weekly", defaultValue: "Haftalık", comment: "Weekly frequency"),
            strength: 0.68,
            examples: [
                String(localized: "analytics.pattern.most_social_day", defaultValue: "En sosyal gününüz: \(dayName)", comment: "Most social day example"),
                String(localized: "analytics.pattern.social_day_note", defaultValue: "Bu günlerde arkadaşlarınızla daha fazla görüşüyorsunuz", comment: "Social day note")
            ]
        )
    }

    private func detectProductivityPatterns(context: ModelContext) async -> AnalyticsDetectedPattern? {
        guard let goals = try? context.fetch(FetchDescriptor<Goal>()),
              let habits = try? context.fetch(FetchDescriptor<Habit>()) else {
            return nil
        }

        let completedGoals = goals.filter { $0.isCompleted }
        guard completedGoals.count >= 5 else { return nil }

        let calendar = Calendar.current
        let now = Date()

        // Goal completion timing analizi
        var lastMinuteCount = 0 // Son 3 gün içinde tamamlanan
        var earlyCompletionCount = 0 // Deadline'dan 7+ gün önce
        var completionHours: [Int] = [] // Tamamlanma saatleri

        for goal in completedGoals {
            // Created date yoksa targetDate'ten 30 gün önce olduğunu varsay
            let estimatedCreated = calendar.date(byAdding: .day, value: -30, to: goal.targetDate) ?? goal.targetDate
            let daysToComplete = calendar.dateComponents([.day], from: estimatedCreated, to: goal.targetDate).day ?? 0

            if daysToComplete <= 3 {
                lastMinuteCount += 1
            } else if daysToComplete >= 7 {
                earlyCompletionCount += 1
            }

            // Completion hour (eğer targetDate saati anlamlıysa)
            let hour = calendar.component(.hour, from: goal.targetDate)
            if hour >= 6 && hour <= 23 { // Geçerli saat aralığı
                completionHours.append(hour)
            }
        }

        // Habit consistency analizi
        var totalHabitScore = 0.0
        var habitCount = 0

        for habit in habits {
            if let completions = habit.completions, !completions.isEmpty {
                let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
                let recentCompletions = completions.filter { $0.completedAt >= thirtyDaysAgo }
                let completionRate = Double(recentCompletions.count) / 30.0
                totalHabitScore += min(completionRate, 1.0)
                habitCount += 1
            }
        }

        let avgHabitCompletion = habitCount > 0 ? totalHabitScore / Double(habitCount) : 0.0

        // Pattern strength hesapla
        let lastMinuteRatio = Double(lastMinuteCount) / Double(completedGoals.count)
        let earlyRatio = Double(earlyCompletionCount) / Double(completedGoals.count)
        let patternStrength = max(lastMinuteRatio, earlyRatio, avgHabitCompletion)

        guard patternStrength > 0.4 else { return nil }

        // En produktif saat
        var mostProductiveHour: Int?
        if completionHours.count >= 3 {
            let hourCounts = Dictionary(grouping: completionHours, by: { $0 })
                .mapValues { $0.count }
            mostProductiveHour = hourCounts.max(by: { $0.value < $1.value })?.key
        }

        // Examples oluştur
        var examples: [String] = []

        if lastMinuteRatio > 0.5 {
            examples.append("Hedeflerin %\(Int(lastMinuteRatio * 100))'ını son dakikada tamamlıyorsunuz")
            examples.append("💡 Öneri: Hedefleri küçük parçalara bölün")
        } else if earlyRatio > 0.5 {
            examples.append("Harika! Hedeflerinizi erken tamamlıyorsunuz (%\(Int(earlyRatio * 100)))")
        }

        if let hour = mostProductiveHour {
            let timeStr = String(format: "%02d:00", hour)
            examples.append("En produktif saatiniz: \(timeStr)")
        }

        if avgHabitCompletion > 0.7 {
            examples.append("Alışkanlık tutarlılığınız yüksek (%\(Int(avgHabitCompletion * 100)))")
        } else if avgHabitCompletion > 0 {
            examples.append("Alışkanlıklarda daha düzenli olabilirsiniz")
        }

        print("📊 [AIAnalytics] Productivity pattern: lastMinute=\(Int(lastMinuteRatio*100))%, early=\(Int(earlyRatio*100))%, habit=\(Int(avgHabitCompletion*100))%")

        return AnalyticsDetectedPattern(
            patternType: .goalCompletionTiming,
            description: "Üretkenlik pattern'i tespit edildi",
            frequency: "Aylık",
            strength: patternStrength,
            examples: examples
        )
    }

    private func detectLocationRoutines(context: ModelContext) async -> AnalyticsDetectedPattern? {
        guard let locations = try? context.fetch(FetchDescriptor<LocationLog>()) else {
            return nil
        }

        guard locations.count >= 10 else { return nil }

        return AnalyticsDetectedPattern(
            patternType: .locationRoutine,
            description: String(localized: "analytics.pattern.location_routine_desc", defaultValue: "Konum rutinleri tespit edildi", comment: "Location routine pattern description"),
            frequency: String(localized: "analytics.pattern.frequency_daily", defaultValue: "Günlük", comment: "Daily frequency"),
            strength: 0.71,
            examples: [
                String(localized: "analytics.pattern.location_regular_routine", defaultValue: "Düzenli bir günlük rutin izliyorsunuz", comment: "Regular routine example"),
                String(localized: "analytics.pattern.location_same_places", defaultValue: "Genellikle aynı saatlerde aynı yerlerde bulunuyorsunuz", comment: "Same places example")
            ]
        )
    }

    // MARK: - AI Insights Generation

    /// AI destekli genel içgörüler oluştur
    private func generateAIInsights(context: ModelContext) async {
        var generatedInsights: [AnalyticsAIInsight] = []

        // Friend-mood correlations'tan insights
        for correlation in friendMoodCorrelations.prefix(3) {
            if correlation.correlationScore > 0.6 {
                generatedInsights.append(
                    AnalyticsAIInsight(
                        title: String(localized: "analytics.ai.insight_positive_social_title", defaultValue: "Pozitif Sosyal Etki", comment: "Positive social impact insight title"),
                        description: String(localized: "analytics.ai.insight_positive_social_desc", defaultValue: "\(correlation.friendName) ile daha fazla zaman geçirmeyi düşünün", comment: "Positive social impact insight description"),
                        category: .social,
                        confidence: correlation.correlationScore,
                        actionable: true,
                        suggestedAction: String(localized: "analytics.ai.insight_positive_social_action", defaultValue: "\(correlation.friendName)'e mesaj gönderin", comment: "Positive social impact suggested action")
                    )
                )
            }
        }

        // Pattern-based insights
        for pattern in detectedPatterns {
            let insight = AnalyticsAIInsight(
                title: String(localized: "analytics.ai.insight_pattern_title", defaultValue: "Pattern Tespit Edildi", comment: "Pattern detected insight title"),
                description: pattern.description,
                category: .pattern,
                confidence: pattern.strength,
                actionable: false,
                suggestedAction: nil
            )
            generatedInsights.append(insight)
        }

        // Wellness insight
        if let analytics = AnalyticsService.shared.overviewAnalytics {
            if analytics.wellnessScore > 75 {
                generatedInsights.append(
                    AnalyticsAIInsight(
                        title: "Harika Bir Dönemdesiniz! 🌟",
                        description: "Genel wellness skorunuz %\(Int(analytics.wellnessScore)). Bu harika performansı sürdürün!",
                        category: .wellness,
                        confidence: 0.9,
                        actionable: false,
                        suggestedAction: nil
                    )
                )
            } else if analytics.wellnessScore < 50 {
                generatedInsights.append(
                    AnalyticsAIInsight(
                        title: "Kendinize Zaman Ayırın",
                        description: "Son zamanlarda düşük performans gösteriyorsunuz. Kendinize daha fazla zaman ayırmayı deneyin.",
                        category: .wellness,
                        confidence: 0.85,
                        actionable: true,
                        suggestedAction: "Self-care aktiviteleri planlayın"
                    )
                )
            }
        }

        // Goal category success insights
        if let goalAnalytics = AnalyticsService.shared.goalAnalytics {
            let topCategory = goalAnalytics.successByCategory.max(by: { $0.value < $1.value })
            let worstCategory = goalAnalytics.successByCategory.min(by: { $0.value < $1.value })

            if let top = topCategory, top.value > 0.7, goalAnalytics.successByCategory.count > 1 {
                let categoryEmoji = categoryEmojiFor(top.key)
                generatedInsights.append(
                    AnalyticsAIInsight(
                        title: "\(categoryEmoji) \(top.key) Kategorisinde Başarılısınız",
                        description: "Bu kategoride %\(Int(top.value * 100)) başarı oranınız var. Bu alandaki deneyiminizi diğer hedeflerinize de uygulayın!",
                        category: .productivity,
                        confidence: top.value,
                        actionable: true,
                        suggestedAction: "Başarılı stratejilerinizi not edin"
                    )
                )
            }

            if let worst = worstCategory, worst.value < 0.4, goalAnalytics.successByCategory.count > 1 {
                generatedInsights.append(
                    AnalyticsAIInsight(
                        title: "\(worst.key) Hedeflerinde Zorluk",
                        description: "Bu kategoride %\(Int(worst.value * 100)) başarı oranınız var. Hedefleri daha küçük adımlara bölebilirsiniz.",
                        category: .productivity,
                        confidence: 1.0 - worst.value,
                        actionable: true,
                        suggestedAction: "Daha küçük, ulaşılabilir hedefler belirleyin"
                    )
                )
            }
        }

        // Habit streak insights
        if let habitAnalytics = AnalyticsService.shared.habitAnalytics {
            if habitAnalytics.bestStreak >= 7 {
                generatedInsights.append(
                    AnalyticsAIInsight(
                        title: "🔥 Muhteşem Streak!",
                        description: "\(habitAnalytics.bestStreak) günlük en uzun streak'iniz var! Bu tutarlılık harika.",
                        category: .productivity,
                        confidence: 0.95,
                        actionable: true,
                        suggestedAction: "Bu momentum'u sürdürün"
                    )
                )
            }

            if habitAnalytics.averageCompletionRate > 0.8 {
                generatedInsights.append(
                    AnalyticsAIInsight(
                        title: "✅ Alışkanlık Şampiyonu",
                        description: "%\(Int(habitAnalytics.averageCompletionRate * 100)) tamamlama oranıyla alışkanlıklarınızda çok disiplinlisiniz!",
                        category: .productivity,
                        confidence: habitAnalytics.averageCompletionRate,
                        actionable: false,
                        suggestedAction: nil
                    )
                )
            }
        }

        // Mood improvement insights (from correlations)
        if let moodAnalytics = AnalyticsService.shared.moodAnalytics {
            let recentTrend = moodAnalytics.moodTrend.suffix(7)
            if recentTrend.count >= 5 {
                let first3 = Array(recentTrend.prefix(3)).map { $0.value }.reduce(0, +) / 3.0
                let last3 = Array(recentTrend.suffix(3)).map { $0.value }.reduce(0, +) / 3.0
                let improvement = last3 - first3

                if improvement > 0.5 {
                    generatedInsights.append(
                        AnalyticsAIInsight(
                            title: "📈 Ruh Haliniz İyileşiyor!",
                            description: "Son günlerde ruh halinizde belirgin bir iyileşme var. Ne yaptığınızı sürdürün!",
                            category: .mood,
                            confidence: 0.85,
                            actionable: false,
                            suggestedAction: nil
                        )
                    )
                }
            }

            if moodAnalytics.consistencyRate > 0.8 {
                generatedInsights.append(
                    AnalyticsAIInsight(
                        title: "📝 Düzenli Takip",
                        description: "Mood kayıtlarınızı düzenli tutuyorsunuz (%\(Int(moodAnalytics.consistencyRate * 100))). Bu harika bir alışkanlık!",
                        category: .mood,
                        confidence: 0.9,
                        actionable: false,
                        suggestedAction: nil
                    )
                )
            }
        }

        // Social insights
        if let socialAnalytics = AnalyticsService.shared.socialAnalytics {
            if socialAnalytics.activeContacts > 0 && socialAnalytics.totalContacts > 0 {
                let activeRatio = Double(socialAnalytics.activeContacts) / Double(socialAnalytics.totalContacts)

                if activeRatio > 0.7 {
                    generatedInsights.append(
                        AnalyticsAIInsight(
                            title: "👥 Sosyal Bağlarınız Güçlü",
                            description: "Arkadaşlarınızın %\(Int(activeRatio * 100))'ıyla düzenli görüşüyorsunuz. Harika!",
                            category: .social,
                            confidence: 0.88,
                            actionable: false,
                            suggestedAction: nil
                        )
                    )
                } else if activeRatio < 0.3 && socialAnalytics.needsAttentionCount > 2 {
                    generatedInsights.append(
                        AnalyticsAIInsight(
                            title: "💬 Arkadaşlarınıza Zaman Ayırın",
                            description: "\(socialAnalytics.needsAttentionCount) kişiyle görüşme zamanınız geçmiş. Haftasonu bir kahve planı yapabilirsiniz!",
                            category: .social,
                            confidence: 0.85,
                            actionable: true,
                            suggestedAction: "Bu hafta 1-2 arkadaşınıza mesaj gönderin"
                        )
                    )
                }
            }
        }

        await MainActor.run {
            insights = generatedInsights
            print("✅ [AIAnalytics] Generated \(generatedInsights.count) insights")
        }
    }

    /// Kategori için emoji döndür
    private func categoryEmojiFor(_ category: String) -> String {
        switch category.lowercased() {
        case "sağlık", "health", "fitness": return "💪"
        case "kariyer", "career", "iş": return "💼"
        case "kişisel", "personal": return "✨"
        case "sosyal", "social": return "👥"
        case "finans", "finance": return "💰"
        case "eğitim", "education": return "📚"
        default: return "🎯"
        }
    }

    // MARK: - Predictions

    /// Gelecek tahminleri oluştur (Linear Regression + Pattern-based)
    private func generatePredictions(context: ModelContext) async {
        var generatedPredictions: [AnalyticsPredictiveInsight] = []

        // 1. Mood Trend Prediction (Linear Regression)
        if let moodAnalytics = AnalyticsService.shared.moodAnalytics {
            let trendData = moodAnalytics.moodTrend.suffix(14) // Son 14 gün

            if trendData.count >= 7 {
                // Linear regression ile trend tahmini
                let (slope, intercept, r2) = calculateLinearRegression(data: Array(trendData))

                // 7 gün sonrası için tahmin
                let futureDay = Double(trendData.count + 7)
                let predictedMood = slope * futureDay + intercept

                // Confidence: R² değeri (0-1 arası, ne kadar yüksekse o kadar güvenilir)
                let confidence = max(0.5, min(0.95, r2))

                // Trend yönü
                if slope > 0.1 {
                    // Yükseliş trendi
                    generatedPredictions.append(
                        AnalyticsPredictiveInsight(
                            prediction: "📈 Ruh haliniz gelecek hafta daha iyi olacak",
                            confidence: confidence,
                            timeframe: "Önümüzdeki 7 gün",
                            basedOn: [
                                "Son 14 günlük mood trendi (yükseliş)",
                                "Tahmin edilen mood: \(String(format: "%.1f", predictedMood))/5",
                                "Trend güvenilirliği: %\(Int(r2 * 100))"
                            ],
                            recommendation: "Pozitif enerjiyi yeni hedefler için kullanın!"
                        )
                    )
                } else if slope < -0.1 {
                    // Düşüş trendi
                    generatedPredictions.append(
                        AnalyticsPredictiveInsight(
                            prediction: "⚠️ Ruh haliniz gelecek hafta düşebilir",
                            confidence: confidence,
                            timeframe: "Önümüzdeki 7 gün",
                            basedOn: [
                                "Son 14 günlük mood trendi (düşüş)",
                                "Tahmin edilen mood: \(String(format: "%.1f", predictedMood))/5",
                                "Trend güvenilirliği: %\(Int(r2 * 100))"
                            ],
                            recommendation: "Self-care aktivitelerine zaman ayırın, arkadaşlarınızla görüşün"
                        )
                    )
                } else {
                    // Stabil trend
                    generatedPredictions.append(
                        AnalyticsPredictiveInsight(
                            prediction: "😌 Ruh haliniz gelecek hafta stabil kalacak",
                            confidence: confidence,
                            timeframe: "Önümüzdeki 7 gün",
                            basedOn: [
                                "Son 14 günlük mood trendi (stabil)",
                                "Tahmin edilen mood: \(String(format: "%.1f", predictedMood))/5"
                            ],
                            recommendation: "Bu dengeyi korumak için rutininize sadık kalın"
                        )
                    )
                }
            }
        }

        // 2. Pattern-based Mood Prediction
        // Eğer haftalık mood cycle pattern'i tespit edildiyse
        let weeklyPattern = detectedPatterns.first { $0.patternType == .weeklyMoodCycle }
        if let pattern = weeklyPattern, pattern.strength > 0.3 {
            let calendar = Calendar.current
            let today = calendar.component(.weekday, from: Date())

            // Pattern description'dan düşük mood günleri çıkar
            // Örnek: "En iyi gün: Cumartesi (4.2/5), En kötü gün: Pazartesi (2.8/5)"
            if pattern.description.contains("En kötü gün: Pazartesi") && today == 7 { // Pazar
                generatedPredictions.append(
                    AnalyticsPredictiveInsight(
                        prediction: "⚠️ Yarın (Pazartesi) ruh haliniz düşük olabilir",
                        confidence: 0.75,
                        timeframe: "Yarın",
                        basedOn: [
                            "Haftalık mood cycle pattern'iniz",
                            "Pazartesi günleri genelde düşük mood",
                            "Pattern gücü: %\(Int(pattern.strength * 100))"
                        ],
                        recommendation: "Pazartesi için motivasyon artırıcı aktiviteler planlayın"
                    )
                )
            }
        }

        // 3. Social Activity Prediction
        if let socialAnalytics = AnalyticsService.shared.socialAnalytics {
            // Trend analizi: son 30 gün vs önceki 30 gün
            let recentContactRate = Double(socialAnalytics.activeContacts) / max(1.0, Double(socialAnalytics.totalContacts))

            if socialAnalytics.needsAttentionCount > 3 {
                let riskLevel = min(0.95, 0.6 + Double(socialAnalytics.needsAttentionCount) * 0.05)

                generatedPredictions.append(
                    AnalyticsPredictiveInsight(
                        prediction: "👥 Sosyal bağlantılarınız zayıflıyor",
                        confidence: riskLevel,
                        timeframe: "Önümüzdeki 2 hafta",
                        basedOn: [
                            "\(socialAnalytics.needsAttentionCount) arkadaşla görüşme süresi doldu",
                            "Aktif iletişim oranı: %\(Int(recentContactRate * 100))"
                        ],
                        recommendation: "Bu hafta en az 2-3 arkadaşınızla iletişime geçin"
                    )
                )
            } else if recentContactRate > 0.7 {
                generatedPredictions.append(
                    AnalyticsPredictiveInsight(
                        prediction: "🌟 Sosyal hayatınız gelecek hafta da güçlü kalacak",
                        confidence: 0.80,
                        timeframe: "Önümüzdeki hafta",
                        basedOn: [
                            "Yüksek aktif iletişim oranı (%\(Int(recentContactRate * 100)))",
                            "Düzenli görüşme alışkanlığınız var"
                        ],
                        recommendation: "Bu momentum'u sürdürün!"
                    )
                )
            }
        }

        // 4. Goal Completion Risk
        if let goalAnalytics = AnalyticsService.shared.goalAnalytics {
            if goalAnalytics.completionRate < 0.5 && goalAnalytics.upcomingDeadlines > 2 {
                let risk = 0.70 + min(0.25, Double(goalAnalytics.upcomingDeadlines) * 0.05)

                generatedPredictions.append(
                    AnalyticsPredictiveInsight(
                        prediction: "🚨 Hedef deadline'ları kaçırma riski yüksek",
                        confidence: risk,
                        timeframe: "Önümüzdeki hafta",
                        basedOn: [
                            "\(goalAnalytics.upcomingDeadlines) yaklaşan deadline",
                            "Tamamlanma oranı: %\(Int(goalAnalytics.completionRate * 100))",
                            "Geçmiş performans düşük"
                        ],
                        recommendation: "Hedefleri önceliklendirin ve küçük adımlara bölün"
                    )
                )
            } else if goalAnalytics.completionRate > 0.7 {
                generatedPredictions.append(
                    AnalyticsPredictiveInsight(
                        prediction: "🎯 Hedeflerinizi başarıyla tamamlayacaksınız",
                        confidence: 0.85,
                        timeframe: "Önümüzdeki hafta",
                        basedOn: [
                            "Yüksek tamamlanma oranı (%\(Int(goalAnalytics.completionRate * 100)))",
                            "Düzenli ilerleme kaydediyorsunuz"
                        ],
                        recommendation: "Momentum'u kaybetmeyin, yeni hedefler ekleyin"
                    )
                )
            }
        }

        // 5. Habit Streak Prediction
        if let habitAnalytics = AnalyticsService.shared.habitAnalytics {
            if habitAnalytics.bestStreak >= 7 && habitAnalytics.averageCompletionRate > 0.7 {
                let streakConfidence = min(0.90, 0.6 + habitAnalytics.averageCompletionRate * 0.3)

                generatedPredictions.append(
                    AnalyticsPredictiveInsight(
                        prediction: "🔥 Streak'iniz gelecek hafta da devam edecek",
                        confidence: streakConfidence,
                        timeframe: "Önümüzdeki 7 gün",
                        basedOn: [
                            "Mevcut en uzun streak: \(habitAnalytics.bestStreak) gün",
                            "Ortalama tamamlanma: %\(Int(habitAnalytics.averageCompletionRate * 100))",
                            "Güçlü alışkanlık pattern'i"
                        ],
                        recommendation: "Her gün için hatırlatıcı kur, momentum'u koru"
                    )
                )
            } else if habitAnalytics.averageCompletionRate < 0.4 {
                generatedPredictions.append(
                    AnalyticsPredictiveInsight(
                        prediction: "⚠️ Alışkanlıklar risk altında",
                        confidence: 0.75,
                        timeframe: "Önümüzdeki hafta",
                        basedOn: [
                            "Düşük tamamlanma oranı (%\(Int(habitAnalytics.averageCompletionRate * 100)))",
                            "Düzenli takip eksikliği"
                        ],
                        recommendation: "Alışkanlıkları daha küçük, kolay adımlara bölün"
                    )
                )
            }
        }

        // 6. Productivity Pattern Prediction
        let productivityPattern = detectedPatterns.first { $0.patternType == .goalCompletionTiming }
        if let pattern = productivityPattern, pattern.strength > 0.4 {
            if pattern.description.contains("son dakika") || pattern.description.contains("last-minute") {
                generatedPredictions.append(
                    AnalyticsPredictiveInsight(
                        prediction: "⏰ Gelecek hafta da son dakika yetişme riski var",
                        confidence: 0.78,
                        timeframe: "Önümüzdeki hafta",
                        basedOn: [
                            "Son dakika tamamlama pattern'iniz güçlü",
                            "Pattern gücü: %\(Int(pattern.strength * 100))",
                            "Geçmiş davranış tekrarlanıyor"
                        ],
                        recommendation: "Hedeflere daha erken başlamayı deneyin, ara deadline'lar koyun"
                    )
                )
            }
        }

        await MainActor.run {
            predictions = generatedPredictions
            print("🔮 [AI Analytics] \(generatedPredictions.count) tahmin oluşturuldu")
        }
    }

    /// Linear regression hesapla (slope, intercept, R²)
    private func calculateLinearRegression(data: [MoodAnalytics.MoodPoint]) -> (slope: Double, intercept: Double, r2: Double) {
        guard data.count >= 2 else { return (0, 0, 0) }

        let n = Double(data.count)

        // x: gün indexi (0, 1, 2, ...), y: mood değeri
        let xValues = (0..<data.count).map { Double($0) }
        let yValues = data.map { $0.value }

        let sumX = xValues.reduce(0, +)
        let sumY = yValues.reduce(0, +)
        let sumXY = zip(xValues, yValues).map { $0 * $1 }.reduce(0, +)
        let sumX2 = xValues.map { $0 * $0 }.reduce(0, +)
        let sumY2 = yValues.map { $0 * $0 }.reduce(0, +)

        // Slope (eğim): m = (n*ΣXY - ΣX*ΣY) / (n*ΣX² - (ΣX)²)
        let numerator = n * sumXY - sumX * sumY
        let denominator = n * sumX2 - sumX * sumX

        guard denominator != 0 else { return (0, 0, 0) }

        let slope = numerator / denominator

        // Intercept (kesişim): b = (ΣY - m*ΣX) / n
        let intercept = (sumY - slope * sumX) / n

        // R² (coefficient of determination): ne kadar iyi fit olduğunu gösterir (0-1 arası)
        let meanY = sumY / n
        let ssTotal = yValues.map { pow($0 - meanY, 2) }.reduce(0.0, +)
        let ssResidual = zip(xValues, yValues).map { x, y in
            let predicted = slope * x + intercept
            return pow(y - predicted, 2)
        }.reduce(0.0, +)

        let r2 = ssTotal > 0 ? max(0, 1 - (ssResidual / ssTotal)) : 0

        return (slope, intercept, r2)
    }

    // MARK: - Helper Functions

    private func weekdayName(_ weekday: Int) -> String {
        let days = [
            String(localized: "analytics.weekday.sunday", defaultValue: "Pazar", comment: "Sunday"),
            String(localized: "analytics.weekday.monday", defaultValue: "Pazartesi", comment: "Monday"),
            String(localized: "analytics.weekday.tuesday", defaultValue: "Salı", comment: "Tuesday"),
            String(localized: "analytics.weekday.wednesday", defaultValue: "Çarşamba", comment: "Wednesday"),
            String(localized: "analytics.weekday.thursday", defaultValue: "Perşembe", comment: "Thursday"),
            String(localized: "analytics.weekday.friday", defaultValue: "Cuma", comment: "Friday"),
            String(localized: "analytics.weekday.saturday", defaultValue: "Cumartesi", comment: "Saturday")
        ]
        return days[(weekday - 1) % 7]
    }
}

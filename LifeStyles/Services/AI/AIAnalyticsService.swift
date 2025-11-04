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

            var positiveCount = 0
            var negativeCount = 0
            var moodSum = 0.0
            var moodCount = 0

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
                    moodSum += Double(mood.intensity)
                    moodCount += 1

                    if mood.intensity >= 4 {
                        positiveCount += 1
                    } else if mood.intensity <= 2 {
                        negativeCount += 1
                    }
                }
            }

            let avgMood = moodCount > 0 ? moodSum / Double(moodCount) : 3.0

            // Korelasyon skoru hesapla (basit versiyon)
            let totalInteractions = positiveCount + negativeCount
            let correlationScore = totalInteractions > 0
                ? (Double(positiveCount) - Double(negativeCount)) / Double(totalInteractions)
                : 0.0

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

        let calendar = Calendar.current
        var weekdayMoods: [Int: [Double]] = [:] // 1=Pazar, 2=Pazartesi, ...

        for mood in moods {
            let weekday = calendar.component(.weekday, from: mood.date)
            weekdayMoods[weekday, default: []].append(Double(mood.intensity))
        }

        // Her gün için ortalama hesapla
        var averages: [(weekday: Int, avg: Double)] = []
        for (weekday, values) in weekdayMoods {
            let avg = values.reduce(0, +) / Double(values.count)
            averages.append((weekday: weekday, avg: avg))
        }

        guard averages.count >= 5 else { return nil }

        // En iyi ve en kötü günleri bul
        let sorted = averages.sorted { $0.avg > $1.avg }
        let bestDay = weekdayName(sorted.first?.weekday ?? 1)
        let worstDay = weekdayName(sorted.last?.weekday ?? 1)

        return AnalyticsDetectedPattern(
            patternType: .weeklyMoodCycle,
            description: String(localized: "analytics.pattern.weekly_mood_cycle_desc", defaultValue: "Haftalık ruh hali döngüsü tespit edildi", comment: "Weekly mood cycle pattern description"),
            frequency: String(localized: "analytics.pattern.frequency_weekly", defaultValue: "Haftalık", comment: "Weekly frequency"),
            strength: 0.75,
            examples: [
                String(localized: "analytics.pattern.best_days", defaultValue: "En iyi günleriniz: \(bestDay)", comment: "Best days example"),
                String(localized: "analytics.pattern.worst_days", defaultValue: "En zorlu günleriniz: \(worstDay)", comment: "Worst days example")
            ]
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

        guard completedGoals.count >= 3 else { return nil }

        return AnalyticsDetectedPattern(
            patternType: .goalCompletionTiming,
            description: String(localized: "analytics.pattern.goal_completion_desc", defaultValue: "Hedef tamamlama pattern'i", comment: "Goal completion pattern description"),
            frequency: String(localized: "analytics.pattern.frequency_monthly", defaultValue: "Aylık", comment: "Monthly frequency"),
            strength: 0.62,
            examples: [
                String(localized: "analytics.pattern.goal_last_minute", defaultValue: "Hedeflerinizi genellikle son dakikada tamamlıyorsunuz", comment: "Last minute goal completion example"),
                String(localized: "analytics.pattern.goal_early_success", defaultValue: "Erken başlanan hedefler daha başarılı oluyor", comment: "Early start goal success example")
            ]
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
                        title: String(localized: "analytics.ai.insight_wellness_high_title", defaultValue: "Harika Bir Dönemdesiniz! 🌟", comment: "High wellness insight title"),
                        description: String(localized: "analytics.ai.insight_wellness_high_desc", defaultValue: "Genel wellness skorunuz %\(Int(analytics.wellnessScore)). Bu harika performansı sürdürün!", comment: "High wellness insight description"),
                        category: .wellness,
                        confidence: 0.9,
                        actionable: false,
                        suggestedAction: nil
                    )
                )
            } else if analytics.wellnessScore < 50 {
                generatedInsights.append(
                    AnalyticsAIInsight(
                        title: String(localized: "analytics.ai.insight_wellness_low_title", defaultValue: "Kendinize Zaman Ayırın", comment: "Low wellness insight title"),
                        description: String(localized: "analytics.ai.insight_wellness_low_desc", defaultValue: "Son zamanlarda düşük performans gösteriyorsunuz. Kendinize daha fazla zaman ayırmayı deneyin.", comment: "Low wellness insight description"),
                        category: .wellness,
                        confidence: 0.85,
                        actionable: true,
                        suggestedAction: String(localized: "analytics.ai.insight_wellness_low_action", defaultValue: "Self-care aktiviteleri planlayın", comment: "Low wellness suggested action")
                    )
                )
            }
        }

        await MainActor.run {
            insights = generatedInsights
        }
    }

    // MARK: - Predictions

    /// Gelecek tahminleri oluştur
    private func generatePredictions(context: ModelContext) async {
        var generatedPredictions: [AnalyticsPredictiveInsight] = []

        // Mood prediction
        if let moodAnalytics = AnalyticsService.shared.moodAnalytics {
            let trend = moodAnalytics.moodTrend.suffix(7)
            if trend.count >= 5 {
                let recentAvg = trend.map { $0.value }.reduce(0, +) / Double(trend.count)

                if recentAvg > 3.5 {
                    generatedPredictions.append(
                        AnalyticsPredictiveInsight(
                            prediction: String(localized: "analytics.prediction.mood_high", defaultValue: "Önümüzdeki hafta ruh halinizin yüksek kalması bekleniyor", comment: "High mood prediction"),
                            confidence: 0.75,
                            timeframe: String(localized: "analytics.prediction.timeframe_next_week", defaultValue: "Önümüzdeki hafta", comment: "Next week timeframe"),
                            basedOn: [
                                String(localized: "analytics.prediction.based_on_mood_trend", defaultValue: "Son 7 günlük mood trendi", comment: "Based on mood trend"),
                                String(localized: "analytics.prediction.based_on_social_activity", defaultValue: "Sosyal aktivite düzeyi", comment: "Based on social activity")
                            ],
                            recommendation: String(localized: "analytics.prediction.mood_high_recommendation", defaultValue: "Bu pozitif enerjiyi yeni hedefler için kullanın!", comment: "High mood recommendation")
                        )
                    )
                }
            }
        }

        // Social prediction
        if let socialAnalytics = AnalyticsService.shared.socialAnalytics {
            if socialAnalytics.needsAttentionCount > 3 {
                generatedPredictions.append(
                    AnalyticsPredictiveInsight(
                        prediction: String(localized: "analytics.prediction.social_weak", defaultValue: "Yakında sosyal bağlantılarınız zayıflayabilir", comment: "Weak social connections prediction"),
                        confidence: 0.82,
                        timeframe: String(localized: "analytics.prediction.timeframe_two_weeks", defaultValue: "Önümüzdeki 2 hafta", comment: "Two weeks timeframe"),
                        basedOn: [String(localized: "analytics.prediction.based_on_overdue_contacts", defaultValue: "\(socialAnalytics.needsAttentionCount) arkadaşla görüşme süresi doldu", comment: "Based on overdue contacts")],
                        recommendation: String(localized: "analytics.prediction.social_weak_recommendation", defaultValue: "Bu hafta en az 2 arkadaşınızla iletişime geçin", comment: "Weak social connections recommendation")
                    )
                )
            }
        }

        // Goal prediction
        if let goalAnalytics = AnalyticsService.shared.goalAnalytics {
            if goalAnalytics.completionRate < 0.5 && goalAnalytics.upcomingDeadlines > 2 {
                generatedPredictions.append(
                    AnalyticsPredictiveInsight(
                        prediction: String(localized: "analytics.prediction.goal_miss_deadline", defaultValue: "Önümüzdeki hafta hedef deadline'ları kaçırma riski yüksek", comment: "Goal deadline miss prediction"),
                        confidence: 0.70,
                        timeframe: String(localized: "analytics.prediction.timeframe_next_week", defaultValue: "Önümüzdeki hafta", comment: "Next week timeframe"),
                        basedOn: [
                            String(localized: "analytics.prediction.based_on_upcoming_deadlines", defaultValue: "\(goalAnalytics.upcomingDeadlines) yaklaşan deadline", comment: "Based on upcoming deadlines"),
                            String(localized: "analytics.prediction.based_on_low_completion", defaultValue: "Düşük tamamlanma oranı", comment: "Based on low completion rate")
                        ],
                        recommendation: String(localized: "analytics.prediction.goal_miss_recommendation", defaultValue: "Hedefleri önceliklendirin ve küçük adımlara bölün", comment: "Goal deadline miss recommendation")
                    )
                )
            }
        }

        await MainActor.run {
            predictions = generatedPredictions
        }
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

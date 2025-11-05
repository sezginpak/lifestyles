//
//  AnalyticsViewModel.swift
//  LifeStyles
//
//  Created by Claude on 04.11.2025.
//

import Foundation
import SwiftData

// MARK: - Time Range Selection

enum AnalyticsTimeRange: String, CaseIterable {
    case week
    case month
    case threeMonths
    case year

    var localizedTitle: String {
        switch self {
        case .week: return String(localized: "analytics.timeRange.week", defaultValue: "7 Gün", comment: "7 days time range")
        case .month: return String(localized: "analytics.timeRange.month", defaultValue: "30 Gün", comment: "30 days time range")
        case .threeMonths: return String(localized: "analytics.timeRange.threeMonths", defaultValue: "90 Gün", comment: "90 days time range")
        case .year: return String(localized: "analytics.timeRange.year", defaultValue: "1 Yıl", comment: "1 year time range")
        }
    }

    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        case .year: return 365
        }
    }
}

// MARK: - View State

enum AnalyticsViewState: Equatable {
    case loading
    case loaded
    case error(String)
    case empty
}

// MARK: - Analytics ViewModel

@Observable
@MainActor
class AnalyticsViewModel {
    // Services
    private let analyticsService = AnalyticsService.shared
    @available(iOS 26.0, *)
    private var aiAnalyticsService: AIAnalyticsService {
        AIAnalyticsService.shared
    }

    // State
    var viewState: AnalyticsViewState = .loading
    var selectedTimeRange: AnalyticsTimeRange = .month

    // Data
    var overviewData: OverviewAnalytics?
    var socialData: SocialAnalytics?
    var moodData: MoodAnalytics?
    var goalData: GoalPerformanceAnalytics?
    var habitData: HabitPerformanceAnalytics?
    var locationData: LocationAnalytics?
    var correlationData: CorrelationData?

    // Mood correlation data (non-AI)
    var friendCorrelations: [MoodFriendCorrelation] = []
    var goalCorrelations: [MoodGoalCorrelation] = []
    var locationCorrelations: [MoodLocationCorrelation] = []

    // AI Data (iOS 26+)
    var aiInsights: [AnalyticsAIInsight] = []
    var detectedPatterns: [AnalyticsDetectedPattern] = []
    var predictions: [AnalyticsPredictiveInsight] = []
    var friendMoodCorrelations: [AnalyticsFriendMoodCorrelation] = []
    var isAIAvailable: Bool {
        if #available(iOS 26.0, *) {
            return true
        }
        return false
    }

    // UI State
    var isRefreshing: Bool = false
    var lastRefreshDate: Date?
    var showExportSheet: Bool = false
    var selectedSection: AnalyticsSection?

    enum AnalyticsSection: String, CaseIterable {
        case overview
        case social
        case mood
        case goals
        case habits
        case location
        case ai

        var localizedTitle: String {
            switch self {
            case .overview: return String(localized: "analytics.section.overview", defaultValue: "Genel Bakış", comment: "Overview section title")
            case .social: return String(localized: "analytics.section.social", defaultValue: "İletişim", comment: "Social section title")
            case .mood: return String(localized: "analytics.section.mood", defaultValue: "Ruh Hali", comment: "Mood section title")
            case .goals: return String(localized: "analytics.section.goals", defaultValue: "Hedefler", comment: "Goals section title")
            case .habits: return String(localized: "analytics.section.habits", defaultValue: "Alışkanlıklar", comment: "Habits section title")
            case .location: return String(localized: "analytics.section.location", defaultValue: "Mobilite", comment: "Location section title")
            case .ai: return String(localized: "analytics.section.ai", defaultValue: "AI İçgörüleri", comment: "AI Insights section title")
            }
        }
    }

    init() {}

    // MARK: - Data Loading

    /// İlk veri yüklemesi
    func loadData(context: ModelContext) async {
        viewState = .loading

        // Setup services
        analyticsService.setModelContext(context)

        // Load analytics data
        await analyticsService.loadAllAnalytics()

        // Load mood correlations (non-AI)
        await loadMoodCorrelations(context: context)

        // AI analytics (iOS 26+)
        if #available(iOS 26.0, *) {
            await aiAnalyticsService.runComprehensiveAnalysis(context: context)
            updateAIData()
        }

        // Update local data
        updateData()

        // Check if we have any data
        if overviewData == nil && socialData == nil && moodData == nil {
            viewState = .empty
        } else {
            viewState = .loaded
            lastRefreshDate = Date()
        }
    }

    /// Verileri yenile
    func refreshData(context: ModelContext) async {
        isRefreshing = true

        await analyticsService.loadAllAnalytics()

        // Load mood correlations (non-AI)
        await loadMoodCorrelations(context: context)

        if #available(iOS 26.0, *) {
            await aiAnalyticsService.runComprehensiveAnalysis(context: context)
            updateAIData()
        }

        updateData()

        lastRefreshDate = Date()
        isRefreshing = false
    }

    /// Mood korelasyonlarını yükle (MoodAnalyticsService)
    private func loadMoodCorrelations(context: ModelContext) async {
        // Tüm mood kayıtlarını çek
        guard let moods = try? context.fetch(FetchDescriptor<MoodEntry>()) else {
            print("⚠️ [AnalyticsViewModel] Mood entries fetch failed")
            return
        }

        let moodAnalyticsService = MoodAnalyticsService.shared

        // Friend korelasyonlarını hesapla
        let friends = moodAnalyticsService.calculateFriendCorrelations(
            moodEntries: moods,
            context: context
        )

        // Goal korelasyonlarını hesapla
        let goals = moodAnalyticsService.calculateGoalCorrelations(
            moodEntries: moods,
            context: context
        )

        // Location korelasyonlarını hesapla
        let locations = moodAnalyticsService.calculateLocationCorrelations(
            moodEntries: moods,
            context: context
        )

        await MainActor.run {
            self.friendCorrelations = friends
            self.goalCorrelations = goals
            self.locationCorrelations = locations

            print("✅ [AnalyticsViewModel] Mood correlations loaded:")
            print("   - Friends: \(friends.count)")
            print("   - Goals: \(goals.count)")
            print("   - Locations: \(locations.count)")
        }
    }

    /// Local data'yı service'lerden güncelle
    private func updateData() {
        overviewData = analyticsService.overviewAnalytics
        socialData = analyticsService.socialAnalytics
        moodData = analyticsService.moodAnalytics
        goalData = analyticsService.goalAnalytics
        habitData = analyticsService.habitAnalytics
        locationData = analyticsService.locationAnalytics
        correlationData = analyticsService.correlationData
    }

    /// AI data'yı güncelle
    @available(iOS 26.0, *)
    private func updateAIData() {
        aiInsights = aiAnalyticsService.insights
        detectedPatterns = aiAnalyticsService.detectedPatterns
        predictions = aiAnalyticsService.predictions
        friendMoodCorrelations = aiAnalyticsService.friendMoodCorrelations
    }

    // MARK: - Export Functionality

    /// Analytics raporunu text formatında oluştur
    func generateTextReport() -> String {
        var report = "📊 LifeStyles Analytics Raporu\n"
        report += "📅 Tarih: \(formattedDate(Date()))\n"
        report += "⏱ Dönem: \(selectedTimeRange.rawValue)\n\n"

        // Overview
        if let overview = overviewData {
            report += "🎯 GENEL BAKIŞ\n"
            report += "━━━━━━━━━━━━━━━━\n"
            report += "Wellness Skoru: \(Int(overview.wellnessScore))/100\n"
            report += "Aktif Günler: \(overview.totalActiveDays)\n"
            report += "Düzenlilik: %\(Int(overview.consistencyScore * 100))\n"
            report += "Trend: \(trendEmoji(overview.improvementTrend))\n\n"
        }

        // Social
        if let social = socialData {
            report += "👥 İLETİŞİM\n"
            report += "━━━━━━━━━━━━━━━━\n"
            report += "Toplam Kişi: \(social.totalContacts)\n"
            report += "Aktif: \(social.activeContacts)\n"
            report += "Dikkat Gereken: \(social.needsAttentionCount)\n"
            if let mostContacted = social.mostContactedPerson {
                report += "En Çok Görüşülen: \(mostContacted)\n"
            }
            report += "\n"
        }

        // Mood
        if let mood = moodData {
            report += "😊 RUH HALİ\n"
            report += "━━━━━━━━━━━━━━━━\n"
            report += "Ortalama: \(String(format: "%.1f", mood.averageMood))/5\n"
            report += "Düzenlilik: %\(Int(mood.consistencyRate * 100))\n"
            report += "\n"
        }

        // Goals
        if let goals = goalData {
            report += "🎯 HEDEFLER\n"
            report += "━━━━━━━━━━━━━━━━\n"
            report += "Toplam: \(goals.totalGoals)\n"
            report += "Tamamlanan: \(goals.completedGoals)\n"
            report += "Başarı Oranı: %\(Int(goals.completionRate * 100))\n"
            report += "Yaklaşan Deadline: \(goals.upcomingDeadlines)\n\n"
        }

        // Habits
        if let habits = habitData {
            report += "✅ ALIŞKANLIKLAR\n"
            report += "━━━━━━━━━━━━━━━━\n"
            report += "Toplam: \(habits.totalHabits)\n"
            report += "Aktif: \(habits.activeHabits)\n"
            report += "En Uzun Seri: \(habits.bestStreak) gün\n"
            report += "Tamamlanma: %\(Int(habits.averageCompletionRate * 100))\n\n"
        }

        // Location
        if let location = locationData {
            report += "📍 MOBİLİTE\n"
            report += "━━━━━━━━━━━━━━━━\n"
            report += "Benzersiz Yer: \(location.uniquePlaces)\n"
            report += "Mobilite Skoru: \(Int(location.mobilityScore))/100\n"
            report += "Evde: %\(Int(location.homeTimePercentage * 100))\n\n"
        }

        // AI Insights
        if #available(iOS 26.0, *), !aiInsights.isEmpty {
            report += "🤖 AI İÇGÖRÜLERİ\n"
            report += "━━━━━━━━━━━━━━━━\n"
            for insight in aiInsights.prefix(3) {
                report += "• \(insight.title)\n"
                report += "  \(insight.description)\n\n"
            }
        }

        report += "━━━━━━━━━━━━━━━━\n"
        report += "LifeStyles ile oluşturuldu ❤️\n"

        return report
    }

    /// Raporu dosyaya kaydet
    func saveReportToFile() -> URL? {
        let report = generateTextReport()
        let fileName = "LifeStyles_Analytics_\(Date().timeIntervalSince1970).txt"

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try report.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("❌ Rapor kayıt hatası: \(error)")
            return nil
        }
    }

    // MARK: - Computed Properties

    /// En iyi performans gösteren kategori
    var topPerformingCategory: String? {
        guard let goals = goalData else { return nil }

        let sorted = goals.successByCategory.sorted { $0.value > $1.value }
        return sorted.first?.key
    }

    /// En pozitif etki yapan arkadaş
    var mostPositiveFriend: String? {
        guard #available(iOS 26.0, *) else { return nil }

        let sorted = friendMoodCorrelations.sorted { $0.correlationScore > $1.correlationScore }
        return sorted.first?.friendName
    }

    /// Genel trend yönü
    var overallTrend: String {
        guard let overview = overviewData else { return "─" }

        switch overview.improvementTrend {
        case .improving: return "📈"
        case .stable: return "─"
        case .declining: return "📉"
        }
    }

    /// Wellness seviyesi kategorisi
    var wellnessLevel: String {
        guard let overview = overviewData else {
            return String(localized: "analytics.wellness.unknown", defaultValue: "Bilinmiyor", comment: "Unknown wellness level")
        }

        let score = overview.wellnessScore

        switch score {
        case 80...100: return String(localized: "analytics.wellness.excellent", defaultValue: "Mükemmel", comment: "Excellent wellness level")
        case 60..<80: return String(localized: "analytics.wellness.good", defaultValue: "İyi", comment: "Good wellness level")
        case 40..<60: return String(localized: "analytics.wellness.moderate", defaultValue: "Orta", comment: "Moderate wellness level")
        case 20..<40: return String(localized: "analytics.wellness.needsImprovement", defaultValue: "Geliştirilmeli", comment: "Needs improvement wellness level")
        default: return String(localized: "analytics.wellness.low", defaultValue: "Düşük", comment: "Low wellness level")
        }
    }

    /// Wellness level rengi
    var wellnessColor: String {
        guard let overview = overviewData else { return "gray" }

        let score = overview.wellnessScore

        switch score {
        case 80...100: return "green"
        case 60..<80: return "blue"
        case 40..<60: return "yellow"
        case 20..<40: return "orange"
        default: return "red"
        }
    }

    // MARK: - Helper Functions

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }

    private func trendEmoji(_ trend: OverviewAnalytics.TrendDirection) -> String {
        switch trend {
        case .improving: return "📈 Gelişiyor"
        case .stable: return "─ Stabil"
        case .declining: return "📉 Düşüyor"
        }
    }

    /// Kategori için emoji döndür
    func categoryEmoji(_ category: String) -> String {
        switch category.lowercased() {
        case "social", "sosyal": return "👥"
        case "fitness", "sağlık": return "💪"
        case "personal", "kişisel": return "✨"
        case "career", "kariyer": return "💼"
        case "finance", "finans": return "💰"
        default: return "🎯"
        }
    }

    /// Korelasyon gücü açıklaması
    func correlationStrength(_ value: Double) -> String {
        let absValue = abs(value)
        switch absValue {
        case 0.8...1.0: return String(localized: "analytics.correlation.veryStrong", defaultValue: "Çok Güçlü", comment: "Very strong correlation")
        case 0.6..<0.8: return String(localized: "analytics.correlation.strong", defaultValue: "Güçlü", comment: "Strong correlation")
        case 0.4..<0.6: return String(localized: "analytics.correlation.moderate", defaultValue: "Orta", comment: "Moderate correlation")
        case 0.2..<0.4: return String(localized: "analytics.correlation.weak", defaultValue: "Zayıf", comment: "Weak correlation")
        default: return String(localized: "analytics.correlation.veryWeak", defaultValue: "Çok Zayıf", comment: "Very weak correlation")
        }
    }

    /// Korelasyon rengi
    func correlationColor(_ value: Double) -> String {
        if value > 0.6 {
            return "green"
        } else if value > 0.3 {
            return "blue"
        } else if value > 0 {
            return "gray"
        } else if value > -0.3 {
            return "orange"
        } else {
            return "red"
        }
    }
}

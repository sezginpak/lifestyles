//
//  MoodJournalViewModel.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Mood & Journal state management
//

import Foundation
import SwiftData

@Observable
@MainActor
class MoodJournalViewModel {
    // Services
    private let analyticsService = MoodAnalyticsService.shared
    private let journalService = JournalService.shared
    private let aiService = MoodAIService.shared
    private let streakService = MoodStreakService.shared
    private let tagService = TagSuggestionService.shared

    // State - Mood
    var moodEntries: [MoodEntry] = []
    var todaysMoods: [MoodEntry] = [] // Gün içindeki tüm mood'lar
    var selectedDate: Date = Date()
    var editingMoodEntry: MoodEntry? // Düzenleme için

    // State - Journal
    var journalEntries: [JournalEntry] = []
    var filteredJournalType: JournalType?
    var searchQuery: String = ""

    // State - Analytics
    var moodStats: MoodStats = .empty()
    var moodCorrelation: MoodCorrelation = .empty()
    var heatmapData: [MoodDayData] = []

    // State - AI
    var aiInsight: MoodAIInsight?
    var isLoadingAI: Bool = false

    // State - Streak
    var streakData: StreakData = .empty()

    // State - Location Correlation
    var locationCorrelations: [MoodLocationCorrelation] = []

    // State - Tags
    var tagSuggestions: [String] = []

    // State - UI
    var selectedTab: Tab = .mood
    var showingJournalEditor: Bool = false
    var editingJournalEntry: JournalEntry?
    var selectedJournalForDetail: JournalEntry? // Detay görüntüleme için

    // State - Error Handling
    var errorMessage: String?
    var showError: Bool = false

    enum Tab: String, CaseIterable {
        case mood = "Mood"
        case journal = "Journal"
        case analytics = "Analiz"

        var icon: String {
            switch self {
            case .mood: return "face.smiling"
            case .journal: return "book.fill"
            case .analytics: return "chart.bar.fill"
            }
        }
    }

    // MARK: - Data Loading

    /// Tüm verileri yükle
    func loadAllData(context: ModelContext) {
        loadMoodEntries(context: context)
        loadJournalEntries(context: context)
        loadTodaysMoods()

        // Analytics'i arka planda yükle (UI'ı bloklamadan)
        Task { @MainActor in
            // UI'ın render olması için kısa gecikme
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 saniye
            loadAnalytics(context: context)
        }
    }

    /// Mood entry'leri yükle
    private func loadMoodEntries(context: ModelContext) {
        let descriptor = FetchDescriptor<MoodEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            moodEntries = try context.fetch(descriptor)
        } catch {
            print("❌ Failed to load mood entries: \(error)")
            moodEntries = []
        }
    }

    /// Journal entry'leri yükle
    private func loadJournalEntries(context: ModelContext) {
        journalEntries = journalService.fetchAllEntries(context: context)
    }

    /// Analytics hesapla (arka planda - UI donmasını önlemek için)
    private func loadAnalytics(context: ModelContext) {
        // Son 30 günün verileri
        let last30Days = analyticsService.filterEntriesByPeriod(
            entries: moodEntries,
            period: .month
        )

        // Stats
        moodStats = analyticsService.calculateMoodStats(entries: last30Days)

        // Heatmap
        heatmapData = analyticsService.generateHeatmapData(
            entries: moodEntries,
            days: 30
        )

        // Correlations
        let goalCorrelations = analyticsService.calculateGoalCorrelations(
            moodEntries: last30Days,
            context: context
        )
        let friendCorrelations = analyticsService.calculateFriendCorrelations(
            moodEntries: last30Days,
            context: context
        )

        moodCorrelation = MoodCorrelation(
            goalCorrelations: goalCorrelations,
            friendCorrelations: friendCorrelations
        )

        // Streak hesapla
        streakData = streakService.calculateStreak(entries: moodEntries)

        // Location correlations
        locationCorrelations = analyticsService.calculateLocationCorrelations(
            moodEntries: last30Days,
            context: context
        )
    }

    /// Bugünün tüm mood'larını yükle
    private func loadTodaysMoods() {
        todaysMoods = moodEntries.filter { $0.isToday }
            .sorted { $0.date > $1.date } // En yeni önce
    }

    /// Yeni mood eklendiğinde incremental update (filter yerine)
    private func addTodaysMood(_ mood: MoodEntry) {
        // Önce array'e ekle
        todaysMoods.insert(mood, at: 0) // En başa ekle (en yeni)

        // Sadece bugünün mood'larını tut (eski tarihli olanları temizle)
        todaysMoods = todaysMoods.filter { $0.isToday }
            .sorted { $0.date > $1.date }
    }

    /// En son kaydedilen mood (computed property)
    var currentMood: MoodEntry? {
        todaysMoods.first
    }

    /// Yeni mood eklenebilir mi? (günde max 5)
    var canAddMood: Bool {
        todaysMoods.count < 5
    }

    /// Bugünün ortalama mood skoru
    var todaysMoodAverage: Double {
        guard !todaysMoods.isEmpty else { return 0.0 }
        let totalScore = todaysMoods.reduce(0.0) { $0 + $1.score }
        return totalScore / Double(todaysMoods.count)
    }

    /// Bugünün mood emoji'si (en yaygın mood)
    var todaysMoodEmoji: String {
        guard let currentMood = currentMood else { return "😊" }
        return currentMood.moodType.emoji
    }

    // MARK: - Mood Operations

    /// Yeni mood kaydet (günde max 5)
    func logMood(
        moodType: MoodType,
        intensity: Int,
        note: String?,
        relatedLocation: LocationLog? = nil,
        context: ModelContext
    ) {
        // ModelContext nil kontrolü
        guard context.container != nil else {
            print("❌ ModelContext is invalid")
            errorMessage = "Veri kaydedilemedi. Lütfen uygulamayı yeniden başlatın."
            showError = true
            HapticFeedback.error()
            return
        }

        // Günde max 5 kontrol
        guard canAddMood else {
            print("⚠️ Cannot add mood: Daily limit reached (5)")
            errorMessage = "Günlük mood sınırına ulaştınız. Günde en fazla 5 mood kaydedebilirsiniz."
            showError = true
            HapticFeedback.warning()
            return
        }

        let entry = MoodEntry(
            moodType: moodType,
            intensity: intensity,
            note: note,
            relatedLocation: relatedLocation
        )

        do {
            // Önce insert yap
            context.insert(entry)

            // Save işlemini dene
            try context.save()

            // Sadece save başarılıysa state'i güncelle
            moodEntries.insert(entry, at: 0)

            // ✅ PERFORMANCE FIX: Gereksiz filter yerine incremental update
            addTodaysMood(entry)

            HapticFeedback.success()

            print("✅ Mood successfully logged: \(moodType.rawValue)")
        } catch {
            print("❌ Failed to log mood: \(error)")

            // Kullanıcıya anlaşılır hata mesajı göster
            if let nsError = error as NSError? {
                if nsError.domain == "NSCocoaErrorDomain" {
                    errorMessage = "Veritabanı hatası. Lütfen tekrar deneyin."
                } else {
                    errorMessage = "Mood kaydedilirken bir hata oluştu: \(nsError.localizedDescription)"
                }
            } else {
                errorMessage = "Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin."
            }

            showError = true
            HapticFeedback.error()

            // Insert'i geri al (eğer mümkünse)
            context.delete(entry)
        }
    }

    /// Mood sil
    func deleteMood(_ entry: MoodEntry, context: ModelContext) {
        do {
            context.delete(entry)
            try context.save()

            // State güncelle
            moodEntries.removeAll { $0.id == entry.id }

            // ✅ PERFORMANCE FIX: Direkt remove (filter yerine)
            todaysMoods.removeAll { $0.id == entry.id }

            HapticFeedback.success()
        } catch {
            print("❌ Failed to delete mood: \(error)")
            errorMessage = "Mood silinirken bir hata oluştu. Lütfen tekrar deneyin."
            showError = true
            HapticFeedback.error()
        }
    }

    /// Mood düzenleme modunu başlat
    func startEditingMood(_ entry: MoodEntry) {
        editingMoodEntry = entry
    }

    /// Mood güncelle
    func updateMood(
        _ entry: MoodEntry,
        moodType: MoodType? = nil,
        intensity: Int? = nil,
        note: String? = nil,
        context: ModelContext
    ) {
        do {
            // Önce değişiklikleri yap
            if let moodType = moodType {
                entry.moodType = moodType
            }
            if let intensity = intensity {
                entry.intensity = intensity
            }
            if note != nil {
                entry.note = note
            }

            // Save ve state güncelle
            try context.save()

            // ✅ PERFORMANCE FIX: SwiftData otomatik update ediyor, gereksiz filter yok
            // todaysMoods array'i zaten @Observable olduğu için değişikliği algılıyor

            HapticFeedback.success()
        } catch {
            print("❌ Failed to update mood: \(error)")
            errorMessage = "Mood güncellenirken bir hata oluştu. Lütfen tekrar deneyin."
            showError = true
            HapticFeedback.error()
        }
    }

    // MARK: - Journal Operations

    /// Journal entry oluştur
    func createJournalEntry(
        content: String,
        journalType: JournalType,
        title: String? = nil,
        tags: [String] = [],
        linkToTodaysMood: Bool = false,
        context: ModelContext
    ) {
        let moodLink = linkToTodaysMood ? currentMood : nil

        do {
            try journalService.createEntry(
                content: content,
                journalType: journalType,
                title: title,
                tags: tags,
                moodEntry: moodLink,
                context: context
            )

            // Reload
            loadJournalEntries(context: context)
        } catch {
            print("❌ Journal oluşturma hatası: \(error)")
        }
        HapticFeedback.success()
    }

    /// Journal entry sil
    func deleteJournalEntry(_ entry: JournalEntry, context: ModelContext) {
        journalService.deleteEntry(entry, context: context)
        loadJournalEntries(context: context)
    }

    /// Favori toggle
    func toggleFavorite(_ entry: JournalEntry, context: ModelContext) {
        entry.toggleFavorite()

        do {
            try context.save()
        } catch {
            print("❌ Failed to toggle favorite: \(error)")
        }
    }

    /// Filtrelenmiş journal listesi
    var filteredJournalEntries: [JournalEntry] {
        var filtered = journalEntries

        // Type filter
        if let type = filteredJournalType {
            filtered = filtered.filter { $0.journalType == type }
        }

        // Search filter
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            filtered = filtered.filter { entry in
                entry.content.lowercased().contains(query) ||
                (entry.title?.lowercased().contains(query) ?? false)
            }
        }

        return filtered
    }

    // MARK: - AI Operations

    /// Haftalık AI analizi
    @available(iOS 26.0, *)
    func generateWeeklyAnalysis(context: ModelContext) async {
        isLoadingAI = true

        let insight = await aiService.analyzeWeeklyMood(
            entries: moodEntries,
            context: context
        )

        await MainActor.run {
            aiInsight = insight
            isLoadingAI = false
        }
    }

    // MARK: - Helpers

    /// Belirli bir tarihteki mood'u bul
    func getMoodForDate(_ date: Date) -> MoodEntry? {
        moodEntries.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    /// Bu ayki journal sayısı
    var journalCountThisMonth: Int {
        journalEntries.filter { $0.isThisMonth }.count
    }

    /// JournalEntry için isThisMonth helper extension
    private func isThisMonth(_ entry: JournalEntry) -> Bool {
        Calendar.current.isDate(entry.date, equalTo: Date(), toGranularity: .month)
    }

    /// Bu haftaki mood sayısı
    var moodCountThisWeek: Int {
        moodEntries.filter { $0.isThisWeek }.count
    }

    // MARK: - Tag Operations

    /// Journal type'a göre tag önerileri al
    func loadTagSuggestions(for journalType: JournalType, existingTags: [String]) {
        tagSuggestions = tagService.suggestTags(
            for: journalType,
            existingTags: existingTags,
            allEntries: journalEntries
        )
    }

    /// İçerikten tag önerisi al
    func suggestTagsFromContent(_ content: String) -> [String] {
        tagService.suggestTagsFromContent(content)
    }

    // MARK: - Journal Edit Operations

    /// Journal entry düzenle
    func updateJournalEntry(
        _ entry: JournalEntry,
        title: String?,
        content: String,
        tags: [String],
        context: ModelContext
    ) {
        journalService.updateEntry(
            entry,
            content: content,
            title: title,
            tags: tags,
            context: context
        )

        loadJournalEntries(context: context)
        HapticFeedback.success()
    }

    /// Journal düzenleme modunu başlat
    func startEditingJournal(_ entry: JournalEntry) {
        editingJournalEntry = entry
        showingJournalEditor = true
    }
}

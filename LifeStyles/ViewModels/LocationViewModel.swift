//
//  LocationViewModel.swift
//  LifeStyles
//
//  Created by Claude on 15.10.2025.
//

import Foundation
import SwiftData
import CoreLocation

@Observable
class LocationViewModel {
    var isAtHome: Bool = false
    var hoursAtHome: Double = 0
    var currentActivity: String = "Bilinmiyor"
    var suggestedActivities: [ActivitySuggestion] = []
    var showingPermissionAlert = false
    var homeLocationSet = false

    // Yeni özellikler - Filtering & Stats
    var selectedCategory: ActivityType?
    var selectedTimeOfDay: String?
    var activityStats: ActivityStats?
    var badges: [Badge] = []
    var favoriteActivities: [ActivitySuggestion] = []

    // Periyodik takip durumu
    var isPeriodicTrackingActive: Bool = false
    var lastRecordedLocation: Date?
    var totalLocationsRecorded: Int = 0
    var locationHistory: [LocationLog] = []

    // AI State (iOS 26+)
    var aiActivityRecommendations: [ActivityRecommendationWrapper] = []
    var isLoadingAI: Bool = false

    @available(iOS 26.0, *)
    private var activityAIService: ActivityAIService {
        ActivityAIService.shared
    }

    private let locationService = LocationService.shared
    private let notificationService = NotificationService.shared
    private var modelContext: ModelContext?

    init() {
        locationService.loadHomeLocation()
        homeLocationSet = locationService.homeLocation != nil
        updateLocationStatus()
        updatePeriodicTrackingStatus()
    }

    // ModelContext'i ayarla
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        locationService.setModelContext(context)

        // Otomatik başlatma: Eğer izin varsa ve takip aktif değilse, otomatik başlat
        autoStartTrackingIfNeeded()
    }

    // Otomatik başlatma mantığı
    private func autoStartTrackingIfNeeded() {
        // Eğer zaten aktifse, tekrar başlatma
        guard !isPeriodicTrackingActive else {
            print("ℹ️ Konum takibi zaten aktif")
            return
        }

        // "Her Zaman" izni var mı kontrol et
        if PermissionManager.shared.hasAlwaysLocationPermission() {
            print("✅ Her Zaman konum izni var, otomatik başlatılıyor...")
            locationService.startPeriodicTracking()
            updatePeriodicTrackingStatus()
        } else {
            print("ℹ️ Her Zaman konum izni yok, otomatik başlatma yapılamadı")
        }
    }

    func requestLocationPermission() {
        locationService.requestPermission()
    }

    func startTracking() {
        locationService.startTracking()
    }

    func stopTracking() {
        locationService.stopTracking()
    }

    func setHomeLocation(latitude: Double, longitude: Double) {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        locationService.setHomeLocation(coordinate)
        homeLocationSet = true
    }

    func updateLocationStatus() {
        isAtHome = locationService.isAtHome
        hoursAtHome = locationService.timeSpentAtHome / 3600

        if isAtHome {
            currentActivity = "Evde"
        } else {
            currentActivity = "Dışarıda"
        }
    }

    func generateActivitySuggestions(context: ModelContext) {
        // Önceki önerileri temizle
        suggestedActivities.removeAll()

        if hoursAtHome >= 4 {
            // Dışarı çık önerileri
            let activities: [(String, String, ActivityType)] = [
                ("Yürüyüşe Çık 🚶", "30 dakika yürüyüş yapın, hava alın", .outdoor),
                ("Spor Yap 🏃", "Yakındaki parka gidip koşu yapabilirsiniz", .exercise),
                ("Kafe'ye Git ☕", "Bir arkadaşınızla kahve içmeye ne dersiniz?", .social),
                ("Alışverişe Çık 🛍️", "İhtiyacınız olan şeyleri almaya çıkabilirsiniz", .outdoor),
                ("Kitapçıya Uğra 📚", "Yeni bir kitap keşfetme zamanı", .learning)
            ]

            for (title, description, type) in activities.prefix(3) {
                let suggestion = ActivitySuggestion(
                    title: title,
                    activityDescription: description,
                    type: type
                )
                context.insert(suggestion)
                suggestedActivities.append(suggestion)
            }
        } else {
            // Ev içi aktiviteler
            let activities: [(String, String, ActivityType)] = [
                ("Meditasyon Yap 🧘", "10 dakika nefes egzersizi yapın", .relax),
                ("Yeni Şeyler Öğren 📖", "Online bir kurs başlatın", .learning),
                ("Yaratıcı Ol 🎨", "Bir şeyler çizin veya yazın", .creative)
            ]

            for (title, description, type) in activities.prefix(2) {
                let suggestion = ActivitySuggestion(
                    title: title,
                    activityDescription: description,
                    type: type
                )
                context.insert(suggestion)
                suggestedActivities.append(suggestion)
            }
        }

        try? context.save()
    }

    func completeActivity(_ activity: ActivitySuggestion, context: ModelContext) {
        activity.isCompleted = true
        activity.completedAt = Date()
        try? context.save()

        // Tebrik bildirimi
        notificationService.sendMotivationalMessage()
    }

    func logLocation(context: ModelContext) {
        guard let location = locationService.currentLocation else { return }

        let locationType: LocationType = isAtHome ? .home : .other
        let log = LocationLog(
            timestamp: Date(),
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            locationType: locationType
        )

        context.insert(log)
        try? context.save()
    }

    // MARK: - Periyodik Takip Fonksiyonları

    func updatePeriodicTrackingStatus() {
        isPeriodicTrackingActive = locationService.isPeriodicTrackingActive
        lastRecordedLocation = locationService.lastRecordedLocation
        totalLocationsRecorded = locationService.totalLocationsRecorded
    }

    func startPeriodicTracking() {
        guard let context = modelContext else {
            print("⚠️ ModelContext ayarlanmamış!")
            return
        }

        locationService.startPeriodicTracking()
        updatePeriodicTrackingStatus()
    }

    func stopPeriodicTracking() {
        locationService.stopPeriodicTracking()
        updatePeriodicTrackingStatus()
    }

    func fetchLocationHistory(for date: Date? = nil) {
        guard let context = modelContext else { return }
        locationHistory = locationService.fetchLocationHistory(for: date, context: context)
    }

    func getLocationCountForLastDays(_ days: Int) -> Int {
        guard let context = modelContext else { return 0 }
        return locationService.getLocationCountForLastDays(days, context: context)
    }

    // Formatlanmış son kayıt zamanı
    var formattedLastRecordedLocation: String {
        guard let date = lastRecordedLocation else { return "Henüz kayıt yok" }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - AI Functions (iOS 26+)

    @available(iOS 26.0, *)
    @MainActor
    func loadAIActivityRecommendations(userGoals: [Goal] = []) async {
        isLoadingAI = true

        do {
            let location = locationService.currentLocation?.coordinate
            let locationType: LocationType? = isAtHome ? .home : .other

            let recommendations = try await activityAIService.generateMultipleRecommendations(
                count: 3,
                location: location,
                locationType: locationType,
                userGoals: userGoals
            )

            // Wrapper'a çevir
            aiActivityRecommendations = recommendations.map { rec in
                ActivityRecommendationWrapper(
                    activity: rec.activity,
                    reason: rec.reason,
                    location: rec.location,
                    estimatedDuration: rec.estimatedDuration,
                    difficulty: rec.difficulty,
                    category: rec.category
                )
            }
        } catch {
            print("❌ AI aktivite önerileri hatası: \(error)")
        }

        isLoadingAI = false
    }

    // MARK: - New Features - Stats & Gamification

    func loadOrCreateStats(context: ModelContext) {
        let descriptor = FetchDescriptor<ActivityStats>()
        if let existingStats = try? context.fetch(descriptor).first {
            activityStats = existingStats
        } else {
            // Create new stats
            let newStats = ActivityStats()
            context.insert(newStats)
            activityStats = newStats
            try? context.save()
        }
    }

    func loadBadges(context: ModelContext) {
        let descriptor = FetchDescriptor<Badge>()
        if let fetchedBadges = try? context.fetch(descriptor).sorted(by: { $0.isEarned && !$1.isEarned }) {
            if fetchedBadges.isEmpty {
                // Create default badges
                let defaultBadges = Badge.createDefaultBadges()
                defaultBadges.forEach { context.insert($0) }
                try? context.save()
                badges = defaultBadges
            } else {
                badges = fetchedBadges
            }
        }
    }

    func loadFavoriteActivities(context: ModelContext) {
        let descriptor = FetchDescriptor<ActivitySuggestion>(
            predicate: #Predicate { $0.isFavorite == true }
        )
        if let favorites = try? context.fetch(descriptor) {
            favoriteActivities = favorites
        }
    }

    // Filtered activities based on selection
    var filteredActivities: [ActivitySuggestion] {
        var filtered = suggestedActivities

        // Category filter
        if let category = selectedCategory {
            filtered = filtered.filter { $0.type == category }
        }

        // Time of day filter
        if let time = selectedTimeOfDay {
            filtered = filtered.filter { $0.timeOfDay == time }
        }

        return filtered
    }

    // Toggle favorite
    func toggleFavorite(_ activity: ActivitySuggestion, context: ModelContext) {
        activity.toggleFavorite()
        try? context.save()

        // Reload favorites
        loadFavoriteActivities(context: context)
    }

    // Complete activity with stats update
    func completeActivityWithStats(_ activity: ActivitySuggestion, context: ModelContext) {
        // Mark activity as complete
        activity.complete()

        // Create completion record
        let completion = ActivityCompletion(
            activityTitle: activity.title,
            activityDescription: activity.activityDescription,
            activityCategory: activity.type.rawValue,
            pointsEarned: activity.calculatedPoints,
            currentStreak: activityStats?.currentStreak ?? 0,
            streakBonusApplied: (activityStats?.currentStreak ?? 0) >= 7,
            difficultyLevel: activity.difficultyLevel,
            relatedSuggestion: activity
        )
        context.insert(completion)

        // Update stats
        if let stats = activityStats {
            stats.recordCompletion(
                category: activity.type,
                timeOfDay: activity.timeOfDay,
                points: activity.calculatedPoints
            )
        }

        // Update badges
        updateBadgeProgress(context: context)

        // Save
        try? context.save()

        // Schedule notification for next day
        scheduleStreakReminder()
    }

    // Update badge progress
    private func updateBadgeProgress(context: ModelContext) {
        guard let stats = activityStats else { return }

        for badge in badges {
            switch badge.category {
            case .streak:
                badge.updateProgress(stats.currentStreak)

            case .completion:
                badge.updateProgress(stats.totalActivitiesCompleted)

            case .time:
                if badge.title.contains("Sabah") {
                    badge.updateProgress(stats.morningActivities)
                } else if badge.title.contains("Gece") {
                    badge.updateProgress(stats.nightActivities)
                }

            case .category:
                if badge.title.contains("Sosyal") {
                    badge.updateProgress(stats.socialCount)
                } else if badge.title.contains("Öğrenme") {
                    badge.updateProgress(stats.learningCount)
                } else if badge.title.contains("Hareket") {
                    badge.updateProgress(stats.exerciseCount)
                } else if badge.title.contains("Doğa") {
                    badge.updateProgress(stats.outdoorCount)
                } else if badge.title.contains("Yaratıcı") {
                    badge.updateProgress(stats.creativeCount)
                } else if badge.title.contains("Zen") {
                    badge.updateProgress(stats.relaxCount)
                }

            case .special:
                break
            }

            // Check if badge was just earned
            if badge.isEarned && badge.earnedAt != nil {
                let timeSinceEarned = Date().timeIntervalSince(badge.earnedAt!)
                if timeSinceEarned < 5 {
                    // Just earned, send notification
                    sendBadgeEarnedNotification(badge)
                }
            }
        }

        try? context.save()
    }

    // Generate activities with time of day
    func generateActivitiesWithTimeOfDay(context: ModelContext) {
        let currentHour = Calendar.current.component(.hour, from: Date())
        let timeOfDay: String

        switch currentHour {
        case 5..<12:
            timeOfDay = "morning"
        case 12..<17:
            timeOfDay = "afternoon"
        case 17..<21:
            timeOfDay = "evening"
        default:
            timeOfDay = "night"
        }

        // Generate activities
        generateActivitySuggestions(context: context, preferredTimeOfDay: timeOfDay)
    }

    // Generate with preferred time
    func generateActivitySuggestions(context: ModelContext, preferredTimeOfDay: String? = nil) {
        // Clear existing
        suggestedActivities.removeAll()

        // Generate 5 activities
        let categories: [ActivityType] = [.outdoor, .exercise, .social, .learning, .creative, .relax]

        for category in categories.shuffled().prefix(5) {
            let activity = createRandomActivity(category: category, timeOfDay: preferredTimeOfDay)
            context.insert(activity)
            suggestedActivities.append(activity)
        }

        try? context.save()
    }

    private func createRandomActivity(category: ActivityType, timeOfDay: String?) -> ActivitySuggestion {
        let templates = getActivityTemplates(for: category)
        let template = templates.randomElement() ?? ("Aktivite", "Açıklama")

        return ActivitySuggestion(
            title: template.0,
            activityDescription: template.1,
            type: category,
            completionPoints: Int.random(in: 10...50),
            sourceType: .ruleBased,
            difficultyLevel: ["easy", "medium", "hard"].randomElement()!,
            estimatedDuration: [" 15 dk", "30 dk", "45 dk", "1 saat"].randomElement(),
            scientificReason: getScientificReason(for: category),
            timeOfDay: timeOfDay
        )
    }

    private func getActivityTemplates(for category: ActivityType) -> [(String, String)] {
        switch category {
        case .outdoor:
            return [
                ("Yeşilde Yürüyüş", "Yakındaki bir parkta 30 dakika tempolu yürüyüş yap"),
                ("Doğa Fotoğrafçılığı", "Doğada güzel anları fotoğrafla"),
                ("Açık Hava Meditasyonu", "Yeşil alanda 15 dakika meditasyon")
            ]
        case .exercise:
            return [
                ("Ev Egzersizi", "20 dakika vücut ağırlığı çalışması"),
                ("Yoga Seansı", "30 dakika rahatlatıcı yoga"),
                ("Koşu", "Tempolu 25 dakika koşu")
            ]
        case .social:
            return [
                ("Arkadaş Kahvesi", "Bir arkadaşınla kahve içmeye çık"),
                ("Video Görüşme", "Uzaktaki sevdiklerinle görüntülü konuş"),
                ("Aile Yemeği", "Ailenle birlikte yemek ye")
            ]
        case .learning:
            return [
                ("Podcast Dinle", "İlgi alanında 30 dakika podcast"),
                ("Kitap Oku", "20 sayfa kitap oku"),
                ("Online Kurs", "Yeni bir beceri öğren")
            ]
        case .creative:
            return [
                ("Günlük Yaz", "15 dakika düşüncelerini yaz"),
                ("Çizim", "Serbest çizim yap"),
                ("Müzik", "Sevdiğin bir enstrümanı çal")
            ]
        case .relax:
            return [
                ("Derin Nefes", "10 dakika nefes egzersizi"),
                ("Müzik Dinle", "Rahatlatıcı müzik dinle"),
                ("Sıcak Duş", "15 dakika sıcak duş al")
            ]
        }
    }

    private func getScientificReason(for category: ActivityType) -> String {
        switch category {
        case .outdoor:
            return "Doğada vakit geçirmek kortizol seviyesini düşürür ve ruh halini iyileştirir."
        case .exercise:
            return "Egzersiz endorfin salgılanmasını artırır ve stresi azaltır."
        case .social:
            return "Sosyal bağlar oksitoksin hormonu salgılatır ve mutluluğu artırır."
        case .learning:
            return "Yeni şeyler öğrenmek beyin plastisite artırır ve zihinsel sağlığı korur."
        case .creative:
            return "Yaratıcılık dopamin salgılanmasını tetikler ve özgüveni artırır."
        case .relax:
            return "Dinlenme parasempatik sinir sistemini aktive eder ve stresi azaltır."
        }
    }

    // Notifications
    private func scheduleStreakReminder() {
        // Schedule for tomorrow morning
        notificationService.scheduleDailyActivityReminder()
    }

    private func sendBadgeEarnedNotification(_ badge: Badge) {
        notificationService.sendBadgeEarnedNotification(badgeTitle: badge.title, badgeDescription: badge.badgeDescription)
    }
}

// MARK: - Wrapper Types (iOS 17+ compat)

struct ActivityRecommendationWrapper: Codable, Identifiable {
    let id = UUID()
    let activity: String
    let reason: String
    let location: String
    let estimatedDuration: String
    let difficulty: String
    let category: String
}

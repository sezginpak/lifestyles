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
@MainActor
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

    // Error Handling
    var errorMessage: String?
    var showError: Bool = false

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
            return
        }

        // "Her Zaman" izni var mı kontrol et
        if PermissionManager.shared.hasAlwaysLocationPermission() {
            locationService.startPeriodicTracking()
            updatePeriodicTrackingStatus()
        } else {
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
            currentActivity = String(localized: "activity.current.outdoor", comment: "Outdoor")
        }
    }

    func generateActivitySuggestions(context: ModelContext) {
        suggestedActivities.removeAll()

        let activities = hoursAtHome >= 4 ?
            getOutdoorActivities() : getIndoorActivities()

        for (title, description, type) in activities {
            let suggestion = ActivitySuggestion(
                title: title,
                activityDescription: description,
                type: type
            )
            context.insert(suggestion)
            suggestedActivities.append(suggestion)
        }

        do {
            try context.save()
        } catch {
            print("❌ Failed to save activity suggestions: \(error)")
            errorMessage = "Aktivite önerileri kaydedilirken bir hata oluştu."
            showError = true
        }
    }

    private func getOutdoorActivities() -> [(String, String, ActivityType)] {
        let activities: [(String, String, ActivityType)] = [
            (String(localized: "activity.suggestion.walk.title", comment: "Walk"),
             String(localized: "activity.suggestion.walk.desc", comment: "Walk desc"),
             .outdoor),
            (String(localized: "activity.suggestion.exercise.title", comment: "Exercise"),
             String(localized: "activity.suggestion.exercise.desc", comment: "Exercise desc"),
             .exercise),
            (String(localized: "activity.suggestion.cafe.title", comment: "Cafe"),
             String(localized: "activity.suggestion.cafe.desc", comment: "Cafe desc"),
             .social),
            (String(localized: "activity.suggestion.shopping.title", comment: "Shopping"),
             String(localized: "activity.suggestion.shopping.desc", comment: "Shopping desc"),
             .outdoor),
            (String(localized: "activity.suggestion.bookstore.title", comment: "Bookstore"),
             String(localized: "activity.suggestion.bookstore.desc", comment: "Bookstore desc"),
             .learning)
        ]
        return Array(activities.prefix(3))
    }

    private func getIndoorActivities() -> [(String, String, ActivityType)] {
        let activities: [(String, String, ActivityType)] = [
            (String(localized: "activity.suggestion.meditation.title", comment: "Meditation"),
             String(localized: "activity.suggestion.meditation.desc", comment: "Meditation desc"),
             .relax),
            (String(localized: "activity.suggestion.learn.title", comment: "Learn"),
             String(localized: "activity.suggestion.learn.desc", comment: "Learn desc"),
             .learning),
            (String(localized: "activity.suggestion.creative.title", comment: "Creative"),
             String(localized: "activity.suggestion.creative.desc", comment: "Creative desc"),
             .creative)
        ]
        return Array(activities.prefix(2))
    }

    func completeActivity(_ activity: ActivitySuggestion, context: ModelContext) {
        do {
            activity.isCompleted = true
            activity.completedAt = Date()
            try context.save()

            // Tebrik bildirimi
            notificationService.sendMotivationalMessage()
            HapticFeedback.success()
        } catch {
            print("❌ Failed to complete activity: \(error)")
            errorMessage = "Aktivite tamamlanırken bir hata oluştu. Lütfen tekrar deneyin."
            showError = true
            HapticFeedback.error()
        }
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

        do {
            context.insert(log)
            try context.save()
        } catch {
            print("❌ Failed to log location: \(error)")
            errorMessage = "Konum kaydedilirken bir hata oluştu."
            showError = true
        }
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
                (String(localized: "activity.nature.walk.title", comment: "Nature walk"), String(localized: "activity.nature.walk.desc", comment: "Nature walk desc")),
                (String(localized: "activity.nature.photo.title", comment: "Nature photo"), String(localized: "activity.nature.photo.desc", comment: "Nature photo desc")),
                (String(localized: "activity.nature.meditation.title", comment: "Nature meditation"), String(localized: "activity.nature.meditation.desc", comment: "Nature meditation desc"))
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

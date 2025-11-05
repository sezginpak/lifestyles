//
//  SettingsViewModel.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//

import Foundation
import SwiftData
import UserNotifications

@Observable
class SettingsViewModel {
    // Servis referansları
    private let permissionManager = PermissionManager.shared
    private let notificationService = NotificationService.shared
    private let locationService = LocationService.shared

    // İzin durumları
    var locationPermissionStatus: PermissionManager.PermissionStatus = .notDetermined
    var contactsPermissionStatus: PermissionManager.PermissionStatus = .notDetermined
    var notificationsPermissionStatus: PermissionManager.PermissionStatus = .notDetermined

    // Toggle durumları
    var notificationsEnabled: Bool = false
    var locationTrackingEnabled: Bool = false
    var dailyMotivationEnabled: Bool = true

    // Bildirim tercihleri
    var reminderFrequency: ReminderFrequency = .normal
    var quietHoursEnabled: Bool = false
    var quietHoursStart: Date = Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
    var quietHoursEnd: Date = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()

    // Bildirim türü tercihleri
    var friendRemindersEnabled: Bool = true
    var goalRemindersEnabled: Bool = true
    var habitRemindersEnabled: Bool = true
    var locationSuggestionsEnabled: Bool = true
    var motivationMessagesEnabled: Bool = true
    var activityRemindersEnabled: Bool = true
    var streakWarningsEnabled: Bool = true

    // İstatistikler
    var totalFriends: Int = 0
    var totalLocationLogs: Int = 0
    var totalGoals: Int = 0
    var totalHabits: Int = 0
    var storageUsed: String = "0 MB"

    // Veri yönetimi durumu
    var isExporting: Bool = false
    var isImporting: Bool = false
    var isDeleting: Bool = false
    var showDeleteConfirmation: Bool = false
    var operationMessage: String?

    enum ReminderFrequency: String, CaseIterable, Identifiable {
        case frequent = "Sık"
        case normal = "Normal"
        case rare = "Seyrek"

        var id: String { rawValue }

        var description: String {
            switch self {
            case .frequent: return "Günde birkaç kez"
            case .normal: return "Günde bir kez"
            case .rare: return "Haftada birkaç kez"
            }
        }
    }

    init() {
        loadSettings()
        checkPermissions()
    }

    // MARK: - Ayarları Yükle

    private func loadSettings() {
        // UserDefaults'tan ayarları yükle
        dailyMotivationEnabled = UserDefaults.standard.bool(forKey: "dailyMotivationEnabled")
        quietHoursEnabled = UserDefaults.standard.bool(forKey: "quietHoursEnabled")

        if let frequencyRaw = UserDefaults.standard.string(forKey: "reminderFrequency"),
           let frequency = ReminderFrequency(rawValue: frequencyRaw) {
            reminderFrequency = frequency
        }

        if let startDate = UserDefaults.standard.object(forKey: "quietHoursStart") as? Date {
            quietHoursStart = startDate
        }

        if let endDate = UserDefaults.standard.object(forKey: "quietHoursEnd") as? Date {
            quietHoursEnd = endDate
        }

        // Bildirim türü tercihleri (varsayılan true)
        friendRemindersEnabled = UserDefaults.standard.object(forKey: "friendRemindersEnabled") as? Bool ?? true
        goalRemindersEnabled = UserDefaults.standard.object(forKey: "goalRemindersEnabled") as? Bool ?? true
        habitRemindersEnabled = UserDefaults.standard.object(forKey: "habitRemindersEnabled") as? Bool ?? true
        locationSuggestionsEnabled = UserDefaults.standard.object(forKey: "locationSuggestionsEnabled") as? Bool ?? true
        motivationMessagesEnabled = UserDefaults.standard.object(forKey: "motivationMessagesEnabled") as? Bool ?? true
        activityRemindersEnabled = UserDefaults.standard.object(forKey: "activityRemindersEnabled") as? Bool ?? true
        streakWarningsEnabled = UserDefaults.standard.object(forKey: "streakWarningsEnabled") as? Bool ?? true

        // Konum takibi durumu
        locationTrackingEnabled = locationService.isPeriodicTrackingActive
    }

    private func saveSettings() {
        UserDefaults.standard.set(dailyMotivationEnabled, forKey: "dailyMotivationEnabled")
        UserDefaults.standard.set(quietHoursEnabled, forKey: "quietHoursEnabled")
        UserDefaults.standard.set(reminderFrequency.rawValue, forKey: "reminderFrequency")
        UserDefaults.standard.set(quietHoursStart, forKey: "quietHoursStart")
        UserDefaults.standard.set(quietHoursEnd, forKey: "quietHoursEnd")

        // Bildirim türü tercihleri
        UserDefaults.standard.set(friendRemindersEnabled, forKey: "friendRemindersEnabled")
        UserDefaults.standard.set(goalRemindersEnabled, forKey: "goalRemindersEnabled")
        UserDefaults.standard.set(habitRemindersEnabled, forKey: "habitRemindersEnabled")
        UserDefaults.standard.set(locationSuggestionsEnabled, forKey: "locationSuggestionsEnabled")
        UserDefaults.standard.set(motivationMessagesEnabled, forKey: "motivationMessagesEnabled")
        UserDefaults.standard.set(activityRemindersEnabled, forKey: "activityRemindersEnabled")
        UserDefaults.standard.set(streakWarningsEnabled, forKey: "streakWarningsEnabled")
    }

    // MARK: - İzin Kontrolü

    func checkPermissions() {
        locationPermissionStatus = permissionManager.checkLocationPermission()
        contactsPermissionStatus = permissionManager.checkContactsPermission()

        Task {
            notificationsPermissionStatus = await permissionManager.checkNotificationsPermission()
            notificationsEnabled = notificationsPermissionStatus == .authorized
        }
    }

    func openAppSettings() {
        permissionManager.openAppSettings()
    }

    // MARK: - Toggle İşlemleri

    func toggleNotifications(_ enabled: Bool) async {
        if enabled {
            // İzin iste
            let granted = await permissionManager.requestNotificationsPermission()
            notificationsEnabled = granted
        } else {
            // Tüm bildirimleri iptal et
            notificationService.cancelAllNotifications()
            notificationsEnabled = false
        }

        await checkPermissions()
    }

    @MainActor
    func toggleLocationTracking(_ enabled: Bool, context: ModelContext) {
        if enabled {
            locationService.setModelContext(context)
            locationService.startPeriodicTracking()
            locationTrackingEnabled = true
        } else {
            locationService.stopPeriodicTracking()
            locationTrackingEnabled = false
        }
    }

    func toggleDailyMotivation(_ enabled: Bool) {
        dailyMotivationEnabled = enabled
        saveSettings()

        if enabled {
            scheduleDailyMotivation()
        } else {
            // Motivasyon bildirimlerini iptal et
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-motivation"])
        }
    }

    private func scheduleDailyMotivation() {
        // Her gün saat 9'da motivasyon mesajı
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0

        let content = UNMutableNotificationContent()
        content.title = "Günlük Motivasyon"
        content.body = "Yeni bir gün, yeni fırsatlar! 🌟"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily-motivation",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - İstatistikleri Hesapla

    @MainActor
    func calculateStatistics(context: ModelContext) async {
        // Async yapıp yield vererek UI'ı bloke etmeden hesapla
        await Task.yield()

        let counts = await fetchCounts(context: context)

        totalFriends = counts.friends
        totalLocationLogs = counts.locations
        totalGoals = counts.goals
        totalHabits = counts.habits

        // Depolama hesapla (yaklaşık)
        let totalItems = counts.friends + counts.locations + counts.goals + counts.habits
        let estimatedSize = Double(totalItems) * 0.5 // Yaklaşık 0.5 KB per item
        storageUsed = String(format: "%.1f MB", estimatedSize / 1024)
    }

    private func fetchCounts(context: ModelContext) async -> (
        friends: Int,
        locations: Int,
        goals: Int,
        habits: Int
    ) {
        let friendsCount = (try? context.fetch(FetchDescriptor<Friend>()).count) ?? 0
        await Task.yield()

        let logsCount = (try? context.fetch(FetchDescriptor<LocationLog>()).count) ?? 0
        await Task.yield()

        let goalsCount = (try? context.fetch(FetchDescriptor<Goal>()).count) ?? 0
        await Task.yield()

        let habitsCount = (try? context.fetch(FetchDescriptor<Habit>()).count) ?? 0

        return (friendsCount, logsCount, goalsCount, habitsCount)
    }

    // MARK: - Veri Yönetimi

    @MainActor
    func exportData(context: ModelContext) async throws -> URL {
        isExporting = true
        defer { isExporting = false }

        // Tüm verileri topla
        let friends = try context.fetch(FetchDescriptor<Friend>())
        let goals = try context.fetch(FetchDescriptor<Goal>())
        let habits = try context.fetch(FetchDescriptor<Habit>())
        let locationLogs = try context.fetch(FetchDescriptor<LocationLog>())

        // Export yapısı
        let exportData = ExportData(
            exportDate: Date(),
            version: "1.0",
            friends: friends.map { FriendExport(from: $0) },
            goals: goals.map { GoalExport(from: $0) },
            habits: habits.map { HabitExport(from: $0) },
            locationLogs: locationLogs.map { LocationLogExport(from: $0) }
        )

        // JSON'a çevir
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(exportData)

        // Dosyaya kaydet
        let fileName = "LifeStyles_Backup_\(Date().ISO8601Format()).json"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try jsonData.write(to: fileURL)

        operationMessage = "Yedek başarıyla oluşturuldu!"
        return fileURL
    }

    @MainActor
    func importData(from url: URL, context: ModelContext) async throws {
        isImporting = true
        defer { isImporting = false }

        // JSON'ı oku
        let jsonData = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exportData = try decoder.decode(ExportData.self, from: jsonData)

        // Verileri içe aktar
        for friendExport in exportData.friends {
            let frequencyEnum = ContactFrequency(rawValue: friendExport.frequencyRaw) ?? .weekly
            let friend = Friend(
                name: friendExport.name,
                phoneNumber: friendExport.phoneNumber,
                frequency: frequencyEnum,
                isImportant: friendExport.isImportant,
                notes: friendExport.notes,
                avatarEmoji: friendExport.avatarEmoji
            )
            context.insert(friend)
        }

        for goalExport in exportData.goals {
            // Category string'i enum'a çevir
            let categoryEnum = GoalCategory(rawValue: goalExport.categoryRaw) ?? .personal
            let goal = Goal(
                title: goalExport.title,
                goalDescription: goalExport.description,
                category: categoryEnum,
                targetDate: goalExport.targetDate
            )
            goal.isCompleted = goalExport.isCompleted
            context.insert(goal)
        }

        for habitExport in exportData.habits {
            // Frequency string'i enum'a çevir
            let frequencyEnum = HabitFrequency(rawValue: habitExport.frequencyRaw) ?? .daily
            let habit = Habit(
                name: habitExport.name,
                habitDescription: habitExport.description,
                frequency: frequencyEnum,
                reminderTime: habitExport.reminderTime
            )
            context.insert(habit)
        }

        for logExport in exportData.locationLogs {
            let log = LocationLog(
                timestamp: logExport.timestamp,
                latitude: logExport.latitude,
                longitude: logExport.longitude,
                locationType: logExport.locationType,
                accuracy: logExport.accuracy,
                altitude: logExport.altitude
            )
            log.address = logExport.address
            context.insert(log)
        }

        try context.save()
        operationMessage = "Veri başarıyla geri yüklendi!"
    }

    @MainActor
    func deleteAllData(context: ModelContext) async throws {
        isDeleting = true
        defer { isDeleting = false }

        // Tüm modelleri sil
        try context.delete(model: Friend.self)
        try context.delete(model: ContactHistory.self)
        try context.delete(model: Goal.self)
        try context.delete(model: Habit.self)
        try context.delete(model: HabitCompletion.self)
        try context.delete(model: LocationLog.self)

        try context.save()

        // UserDefaults'ı temizle
        if let domain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: domain)
        }

        // Bildirimleri iptal et
        notificationService.cancelAllNotifications()

        // Konum takibini durdur
        locationService.stopPeriodicTracking()

        operationMessage = "Tüm veriler başarıyla silindi!"

        // Ayarları yeniden yükle
        loadSettings()
    }
}

// MARK: - Export Yapıları

struct ExportData: Codable {
    let exportDate: Date
    let version: String
    let friends: [FriendExport]
    let goals: [GoalExport]
    let habits: [HabitExport]
    let locationLogs: [LocationLogExport]
}

struct FriendExport: Codable {
    let name: String
    let phoneNumber: String?
    let frequencyRaw: String
    let isImportant: Bool
    let avatarEmoji: String?
    let notes: String?

    init(from friend: Friend) {
        self.name = friend.name
        self.phoneNumber = friend.phoneNumber
        self.frequencyRaw = friend.frequencyRaw
        self.isImportant = friend.isImportant
        self.avatarEmoji = friend.avatarEmoji
        self.notes = friend.notes
    }
}

struct GoalExport: Codable {
    let title: String
    let description: String
    let targetDate: Date
    let categoryRaw: String
    let isCompleted: Bool

    init(from goal: Goal) {
        self.title = goal.title
        self.description = goal.goalDescription
        self.targetDate = goal.targetDate
        self.categoryRaw = goal.categoryRaw
        self.isCompleted = goal.isCompleted
    }
}

struct HabitExport: Codable {
    let name: String
    let description: String
    let frequencyRaw: String
    let reminderTime: Date?

    init(from habit: Habit) {
        self.name = habit.name
        self.description = habit.habitDescription
        self.frequencyRaw = habit.frequencyRaw
        self.reminderTime = habit.reminderTime
    }
}

struct LocationLogExport: Codable {
    let timestamp: Date
    let latitude: Double
    let longitude: Double
    let locationType: LocationType
    let accuracy: Double
    let altitude: Double
    let address: String?

    init(from log: LocationLog) {
        self.timestamp = log.timestamp
        self.latitude = log.latitude
        self.longitude = log.longitude
        self.locationType = log.locationType
        self.accuracy = log.accuracy
        self.altitude = log.altitude
        self.address = log.address
    }
}

// MARK: - Test Notification Functions

extension SettingsViewModel {
    /// Test bildirimi gönder - Arkadaş hatırlatması
    func sendTestFriendNotification() {
        notificationService.scheduleContactReminder(contactName: "Test Arkadaş", daysSince: 5)
    }

    /// Test bildirimi gönder - Hedef hatırlatması
    func sendTestGoalNotification() {
        notificationService.scheduleGoalReminder(goalTitle: "Test Hedef", daysLeft: 3)
    }

    /// Test bildirimi gönder - Alışkanlık
    func sendTestHabitNotification() {
        let testTime = Date().addingTimeInterval(5) // 5 saniye sonra
        notificationService.scheduleHabitReminder(habitName: "Test Alışkanlık", at: testTime)
    }

    /// Test bildirimi gönder - Konum/Dışarı çıkma
    func sendTestLocationNotification() {
        notificationService.sendGoOutsideReminder(hoursAtHome: 6)
    }

    /// Test bildirimi gönder - Motivasyon
    func sendTestMotivationNotification() {
        notificationService.sendMotivationalMessage()
    }

    /// Test bildirimi gönder - Aktivite hatırlatması
    func sendTestActivityNotification() {
        notificationService.scheduleDailyActivityReminder()
    }

    /// Test bildirimi gönder - Streak uyarısı
    func sendTestStreakNotification() {
        notificationService.sendStreakWarning(currentStreak: 7)
    }

    /// Tüm bildirim türü tercihlerini kaydet
    func saveNotificationPreferences() {
        saveSettings()
    }
}

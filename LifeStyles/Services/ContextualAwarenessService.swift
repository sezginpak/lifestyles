//
//  ContextualAwarenessService.swift
//  LifeStyles
//
//  Context-aware notification management
//  Kullanıcının mevcut durumuna göre bildirim gönderme kararı verir
//

import Foundation
import CoreLocation
import UIKit

@Observable
class ContextualAwarenessService {
    static let shared = ContextualAwarenessService()

    // Current context
    private(set) var currentContext: UserContext

    // Context history
    private var history: ContextHistory

    // Rules
    private var rules: [ContextRule] = []

    private init() {
        self.currentContext = UserContext()
        self.history = ContextHistory()
        setupDefaultRules()
        startContextMonitoring()
    }

    // MARK: - Context Updates

    /// Context'i güncelle
    func updateContext(
        location: LocationContext? = nil,
        calendar: CalendarContext? = nil,
        activity: ActivityContext? = nil,
        focus: FocusContext? = nil
    ) {

        let newContext = UserContext(
            location: location ?? currentContext.location,
            calendar: calendar ?? currentContext.calendar,
            activity: activity ?? currentContext.activity,
            focus: focus ?? currentContext.focus,
            timeOfDay: TimeOfDayContext.current,
            battery: getBatteryContext()
        )

        currentContext = newContext
        history.add(newContext)

        print("🔄 Context güncellendi - Score: \(String(format: "%.2f", newContext.notificationScore))")
    }

    /// Konum context'ini güncelle
    func updateLocation(_ type: LocationContext.LocationType, isMoving: Bool = false) {
        let locationContext = LocationContext(
            type: type,
            coordinate: nil,
            placeName: nil,
            isMoving: isMoving
        )

        updateContext(location: locationContext)
    }

    /// Takvim context'ini güncelle
    func updateCalendar(_ calendarContext: CalendarContext) {
        updateContext(calendar: calendarContext)
    }

    /// Aktivite context'ini güncelle
    func updateActivity(_ activity: ActivityContext) {
        updateContext(activity: activity)
    }

    /// Focus mode'u güncelle
    func updateFocus(_ focus: FocusContext) {
        updateContext(focus: focus)
    }

    // MARK: - Notification Decision

    /// Bildirim gönderilmeli mi?
    func shouldSendNotification(priority: PriorityLevel) -> Bool {
        // Kritik bildirimleri her zaman gönder (driving hariç)
        if priority == .critical {
            return currentContext.canSendCriticalNotifications
        }

        // Priority'ye göre kontrol
        switch priority {
        case .critical:
            return currentContext.canSendCriticalNotifications
        case .high:
            return currentContext.canSendRegularNotifications
        case .normal:
            return currentContext.canSendRegularNotifications
        case .low, .minimal:
            return currentContext.canSendLowPriorityNotifications
        }
    }

    /// Bildirim için context skoru
    func getNotificationScore() -> Double {
        return currentContext.notificationScore
    }

    /// Belirli bir kategori için uygun mu?
    func isAppropriateTime(for category: String) -> Bool {
        let score = currentContext.notificationScore

        // Kategori bazlı minimum skorlar
        let minimumScore: Double
        switch category.lowercased() {
        case "contact", "contact_reminder":
            minimumScore = 0.5
        case "goal", "goal_reminder":
            minimumScore = 0.6
        case "habit", "habit_reminder":
            minimumScore = 0.5
        case "activity", "activity_suggestion":
            minimumScore = 0.7
        case "motivation":
            minimumScore = 0.6
        case "streak", "streak_warning":
            minimumScore = 0.3 // Daha esnek
        default:
            minimumScore = 0.5
        }

        return score >= minimumScore
    }

    // MARK: - Rules

    private func setupDefaultRules() {
        // Do Not Disturb - Tüm bildirimleri engelle
        rules.append(ContextRule(
            name: "Block during DND",
            condition: .focus(.doNotDisturb),
            action: .blockAll
        ))

        // Driving - Sadece kritik bildirimlere izin ver
        rules.append(ContextRule(
            name: "Critical only while driving",
            condition: .activity(.driving),
            action: .allowOnlyCritical
        ))

        // Toplantıda - Düşük önceliklileri engelle
        rules.append(ContextRule(
            name: "Block low priority in meetings",
            condition: .calendarBusy,
            action: .blockLowPriority
        ))

        // Düşük pil - Throttle
        rules.append(ContextRule(
            name: "Throttle on low battery",
            condition: .batteryLow,
            action: .throttle(factor: 0.5)
        ))
    }

    func addRule(_ rule: ContextRule) {
        rules.append(rule)
    }

    func evaluateRules() -> [ContextRule.ActionType] {
        return rules.compactMap { $0.evaluate(currentContext) }
    }

    // MARK: - Battery

    private func getBatteryContext() -> BatteryContext? {
        UIDevice.current.isBatteryMonitoringEnabled = true

        let level = UIDevice.current.batteryLevel
        guard level >= 0 else { return nil }

        return BatteryContext(
            level: Double(level),
            isCharging: UIDevice.current.batteryState == .charging ||
                       UIDevice.current.batteryState == .full,
            isLowPowerMode: ProcessInfo.processInfo.isLowPowerModeEnabled
        )
    }

    // MARK: - Monitoring

    private func startContextMonitoring() {
        // Her 5 dakikada bir context'i güncelle
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.refreshContext()
        }

        print("✅ Context monitoring başlatıldı")
    }

    private func refreshContext() {
        // TimeOfDay otomatik olarak güncellenir
        updateContext()
    }

    // MARK: - Analytics

    func printContextInfo() {
        print("\n📍 === Current Context ===")
        print("Time: \(currentContext.timeOfDay.period.rawValue)")
        print("Location: \(currentContext.location?.type.rawValue ?? "unknown")")
        print("Activity: \(currentContext.activity.rawValue)")
        print("Focus: \(currentContext.focus.mode.rawValue)")
        print("Calendar Busy: \(currentContext.calendar?.isBusy ?? false)")
        print("Battery: \(String(format: "%.0f", (currentContext.battery?.level ?? 0) * 100))%")
        print("Notification Score: \(String(format: "%.2f", currentContext.notificationScore))")
        print("========================\n")
    }

    func getMostActiveHours() -> [Int] {
        return history.getMostActiveHours()
    }

    func getAverageScore(inLast minutes: Int) -> Double {
        return history.averageScore(inLast: minutes)
    }
}

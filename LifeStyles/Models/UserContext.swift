//
//  UserContext.swift
//  LifeStyles
//
//  User context models for contextual awareness
//  Kullanıcının mevcut durumunu ve context'ini takip eder
//

import Foundation
import CoreLocation
import EventKit

// MARK: - User Context

struct UserContext: Codable {
    let timestamp: Date
    let location: LocationContext?
    let calendar: CalendarContext?
    let activity: ActivityContext
    let focus: FocusContext
    let timeOfDay: TimeOfDayContext
    let battery: BatteryContext?

    init(
        location: LocationContext? = nil,
        calendar: CalendarContext? = nil,
        activity: ActivityContext = .unknown,
        focus: FocusContext = .none,
        timeOfDay: TimeOfDayContext? = nil,
        battery: BatteryContext? = nil
    ) {
        self.timestamp = Date()
        self.location = location
        self.calendar = calendar
        self.activity = activity
        self.focus = focus
        self.timeOfDay = timeOfDay ?? TimeOfDayContext.current
        self.battery = battery
    }

    /// Context score (0.0 - 1.0) - Bildirim göndermek için ne kadar uygun?
    var notificationScore: Double {
        var score = 1.0

        // Focus mode penalty
        switch focus.mode {
        case .doNotDisturb:
            score *= 0.0 // Asla gönderme
        case .work, .sleep, .personal, .driving:
            score *= 0.2 // Çok düşük
        case .custom:
            score *= 0.5 // Orta
        case .none:
            score *= 1.0 // Tam
        }

        // Calendar penalty (toplantıdaysa)
        if calendar?.isBusy == true {
            score *= 0.3
        }

        // Activity penalty
        switch activity {
        case .driving:
            score *= 0.0 // Asla
        case .walking, .running, .cycling:
            score *= 0.5 // Düşük
        case .stationary:
            score *= 1.0 // Tam
        case .unknown:
            score *= 0.8 // Biraz düşük
        }

        // Time of day bonus/penalty
        score *= timeOfDay.notificationAppropriatenessScore

        // Battery penalty (çok düşükse)
        if let battery = battery, battery.level < 0.1 {
            score *= 0.7
        }

        return min(1.0, max(0.0, score))
    }

    /// Kritik bildirimler gönderilebilir mi?
    var canSendCriticalNotifications: Bool {
        // Driving hariç her zaman gönder
        return activity != .driving
    }

    /// Normal bildirimler gönderilebilir mi?
    var canSendRegularNotifications: Bool {
        return notificationScore > 0.3
    }

    /// Düşük öncelikli bildirimler gönderilebilir mi?
    var canSendLowPriorityNotifications: Bool {
        return notificationScore > 0.6
    }
}

// MARK: - Location Context

struct LocationContext: Codable {
    let type: LocationType
    let coordinate: CoordinateData?
    let placeName: String?
    let isMoving: Bool

    enum LocationType: String, Codable {
        case home           // Ev
        case work           // İş
        case gym            // Spor salonu
        case restaurant     // Restoran/Kafe
        case outdoor        // Dışarıda (açık alan)
        case transit        // Yolda/Ulaşımda
        case unknown        // Bilinmiyor

        var notificationFriendliness: Double {
            switch self {
            case .home: return 1.0          // En uygun
            case .work: return 0.6          // Orta
            case .gym: return 0.4           // Düşük
            case .restaurant: return 0.5    // Orta
            case .outdoor: return 0.7       // İyi
            case .transit: return 0.3       // Düşük
            case .unknown: return 0.5       // Orta
            }
        }
    }

    struct CoordinateData: Codable {
        let latitude: Double
        let longitude: Double
    }
}

// MARK: - Calendar Context

struct CalendarContext: Codable {
    let isBusy: Bool                        // Şu an meşgul mü?
    let currentEvent: CalendarEventData?    // Mevcut etkinlik
    let nextEvent: CalendarEventData?       // Sonraki etkinlik
    let minutesUntilNextEvent: Int?         // Sonraki etkinliğe kaç dakika var?

    struct CalendarEventData: Codable {
        let title: String
        let startDate: Date
        let endDate: Date
        let isAllDay: Bool

        var duration: TimeInterval {
            return endDate.timeIntervalSince(startDate)
        }

        var isHappeningNow: Bool {
            let now = Date()
            return now >= startDate && now <= endDate
        }
    }

    /// Etkinlik bitişine kadar dakika
    var minutesUntilFree: Int? {
        guard let current = currentEvent else { return nil }
        let remaining = current.endDate.timeIntervalSinceNow
        return max(0, Int(remaining / 60))
    }

    /// Yakın zamanda toplantı var mı? (15 dakika içinde)
    var hasUpcomingEvent: Bool {
        if let minutes = minutesUntilNextEvent {
            return minutes <= 15
        }
        return false
    }
}

// MARK: - Activity Context

enum ActivityContext: String, Codable {
    case stationary     // Hareketsiz (oturuyor, duruyor)
    case walking        // Yürüyor
    case running        // Koşuyor
    case cycling        // Bisiklet
    case driving        // Araba kullanıyor
    case unknown        // Bilinmiyor

    var notificationFriendliness: Double {
        switch self {
        case .stationary: return 1.0    // En uygun
        case .walking: return 0.6       // Orta
        case .running: return 0.3       // Düşük
        case .cycling: return 0.3       // Düşük
        case .driving: return 0.0       // Asla
        case .unknown: return 0.7       // Varsayılan iyi
        }
    }
}

// MARK: - Focus Context

struct FocusContext: Codable {
    let mode: FocusMode
    let allowsTimeSensitive: Bool
    let allowsCritical: Bool

    enum FocusMode: String, Codable {
        case none               // Focus modu yok
        case doNotDisturb       // Rahatsız etmeyin
        case sleep              // Uyku
        case work               // Çalışma
        case personal           // Kişisel
        case driving            // Araba kullanıyorum
        case custom             // Özel

        var defaultTimeSensitiveAllowed: Bool {
            switch self {
            case .none: return true
            case .doNotDisturb: return false
            case .sleep: return false
            case .work: return true
            case .personal: return true
            case .driving: return false
            case .custom: return true
            }
        }

        var defaultCriticalAllowed: Bool {
            switch self {
            case .none: return true
            case .doNotDisturb: return true     // Kritik her zaman
            case .sleep: return true            // Kritik her zaman
            case .work: return true
            case .personal: return true
            case .driving: return true          // Kritik her zaman
            case .custom: return true
            }
        }
    }

    static var none: FocusContext {
        return FocusContext(
            mode: .none,
            allowsTimeSensitive: true,
            allowsCritical: true
        )
    }

    /// Bildirim gönderilmeli mi?
    func shouldAllowNotification(priority: PriorityLevel) -> Bool {
        switch priority {
        case .critical:
            return allowsCritical
        case .high:
            return allowsTimeSensitive || mode == .none
        case .normal:
            return mode == .none || mode == .work || mode == .personal
        case .low, .minimal:
            return mode == .none
        }
    }
}

// MARK: - Time of Day Context

struct TimeOfDayContext: Codable {
    let hour: Int           // 0-23
    let dayOfWeek: Int      // 1-7 (1 = Pazar)
    let isWeekend: Bool
    let period: DayPeriod

    enum DayPeriod: String, Codable {
        case earlyMorning   // 05:00 - 08:00
        case morning        // 08:00 - 12:00
        case afternoon      // 12:00 - 17:00
        case evening        // 17:00 - 21:00
        case night          // 21:00 - 24:00
        case lateNight      // 00:00 - 05:00

        var notificationFriendliness: Double {
            switch self {
            case .earlyMorning: return 0.3  // Çok erken
            case .morning: return 1.0       // En iyi
            case .afternoon: return 0.9     // İyi
            case .evening: return 0.8       // İyi
            case .night: return 0.4         // Geç
            case .lateNight: return 0.1     // Çok geç
            }
        }

        static func from(hour: Int) -> DayPeriod {
            switch hour {
            case 5..<8: return .earlyMorning
            case 8..<12: return .morning
            case 12..<17: return .afternoon
            case 17..<21: return .evening
            case 21..<24: return .night
            default: return .lateNight
            }
        }
    }

    static var current: TimeOfDayContext {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let weekday = calendar.component(.weekday, from: now)
        let isWeekend = weekday == 1 || weekday == 7

        return TimeOfDayContext(
            hour: hour,
            dayOfWeek: weekday,
            isWeekend: isWeekend,
            period: DayPeriod.from(hour: hour)
        )
    }

    /// Bildirim uygunluk skoru
    var notificationAppropriatenessScore: Double {
        var score = period.notificationFriendliness

        // Hafta sonu bonusu (daha rahatlar)
        if isWeekend {
            score *= 1.1
        }

        return min(1.0, score)
    }

    /// Sessiz saat mi? (22:00 - 08:00)
    var isQuietHours: Bool {
        return hour < 8 || hour >= 22
    }
}

// MARK: - Battery Context

struct BatteryContext: Codable {
    let level: Double       // 0.0 - 1.0
    let isCharging: Bool
    let isLowPowerMode: Bool

    /// Bildirim gönderilmeli mi? (pil düşükse spam yapma)
    var shouldThrottleNotifications: Bool {
        return level < 0.2 && !isCharging
    }

    /// Agresif throttling gerekli mi?
    var shouldAggressivelyThrottle: Bool {
        return (level < 0.1 || isLowPowerMode) && !isCharging
    }
}

// MARK: - Context History

struct ContextHistory: Codable {
    var entries: [UserContext]
    let maxEntries: Int

    init(maxEntries: Int = 100) {
        self.entries = []
        self.maxEntries = maxEntries
    }

    mutating func add(_ context: UserContext) {
        entries.insert(context, at: 0)
        if entries.count > maxEntries {
            entries = Array(entries.prefix(maxEntries))
        }
    }

    /// Son X dakikadaki ortalama context score
    func averageScore(inLast minutes: Int) -> Double {
        let cutoff = Date().addingTimeInterval(-Double(minutes * 60))
        let recentContexts = entries.filter { $0.timestamp > cutoff }

        guard !recentContexts.isEmpty else { return 0.5 }

        let totalScore = recentContexts.reduce(0.0) { $0 + $1.notificationScore }
        return totalScore / Double(recentContexts.count)
    }

    /// Kullanıcı genelde hangi saatlerde aktif?
    func getMostActiveHours() -> [Int] {
        let hourCounts = Dictionary(grouping: entries) { context in
            context.timeOfDay.hour
        }.mapValues { $0.count }

        return hourCounts.sorted { $0.value > $1.value }
            .prefix(4)
            .map { $0.key }
            .sorted()
    }

    /// En çok bulunulan konumlar
    func getMostFrequentLocations() -> [LocationContext.LocationType] {
        let locations = entries.compactMap { $0.location?.type }
        let locationCounts = Dictionary(grouping: locations) { $0 }
            .mapValues { $0.count }

        return locationCounts.sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
    }
}

// MARK: - Context Rules

struct ContextRule: Codable {
    let id: UUID
    let name: String
    let condition: ConditionType
    let action: ActionType
    let isEnabled: Bool

    enum ConditionType: Codable {
        case location(LocationContext.LocationType)
        case timeOfDay(TimeOfDayContext.DayPeriod)
        case activity(ActivityContext)
        case focus(FocusContext.FocusMode)
        case batteryLow
        case calendarBusy

        func matches(_ context: UserContext) -> Bool {
            switch self {
            case .location(let type):
                return context.location?.type == type
            case .timeOfDay(let period):
                return context.timeOfDay.period == period
            case .activity(let activityType):
                return context.activity == activityType
            case .focus(let mode):
                return context.focus.mode == mode
            case .batteryLow:
                return context.battery?.level ?? 1.0 < 0.2
            case .calendarBusy:
                return context.calendar?.isBusy == true
            }
        }
    }

    enum ActionType: Codable {
        case blockAll
        case blockLowPriority
        case allowOnlyCritical
        case deferAction(minutes: Int)
        case throttle(factor: Double)
    }

    init(
        name: String,
        condition: ConditionType,
        action: ActionType,
        isEnabled: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.condition = condition
        self.action = action
        self.isEnabled = isEnabled
    }

    func evaluate(_ context: UserContext) -> ActionType? {
        guard isEnabled && condition.matches(context) else {
            return nil
        }
        return action
    }
}

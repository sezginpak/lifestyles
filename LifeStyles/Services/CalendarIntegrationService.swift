//
//  CalendarIntegrationService.swift
//  LifeStyles
//
//  Calendar integration for contextual awareness
//  Takvim entegrasyonu ile context-aware bildirim yönetimi
//

import Foundation
import EventKit

@Observable
class CalendarIntegrationService {
    static let shared = CalendarIntegrationService()

    private let eventStore = EKEventStore()
    private var hasAccess = false

    private init() {}

    // MARK: - Permission

    /// Takvim izni iste
    func requestAccess() async -> Bool {
        do {
            #if swift(>=5.9)
            if #available(iOS 17.0, *) {
                hasAccess = try await eventStore.requestFullAccessToEvents()
            } else {
                hasAccess = try await eventStore.requestAccess(to: .event)
            }
            #else
            hasAccess = try await eventStore.requestAccess(to: .event)
            #endif

            print(hasAccess ? "✅ Takvim izni alındı" : "❌ Takvim izni reddedildi")
            return hasAccess
        } catch {
            print("❌ Takvim izin hatası: \(error)")
            return false
        }
    }

    /// İzin durumunu kontrol et
    func checkAccess() -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        hasAccess = status == .fullAccess || status == .authorized
        return hasAccess
    }

    // MARK: - Calendar Context

    /// Mevcut takvim context'ini al
    func getCurrentCalendarContext() -> CalendarContext? {
        guard hasAccess else {
            print("⚠️ Takvim izni yok")
            return nil
        }

        let now = Date()
        let calendar = Calendar.current

        // Şu anki etkinlik
        let currentEvent = getCurrentEvent()

        // Sonraki etkinlik (2 saat içinde)
        let twoHoursLater = calendar.date(byAdding: .hour, value: 2, to: now)!
        let nextEvent = getNextEvent(until: twoHoursLater)

        // Meşgul durumu
        let isBusy = currentEvent != nil

        // Sonraki etkinliğe kadar dakika
        var minutesUntilNext: Int?
        if let next = nextEvent {
            let minutes = calendar.dateComponents([.minute], from: now, to: next.startDate).minute
            minutesUntilNext = minutes
        }

        return CalendarContext(
            isBusy: isBusy,
            currentEvent: currentEvent,
            nextEvent: nextEvent,
            minutesUntilNextEvent: minutesUntilNext
        )
    }

    /// Şu anki etkinliği al
    func getCurrentEvent() -> CalendarContext.CalendarEventData? {
        guard hasAccess else { return nil }

        let now = Date()
        let predicate = eventStore.predicateForEvents(
            withStart: now.addingTimeInterval(-3600), // 1 saat önce
            end: now.addingTimeInterval(3600),         // 1 saat sonra
            calendars: nil
        )

        let events = eventStore.events(matching: predicate)

        // Şu an devam eden etkinliği bul
        let currentEvent = events.first { event in
            event.startDate <= now && event.endDate > now
        }

        guard let event = currentEvent else { return nil }

        return CalendarContext.CalendarEventData(
            title: event.title ?? "Unnamed Event",
            startDate: event.startDate,
            endDate: event.endDate,
            isAllDay: event.isAllDay
        )
    }

    /// Sonraki etkinliği al
    func getNextEvent(until: Date) -> CalendarContext.CalendarEventData? {
        guard hasAccess else { return nil }

        let now = Date()
        let predicate = eventStore.predicateForEvents(
            withStart: now,
            end: until,
            calendars: nil
        )

        let events = eventStore.events(matching: predicate)
            .filter { $0.startDate > now } // Gelecekteki etkinlikler
            .sorted { $0.startDate < $1.startDate }

        guard let event = events.first else { return nil }

        return CalendarContext.CalendarEventData(
            title: event.title ?? "Unnamed Event",
            startDate: event.startDate,
            endDate: event.endDate,
            isAllDay: event.isAllDay
        )
    }

    /// Belirtilen zamanda meşgul mü?
    func isBusy(at date: Date) -> Bool {
        guard hasAccess else { return false }

        let predicate = eventStore.predicateForEvents(
            withStart: date.addingTimeInterval(-60), // 1 dakika önce
            end: date.addingTimeInterval(60),         // 1 dakika sonra
            calendars: nil
        )

        let events = eventStore.events(matching: predicate)

        return events.contains { event in
            event.startDate <= date && event.endDate > date
        }
    }

    /// Sonraki boş zaman dilimini bul
    func findNextFreeSlot(duration minutes: Int = 15) -> Date? {
        guard hasAccess else { return nil }

        let now = Date()
        let endOfDay = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: now)!

        var currentTime = now

        while currentTime < endOfDay {
            let slotEnd = currentTime.addingTimeInterval(TimeInterval(minutes * 60))

            // Bu slot boş mu?
            let predicate = eventStore.predicateForEvents(
                withStart: currentTime,
                end: slotEnd,
                calendars: nil
            )

            let events = eventStore.events(matching: predicate)

            if events.isEmpty {
                return currentTime
            }

            // 15 dakika ileri git
            currentTime = currentTime.addingTimeInterval(900)
        }

        return nil
    }

    // MARK: - Analytics

    /// Bugünkü etkinlik sayısı
    func getTodaysEventCount() -> Int {
        guard hasAccess else { return 0 }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = eventStore.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: nil
        )

        return eventStore.events(matching: predicate).count
    }

    /// Bugün meşgul saatler
    func getBusyHoursToday() -> [Int] {
        guard hasAccess else { return [] }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = eventStore.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: nil
        )

        let events = eventStore.events(matching: predicate)

        var busyHours = Set<Int>()
        for event in events {
            let startHour = calendar.component(.hour, from: event.startDate)
            let endHour = calendar.component(.hour, from: event.endDate)

            for hour in startHour...endHour {
                busyHours.insert(hour)
            }
        }

        return Array(busyHours).sorted()
    }

    func printCalendarInfo() {
        print("\n📅 === Calendar Info ===")
        print("Has Access: \(hasAccess)")

        if hasAccess {
            if let current = getCurrentEvent() {
                print("Current Event: \(current.title)")
                print("  Ends at: \(current.endDate)")
            } else {
                print("No current event")
            }

            if let next = getNextEvent(until: Date().addingTimeInterval(7200)) {
                print("Next Event: \(next.title)")
                print("  Starts at: \(next.startDate)")
            } else {
                print("No upcoming events")
            }

            print("Today's Events: \(getTodaysEventCount())")
            print("Busy Hours: \(getBusyHoursToday())")
        }

        print("========================\n")
    }
}

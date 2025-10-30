//
//  PlaceVisitTracker.swift
//  LifeStyles
//
//  Created by Claude on 25.10.2025.
//  Yer ziyaretleri için istatistik ve analiz servisi
//

import Foundation
import SwiftData

struct PlaceVisitTracker {
    static let shared = PlaceVisitTracker()

    private init() {}

    // MARK: - Visit Queries

    /// Get today's visits
    func getTodayVisits(context: ModelContext) -> [PlaceVisit] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let descriptor = FetchDescriptor<PlaceVisit>(
            predicate: #Predicate { visit in
                visit.arrivalTime >= today
            },
            sortBy: [SortDescriptor(\.arrivalTime, order: .reverse)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    /// Get visits for a specific date
    func getVisits(for date: Date, context: ModelContext) -> [PlaceVisit] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()

        let descriptor = FetchDescriptor<PlaceVisit>(
            predicate: #Predicate { visit in
                visit.arrivalTime >= startOfDay && visit.arrivalTime < endOfDay
            },
            sortBy: [SortDescriptor(\.arrivalTime)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    /// Get visits for the last N days
    func getRecentVisits(days: Int, context: ModelContext) -> [PlaceVisit] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        let descriptor = FetchDescriptor<PlaceVisit>(
            predicate: #Predicate { visit in
                visit.arrivalTime >= startDate
            },
            sortBy: [SortDescriptor(\.arrivalTime, order: .reverse)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    /// Get visits for a specific place
    func getVisits(for place: SavedPlace, context: ModelContext) -> [PlaceVisit] {
        let placeId = place.id

        let descriptor = FetchDescriptor<PlaceVisit>(
            predicate: #Predicate { visit in
                visit.place?.id == placeId
            },
            sortBy: [SortDescriptor(\.arrivalTime, order: .reverse)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Statistics

    /// Get most visited places (top 5)
    func getMostVisitedPlaces(context: ModelContext, limit: Int = 5) -> [SavedPlace] {
        let descriptor = FetchDescriptor<SavedPlace>(
            sortBy: [SortDescriptor(\.visitCount, order: .reverse)]
        )

        guard let allPlaces = try? context.fetch(descriptor) else {
            return []
        }

        return Array(allPlaces.prefix(limit))
    }

    /// Get places by total time spent (top 5)
    func getPlacesByTimeSpent(context: ModelContext, limit: Int = 5) -> [SavedPlace] {
        let descriptor = FetchDescriptor<SavedPlace>(
            sortBy: [SortDescriptor(\.totalTimeSpent, order: .reverse)]
        )

        guard let allPlaces = try? context.fetch(descriptor) else {
            return []
        }

        return Array(allPlaces.prefix(limit))
    }

    /// Get time distribution for today
    func getTodayTimeDistribution(context: ModelContext) -> [(place: SavedPlace, percentage: Double)] {
        let visits = getTodayVisits(context: context)

        // Group by place and sum durations
        var timeByPlace: [UUID: TimeInterval] = [:]

        for visit in visits where !visit.isOngoing {
            if let placeId = visit.place?.id {
                timeByPlace[placeId, default: 0] += visit.duration
            }
        }

        let totalTime = timeByPlace.values.reduce(0, +)
        guard totalTime > 0 else { return [] }

        // Calculate percentages
        var distribution: [(place: SavedPlace, percentage: Double)] = []

        for (placeId, time) in timeByPlace {
            if let place = getPlace(by: placeId, context: context) {
                let percentage = (time / totalTime) * 100
                distribution.append((place: place, percentage: percentage))
            }
        }

        return distribution.sorted { $0.percentage > $1.percentage }
    }

    /// Get weekly summary
    func getWeeklySummary(context: ModelContext) -> WeeklySummary {
        let visits = getRecentVisits(days: 7, context: context)

        let totalVisits = visits.count
        let totalTime = visits.reduce(0) { $0 + $1.duration }

        // Count unique places
        let uniquePlaces = Set(visits.compactMap { $0.place?.id }).count

        // Most visited place this week
        var visitCountByPlace: [UUID: Int] = [:]
        for visit in visits {
            if let placeId = visit.place?.id {
                visitCountByPlace[placeId, default: 0] += 1
            }
        }

        let mostVisitedPlaceId = visitCountByPlace.max(by: { $0.value < $1.value })?.key
        let mostVisitedPlace = mostVisitedPlaceId.flatMap { getPlace(by: $0, context: context) }

        return WeeklySummary(
            totalVisits: totalVisits,
            totalTime: totalTime,
            uniquePlaces: uniquePlaces,
            mostVisitedPlace: mostVisitedPlace,
            averageVisitsPerDay: Double(totalVisits) / 7.0
        )
    }

    /// Get daily average time at a place
    func getAverageDailyTime(for place: SavedPlace, days: Int, context: ModelContext) -> TimeInterval {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        let placeId = place.id

        let descriptor = FetchDescriptor<PlaceVisit>(
            predicate: #Predicate { visit in
                visit.place?.id == placeId && visit.arrivalTime >= startDate
            }
        )

        guard let visits = try? context.fetch(descriptor) else {
            return 0
        }

        let totalTime = visits.reduce(0) { $0 + $1.duration }
        return totalTime / Double(days)
    }

    // MARK: - Helper

    private func getPlace(by id: UUID, context: ModelContext) -> SavedPlace? {
        let descriptor = FetchDescriptor<SavedPlace>(
            predicate: #Predicate { $0.id == id }
        )
        return try? context.fetch(descriptor).first
    }
}

// MARK: - Summary Models

struct WeeklySummary {
    let totalVisits: Int
    let totalTime: TimeInterval
    let uniquePlaces: Int
    let mostVisitedPlace: SavedPlace?
    let averageVisitsPerDay: Double

    var formattedTotalTime: String {
        let hours = Int(totalTime) / 3600
        let minutes = (Int(totalTime) % 3600) / 60

        if hours > 0 {
            return "\(hours) saat \(minutes) dakika"
        } else {
            return "\(minutes) dakika"
        }
    }
}

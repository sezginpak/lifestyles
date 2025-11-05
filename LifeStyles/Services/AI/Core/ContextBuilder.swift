//
//  ContextBuilder.swift
//  LifeStyles
//
//  Modular Context Building System
//  Created by Claude on 22.10.2025.
//

import Foundation
import SwiftData

// MARK: - Base Protocol

/// Protocol for all context builders
protocol ContextProvider {
    associatedtype ContextType: Codable
    func buildContext(modelContext: ModelContext) async -> ContextType
}

// MARK: - Context Data Models

/// Friend snapshot for AI context
struct FriendSnapshot: Codable {
    let name: String
    let relationshipType: String
    let daysSinceLastContact: Int
    let isOverdue: Bool
    let communicationFrequency: String
    let notes: String?
    let sharedInterests: String?
    let isImportant: Bool
}

/// Mood snapshot for AI context
struct MoodSnapshot: Codable {
    let type: String
    let intensity: Int
    let date: Date
    let note: String?
}

/// Mood trend analysis
struct MoodTrend: Codable {
    let averageIntensity: Double
    let dominantMood: String
    let moodVariance: String  // "stable", "volatile", "improving", "declining"
    let bestDay: Date?
    let worstDay: Date?
}

/// Goal snapshot for AI context
struct GoalSnapshot: Codable {
    let title: String
    let category: String
    let progress: Double  // 0.0-1.0
    let daysRemaining: Int
    let isOverdue: Bool
}

/// Habit snapshot for AI context
struct HabitSnapshot: Codable {
    let name: String
    let frequency: String
    let currentStreak: Int
    let weeklyCompletionRate: Double  // 0.0-1.0
    let lastCompletedDate: Date?
}

/// Saved place snapshot for AI context
struct SavedPlaceSnapshot: Codable {
    let name: String
    let emoji: String
    let category: String
    let address: String?
    let visitCount: Int
    let lastVisitedAt: Date?
    let notes: String?
}

/// Location pattern
struct LocationPattern: Codable {
    let hoursAtHomeToday: Double
    let hoursAtHomeThisWeek: Double
    let lastOutdoorActivity: Date?
    let mostVisitedPlaces: [String]
    let savedPlaces: [SavedPlaceSnapshot] // Kayıtlı yerler (iş, ev, vs.)
}

/// Journal snapshot for AI context
struct JournalSnapshot: Codable {
    let date: Date
    let title: String?
    let content: String
    let type: String
    let tags: [String]
    let wordCount: Int
    let isFavorite: Bool
}

// MARK: - Friend Context Builder

class FriendContextBuilder {
    static func buildAll(modelContext: ModelContext) async -> [FriendSnapshot] {
        let descriptor = FetchDescriptor<Friend>()

        guard let friends = try? modelContext.fetch(descriptor) else {
            return []
        }

        return friends.map { friend in
            FriendSnapshot(
                name: friend.name,
                relationshipType: friend.relationshipType.rawValue,
                daysSinceLastContact: daysSince(friend.lastContactDate),
                isOverdue: friend.needsContact,
                communicationFrequency: friend.frequency.rawValue,
                notes: friend.notes,
                sharedInterests: friend.sharedInterests,
                isImportant: friend.isImportant
            )
        }
    }

    static func buildOverdue(modelContext: ModelContext) async -> [FriendSnapshot] {
        let all = await buildAll(modelContext: modelContext)
        return all.filter { $0.isOverdue }
    }

    private static func daysSince(_ date: Date?) -> Int {
        guard let date = date else { return 999 }
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 999
        return max(0, days)
    }
}

// MARK: - Mood Context Builder

class MoodContextBuilder {
    static func buildCurrent(modelContext: ModelContext) async -> MoodSnapshot? {
        // Bugünkü mood'u al
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        let descriptor = FetchDescriptor<MoodEntry>(
            predicate: #Predicate { entry in
                entry.date >= startOfDay
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        guard let entries = try? modelContext.fetch(descriptor),
              let latest = entries.first else {
            return nil
        }

        return MoodSnapshot(
            type: latest.moodType.rawValue,
            intensity: latest.intensity,
            date: latest.date,
            note: latest.note
        )
    }

    static func buildTrend(modelContext: ModelContext, days: Int = 7) async -> MoodTrend? {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) else {
            return nil
        }

        let descriptor = FetchDescriptor<MoodEntry>(
            predicate: #Predicate { entry in
                entry.date >= startDate
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        guard let entries = try? modelContext.fetch(descriptor),
              !entries.isEmpty else {
            return nil
        }

        // Calculate average intensity
        let avgIntensity = Double(entries.map { $0.intensity }.reduce(0, +)) / Double(entries.count)

        // Find dominant mood
        let moodCounts = Dictionary(grouping: entries, by: { $0.moodType.rawValue })
            .mapValues { $0.count }
        let dominantMood = moodCounts.max(by: { $0.value < $1.value })?.key ?? "unknown"

        // Find best/worst days
        let bestEntry = entries.max(by: { $0.intensity < $1.intensity })
        let worstEntry = entries.min(by: { $0.intensity < $1.intensity })

        // Calculate variance
        let variance: String
        if avgIntensity >= 4 {
            variance = "positive"
        } else if avgIntensity >= 3 {
            variance = "stable"
        } else {
            variance = "needs_attention"
        }

        return MoodTrend(
            averageIntensity: avgIntensity,
            dominantMood: dominantMood,
            moodVariance: variance,
            bestDay: bestEntry?.date,
            worstDay: worstEntry?.date
        )
    }
}

// MARK: - Goal Context Builder

class GoalContextBuilder {
    static func buildActive(modelContext: ModelContext) async -> [GoalSnapshot] {
        let descriptor = FetchDescriptor<Goal>(
            predicate: #Predicate { goal in
                !goal.isCompleted
            }
        )

        guard let goals = try? modelContext.fetch(descriptor) else {
            return []
        }

        return goals.map { goal in
            GoalSnapshot(
                title: goal.title,
                category: goal.category.rawValue,
                progress: goal.progress,
                daysRemaining: goal.daysRemaining,
                isOverdue: goal.isOverdue
            )
        }
    }
}

// MARK: - Habit Context Builder

class HabitContextBuilder {
    static func buildAll(modelContext: ModelContext) async -> [HabitSnapshot] {
        let descriptor = FetchDescriptor<Habit>()

        guard let habits = try? modelContext.fetch(descriptor) else {
            return []
        }

        return habits.map { habit in
            // Compute last completed date from completions
            let lastCompleted = habit.completions?
                .map { $0.completedAt }
                .max()

            return HabitSnapshot(
                name: habit.name,
                frequency: habit.frequency.rawValue,
                currentStreak: habit.currentStreak,
                weeklyCompletionRate: habit.weeklyCompletionRate,
                lastCompletedDate: lastCompleted
            )
        }
    }
}

// MARK: - User Profile Context Builder

class ProfileContextBuilder {
    static func build(modelContext: ModelContext) async -> UserProfileSnapshot? {
        let descriptor = FetchDescriptor<UserProfile>()

        guard let profiles = try? modelContext.fetch(descriptor),
              let profile = profiles.first else {
            return nil
        }

        return UserProfileSnapshot(from: profile)
    }
}

// MARK: - Location Context Builder

class LocationContextBuilder {
    static func buildPattern(modelContext: ModelContext) async -> LocationPattern {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return LocationPattern(
                hoursAtHomeToday: 0,
                hoursAtHomeThisWeek: 0,
                lastOutdoorActivity: nil,
                mostVisitedPlaces: [],
                savedPlaces: []
            )
        }

        // Today's logs
        let todayDescriptor = FetchDescriptor<LocationLog>(
            predicate: #Predicate { log in
                log.timestamp >= startOfDay
            }
        )

        // This week's logs
        let weekDescriptor = FetchDescriptor<LocationLog>(
            predicate: #Predicate { log in
                log.timestamp >= startOfWeek
            }
        )

        let todayLogs = (try? modelContext.fetch(todayDescriptor)) ?? []
        let weekLogs = (try? modelContext.fetch(weekDescriptor)) ?? []

        // Calculate hours at home
        let hoursToday = calculateHomeHours(logs: todayLogs)
        let hoursWeek = calculateHomeHours(logs: weekLogs)

        // Find last outdoor activity
        let outdoorLogs = weekLogs.filter { $0.locationType != .home }
        let lastOutdoor = outdoorLogs.last?.timestamp

        // Most visited places (from addresses)
        let places = weekLogs.compactMap { $0.address }.filter { !$0.isEmpty }
        let uniquePlaces = Array(Set(places)).prefix(3)

        // Fetch saved places
        let savedPlacesDescriptor = FetchDescriptor<SavedPlace>(
            sortBy: [SortDescriptor(\.visitCount, order: .reverse)]
        )
        let allSavedPlaces = (try? modelContext.fetch(savedPlacesDescriptor)) ?? []

        // Convert to snapshots (top 5 most visited)
        let savedPlaceSnapshots = allSavedPlaces.prefix(5).map { place in
            SavedPlaceSnapshot(
                name: place.name,
                emoji: place.emoji,
                category: place.category.displayName,
                address: place.address,
                visitCount: place.visitCount,
                lastVisitedAt: place.lastVisitedAt,
                notes: place.notes
            )
        }

        return LocationPattern(
            hoursAtHomeToday: hoursToday,
            hoursAtHomeThisWeek: hoursWeek,
            lastOutdoorActivity: lastOutdoor,
            mostVisitedPlaces: Array(uniquePlaces),
            savedPlaces: savedPlaceSnapshots
        )
    }

    private static func calculateHomeHours(logs: [LocationLog]) -> Double {
        let homeLogs = logs.filter { $0.locationType == .home }
        // Assuming 15 min intervals
        return Double(homeLogs.count) * 0.25
    }
}

// MARK: - Journal Context Builder

class JournalContextBuilder {
    static func buildRecent(modelContext: ModelContext, days: Int = 7) async -> [JournalSnapshot] {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) else {
            return []
        }

        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { entry in
                entry.date >= startDate
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        guard let entries = try? modelContext.fetch(descriptor) else {
            return []
        }

        return entries.map { entry in
            JournalSnapshot(
                date: entry.date,
                title: entry.title,
                content: entry.content,
                type: entry.journalType.rawValue,
                tags: entry.tags,
                wordCount: entry.wordCount,
                isFavorite: entry.isFavorite
            )
        }
    }

    static func buildToday(modelContext: ModelContext) async -> JournalSnapshot? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { entry in
                entry.date >= startOfDay
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        guard let entries = try? modelContext.fetch(descriptor),
              let latest = entries.first else {
            return nil
        }

        return JournalSnapshot(
            date: latest.date,
            title: latest.title,
            content: latest.content,
            type: latest.journalType.rawValue,
            tags: latest.tags,
            wordCount: latest.wordCount,
            isFavorite: latest.isFavorite
        )
    }
}

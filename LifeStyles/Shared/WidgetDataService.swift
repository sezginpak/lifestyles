//
//  WidgetDataService.swift
//  LifeStyles
//
//  Service to convert SwiftData Friend models to FriendWidgetData
//  Used by widget timeline provider
//
//  Created by Claude on 04.11.2025.
//

import Foundation
import SwiftData

/// Service to fetch and convert Friend data for widgets
class WidgetDataService {
    // MARK: - Singleton
    static let shared = WidgetDataService()

    // App Group suite name for sharing data between app and widget
    private let appGroupSuiteName = "group.sezginpak.LifeStyles"
    private let widgetDataKey = "friendsWidgetData"
    private let widgetCountKey = "friendsWidgetCount"

    private init() {}

    // MARK: - Fetch Methods (Main App Only - Requires SwiftData)

    /// Fetch friends for widget display
    /// Filters: Important friends + upcoming contacts
    /// Sorted: Days overdue (descending)
    @MainActor
    func fetchFriendsForWidget(context: ModelContext, limit: Int = 10) throws -> [FriendWidgetData] {
        let descriptor = FetchDescriptor<Friend>(
            sortBy: [SortDescriptor(\.lastContactDate, order: .forward)]
        )

        let allFriends = try context.fetch(descriptor)

        // Filter: Important + needs contact or upcoming
        let filtered = allFriends.filter { friend in
            if friend.isImportant {
                return true
            }
            // Yakında süresi dolacaklar (3 gün içinde)
            return friend.daysRemaining <= 3 && friend.daysRemaining >= 0
        }

        // Sort by days overdue (gecikmiş olanlar önce)
        let sorted = filtered.sorted { lhs, rhs in
            if lhs.daysOverdue > 0 && rhs.daysOverdue > 0 {
                return lhs.daysOverdue > rhs.daysOverdue
            }
            if lhs.daysOverdue > 0 {
                return true
            }
            if rhs.daysOverdue > 0 {
                return false
            }
            return lhs.daysRemaining < rhs.daysRemaining
        }

        // Convert to FriendWidgetData
        return Array(sorted.prefix(limit)).map { convertToWidgetData($0) }
    }

    /// Fetch friend count needing contact
    @MainActor
    func fetchNeedsContactCount(context: ModelContext) throws -> Int {
        let descriptor = FetchDescriptor<Friend>()
        let allFriends = try context.fetch(descriptor)

        return allFriends.filter { $0.needsContact }.count
    }

    /// Fetch top priority friends (for lock screen)
    @MainActor
    func fetchTopPriorityFriends(context: ModelContext, limit: Int = 3) throws -> [FriendWidgetData] {
        let descriptor = FetchDescriptor<Friend>(
            sortBy: [SortDescriptor(\.lastContactDate, order: .forward)]
        )

        let allFriends = try context.fetch(descriptor)

        // Filter: Only overdue or today
        let filtered = allFriends.filter { friend in
            friend.daysOverdue > 0 || (friend.daysRemaining == 0 && friend.needsContact)
        }

        // Sort by importance and overdue days
        let sorted = filtered.sorted { lhs, rhs in
            if lhs.isImportant != rhs.isImportant {
                return lhs.isImportant
            }
            return lhs.daysOverdue > rhs.daysOverdue
        }

        return Array(sorted.prefix(limit)).map { convertToWidgetData($0) }
    }

    // MARK: - Conversion

    /// Convert Friend model to FriendWidgetData
    private func convertToWidgetData(_ friend: Friend) -> FriendWidgetData {
        FriendWidgetData(
            id: friend.id.uuidString,
            name: friend.name,
            emoji: friend.avatarEmoji ?? "👤",
            phoneNumber: friend.phoneNumber,
            isImportant: friend.isImportant,
            daysOverdue: friend.daysOverdue,
            daysRemaining: friend.daysRemaining,
            nextContactDate: friend.nextContactDate,
            lastContactDate: friend.lastContactDate,
            needsContact: friend.needsContact,
            relationshipType: friend.relationshipTypeRaw,
            frequency: friend.frequencyRaw,
            totalContactCount: friend.totalContactCount,
            hasDebt: friend.totalDebt > 0,
            hasCredit: friend.totalCredit > 0,
            balance: friend.hasOutstandingTransactions ? friend.formattedBalance : nil
        )
    }

    // MARK: - Widget Data Sharing (App Group UserDefaults)

    /// Save widget data to App Group UserDefaults (called from main app)
    func saveWidgetData(friends: [FriendWidgetData], totalCount: Int) {
        guard let userDefaults = UserDefaults(suiteName: appGroupSuiteName) else {
            print("❌ Failed to access App Group UserDefaults")
            return
        }

        do {
            let data = try JSONEncoder().encode(friends)
            userDefaults.set(data, forKey: widgetDataKey)
            userDefaults.set(totalCount, forKey: widgetCountKey)
            print("✅ Widget data saved: \(friends.count) friends, \(totalCount) total")
        } catch {
            print("❌ Failed to encode widget data: \(error)")
        }
    }

    /// Load widget data from App Group UserDefaults (called from widget)
    func loadWidgetData() -> (friends: [FriendWidgetData], totalCount: Int) {
        guard let userDefaults = UserDefaults(suiteName: appGroupSuiteName) else {
            print("❌ Failed to access App Group UserDefaults")
            return ([], 0)
        }

        guard let data = userDefaults.data(forKey: widgetDataKey) else {
            print("⚠️ No widget data found")
            return ([], 0)
        }

        do {
            let friends = try JSONDecoder().decode([FriendWidgetData].self, from: data)
            let totalCount = userDefaults.integer(forKey: widgetCountKey)
            print("✅ Widget data loaded: \(friends.count) friends, \(totalCount) total")
            return (friends, totalCount)
        } catch {
            print("❌ Failed to decode widget data: \(error)")
            return ([], 0)
        }
    }
}

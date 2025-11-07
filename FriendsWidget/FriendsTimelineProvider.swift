//
//  FriendsTimelineProvider.swift
//  FriendsWidget
//
//  Timeline provider for Friends Widget
//  Refreshes widget data every 15 minutes
//
//  Created by Claude on 04.11.2025.
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Timeline Entry

struct FriendsEntry: TimelineEntry {
    let date: Date
    let friends: [FriendWidgetData]
    let totalNeedsContact: Int
}

// MARK: - Timeline Provider

struct FriendsTimelineProvider: TimelineProvider {
    typealias Entry = FriendsEntry

    // MARK: - Placeholder

    func placeholder(in context: Context) -> FriendsEntry {
        FriendsEntry(
            date: Date(),
            friends: Self.placeholderFriends(),
            totalNeedsContact: 3
        )
    }

    // MARK: - Snapshot (Widget Gallery)

    func getSnapshot(in context: Context, completion: @escaping (FriendsEntry) -> Void) {
        if context.isPreview {
            // Widget gallery preview
            let entry = FriendsEntry(
                date: Date(),
                friends: Self.placeholderFriends(),
                totalNeedsContact: 3
            )
            completion(entry)
        } else {
            // Gerçek veri
            let entry = fetchFriendsEntry()
            completion(entry)
        }
    }

    // MARK: - Timeline

    func getTimeline(in context: Context, completion: @escaping (Timeline<FriendsEntry>) -> Void) {
        let entry = fetchFriendsEntry()

        // 15 dakika sonra yenile
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)

        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    // MARK: - Data Fetching

    private func fetchFriendsEntry() -> FriendsEntry {
        // Widget UserDefaults'tan veri okur (ana uygulama yazmıştır)
        let (friends, totalCount) = loadWidgetData()

        // En fazla 4 arkadaş göster (Medium widget için)
        let limitedFriends = Array(friends.prefix(4))

        return FriendsEntry(
            date: Date(),
            friends: limitedFriends,
            totalNeedsContact: totalCount
        )
    }

    // MARK: - Widget Data Loading

    /// Load widget data from App Group UserDefaults
    private func loadWidgetData() -> (friends: [FriendWidgetData], totalCount: Int) {
        let appGroupSuiteName = "group.sezginpak.LifeStyles"
        let widgetDataKey = "friendsWidgetData"
        let widgetCountKey = "friendsWidgetCount"

        print("🔍 WIDGET: Loading widget data...")
        print("🔍 WIDGET: App Group: \(appGroupSuiteName)")

        guard let userDefaults = UserDefaults(suiteName: appGroupSuiteName) else {
            print("❌ WIDGET: Failed to access App Group UserDefaults")
            print("❌ WIDGET: Bu App Group tanımlı değil!")
            return ([], 0)
        }

        print("✅ WIDGET: UserDefaults erişildi")

        guard let data = userDefaults.data(forKey: widgetDataKey) else {
            print("⚠️ WIDGET: No widget data found in UserDefaults")
            print("⚠️ WIDGET: Key: \(widgetDataKey)")

            // Tüm key'leri listele
            let allKeys = userDefaults.dictionaryRepresentation().keys
            print("📋 WIDGET: UserDefaults içindeki tüm key'ler: \(allKeys)")

            return ([], 0)
        }

        print("✅ WIDGET: Data bulundu, decode ediliyor...")

        do {
            let friends = try JSONDecoder().decode([FriendWidgetData].self, from: data)
            let totalCount = userDefaults.integer(forKey: widgetCountKey)
            print("✅ WIDGET: Widget data loaded: \(friends.count) friends, \(totalCount) total")

            // İlk birkaç arkadaşı logla
            for (index, friend) in friends.prefix(3).enumerated() {
                print("  \(index + 1). \(friend.name) - \(friend.statusText)")
            }

            return (friends, totalCount)
        } catch {
            print("❌ WIDGET: Failed to decode widget data: \(error)")
            return ([], 0)
        }
    }

    // MARK: - Placeholder Data

    private static func placeholderFriends() -> [FriendWidgetData] {
        return [
            FriendWidgetData(
                id: UUID().uuidString,
                name: "Ahmet Yılmaz",
                emoji: "👨‍💼",
                phoneNumber: "+90 555 123 4567",
                isImportant: true,
                daysOverdue: 3,
                daysRemaining: 0,
                nextContactDate: Date(),
                lastContactDate: Date().addingTimeInterval(-7 * 24 * 60 * 60),
                needsContact: true,
                relationshipType: "friend",
                frequency: "weekly",
                totalContactCount: 12,
                hasDebt: false,
                hasCredit: false,
                balance: nil
            ),
            FriendWidgetData(
                id: UUID().uuidString,
                name: "Ayşe Demir",
                emoji: "👩‍🎨",
                phoneNumber: "+90 555 987 6543",
                isImportant: false,
                daysOverdue: 0,
                daysRemaining: 1,
                nextContactDate: Date().addingTimeInterval(24 * 60 * 60),
                lastContactDate: Date().addingTimeInterval(-6 * 24 * 60 * 60),
                needsContact: false,
                relationshipType: "friend",
                frequency: "weekly",
                totalContactCount: 8,
                hasDebt: true,
                hasCredit: false,
                balance: "- ₺150"
            ),
            FriendWidgetData(
                id: UUID().uuidString,
                name: "Mehmet Kaya",
                emoji: "🧑‍💻",
                phoneNumber: "+90 555 456 7890",
                isImportant: true,
                daysOverdue: 0,
                daysRemaining: 2,
                nextContactDate: Date().addingTimeInterval(2 * 24 * 60 * 60),
                lastContactDate: Date().addingTimeInterval(-5 * 24 * 60 * 60),
                needsContact: false,
                relationshipType: "colleague",
                frequency: "weekly",
                totalContactCount: 15,
                hasDebt: false,
                hasCredit: true,
                balance: "+ ₺75"
            )
        ]
    }
}

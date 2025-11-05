//
//  LockScreenWidgets.swift
//  FriendsWidget
//
//  Lock Screen widgets (Circular, Rectangular, Inline)
//  Shows count of friends needing contact
//
//  Created by Claude on 04.11.2025.
//

import WidgetKit
import SwiftUI

// MARK: - Lock Screen Widget

struct FriendsLockScreenWidget: Widget {
    let kind: String = "FriendsLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FriendsTimelineProvider()) { entry in
            LockScreenWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Arkadaş Sayacı")
        .description("İletişim gereken arkadaş sayısını gösterir")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Lock Screen Widget View

struct LockScreenWidgetView: View {
    let entry: FriendsEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularWidgetView(count: entry.totalNeedsContact)
        case .accessoryRectangular:
            RectangularWidgetView(friends: entry.friends, count: entry.totalNeedsContact)
        case .accessoryInline:
            InlineWidgetView(count: entry.totalNeedsContact)
        default:
            EmptyView()
        }
    }
}

// MARK: - Circular Widget (Circular Lock Screen)

struct CircularWidgetView: View {
    let count: Int

    var body: some View {
        ZStack {
            // Progress ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: count > 0 ? [.red.opacity(0.3), .orange.opacity(0.3)] : [.green.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 4
                )

            VStack(spacing: 2) {
                Image(systemName: count > 0 ? "phone.badge.waveform.fill" : "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: count > 0 ? [.red, .orange] : [.green],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
            }
        }
        .widgetAccentable()
    }
}

// MARK: - Rectangular Widget (Rectangular Lock Screen)

struct RectangularWidgetView: View {
    let friends: [FriendWidgetData]
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 12, weight: .semibold))

                Text("Arkadaşlarım")
                    .font(.system(size: 12, weight: .bold, design: .rounded))

                Spacer()

                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.red)
                }
            }

            // Friends list (top 2)
            if friends.isEmpty {
                Text("Hepsi tamam ✓")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(friends.prefix(2)) { friend in
                        HStack(spacing: 6) {
                            Text(friend.emoji)
                                .font(.system(size: 12))

                            Text(friend.name)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .lineLimit(1)

                            Spacer()

                            Text(friend.statusText)
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundColor(colorForStatus(friend.statusCategory))
                        }
                    }
                }
            }
        }
        .widgetAccentable()
    }

    private func colorForStatus(_ status: FriendStatus) -> Color {
        switch status {
        case .overdue:
            return .red
        case .upcoming:
            return .orange
        case .onTime:
            return .green
        }
    }
}

// MARK: - Inline Widget (Inline Lock Screen)

struct InlineWidgetView: View {
    let count: Int

    var body: some View {
        if count > 0 {
            Label("\(count) arkadaş bekliyor 📞", systemImage: "person.2.fill")
                .widgetAccentable()
        } else {
            Label("Hepsi tamam ✓", systemImage: "checkmark.circle.fill")
                .widgetAccentable()
        }
    }
}

// MARK: - Preview

#Preview("Circular", as: .accessoryCircular) {
    FriendsLockScreenWidget()
} timeline: {
    FriendsEntry(date: Date(), friends: [], totalNeedsContact: 3)
    FriendsEntry(date: Date(), friends: [], totalNeedsContact: 0)
}

#Preview("Rectangular", as: .accessoryRectangular) {
    FriendsLockScreenWidget()
} timeline: {
    FriendsEntry(
        date: Date(),
        friends: [
            FriendWidgetData(
                id: UUID().uuidString,
                name: "Ahmet Yılmaz",
                emoji: "👨‍💼",
                phoneNumber: "+90 555 123 4567",
                isImportant: true,
                daysOverdue: 3,
                daysRemaining: 0,
                nextContactDate: Date(),
                lastContactDate: nil,
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
                phoneNumber: nil,
                isImportant: false,
                daysOverdue: 0,
                daysRemaining: 1,
                nextContactDate: Date().addingTimeInterval(24 * 60 * 60),
                lastContactDate: nil,
                needsContact: false,
                relationshipType: "friend",
                frequency: "weekly",
                totalContactCount: 8,
                hasDebt: true,
                hasCredit: false,
                balance: "- ₺150"
            )
        ],
        totalNeedsContact: 5
    )
}

#Preview("Inline", as: .accessoryInline) {
    FriendsLockScreenWidget()
} timeline: {
    FriendsEntry(date: Date(), friends: [], totalNeedsContact: 3)
}

//
//  MediumFriendsWidget.swift
//  FriendsWidget
//
//  iOS 26 Timeline View - Apple Calendar Style
//  Native, minimal, professional design
//
//  Created by Claude on 05.11.2025.
//

import WidgetKit
import SwiftUI

// MARK: - Medium Widget

struct MediumFriendsWidget: Widget {
    let kind: String = "FriendsMediumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FriendsTimelineProvider()) { entry in
            MediumFriendsWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Arkadaşlarım")
        .description("İletişim kurman gereken arkadaşlarını gösterir")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Medium Widget View

struct MediumFriendsWidgetView: View {
    let entry: FriendsEntry

    var body: some View {
        if entry.friends.isEmpty {
            EmptyStateView()
        } else {
            FriendsListView(friends: entry.friends, totalCount: entry.totalNeedsContact)
        }
    }
}

// MARK: - Timeline View (iOS 26 - Medium 4x2 Optimized)

struct FriendsListView: View {
    let friends: [FriendWidgetData]
    let totalCount: Int

    var body: some View {
        VStack(spacing: 0) {
            // Header - Compact for Medium Widget
            HStack {
                Text(String(localized: "widget.today", comment: ""))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Spacer()

                Text(String(localized: "text.totalcount"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 6)

            // Timeline Rows - Compact spacing
            VStack(spacing: 0) {
                ForEach(Array(friends.prefix(3).enumerated()), id: \.element.id) { index, friend in
                    TimelineRow(friend: friend)

                    if index < min(2, friends.count - 1) {
                        Divider()
                            .padding(.leading, 48)
                            .padding(.vertical, 2)
                    }
                }
            }

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Timeline Row (Medium 4x2 Optimized)

struct TimelineRow: View {
    let friend: FriendWidgetData

    var body: some View {
        if let url = URL(string: "lifestyles://friend-detail/\(friend.id)") {
            Link(destination: url) {
                rowContent
            }
            .buttonStyle(.plain)
        } else {
            rowContent
        }
    }

    private var rowContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Top: Dot + Emoji + Name + Star
            HStack(spacing: 10) {
                // Status Dot (7pt circle - smaller)
                Circle()
                    .fill(statusColor)
                    .frame(width: 7, height: 7)

                // Emoji (compact)
                Text(friend.emoji)
                    .font(.system(size: 26))

                // Name
                Text(friend.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                // Star (Important)
                if friend.isImportant {
                    Image(systemName: "star.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.yellow)
                }

                Spacer(minLength: 0)
            }

            // Bottom: Status Text (Indented)
            HStack(spacing: 0) {
                // Indent (dot + spacing + emoji + spacing = 47pt)
                Spacer()
                    .frame(width: 47)

                Text(friend.statusText)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .contentShape(Rectangle())
    }

    private var statusColor: Color {
        switch friend.statusCategory {
        case .overdue:
            return .red
        case .upcoming:
            return .orange
        case .onTime:
            return .green
        }
    }
}

// MARK: - Empty State (Medium 4x2 Optimized)

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(.green)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 3) {
                Text(String(localized: "widget.all.up.to.date", comment: ""))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

                Text(String(localized: "widget.all.friends.contacted", comment: ""))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(12)
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    MediumFriendsWidget()
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
                phoneNumber: nil,
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
        ],
        totalNeedsContact: 5
    )
}

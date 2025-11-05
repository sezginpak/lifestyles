//
//  MediumFriendsWidget.swift
//  FriendsWidget
//
//  Medium size widget showing 3-4 friends needing contact
//  Glassmorphism design with gradients
//
//  Created by Claude on 04.11.2025.
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

// MARK: - Friends List View

struct FriendsListView: View {
    let friends: [FriendWidgetData]
    let totalCount: Int

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HeaderView(totalCount: totalCount)

            // Friends List
            VStack(spacing: 8) {
                ForEach(friends.prefix(3)) { friend in
                    FriendCardView(friend: friend)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
    }
}

// MARK: - Header View

struct HeaderView: View {
    let totalCount: Int

    var body: some View {
        HStack(spacing: 8) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.2, green: 0.5, blue: 1.0), Color(red: 0.4, green: 0.3, blue: 0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)

                Image(systemName: "person.2.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }

            // Title
            VStack(alignment: .leading, spacing: 2) {
                Text("Arkadaşlarım")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("\(totalCount) kişi bekliyor")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Friend Card View

struct FriendCardView: View {
    let friend: FriendWidgetData

    var body: some View {
        if let url = URL(string: "lifestyles://friend-detail/\(friend.id)") {
            Link(destination: url) {
                cardContent
            }
            .buttonStyle(.plain)
        } else {
            cardContent
        }
    }

    private var cardContent: some View {
        HStack(spacing: 12) {
                // Avatar
                AvatarView(emoji: friend.emoji, status: friend.statusCategory)

                // Info
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        Text(friend.name)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        if friend.isImportant {
                            Image(systemName: "star.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }

                    StatusBadge(friend: friend)
                }

                Spacer()

                // Action Icon
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        gradientForStatus(friend.statusCategory).opacity(0.2),
                        lineWidth: 1
                    )
            )
    }

    private func gradientForStatus(_ status: FriendStatus) -> LinearGradient {
        switch status {
        case .overdue:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.3, blue: 0.3), Color(red: 1.0, green: 0.6, blue: 0.2)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .upcoming:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 1.0, green: 0.8, blue: 0.3)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .onTime:
            return LinearGradient(
                colors: [Color(red: 0.2, green: 0.8, blue: 0.5), Color(red: 0.3, green: 0.9, blue: 0.7)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}

// MARK: - Avatar View

struct AvatarView: View {
    let emoji: String
    let status: FriendStatus

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Avatar background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .opacity(0.2)
                    )
                    .frame(width: 40, height: 40)

                Text(emoji)
                    .font(.system(size: 20))
            }

            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color(.systemBackground), lineWidth: 2)
                )
        }
    }

    private var gradientColors: [Color] {
        switch status {
        case .overdue:
            return [Color(red: 1.0, green: 0.3, blue: 0.3), Color(red: 1.0, green: 0.6, blue: 0.2)]
        case .upcoming:
            return [Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 1.0, green: 0.8, blue: 0.3)]
        case .onTime:
            return [Color(red: 0.2, green: 0.8, blue: 0.5), Color(red: 0.3, green: 0.9, blue: 0.7)]
        }
    }

    private var statusColor: Color {
        switch status {
        case .overdue:
            return Color(red: 1.0, green: 0.3, blue: 0.3)
        case .upcoming:
            return Color(red: 1.0, green: 0.6, blue: 0.2)
        case .onTime:
            return Color(red: 0.2, green: 0.8, blue: 0.5)
        }
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let friend: FriendWidgetData

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: friend.statusIcon)
                .font(.system(size: 9, weight: .semibold))
            Text(friend.statusText)
                .font(.system(size: 10, weight: .medium, design: .rounded))
        }
        .foregroundStyle(gradientForStatus)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(colorForStatus.opacity(0.15))
        )
    }

    private var gradientForStatus: LinearGradient {
        switch friend.statusCategory {
        case .overdue:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.3, blue: 0.3), Color(red: 1.0, green: 0.6, blue: 0.2)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .upcoming:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 1.0, green: 0.8, blue: 0.3)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .onTime:
            return LinearGradient(
                colors: [Color(red: 0.2, green: 0.8, blue: 0.5), Color(red: 0.3, green: 0.9, blue: 0.7)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    private var colorForStatus: Color {
        switch friend.statusCategory {
        case .overdue:
            return Color(red: 1.0, green: 0.3, blue: 0.3)
        case .upcoming:
            return Color(red: 1.0, green: 0.6, blue: 0.2)
        case .onTime:
            return Color(red: 0.2, green: 0.8, blue: 0.5)
        }
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 0.2, green: 0.8, blue: 0.5), Color(red: 0.3, green: 0.9, blue: 0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 4) {
                Text("Harika! ✨")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("Tüm arkadaşların ile güncel")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
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

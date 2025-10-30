//
//  FriendDetailSupporting.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Refactored from FriendDetailView.swift - Supporting views
//

import SwiftUI

// MARK: - Supporting Views

struct FriendQuickActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.body)
                .frame(width: 44, height: 44)
                .background(color)
                .foregroundStyle(.white)
                .clipShape(Circle())
                .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }
}

struct CompactHistoryCard: View {
    let historyItem: ContactHistory

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                Text(formatDay(historyItem.date))
                    .font(.caption)
                    .fontWeight(.bold)

                Text(formatMonth(historyItem.date))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 40)

            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 1)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(formatTime(historyItem.date))
                        .font(.caption)
                        .fontWeight(.semibold)

                    if let mood = historyItem.mood {
                        Spacer()
                        Text(mood.emoji)
                    }
                }

                if let notes = historyItem.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct AchievementBadge: View {
    let badge: FriendAchievement

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: badge.icon)
                .font(.title3)
                .foregroundStyle(badge.color)

            Text(badge.title)
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .frame(width: 80)
        .padding(.vertical, 12)
        .background(badge.color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct PatternCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}


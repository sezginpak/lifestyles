//
//  MoodCorrelationCards.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Mood korelasyon kartları (Goal, Friend, Location)
//

import SwiftUI

// MARK: - Goal Correlation Section

struct GoalCorrelationSection: View {
    let correlations: [MoodGoalCorrelation]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "target")
                    .foregroundStyle(.purple)
                Text(String(localized: "mood.correlation.goal.title", comment: "Goal - Mood correlation"))
                    .font(.headline)

                Spacer()
            }

            if correlations.isEmpty {
                emptyState(message: "Henüz yeterli veri yok")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(correlations.prefix(5)) { correlation in
                            GoalCorrelationCard(correlation: correlation)
                        }
                    }
                }
            }
        }
    }

    private func emptyState(message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 20)
    }
}

struct GoalCorrelationCard: View {
    let correlation: MoodGoalCorrelation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(correlation.goal.emoji ?? correlation.goal.category.emoji)
                    .font(.title2)

                Spacer()

                // Correlation badge
                Text(correlation.formattedScore)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(correlation.isPositive ? .green : .red)
                    )
            }

            // Goal title
            Text(correlation.goal.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)

            // Description
            Text(correlation.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            // Sample size
            Text(String(format: NSLocalizedString("mood.correlation.data.points.format", comment: "X data points"), correlation.sampleSize))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(width: 200)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    (correlation.isPositive ? Color.green : Color.red).opacity(0.3),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Friend Correlation Section

struct FriendCorrelationSection: View {
    let correlations: [MoodFriendCorrelation]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(.blue)
                Text(String(localized: "mood.correlation.friend.title", comment: "Friend - Mood correlation"))
                    .font(.headline)

                Spacer()
            }

            if correlations.isEmpty {
                emptyState(message: "Henüz yeterli veri yok")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(correlations.prefix(5)) { correlation in
                            FriendCorrelationCard(correlation: correlation)
                        }
                    }
                }
            }
        }
    }

    private func emptyState(message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 20)
    }
}

struct FriendCorrelationCard: View {
    let correlation: MoodFriendCorrelation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Friend emoji/avatar
                if let emoji = correlation.friend.avatarEmoji {
                    Text(emoji)
                        .font(.title2)
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }

                Spacer()

                // Correlation badge
                Text(correlation.formattedScore)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(correlation.isPositive ? .green : .red)
                    )
            }

            // Friend name
            Text(correlation.friend.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)

            // Description
            Text(correlation.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            // Sample size
            Text(String(format: NSLocalizedString("mood.correlation.meetings.format", comment: "X meetings"), correlation.sampleSize))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(width: 200)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    (correlation.isPositive ? Color.green : Color.red).opacity(0.3),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Location Correlation Section

struct LocationCorrelationSection: View {
    let correlations: [MoodLocationCorrelation]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(.orange)
                Text(String(localized: "mood.correlation.location.title", comment: "Location - Mood correlation"))
                    .font(.headline)

                Spacer()
            }

            if correlations.isEmpty {
                emptyState(message: "Mood'lara lokasyon eklemeye başlayın")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(correlations.prefix(5)) { correlation in
                            LocationCorrelationCard(correlation: correlation)
                        }
                    }
                }
            }
        }
    }

    private func emptyState(message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 20)
    }
}

struct LocationCorrelationCard: View {
    let correlation: MoodLocationCorrelation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)

                Spacer()

                // Correlation badge
                Text(correlation.formattedScore)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(correlation.isPositive ? .green : .red)
                    )
            }

            // Location name
            Text(correlation.location.address ?? "Bilinmeyen Lokasyon")
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)

            // Dominant mood
            if let dominantMood = correlation.dominantMood {
                HStack(spacing: 4) {
                    Text(dominantMood.emoji)
                    Text(dominantMood.displayName)
                        .font(.caption)
                        .foregroundStyle(dominantMood.color)
                }
            }

            // Description
            Text(correlation.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            // Visit count
            Text("\(correlation.visitCount) ziyaret")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(width: 200)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    (correlation.isPositive ? Color.green : Color.red).opacity(0.3),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - All Correlations View

struct MoodCorrelationsView: View {
    let goalCorrelations: [MoodGoalCorrelation]
    let friendCorrelations: [MoodFriendCorrelation]
    let locationCorrelations: [MoodLocationCorrelation]

    var body: some View {
        VStack(spacing: 24) {
            // Goals
            if !goalCorrelations.isEmpty {
                GoalCorrelationSection(correlations: goalCorrelations)
            }

            // Friends
            if !friendCorrelations.isEmpty {
                FriendCorrelationSection(correlations: friendCorrelations)
            }

            // Locations
            if !locationCorrelations.isEmpty {
                LocationCorrelationSection(correlations: locationCorrelations)
            }

            // Empty state (hepsi boşsa)
            if goalCorrelations.isEmpty && friendCorrelations.isEmpty && locationCorrelations.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)

                    Text(String(localized: "mood.correlation.empty.title", comment: "No correlation data yet"))
                        .font(.headline)

                    Text(String(localized: "mood.correlation.empty.message", comment: "Relationships will appear as your mood entries increase"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(40)
            }
        }
    }
}

#Preview {
    ScrollView {
        MoodCorrelationsView(
            goalCorrelations: [],
            friendCorrelations: [],
            locationCorrelations: []
        )
        .padding()
    }
}

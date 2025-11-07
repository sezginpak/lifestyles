//
//  TimelineMoodView.swift
//  LifeStyles
//
//  Modern timeline view for mood tracking
//  Created by Claude on 30.10.2025.
//

import SwiftUI

struct TimelineMoodView: View {
    let moodEntries: [MoodEntry]
    let onEdit: (MoodEntry) -> Void
    let onDelete: (MoodEntry) -> Void
    let onRefresh: () async -> Void

    @State private var selectedEntry: MoodEntry?
    @State private var isRefreshing = false

    // Group moods by day
    var groupedMoods: [(Date, [MoodEntry])] {
        let grouped = Dictionary(grouping: moodEntries) { entry in
            Calendar.current.startOfDay(for: entry.date)
        }
        return grouped
            .sorted { $0.key > $1.key } // Newest first
            .map { ($0.key, $0.value.sorted { $0.date > $1.date }) }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if moodEntries.isEmpty {
                    emptyState
                } else {
                    ForEach(Array(groupedMoods.enumerated()), id: \.offset) { index, group in
                        let (date, moods) = group

                        // Section header
                        sectionHeader(date: date, isFirst: index == 0)

                        // Mood entries for this day
                        ForEach(Array(moods.enumerated()), id: \.element.id) { moodIndex, mood in
                            timelineNode(
                                mood: mood,
                                isFirst: moodIndex == 0,
                                isLast: moodIndex == moods.count - 1,
                                isLastDay: index == groupedMoods.count - 1 && moodIndex == moods.count - 1
                            )
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .opacity
                            ))
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .refreshable {
            await performRefresh()
        }
    }

    // MARK: - Section Header

    func sectionHeader(date: Date, isFirst: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(relativeDateString(date))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)

                Text(fullDateString(date))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Day mood summary
            if let moods = groupedMoods.first(where: { $0.0 == date })?.1 {
                daySummaryBadge(moods: moods)
            }
        }
        .padding(.top, isFirst ? 0 : 24)
        .padding(.bottom, 12)
    }

    func daySummaryBadge(moods: [MoodEntry]) -> some View {
        let averageScore = moods.map { $0.score }.reduce(0, +) / Double(moods.count)
        let dominantMood = moods.max(by: { $0.intensity < $1.intensity })?.moodType ?? .neutral

        return HStack(spacing: 6) {
            Text(dominantMood.emoji)
                .font(.system(size: 16))

            Text(String(localized: "journal.percentage.format", defaultValue: "\(Int(averageScore * 50 + 50))%", comment: "Percentage"))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(moodGradient(for: averageScore))
        )
        .shadow(color: moodColor(for: averageScore).opacity(0.3), radius: 4)
    }

    // MARK: - Timeline Node

    func timelineNode(mood: MoodEntry, isFirst: Bool, isLast: Bool, isLastDay: Bool) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline column
            VStack(spacing: 0) {
                // Top line
                if !isFirst {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [moodColor(for: mood.score).opacity(0.3), moodColor(for: mood.score).opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2, height: 20)
                }

                // Node circle
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(moodColor(for: mood.score).opacity(0.2))
                        .frame(width: 56, height: 56)
                        .blur(radius: 8)

                    // Main circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [moodColor(for: mood.score), moodColor(for: mood.score).opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                        .shadow(color: moodColor(for: mood.score).opacity(0.4), radius: 8)

                    // Emoji
                    Text(mood.moodType.emoji)
                        .font(.system(size: 24))
                }

                // Bottom line
                if !isLast || !isLastDay {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [moodColor(for: mood.score).opacity(0.1), moodColor(for: mood.score).opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2)
                        .frame(minHeight: 60)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 0) {
                moodCard(mood: mood)
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Mood Card

    func moodCard(mood: MoodEntry) -> some View {
        Button(action: {
            selectedEntry = mood
            HapticFeedback.light()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header: Time + Intensity
                HStack {
                    Text(timeString(mood.date))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(moodColor(for: mood.score))

                    Spacer()

                    intensityIndicator(intensity: mood.intensity)
                }

                // Mood name
                Text(mood.moodType.displayName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)

                // Note (if exists)
                if let note = mood.note, !note.isEmpty {
                    Text(note)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                // Related info
                relatedInfoRow(mood: mood)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(moodColor(for: mood.score).opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .contextMenu {
            Button(action: { onEdit(mood) }) {
                Label(String(localized: "button.edit", comment: "Edit button"), systemImage: "pencil")
            }

            Button(role: .destructive, action: { onDelete(mood) }) {
                Label(String(localized: "button.delete", comment: "Delete button"), systemImage: "trash")
            }
        }
    }

    // MARK: - Intensity Indicator

    func intensityIndicator(intensity: Int) -> some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { level in
                RoundedRectangle(cornerRadius: 2)
                    .fill(level <= intensity ? Color.white : Color.white.opacity(0.3))
                    .frame(width: 20, height: 4)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(moodColor(for: Double(intensity - 3) / 2.0).opacity(0.8))
        )
    }

    // MARK: - Related Info

    func relatedInfoRow(mood: MoodEntry) -> some View {
        HStack(spacing: 12) {
            if let goals = mood.relatedGoals, !goals.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "target")
                        .font(.system(size: 10))
                    Text(String(localized: "goals.count", defaultValue: "\(goals.count)", comment: "Goals count"))
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(.blue)
            }

            if let friends = mood.relatedFriends, !friends.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "person.2")
                        .font(.system(size: 10))
                    Text(String(localized: "friends.count", defaultValue: "\(friends.count)", comment: "Friends count"))
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(.green)
            }

            if mood.relatedLocation != nil {
                HStack(spacing: 4) {
                    Image(systemName: "location")
                        .font(.system(size: 10))
                }
                .foregroundColor(.orange)
            }
        }
    }

    // MARK: - Empty State

    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "face.smiling")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.top, 60)

            Text(String(localized: "mood.no.records", comment: ""))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)

            Text(String(localized: "mood.tap.to.record", comment: ""))
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }

    // MARK: - Helpers

    func relativeDateString(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Bugün"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Dün"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMMM EEEE"
            formatter.locale = Locale(identifier: "tr_TR")
            return formatter.string(from: date)
        }
    }

    func fullDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy, EEEE"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }

    func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    func moodColor(for score: Double) -> Color {
        if score > 0.5 {
            return .green
        } else if score > 0 {
            return .blue
        } else if score > -0.5 {
            return .orange
        } else {
            return .red
        }
    }

    func moodGradient(for score: Double) -> LinearGradient {
        let color = moodColor(for: score)
        return LinearGradient(
            colors: [color, color.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    func performRefresh() async {
        isRefreshing = true
        await onRefresh()
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay for smooth UX
        isRefreshing = false
    }
}

// MARK: - Preview

#Preview {
    let sampleMoods: [MoodEntry] = [
        MoodEntry(
            date: Date(),
            moodType: .happy,
            intensity: 4,
            note: "Harika bir gün geçirdim! Sabah koşusu çok iyiydi."
        ),
        MoodEntry(
            date: Date().addingTimeInterval(-3600),
            moodType: .excited,
            intensity: 5,
            note: "Proje tamamlandı!"
        ),
        MoodEntry(
            date: Date().addingTimeInterval(-86400),
            moodType: .neutral,
            intensity: 3,
            note: "Normal bir gün"
        ),
        MoodEntry(
            date: Date().addingTimeInterval(-86400 - 7200),
            moodType: .tired,
            intensity: 2,
            note: "Yorgunum"
        )
    ]

    return TimelineMoodView(
        moodEntries: sampleMoods,
        onEdit: { _ in },
        onDelete: { _ in },
        onRefresh: { }
    )
}

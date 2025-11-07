//
//  MoodCompactComponents.swift
//  LifeStyles
//
//  Created by Claude on 22.10.2025.
//  Compact mood ve journal component'leri - Dashboard ve liste görünümleri için
//

import SwiftUI

// MARK: - 1. CompactMoodCard

/// Mood entry'yi kompakt gösterir (56px height)
struct CompactMoodCard: View {
    let mood: MoodEntry
    @State private var isPressed: Bool = false

    var body: some View {
        HStack(spacing: Spacing.medium) {
            // Emoji (32pt circle)
            Text(mood.moodType.emoji)
                .font(.largeTitle)
                .frame(width: 32, height: 32)
                .accessibilityHidden(true)

            // Mood info
            VStack(alignment: .leading, spacing: Spacing.micro) {
                HStack(spacing: Spacing.small) {
                    Text(mood.moodType.displayName)
                        .cardTitle()

                    // Intensity dots (1-5)
                    IntensityDots(intensity: mood.intensity)
                }

                if let note = mood.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Relative time
            Text(relativeTime(for: mood.date))
                .metadataText()
        }
        .padding(Spacing.medium)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.normal, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.normal, style: .continuous)
                .strokeBorder(mood.moodType.color.opacity(0.4), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "mood.with.intensity", defaultValue: "\(mood.moodType.displayName), intensity level \(mood.intensity)", comment: "Mood with intensity"))
        .accessibilityHint("Detayları görmek için tıklayın")
        .accessibilityAddTraits(.isButton)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isPressed)
        .onTapGesture {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                    isPressed = false
                }
            }
            HapticFeedback.light()
        }
    }

    /// Relative time formatter (e.g., "2s önce", "5d önce")
    private func relativeTime(for date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)

        if interval < 60 {
            return "Az önce"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)d önce"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)s önce"
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days)g önce"
        } else {
            let weeks = Int(interval / 604800)
            return "\(weeks)h önce"
        }
    }
}

// MARK: - 2. MiniStatCard

/// İstatistik gösterir (90px height)
struct MiniStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.small) {
            // Icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            // Value
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            // Title
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 90)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.normal, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.normal, style: .continuous)
                .strokeBorder(color.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "mood.title.value", defaultValue: "\(title): \(value)", comment: "Title value"))
        .accessibilityValue(value)
    }
}

// MARK: - 3. CompactJournalTypePill

/// Journal type'ı kompakt gösterir
struct CompactJournalTypePill: View {
    let type: JournalType
    var compact: Bool = false
    var showIcon: Bool = true

    private var height: CGFloat {
        compact ? 24 : 28
    }

    private var fontSize: Font {
        compact ? .caption2 : .caption
    }

    var body: some View {
        HStack(spacing: Spacing.micro) {
            if showIcon {
                Image(systemName: type.icon)
                    .font(fontSize)
            }

            Text(type.emoji)
                .font(fontSize)

            Text(type.displayName)
                .font(fontSize)
                .fontWeight(.medium)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, compact ? Spacing.small : Spacing.medium)
        .frame(height: height)
        .background(type.color.gradient)
        .clipShape(Capsule())
    }
}

// MARK: - 4. InlineMoodStreak

/// Streak bilgisini inline gösterir (28px height)
struct InlineMoodStreak: View {
    let currentStreak: Int
    var isActive: Bool = true

    var body: some View {
        HStack(spacing: Spacing.small) {
            Image(systemName: "flame.fill")
                .font(.body)
                .foregroundStyle(isActive ? .orange : .secondary)

            Text(String(format: NSLocalizedString("mood.streak.days.format", comment: "Day streak count"), currentStreak))
                .font(.callout)
                .fontWeight(.medium)
                .foregroundStyle(isActive ? .primary : .secondary)
        }
        .padding(.horizontal, Spacing.medium)
        .frame(height: 28)
        .background(
            Capsule()
                .fill(isActive ? Color.orange.opacity(0.15) : Color.gray.opacity(0.1))
        )
        .overlay(
            Capsule()
                .strokeBorder(isActive ? Color.orange.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "mood.daily.streak", defaultValue: "\(currentStreak) day streak", comment: "Daily streak"))
        .accessibilityValue(isActive ? "Aktif" : "İnaktif")
    }
}

// MARK: - 5. MoodGridItem (Bonus)

/// Grid view için mood card (4 column layout)
struct MoodGridItem: View {
    let mood: MoodEntry?
    let date: Date

    var body: some View {
        VStack(spacing: Spacing.micro) {
            if let mood = mood {
                // Mood var
                Text(mood.moodType.emoji)
                    .font(.largeTitle)

                Text(weekdayShort(for: date))
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                // Intensity indicator (simple circle)
                Circle()
                    .fill(mood.moodType.color)
                    .frame(width: 6, height: 6)
            } else {
                // Mood yok
                Circle()
                    .strokeBorder(.tertiary, lineWidth: 1)
                    .frame(width: 32, height: 32)

                Text(weekdayShort(for: date))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Circle()
                    .fill(.tertiary)
                    .frame(width: 4, height: 4)
            }
        }
        .frame(width: 80, height: 80)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.compact, style: .continuous)
                .fill(mood != nil ? Material.ultraThinMaterial : Material.ultraThin)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.compact, style: .continuous)
                .strokeBorder(
                    mood != nil ? mood!.moodType.color.opacity(0.4) : Color.clear,
                    lineWidth: 1
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(mood != nil ? "\(mood!.moodType.displayName), \(weekdayShort(for: date))" : "Mood kaydı yok, \(weekdayShort(for: date))")
    }

    /// Weekday short name (e.g., "Pzt", "Sal")
    private func weekdayShort(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// MARK: - Helper Views

/// Intensity dots indicator (1-5)
private struct IntensityDots: View {
    let intensity: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { index in
                Circle()
                    .fill(index <= intensity ? Color.brandPrimary : Color.gray.opacity(0.3))
                    .frame(width: 4, height: 4)
            }
        }
    }
}

// MARK: - Previews

#Preview("CompactMoodCard") {
    VStack(spacing: Spacing.medium) {
        CompactMoodCard(
            mood: MoodEntry(
                moodType: .happy,
                intensity: 4,
                note: "Harika bir gün!"
            )
        )

        CompactMoodCard(
            mood: MoodEntry(
                moodType: .stressed,
                intensity: 3,
                note: "İş yoğunluğu fazla"
            )
        )

        CompactMoodCard(
            mood: MoodEntry(
                moodType: .grateful,
                intensity: 5
            )
        )
    }
    .padding()
    .background(Color.backgroundPrimary)
}

#Preview("MiniStatCard") {
    HStack(spacing: Spacing.medium) {
        MiniStatCard(
            title: "Toplam",
            value: "42",
            icon: "chart.bar.fill",
            color: .brandPrimary
        )

        MiniStatCard(
            title: "Streak",
            value: "7",
            icon: "flame.fill",
            color: .orange
        )

        MiniStatCard(
            title: "Ortalama",
            value: "4.2",
            icon: "star.fill",
            color: .success
        )
    }
    .padding()
    .background(Color.backgroundPrimary)
}

#Preview("CompactJournalTypePill") {
    VStack(spacing: Spacing.medium) {
        HStack(spacing: Spacing.small) {
            CompactJournalTypePill(type: .general)
            CompactJournalTypePill(type: .gratitude)
        }

        HStack(spacing: Spacing.small) {
            CompactJournalTypePill(type: .achievement, compact: true)
            CompactJournalTypePill(type: .lesson, compact: true)
        }

        HStack(spacing: Spacing.small) {
            CompactJournalTypePill(type: .general, showIcon: false)
            CompactJournalTypePill(type: .gratitude, compact: true, showIcon: false)
        }
    }
    .padding()
    .background(Color.backgroundPrimary)
}

#Preview("InlineMoodStreak") {
    VStack(spacing: Spacing.medium) {
        InlineMoodStreak(currentStreak: 7, isActive: true)
        InlineMoodStreak(currentStreak: 0, isActive: false)
        InlineMoodStreak(currentStreak: 14, isActive: true)
    }
    .padding()
    .background(Color.backgroundPrimary)
}

#Preview("MoodGridItem") {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: Spacing.small) {
        MoodGridItem(
            mood: MoodEntry(moodType: .happy, intensity: 4),
            date: Date()
        )

        MoodGridItem(
            mood: MoodEntry(moodType: .grateful, intensity: 5),
            date: Date().addingTimeInterval(-86400)
        )

        MoodGridItem(
            mood: nil,
            date: Date().addingTimeInterval(-172800)
        )

        MoodGridItem(
            mood: MoodEntry(moodType: .stressed, intensity: 2),
            date: Date().addingTimeInterval(-259200)
        )
    }
    .padding()
    .background(Color.backgroundPrimary)
}

#Preview("All Components Combined") {
    ScrollView {
        VStack(spacing: Spacing.large) {
            // Section 1: Compact Cards
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text(String(localized: "compact.mood.cards", comment: "Compact Mood Cards"))
                    .font(.title3)
                    .fontWeight(.bold)

                CompactMoodCard(
                    mood: MoodEntry(
                        moodType: .veryHappy,
                        intensity: 5,
                        note: "Muhteşem bir gün!"
                    )
                )

                CompactMoodCard(
                    mood: MoodEntry(
                        moodType: .anxious,
                        intensity: 3,
                        note: "Biraz endişeli hissediyorum"
                    )
                )
            }

            // Section 2: Stats
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text(String(localized: "mood.mini.stat.cards", comment: "Mini Stat Cards"))
                    .font(.title3)
                    .fontWeight(.bold)

                HStack(spacing: Spacing.medium) {
                    MiniStatCard(
                        title: "Bu Hafta",
                        value: "7",
                        icon: "calendar",
                        color: .brandPrimary
                    )

                    MiniStatCard(
                        title: "Streak",
                        value: "14",
                        icon: "flame.fill",
                        color: .orange
                    )

                    MiniStatCard(
                        title: "En İyi",
                        value: "30",
                        icon: "trophy.fill",
                        color: .success
                    )
                }
            }

            // Section 3: Journal Types
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text(String(localized: "journal.type.pills", comment: "Journal Type Pills"))
                    .font(.title3)
                    .fontWeight(.bold)

                HStack(spacing: Spacing.small) {
                    CompactJournalTypePill(type: .general)
                    CompactJournalTypePill(type: .gratitude, compact: true)
                }
            }

            // Section 4: Streak
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text(String(localized: "debug.streak.indicator", comment: "Streak Indicator"))
                    .font(.title3)
                    .fontWeight(.bold)

                InlineMoodStreak(currentStreak: 7, isActive: true)
            }

            // Section 5: Grid
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text(String(localized: "debug.mood.grid.week", comment: "Mood Grid (Week View)"))
                    .font(.title3)
                    .fontWeight(.bold)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: Spacing.small) {
                    ForEach(0..<7, id: \.self) { index in
                        if index % 3 == 0 {
                            MoodGridItem(
                                mood: nil,
                                date: Date().addingTimeInterval(Double(-index) * 86400)
                            )
                        } else {
                            MoodGridItem(
                                mood: MoodEntry(
                                    moodType: MoodType.allCases.randomElement()!,
                                    intensity: Int.random(in: 1...5)
                                ),
                                date: Date().addingTimeInterval(Double(-index) * 86400)
                            )
                        }
                    }
                }
            }
        }
        .padding()
    }
    .background(Color.backgroundPrimary)
}

// MARK: - 6. TodayMoodCard (Gün İçi Mood Kartları)

/// Bugünün mood'larını gösterir (spotlight veya compact variant)
struct TodayMoodCard: View {
    let mood: MoodEntry
    var isSpotlight: Bool = false
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    @State private var isPressed: Bool = false
    @State private var showDeleteConfirm: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: isSpotlight ? Spacing.medium : Spacing.small) {
            // Header: Emoji + Actions
            HStack(alignment: .top) {
                Text(mood.moodType.emoji)
                    .font(.system(size: isSpotlight ? 64 : 40))

                Spacer()

                if isSpotlight {
                    // Edit/Delete buttons
                    HStack(spacing: Spacing.small) {
                        Button {
                            HapticFeedback.light()
                            onEdit?()
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .padding(6)
                                .background(Circle().fill(Color.brandPrimary))
                        }
                        .buttonStyle(.plain)

                        Button {
                            HapticFeedback.warning()
                            showDeleteConfirm = true
                        } label: {
                            Image(systemName: "trash.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .padding(6)
                                .background(Circle().fill(Color.red))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Mood Info
            VStack(alignment: .leading, spacing: Spacing.micro) {
                Text(mood.moodType.displayName)
                    .font(isSpotlight ? .title3 : .subheadline)
                    .fontWeight(.bold)

                // Time
                Text(timeString(for: mood.date))
                    .font(isSpotlight ? .callout : .caption)
                    .foregroundStyle(.secondary)

                // Intensity
                HStack(spacing: 3) {
                    ForEach(1...5, id: \.self) { index in
                        Circle()
                            .fill(index <= mood.intensity ? mood.moodType.color : Color.gray.opacity(0.3))
                            .frame(width: isSpotlight ? 6 : 5, height: isSpotlight ? 6 : 5)
                    }
                }
                .padding(.top, Spacing.micro)
            }

            // Note (if exists and spotlight)
            if isSpotlight, let note = mood.note, !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .padding(.top, Spacing.micro)
            }

            Spacer()
        }
        .padding(isSpotlight ? Spacing.large : Spacing.medium)
        .frame(width: isSpotlight ? 180 : 130, height: isSpotlight ? 200 : 150)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.CornerRadius.large, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            mood.moodType.color.opacity(0.15),
                            mood.moodType.color.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.CornerRadius.large, style: .continuous)
                .strokeBorder(
                    mood.moodType.color.opacity(isSpotlight ? 0.5 : 0.3),
                    lineWidth: isSpotlight ? 2 : 1
                )
        )
        .shadow(
            color: isSpotlight ? mood.moodType.color.opacity(0.2) : .clear,
            radius: 12,
            y: 4
        )
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isPressed)
        .alert("Mood'u Sil", isPresented: $showDeleteConfirm) {
            Button(String(localized: "button.cancel", comment: "Cancel button"), role: .cancel) { }
            Button(String(localized: "button.delete", comment: "Delete button"), role: .destructive) {
                onDelete?()
            }
        } message: {
            Text(String(localized: "mood.delete.confirmation", comment: "Are you sure you want to delete this mood entry?"))
        }
    }

    /// Saat formatı (HH:mm)
    private func timeString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
}

// MARK: - 7. TodayMoodsScrollView (Yatay Kaydırmalı Grid)

/// Bugünün mood'larını yatay scrollview ile gösterir
struct TodayMoodsScrollView: View {
    let moods: [MoodEntry]
    var onEdit: ((MoodEntry) -> Void)?
    var onDelete: ((MoodEntry) -> Void)?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.medium) {
                ForEach(Array(moods.enumerated()), id: \.element.id) { index, mood in
                    TodayMoodCard(
                        mood: mood,
                        isSpotlight: index == 0, // İlk mood spotlight
                        onEdit: { onEdit?(mood) },
                        onDelete: { onDelete?(mood) }
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, Spacing.large)
        }
        .frame(height: 220)
    }
}

// MARK: - Previews (Yeni Component'ler)

#Preview("TodayMoodCard - Spotlight") {
    TodayMoodCard(
        mood: MoodEntry(
            moodType: .happy,
            intensity: 4,
            note: "Harika bir sabah!"
        ),
        isSpotlight: true
    )
    .padding()
    .background(Color.backgroundPrimary)
}

#Preview("TodayMoodCard - Compact") {
    HStack(spacing: Spacing.medium) {
        TodayMoodCard(
            mood: MoodEntry(
                moodType: .excited,
                intensity: 5
            ),
            isSpotlight: false
        )

        TodayMoodCard(
            mood: MoodEntry(
                moodType: .grateful,
                intensity: 4
            ),
            isSpotlight: false
        )
    }
    .padding()
    .background(Color.backgroundPrimary)
}

#Preview("TodayMoodsScrollView") {
    TodayMoodsScrollView(
        moods: [
            MoodEntry(moodType: .happy, intensity: 4, note: "Sabah kahvem harika!"),
            MoodEntry(moodType: .excited, intensity: 5),
            MoodEntry(moodType: .grateful, intensity: 4),
            MoodEntry(moodType: .neutral, intensity: 3)
        ]
    )
    .background(Color.backgroundPrimary)
}

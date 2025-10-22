//
//  MoodTrackerView.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Günlük mood tracking view
//

import SwiftUI
import SwiftData

struct MoodTrackerView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: MoodJournalViewModel

    @State private var selectedMood: MoodType = .happy
    @State private var intensity: Int = 3
    @State private var note: String = ""
    @State private var showingMoodPicker: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Today's Mood Card
                if let todaysMood = viewModel.todaysMood {
                    existingMoodCard(todaysMood)
                } else {
                    newMoodCard
                }

                // Streak Display
                if viewModel.streakData.currentStreak > 0 {
                    streakCard
                }

                // Recent Moods
                if !viewModel.moodEntries.isEmpty {
                    recentMoodsSection
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingMoodPicker) {
            moodPickerSheet
        }
    }

    // MARK: - Today's Mood (New)

    private var newMoodCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "mood.how.are.you.today", comment: "How are you today?"))
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(String(localized: "mood.record.your.mood", comment: "Record your mood"))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("😊")
                    .font(.system(size: 50))
            }

            Button {
                HapticFeedback.medium()
                showingMoodPicker = true
            } label: {
                HStack {
                    Image(systemName: "face.smiling")
                    Text(String(localized: "mood.record.button", comment: "Record mood"))
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Today's Mood (Existing)

    private func existingMoodCard(_ mood: MoodEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "mood.todays.mood", comment: "Today's mood"))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(mood.moodType.displayName)
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Spacer()

                Text(mood.moodType.emoji)
                    .font(.system(size: 60))
            }

            // Intensity bars
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(level <= mood.intensity ? mood.moodType.color : Color(.tertiarySystemFill))
                        .frame(height: 4)
                }
            }

            if let note = mood.note, !note.isEmpty {
                Text(note)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.tertiarySystemBackground))
                    )
            }

            Text(String(format: NSLocalizedString("mood.recorded.at.format", comment: "Recorded today at X"), mood.date.formatted(date: .omitted, time: .shortened)))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
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
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(mood.moodType.color.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text(String(localized: "mood.streak", comment: "Streak"))
                    .font(.headline)

                Spacer()
            }

            CompactStreakDisplay(
                currentStreak: viewModel.streakData.currentStreak,
                isActive: viewModel.streakData.isActive
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Recent Moods

    private var recentMoodsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "mood.recent.entries", comment: "Recent entries"))
                .font(.headline)

            ForEach(Array(viewModel.moodEntries.prefix(7).enumerated()), id: \.element.id) { index, mood in
                if index != 0 || !mood.isToday { // Bugünkü zaten yukarıda gösteriliyor
                    moodRowCard(mood)
                }
            }
        }
    }

    private func moodRowCard(_ mood: MoodEntry) -> some View {
        HStack(spacing: 12) {
            // Emoji
            Text(mood.moodType.emoji)
                .font(.system(size: 40))

            VStack(alignment: .leading, spacing: 4) {
                Text(mood.moodType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(mood.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let note = mood.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Intensity
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 2) {
                    ForEach(1...mood.intensity, id: \.self) { _ in
                        Circle()
                            .fill(mood.moodType.color)
                            .frame(width: 6, height: 6)
                    }
                }

                Text("\(mood.intensity)/5")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Mood Picker Sheet

    private var moodPickerSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Emoji Picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "mood.how.feeling", comment: "How are you feeling?"))
                            .font(.headline)

                        MoodEmojiPicker(selectedMood: $selectedMood)
                    }

                    // Intensity Slider
                    MoodIntensitySlider(intensity: $intensity, selectedMood: selectedMood)

                    // Note
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "mood.note.optional", comment: "Note (Optional)"))
                            .font(.subheadline)
                            .fontWeight(.medium)

                        TextField(String(localized: "mood.whats.happening.placeholder", comment: "What happened today?"), text: $note, axis: .vertical)
                            .textFieldStyle(.plain)
                            .lineLimit(3...5)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.tertiarySystemBackground))
                            )
                    }
                }
                .padding()
            }
            .navigationTitle(String(localized: "mood.record.title", comment: "Record Mood"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel", comment: "Cancel")) {
                        showingMoodPicker = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.save", comment: "Save")) {
                        saveMood()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Actions

    private func saveMood() {
        viewModel.logMood(
            moodType: selectedMood,
            intensity: intensity,
            note: note.isEmpty ? nil : note,
            context: modelContext
        )

        showingMoodPicker = false

        // Reset
        note = ""
        intensity = 3
    }
}

#Preview {
    MoodTrackerView(viewModel: MoodJournalViewModel())
        .modelContainer(for: [MoodEntry.self, JournalEntry.self])
}

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
            VStack(spacing: Spacing.large) {
                // Today's Mood Card (Compact)
                if let todaysMood = viewModel.todaysMood {
                    compactExistingMoodCard(todaysMood)
                } else {
                    compactNewMoodCard
                }

                // Stats Section (3 Column)
                statsSection

                // Recent Moods (Grid 2-column)
                if !viewModel.moodEntries.isEmpty {
                    compactRecentMoodsSection
                }
            }
            .padding(Spacing.large)
        }
        .sheet(isPresented: $showingMoodPicker) {
            moodPickerSheet
        }
    }

    // MARK: - Today's Mood (New) - COMPACT

    private var compactNewMoodCard: some View {
        HStack(spacing: Spacing.medium) {
            // Emoji (smaller)
            Text("😊")
                .font(.system(size: 40))

            VStack(alignment: .leading, spacing: Spacing.micro) {
                Text(String(localized: "mood.how.are.you.today", comment: "How are you today?"))
                    .font(.headline)
                    .fontWeight(.bold)

                Text(String(localized: "mood.record.your.mood", comment: "Record your mood"))
                    .secondaryText()
            }

            Spacer()

            // Record button (compact)
            Button {
                HapticFeedback.medium()
                showingMoodPicker = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .buttonStyle(.plain)
            .scaleEffect(showingMoodPicker ? 0.95 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: showingMoodPicker)
        }
        .padding(Spacing.large)
        .frame(height: 88)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.relaxed)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Today's Mood (Existing) - COMPACT

    private func compactExistingMoodCard(_ mood: MoodEntry) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(spacing: Spacing.medium) {
                // Emoji (40pt)
                Text(mood.moodType.emoji)
                    .font(.system(size: 40))

                VStack(alignment: .leading, spacing: Spacing.micro) {
                    Text(String(localized: "mood.todays.mood", comment: "Today's mood"))
                        .metadataText()

                    Text(mood.moodType.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                }

                Spacer()

                // Intensity dots inline
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 2) {
                        ForEach(1...mood.intensity, id: \.self) { _ in
                            Circle()
                                .fill(mood.moodType.color)
                                .frame(width: 6, height: 6)
                        }
                    }
                    Text("\(mood.intensity)/5")
                        .smallMetadataText()
                }
            }

            // Streak inline
            if viewModel.streakData.currentStreak > 0 {
                InlineMoodStreak(
                    currentStreak: viewModel.streakData.currentStreak,
                    isActive: viewModel.streakData.isActive
                )
            }

            if let note = mood.note, !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .padding(.top, Spacing.micro)
            }
        }
        .padding(Spacing.large)
        .frame(height: 88)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.relaxed)
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
            RoundedRectangle(cornerRadius: CornerRadius.relaxed)
                .strokeBorder(mood.moodType.color.opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: - Stats Section (3-column Grid)

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("İstatistikler")
                .cardTitle()

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.medium) {
                MiniStatCard(
                    title: "Toplam",
                    value: "\(viewModel.moodEntries.count)",
                    icon: "chart.bar.fill",
                    color: .brandPrimary
                )

                MiniStatCard(
                    title: "Ortalama",
                    value: String(format: "%.1f", viewModel.moodStats.averageMood),
                    icon: "star.fill",
                    color: .orange
                )

                MiniStatCard(
                    title: "Bu Hafta",
                    value: "\(viewModel.moodCountThisWeek)",
                    icon: "calendar",
                    color: .blue
                )
            }
        }
    }

    // MARK: - Recent Moods (Compact Grid 2-column)

    private var compactRecentMoodsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text(String(localized: "mood.recent.entries", comment: "Recent entries"))
                .cardTitle()

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Spacing.medium),
                GridItem(.flexible(), spacing: Spacing.medium)
            ], spacing: Spacing.medium) {
                ForEach(Array(viewModel.moodEntries.prefix(6).enumerated()), id: \.element.id) { index, mood in
                    if index != 0 || !mood.isToday { // Bugünkü zaten yukarıda gösteriliyor
                        CompactMoodCard(mood: mood)
                    }
                }
            }
        }
    }

    // MARK: - Mood Picker Sheet

    private var moodPickerSheet: some View {
        NavigationStack {
            ScrollView {
                // DS: Updated spacing from 24 to Spacing.xxlarge (keeping 24 for major sections)
                VStack(spacing: Spacing.xxlarge) {
                    // Emoji Picker
                    // DS: Updated spacing from 12 to Spacing.medium
                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        Text(String(localized: "mood.how.feeling", comment: "How are you feeling?"))
                            .cardTitle() // DS: Using typography helper

                        MoodEmojiPicker(selectedMood: $selectedMood)
                    }

                    // Intensity Slider
                    MoodIntensitySlider(intensity: $intensity, selectedMood: selectedMood)

                    // Note
                    // DS: Updated spacing from 8 to Spacing.small
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text(String(localized: "mood.note.optional", comment: "Note (Optional)"))
                            .font(.subheadline)
                            .fontWeight(.medium)

                        TextField(String(localized: "mood.whats.happening.placeholder", comment: "What happened today?"), text: $note, axis: .vertical)
                            .textFieldStyle(.plain)
                            .lineLimit(3...5)
                            .padding()
                            .background(
                                // DS: Updated cornerRadius to CornerRadius.normal
                                RoundedRectangle(cornerRadius: CornerRadius.normal)
                                    .fill(Color(.tertiarySystemBackground))
                            )
                    }
                }
                // DS: Updated padding to Spacing.large
                .padding(Spacing.large)
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

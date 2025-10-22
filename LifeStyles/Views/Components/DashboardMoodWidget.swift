//
//  DashboardMoodWidget.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Dashboard'da mood gösterimi
//

import SwiftUI
import SwiftData

struct DashboardMoodWidget: View {
    @Environment(\.modelContext) private var modelContext
    @State private var todaysMood: MoodEntry?
    @State private var showingMoodPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "dashboard.todays.mood", comment: "Today's Mood"))
                .font(.headline)
                .padding(.horizontal)

            if let mood = todaysMood {
                existingMoodCard(mood)
                    .padding(.horizontal)
            } else {
                promptMoodCard
                    .padding(.horizontal)
            }
        }
        .onAppear {
            loadTodaysMood()
        }
        .sheet(isPresented: $showingMoodPicker) {
            MoodPickerSheet(onSave: { moodType, intensity, note in
                saveMood(moodType: moodType, intensity: intensity, note: note)
            })
        }
    }

    // MARK: - Existing Mood Card

    private func existingMoodCard(_ mood: MoodEntry) -> some View {
        HStack(spacing: 16) {
            // Emoji
            Text(mood.moodType.emoji)
                .font(.system(size: 50))

            VStack(alignment: .leading, spacing: 4) {
                Text(mood.moodType.displayName)
                    .font(.title3)
                    .fontWeight(.semibold)

                // Intensity bars (Flexible)
                GeometryReader { geometry in
                    HStack(spacing: 3) {
                        ForEach(1...5, id: \.self) { level in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(level <= mood.intensity ? mood.moodType.color : Color(.tertiarySystemFill))
                                .frame(height: 4)
                        }
                    }
                }
                .frame(height: 4)
                .frame(maxWidth: 160)

                if let note = mood.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()
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

    // MARK: - Prompt Card

    private var promptMoodCard: some View {
        Button {
            HapticFeedback.medium()
            showingMoodPicker = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "mood.how.are.you.today", comment: "How are you today?"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text("Mood'unu kaydet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "face.smiling")
                    .font(.title)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.purple.opacity(0.3), .pink.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Data Loading

    private func loadTodaysMood() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = #Predicate<MoodEntry> { entry in
            entry.date >= startOfDay && entry.date < endOfDay
        }

        var descriptor = FetchDescriptor<MoodEntry>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\MoodEntry.date, order: .reverse)]
        descriptor.fetchLimit = 1

        do {
            let results = try modelContext.fetch(descriptor)
            todaysMood = results.first
        } catch {
            print("❌ Failed to fetch today's mood: \(error)")
        }
    }

    private func saveMood(moodType: MoodType, intensity: Int, note: String?) {
        let entry = MoodEntry(
            moodType: moodType,
            intensity: intensity,
            note: note
        )

        modelContext.insert(entry)

        do {
            try modelContext.save()
            todaysMood = entry
            HapticFeedback.success()
            print("✅ Mood logged: \(moodType.displayName)")
        } catch {
            print("❌ Failed to save mood: \(error)")
        }
    }
}

// MARK: - Mood Picker Sheet

struct MoodPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMood: MoodType = .happy
    @State private var intensity: Int = 3
    @State private var note: String = ""

    let onSave: (MoodType, Int, String?) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Mood Emoji Picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "mood.how.are.you.feeling", comment: "How are you feeling?"))
                            .font(.headline)

                        MoodEmojiPicker(selectedMood: $selectedMood)
                    }

                    // Intensity Slider
                    MoodIntensitySlider(intensity: $intensity, selectedMood: selectedMood)

                    // Note
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Not (Opsiyonel)")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        TextField("Bugün neler oldu?", text: $note, axis: .vertical)
                            .textFieldStyle(.plain)
                            .lineLimit(2...4)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.tertiarySystemBackground))
                            )
                    }
                }
                .padding()
            }
            .navigationTitle("Mood Kaydet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        onSave(selectedMood, intensity, note.isEmpty ? nil : note)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    DashboardMoodWidget()
        .modelContainer(for: [MoodEntry.self])
}

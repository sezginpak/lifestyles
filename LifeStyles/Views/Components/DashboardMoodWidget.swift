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
        VStack(alignment: .leading, spacing: 0) {
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
        VStack(spacing: 0) {
            ZStack {
                // Gradient background
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                mood.moodType.color.opacity(0.2),
                                mood.moodType.color.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Content
                VStack(spacing: 12) {
                    // Header - kompakt
                    HStack {
                        Text(String(localized: "dashboard.todays.mood", comment: "Today's Mood"))
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        Spacer()

                        // Edit button - küçük
                        Button {
                            HapticFeedback.light()
                            showingMoodPicker = true
                        } label: {
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundStyle(mood.moodType.color.opacity(0.6))
                        }
                    }

                    // Emoji ve bilgiler - dengeli dağılım
                    HStack(spacing: 16) {
                        // Sol taraf: Emoji
                        ZStack {
                            Circle()
                                .fill(mood.moodType.color.opacity(0.15))
                                .frame(width: 70, height: 70)

                            Text(mood.moodType.emoji)
                                .font(.system(size: 38))
                        }

                        // Orta: Mood bilgileri
                        VStack(alignment: .leading, spacing: 8) {
                            Text(mood.moodType.displayName)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(mood.moodType.color)

                            // Time stamp
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                Text(mood.date, style: .time)
                                    .font(.caption2)
                            }
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        // Sağ taraf: Intensity göstergesi
                        VStack(spacing: 8) {
                            // Intensity bars - dikey
                            HStack(spacing: 5) {
                                ForEach(1...5, id: \.self) { level in
                                    VStack(spacing: 2) {
                                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                                            .fill(level <= mood.intensity ? mood.moodType.color : mood.moodType.color.opacity(0.15))
                                            .frame(width: 8, height: CGFloat(level * 6 + 12))

                                        if level == mood.intensity {
                                            Circle()
                                                .fill(mood.moodType.color)
                                                .frame(width: 3, height: 3)
                                        }
                                    }
                                }
                            }

                            Text("\(mood.intensity)/5")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(mood.moodType.color)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(mood.moodType.color.opacity(0.15))
                                )
                        }
                    }

                    // Note - sadece varsa göster, kompakt
                    if let note = mood.note, !note.isEmpty {
                        Text(note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(.ultraThinMaterial)
                            )
                    }
                }
                .padding(14)
            }
            .shadow(color: mood.moodType.color.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }

    // MARK: - Prompt Card

    private var promptMoodCard: some View {
        VStack(spacing: 0) {
            ZStack {
                // Gradient background
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                .purple.opacity(0.12),
                                .pink.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(spacing: 12) {
                    // Header - kompakt
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "mood.how.are.you.today", comment: "How are you today?"))
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Text(String(localized: "mood.tap.to.record", comment: "Tap a mood to record how you feel"))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "heart.text.square.fill")
                            .font(.title3)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    // Quick mood selection - dengeli grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach([MoodType.happy, .neutral, .sad, .anxious, .excited, .grateful], id: \.self) { moodType in
                            Button {
                                HapticFeedback.medium()
                                quickSaveMood(moodType: moodType)
                            } label: {
                                VStack(spacing: 6) {
                                    ZStack {
                                        Circle()
                                            .fill(moodType.color.opacity(0.15))
                                            .frame(width: 50, height: 50)

                                        Text(moodType.emoji)
                                            .font(.system(size: 28))
                                    }

                                    Text(moodType.displayName)
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Full picker button - kompakt
                    Button {
                        HapticFeedback.light()
                        showingMoodPicker = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.caption2)

                            Text(String(localized: "mood.more.options", comment: "More options & notes"))
                                .font(.caption2)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.purple)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                        )
                    }
                }
                .padding(14)
            }
            .shadow(color: .purple.opacity(0.08), radius: 8, x: 0, y: 4)
        }
    }

    // Quick save mood with default intensity
    private func quickSaveMood(moodType: MoodType) {
        saveMood(moodType: moodType, intensity: 3, note: nil)
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
                        Text(String(localized: "mood.note.optional", comment: "Note (Optional)"))
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

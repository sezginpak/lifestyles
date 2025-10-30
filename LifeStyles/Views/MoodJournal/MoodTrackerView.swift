//
//  MoodTrackerView.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Günlük mood tracking view - Redesigned with modern UI/UX
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
            VStack(spacing: Spacing.xlarge) {
                // [1] Hero Mood Banner
                heroMoodBanner

                // [2] Quick Stats Bar
                quickStatsBar

                // [3] Mood Timeline (if has moods) OR Empty State
                if !viewModel.todaysMoods.isEmpty {
                    moodTimelineSection
                } else {
                    emptyMoodState
                }

                // [4] Recent Moods Grid (geçmiş günler)
                if !viewModel.moodEntries.isEmpty {
                    recentMoodsSection
                }
            }
            .padding(.vertical, Spacing.large)
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingMoodPicker) {
            moodPickerSheet
                .onAppear {
                    // Edit mode ise mevcut değerleri doldur
                    if let editing = viewModel.editingMoodEntry {
                        selectedMood = editing.moodType
                        intensity = editing.intensity
                        note = editing.note ?? ""
                    } else {
                        // Yeni mood ise varsayılan değerler
                        selectedMood = .happy
                        intensity = 3
                        note = ""
                    }
                }
        }
    }

    // MARK: - [1] Hero Mood Banner

    private var heroMoodBanner: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.micro) {
                    Text(String(localized: "mood.todays.mood", comment: "Today's Mood"))
                        .font(.title3)
                        .fontWeight(.bold)

                    HStack(spacing: Spacing.micro) {
                        if !viewModel.todaysMoods.isEmpty {
                            Text(String(format: NSLocalizedString("mood.records.format", comment: "records count"), viewModel.todaysMoods.count))
                                .metadataText()

                            Circle()
                                .fill(.secondary.opacity(0.4))
                                .frame(width: 3, height: 3)

                            Text(String(format: NSLocalizedString("mood.average.format", comment: "Average"), viewModel.todaysMoodAverage))
                                .metadataText()
                        } else {
                            Text(String(localized: "mood.no.records.yet", comment: "No records yet"))
                                .metadataText()
                        }
                    }
                }

                Spacer()

                // Add Button
                addMoodButton
            }
            .padding(.horizontal, Spacing.large)

            // Content: Timeline or Empty
            if !viewModel.todaysMoods.isEmpty {
                // Timeline ScrollView
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.medium) {
                        ForEach(Array(viewModel.todaysMoods.enumerated()), id: \.element.id) { index, mood in
                            MoodTimelineCard(
                                mood: mood,
                                isLatest: index == 0,
                                onEdit: {
                                    viewModel.startEditingMood(mood)
                                    showingMoodPicker = true
                                },
                                onDelete: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        viewModel.deleteMood(mood, context: modelContext)
                                    }
                                }
                            )
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                        }
                    }
                    .padding(.horizontal, Spacing.large)
                }
                .frame(height: 200)
            } else {
                // Empty Hero State
                heroEmptyState
                    .padding(.horizontal, Spacing.large)
            }
        }
        .padding(.vertical, Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.CornerRadius.large, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.brandPrimary.opacity(0.08),
                            Color.purple.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.CornerRadius.large, style: .continuous)
                .strokeBorder(.white.opacity(0.5), lineWidth: 1)
        )
        .padding(.horizontal, Spacing.large)
    }

    // Hero Empty State
    private var heroEmptyState: some View {
        VStack(spacing: Spacing.large) {
            // Large Emoji
            Text("😊")
                .font(.system(size: 80))
                .scaleEffect(1.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).repeatForever(autoreverses: true), value: viewModel.todaysMoods.count)

            VStack(spacing: Spacing.small) {
                Text(String(localized: "mood.add.first.record", comment: "Add first record"))
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(String(localized: "mood.track.mood", comment: "Track your mood"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                HapticFeedback.medium()
                showingMoodPicker = true
            } label: {
                HStack(spacing: Spacing.small) {
                    Image(systemName: "plus.circle.fill")
                    Text(String(localized: "mood.add.first.record.button", comment: "Add First Record"))
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, Spacing.xlarge)
                .padding(.vertical, Spacing.medium)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.brandPrimary, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: .brandPrimary.opacity(0.4), radius: 12, y: 4)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 240)
    }

    // Add Mood Button
    private var addMoodButton: some View {
        Button {
            if viewModel.canAddMood {
                HapticFeedback.medium()
                showingMoodPicker = true
            } else {
                HapticFeedback.warning()
            }
        } label: {
            HStack(spacing: Spacing.small) {
                Image(systemName: viewModel.canAddMood ? "plus.circle.fill" : "exclamationmark.circle.fill")
                    .font(.title3)
            }
            .foregroundStyle(viewModel.canAddMood ? Color.brandPrimary : Color.secondary)
            .padding(Spacing.small)
            .background(
                Circle()
                    .fill(viewModel.canAddMood ? Color.brandPrimary.opacity(0.15) : Color.gray.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canAddMood)
    }

    // MARK: - [2] Quick Stats Bar

    private var quickStatsBar: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text(String(localized: "mood.statistics", comment: "Statistics"))
                .cardTitle()
                .padding(.horizontal, Spacing.large)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.medium) {
                    // Bugün Ortalama (sadece mood varsa)
                    if !viewModel.todaysMoods.isEmpty {
                        AnimatedStatCard(
                            title: String(localized: "mood.today.avg", comment: "Today Avg."),
                            value: viewModel.todaysMoodAverage,
                            icon: "calendar.badge.clock",
                            color: .purple,
                            format: "%.1f"
                        )
                    }

                    AnimatedStatCard(
                        title: "Streak",
                        value: Double(viewModel.streakData.currentStreak),
                        icon: "flame.fill",
                        color: .orange,
                        format: "%.0f"
                    )

                    AnimatedStatCard(
                        title: String(localized: "mood.general.avg", comment: "General Avg."),
                        value: viewModel.moodStats.averageMood,
                        icon: "star.fill",
                        color: .brandPrimary,
                        format: "%.1f"
                    )

                    AnimatedStatCard(
                        title: String(localized: "mood.this.week", comment: "This Week"),
                        value: Double(viewModel.moodCountThisWeek),
                        icon: "calendar",
                        color: .blue,
                        format: "%.0f"
                    )
                }
                .padding(.horizontal, Spacing.large)
            }
        }
    }

    // MARK: - [3] Mood Timeline Section

    private var moodTimelineSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack {
                Text(String(localized: "mood.todays.flow", comment: "Today's Flow"))
                    .cardTitle()

                Spacer()

                Text("\(viewModel.todaysMoods.count)/5")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Spacing.small)
                    .padding(.vertical, Spacing.micro)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
            }
            .padding(.horizontal, Spacing.large)

            // Timeline List
            VStack(spacing: Spacing.small) {
                ForEach(viewModel.todaysMoods) { mood in
                    MoodTimelineRow(mood: mood)
                }
            }
            .padding(.horizontal, Spacing.large)
        }
    }

    // MARK: - [3] Empty Mood State (Alternative)

    private var emptyMoodState: some View {
        VStack(spacing: Spacing.large) {
            Image(systemName: "face.smiling")
                .font(.system(size: 60))
                .foregroundStyle(.secondary.opacity(0.5))

            VStack(spacing: Spacing.small) {
                Text(String(localized: "mood.start.tracking", comment: "Start tracking"))
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(String(localized: "mood.track.daily.emotions", comment: "Track daily emotions"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xlarge)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.CornerRadius.large, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.CornerRadius.large, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
        .padding(.horizontal, Spacing.large)
    }

    // MARK: - [4] Recent Moods Section

    private var recentMoodsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack {
                Text(String(localized: "mood.past.records", comment: "Past Records"))
                    .cardTitle()

                Spacer()

                Text(String(format: NSLocalizedString("mood.total.format", comment: "total"), viewModel.moodEntries.count))
                    .metadataText()
            }
            .padding(.horizontal, Spacing.large)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Spacing.medium),
                GridItem(.flexible(), spacing: Spacing.medium)
            ], spacing: Spacing.medium) {
                ForEach(Array(viewModel.moodEntries.prefix(6).enumerated()), id: \.element.id) { index, mood in
                    if !mood.isToday { // Bugünkiler zaten yukarıda
                        CompactMoodCard(mood: mood)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .padding(.horizontal, Spacing.large)
        }
    }

    // MARK: - Mood Picker Sheet

    private var moodPickerSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xxlarge) {
                    // Emoji Picker
                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        Text(String(localized: "mood.how.feeling", comment: "How are you feeling?"))
                            .cardTitle()

                        MoodEmojiPicker(selectedMood: $selectedMood)
                    }

                    // Intensity Slider
                    MoodIntensitySlider(intensity: $intensity, selectedMood: selectedMood)

                    // Note
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text(String(localized: "mood.note.optional", comment: "Note (Optional)"))
                            .font(.subheadline)
                            .fontWeight(.medium)

                        TextField(String(localized: "mood.whats.happening.placeholder", comment: "What happened today?"), text: $note, axis: .vertical)
                            .textFieldStyle(.plain)
                            .lineLimit(3...5)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.normal)
                                    .fill(Color(.tertiarySystemBackground))
                            )
                    }
                }
                .padding(Spacing.large)
            }
            .navigationTitle(viewModel.editingMoodEntry != nil ? String(localized: "mood.edit.mood", comment: "Edit Mood") : String(localized: "mood.record.title", comment: "Record Mood"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel", comment: "Cancel")) {
                        showingMoodPicker = false
                        viewModel.editingMoodEntry = nil
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.editingMoodEntry != nil ? String(localized: "common.update", comment: "Update") : String(localized: "common.save", comment: "Save")) {
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
        if let editing = viewModel.editingMoodEntry {
            // Update existing
            viewModel.updateMood(
                editing,
                moodType: selectedMood,
                intensity: intensity,
                note: note.isEmpty ? nil : note,
                context: modelContext
            )
            viewModel.editingMoodEntry = nil
        } else {
            // Create new
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                viewModel.logMood(
                    moodType: selectedMood,
                    intensity: intensity,
                    note: note.isEmpty ? nil : note,
                    context: modelContext
                )
            }
        }

        showingMoodPicker = false

        // Reset
        note = ""
        intensity = 3
    }
}

// MARK: - Supporting Views

/// Mood Timeline Card (Hero section için)
struct MoodTimelineCard: View {
    let mood: MoodEntry
    var isLatest: Bool = false
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    @State private var showDeleteConfirm: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // Header
            HStack(alignment: .top) {
                Text(mood.moodType.emoji)
                    .font(.system(size: isLatest ? 56 : 40))

                Spacer()

                // Actions (sadece latest için)
                if isLatest {
                    Menu {
                        Button {
                            onEdit?()
                        } label: {
                            Label(String(localized: "mood.edit", comment: "Edit"), systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label(String(localized: "mood.delete", comment: "Delete"), systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Info
            VStack(alignment: .leading, spacing: Spacing.micro) {
                Text(mood.moodType.displayName)
                    .font(isLatest ? .title3 : .headline)
                    .fontWeight(.bold)

                Text(timeString(for: mood.date))
                    .font(.callout)
                    .foregroundStyle(.secondary)

                // Intensity
                HStack(spacing: 3) {
                    ForEach(1...5, id: \.self) { index in
                        Circle()
                            .fill(index <= mood.intensity ? mood.moodType.color : Color.gray.opacity(0.2))
                            .frame(width: isLatest ? 7 : 6, height: isLatest ? 7 : 6)
                    }
                }
                .padding(.top, Spacing.micro)
            }

            // Note (sadece latest için)
            if isLatest, let note = mood.note, !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(isLatest ? Spacing.large : Spacing.medium)
        .frame(width: isLatest ? 170 : 140, height: 200)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.CornerRadius.large, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            mood.moodType.color.opacity(isLatest ? 0.2 : 0.12),
                            mood.moodType.color.opacity(isLatest ? 0.1 : 0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.CornerRadius.large, style: .continuous)
                .strokeBorder(mood.moodType.color.opacity(isLatest ? 0.6 : 0.4), lineWidth: isLatest ? 2 : 1)
        )
        .shadow(
            color: isLatest ? mood.moodType.color.opacity(0.25) : .clear,
            radius: 16,
            y: 6
        )
        .alert(String(localized: "mood.delete.mood", comment: "Delete Mood"), isPresented: $showDeleteConfirm) {
            Button(String(localized: "common.cancel", comment: "Cancel"), role: .cancel) { }
            Button(String(localized: "mood.delete", comment: "Delete"), role: .destructive) {
                onDelete?()
            }
        } message: {
            Text(String(localized: "mood.delete.confirmation", comment: "Delete confirmation"))
        }
    }

    private func timeString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
}

/// Mood Timeline Row (Bugünün akışı için)
struct MoodTimelineRow: View {
    let mood: MoodEntry

    var body: some View {
        HStack(spacing: Spacing.medium) {
            // Time
            Text(timeString(for: mood.date))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .leading)

            // Connector
            VStack(spacing: 0) {
                Circle()
                    .fill(mood.moodType.color)
                    .frame(width: 12, height: 12)

                Rectangle()
                    .fill(mood.moodType.color.opacity(0.3))
                    .frame(width: 2)
            }

            // Content
            HStack(spacing: Spacing.medium) {
                Text(mood.moodType.emoji)
                    .font(.title2)

                VStack(alignment: .leading, spacing: Spacing.micro) {
                    HStack(spacing: Spacing.small) {
                        Text(mood.moodType.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        // Intensity dots
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { index in
                                Circle()
                                    .fill(index <= mood.intensity ? mood.moodType.color : Color.gray.opacity(0.2))
                                    .frame(width: 4, height: 4)
                            }
                        }
                    }

                    if let note = mood.note, !note.isEmpty {
                        Text(note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }
            .padding(.vertical, Spacing.small)
            .padding(.horizontal, Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.normal, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.normal, style: .continuous)
                    .strokeBorder(mood.moodType.color.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private func timeString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
}

/// Animated Stat Card (Sayı animasyonlu)
struct AnimatedStatCard: View {
    let title: String
    let value: Double
    let icon: String
    let color: Color
    let format: String

    @State private var displayValue: Double = 0.0

    var body: some View {
        VStack(spacing: Spacing.small) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(String(format: format, displayValue))
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .contentTransition(.numericText(value: displayValue))

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(width: 90, height: 90)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.normal, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.normal, style: .continuous)
                .strokeBorder(color.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1)) {
                displayValue = value
            }
        }
        .onChange(of: value) { oldValue, newValue in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                displayValue = newValue
            }
        }
    }
}

#Preview {
    MoodTrackerView(viewModel: MoodJournalViewModel())
        .modelContainer(for: [MoodEntry.self, JournalEntry.self])
}

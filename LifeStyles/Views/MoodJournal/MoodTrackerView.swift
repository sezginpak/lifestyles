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

                // [3] Timeline View (Tüm mood'lar)
                if !viewModel.moodEntries.isEmpty {
                    timelineSection
                } else {
                    emptyMoodState
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

    // MARK: - [1] Hero Mood Banner (Modern Redesign)

    private var heroMoodBanner: some View {
        VStack(alignment: .leading, spacing: Spacing.large) {
            // Modern Header with Gradient
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    // Animated title
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.title3)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .symbolEffect(.bounce, value: viewModel.todaysMoods.count)

                        Text(String(localized: "mood.todays.mood", comment: "Today's Mood"))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.primary, .primary.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }

                    // Stats badges
                    if !viewModel.todaysMoods.isEmpty {
                        HStack(spacing: 8) {
                            // Kayıt sayısı badge
                            HStack(spacing: 4) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundStyle(Color.brandPrimary)
                                Text(String(localized: "mood.record.count", defaultValue: "\(viewModel.todaysMoods.count) records", comment: "Mood records"))
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(Color.brandPrimary.opacity(0.15))
                            )

                            // Ortalama badge
                            HStack(spacing: 4) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 10))
                                Text(String(format: "%.1f", viewModel.todaysMoodAverage))
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(.purple.opacity(0.15))
                            )
                            .foregroundStyle(.purple)
                        }
                    } else {
                        Text(String(localized: "mood.no.records.yet", comment: "No records yet"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Enhanced Add Button
                modernAddButton
            }
            .padding(.horizontal, Spacing.large)
            .padding(.top, Spacing.medium)

            // Content: Modern Timeline or Empty
            if !viewModel.todaysMoods.isEmpty {
                // Latest mood HERO card
                if let latestMood = viewModel.todaysMoods.first {
                    modernLatestMoodCard(mood: latestMood)
                        .padding(.horizontal, Spacing.large)
                }

                // Previous moods - compact horizontal
                if viewModel.todaysMoods.count > 1 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "mood.previous.records", comment: "Previous Records"))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, Spacing.large)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(viewModel.todaysMoods.dropFirst().enumerated()), id: \.element.id) { index, mood in
                                    compactMoodCard(mood: mood)
                                }
                            }
                            .padding(.horizontal, Spacing.large)
                        }
                    }
                }
            } else {
                // Enhanced Empty State
                modernEmptyState
                    .padding(.horizontal, Spacing.large)
            }
        }
        .padding(.vertical, Spacing.large)
        .background(
            ZStack {
                // Dynamic gradient based on mood
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Glassmorphism overlay
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(0.7)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.6), .white.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
        .padding(.horizontal, Spacing.large)
    }

    // Dynamic gradient based on latest mood
    private var gradientColors: [Color] {
        guard let latestMood = viewModel.todaysMoods.first else {
            return [Color.brandPrimary.opacity(0.1), Color.purple.opacity(0.05)]
        }

        let baseColor = latestMood.moodType.color
        return [
            baseColor.opacity(0.15),
            baseColor.opacity(0.05),
            Color.clear
        ]
    }

    // MARK: - Modern Latest Mood Card

    private func modernLatestMoodCard(mood: MoodEntry) -> some View {
        HStack(spacing: 16) {
            // Giant emoji (animation kaldırıldı - performance için)
            Text(mood.moodType.emoji)
                .font(.system(size: 72))
                .shadow(color: mood.moodType.color.opacity(0.3), radius: 10)

            VStack(alignment: .leading, spacing: 8) {
                // Mood name
                Text(mood.moodType.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(mood.moodType.color)

                // Time
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                    Text(timeString(for: mood.date))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.secondary)

                // Intensity visualization
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(index <= mood.intensity ? mood.moodType.color : Color.gray.opacity(0.2))
                            .frame(width: 30, height: 6)
                    }
                }

                // Note preview
                if let note = mood.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .padding(.top, 4)
                }
            }

            Spacer()

            // Action menu
            Menu {
                Button {
                    viewModel.startEditingMood(mood)
                    showingMoodPicker = true
                } label: {
                    Label(String(localized: "button.edit", comment: "Edit button"), systemImage: "pencil")
                }

                Button(role: .destructive) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        viewModel.deleteMood(mood, context: modelContext)
                    }
                } label: {
                    Label(String(localized: "button.delete", comment: "Delete button"), systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.title2)
                    .foregroundStyle(mood.moodType.color.opacity(0.7))
                    .padding(8)
                    .background(
                        Circle()
                            .fill(mood.moodType.color.opacity(0.15))
                    )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(mood.moodType.color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(mood.moodType.color.opacity(0.3), lineWidth: 1.5)
                )
        )
    }

    // MARK: - Compact Mood Card (for previous moods)

    private func compactMoodCard(mood: MoodEntry) -> some View {
        VStack(spacing: 8) {
            Text(mood.moodType.emoji)
                .font(.system(size: 40))

            Text(timeString(for: mood.date))
                .font(.caption2)
                .foregroundStyle(.secondary)

            // Intensity dots
            HStack(spacing: 3) {
                ForEach(1...5, id: \.self) { index in
                    Circle()
                        .fill(index <= mood.intensity ? mood.moodType.color : Color.gray.opacity(0.2))
                        .frame(width: 5, height: 5)
                }
            }
        }
        .frame(width: 80)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(mood.moodType.color.opacity(0.3), lineWidth: 1)
                )
        )
        .onTapGesture {
            viewModel.startEditingMood(mood)
            showingMoodPicker = true
        }
    }

    // MARK: - Modern Empty State

    private var modernEmptyState: some View {
        VStack(spacing: 20) {
            // Animated emoji
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.brandPrimary.opacity(0.2), .purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Text("😊")
                    .font(.system(size: 60))
                    .scaleEffect(1.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).repeatForever(autoreverses: true), value: viewModel.todaysMoods.count)
            }

            VStack(spacing: 8) {
                Text(String(localized: "mood.how.feeling", comment: "How are you feeling today?"))
                    .font(.title3)
                    .fontWeight(.bold)

                Text(String(localized: "mood.first.prompt", comment: "Create your first mood record"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
    }

    // MARK: - Modern Add Button

    private var modernAddButton: some View {
        Button {
            if viewModel.canAddMood {
                HapticFeedback.medium()
                showingMoodPicker = true
            } else {
                HapticFeedback.warning()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: viewModel.canAddMood ? "plus.circle.fill" : "exclamationmark.circle.fill")
                    .font(.title3)
                Text(viewModel.canAddMood ? "Ekle" : "Limit")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(
                        viewModel.canAddMood
                        ? LinearGradient(
                            colors: [.brandPrimary, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        : LinearGradient(
                            colors: [.gray, .gray.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(
                color: viewModel.canAddMood ? .brandPrimary.opacity(0.4) : .clear,
                radius: 10,
                y: 4
            )
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canAddMood)
    }

    private func timeString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }


    // MARK: - [2] Modern Stats Grid (Redesigned)

    private var quickStatsBar: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with gradient
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text(String(localized: "mood.statistics", comment: "Statistics"))
                    .font(.title3)
                    .fontWeight(.bold)

                Spacer()

                // Haftalık trend badge
                HStack(spacing: 4) {
                    Image(systemName: getTrendIcon())
                        .font(.caption)
                    Text(getTrendText())
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(getTrendColor())
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(getTrendColor().opacity(0.15))
                )
            }
            .padding(.horizontal, Spacing.large)

            // Stats Grid - 2x2
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                // 1. Bugün Ortalama
                if !viewModel.todaysMoods.isEmpty {
                    modernStatCard(
                        title: "Bugün",
                        value: String(format: "%.1f", viewModel.todaysMoodAverage),
                        subtitle: "\(viewModel.todaysMoods.count) kayıt",
                        icon: "sun.max.fill",
                        gradient: [.orange, .pink],
                        progress: viewModel.todaysMoodAverage / 5.0
                    )
                }

                // 2. Streak
                modernStatCard(
                    title: "Seri",
                    value: "\(viewModel.streakData.currentStreak)",
                    subtitle: "gün",
                    icon: "flame.fill",
                    gradient: [.orange, .red],
                    progress: Double(min(viewModel.streakData.currentStreak, 30)) / 30.0,
                    showProgress: viewModel.streakData.currentStreak > 0
                )

                // 3. Genel Ortalama
                modernStatCard(
                    title: "Ortalama",
                    value: String(format: "%.1f", viewModel.moodStats.averageMood),
                    subtitle: "genel",
                    icon: "star.fill",
                    gradient: [.purple, .blue],
                    progress: viewModel.moodStats.averageMood / 5.0
                )

                // 4. Bu Hafta
                modernStatCard(
                    title: "Bu Hafta",
                    value: "\(viewModel.moodCountThisWeek)",
                    subtitle: "kayıt",
                    icon: "calendar.badge.clock",
                    gradient: [.blue, .cyan],
                    progress: Double(viewModel.moodCountThisWeek) / 21.0, // Max 3/gün × 7
                    showProgress: viewModel.moodCountThisWeek > 0
                )
            }
            .padding(.horizontal, Spacing.large)
        }
    }

    // MARK: - Modern Stat Card

    private func modernStatCard(
        title: String,
        value: String,
        subtitle: String,
        icon: String,
        gradient: [Color],
        progress: Double? = nil,
        showProgress: Bool = true
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon with gradient background
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradient.map { $0.opacity(0.2) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Spacer()
            }

            // Value
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fontWeight(.medium)
            }

            // Title
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            // Progress bar (optional)
            if showProgress, let progressValue = progress, progressValue > 0 {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 6)

                        // Progress
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: gradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * min(progressValue, 1.0), height: 6)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progressValue)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 160)
        .background(
            ZStack {
                // Gradient background
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: gradient.map { $0.opacity(0.08) } + [Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Glassmorphism
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(0.5)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: gradient.map { $0.opacity(0.3) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: gradient.first!.opacity(0.15), radius: 10, y: 5)
    }

    // MARK: - Trend Helpers

    private func getTrendIcon() -> String {
        let thisWeek = viewModel.moodCountThisWeek
        // Basit mantık: haftalık kayıt sayısına göre
        if thisWeek >= 14 { return "arrow.up.right" }
        if thisWeek >= 7 { return "arrow.right" }
        return "arrow.down.right"
    }

    private func getTrendText() -> String {
        let thisWeek = viewModel.moodCountThisWeek
        if thisWeek >= 14 { return "Harika" }
        if thisWeek >= 7 { return "İyi" }
        return "Başlangıç"
    }

    private func getTrendColor() -> Color {
        let thisWeek = viewModel.moodCountThisWeek
        if thisWeek >= 14 { return .green }
        if thisWeek >= 7 { return .blue }
        return .orange
    }

    // MARK: - [3] Timeline Section (Yeni Modern Timeline)

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack {
                Text(String(localized: "mood.timeline", comment: "Mood Timeline"))
                    .cardTitle()

                Spacer()

                Text(String(format: NSLocalizedString("mood.total.format", comment: "total"), viewModel.moodEntries.count))
                    .metadataText()
            }
            .padding(.horizontal, Spacing.large)

            // TimelineMoodView entegrasyonu
            TimelineMoodView(
                moodEntries: viewModel.moodEntries,
                onEdit: { mood in
                    viewModel.startEditingMood(mood)
                    showingMoodPicker = true
                },
                onDelete: { mood in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        viewModel.deleteMood(mood, context: modelContext)
                    }
                },
                onRefresh: {
                    // Refresh logic (SwiftData otomatik refresh yapar, ama gerekirse eklenebilir)
                }
            )
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

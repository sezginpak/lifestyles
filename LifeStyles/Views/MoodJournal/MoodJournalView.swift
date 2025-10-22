//
//  MoodJournalView.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Ana mood & journal container
//

import SwiftUI
import SwiftData

struct MoodJournalView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = MoodJournalViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented Control
                Picker("Tab", selection: $viewModel.selectedTab) {
                    ForEach(MoodJournalViewModel.Tab.allCases, id: \.self) { tab in
                        Label(tab.rawValue, systemImage: tab.icon)
                            .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                TabView(selection: $viewModel.selectedTab) {
                    MoodTrackerView(viewModel: viewModel)
                        .tag(MoodJournalViewModel.Tab.mood)

                    JournalListView(viewModel: viewModel)
                        .tag(MoodJournalViewModel.Tab.journal)

                    MoodAnalyticsView(viewModel: viewModel)
                        .tag(MoodJournalViewModel.Tab.analytics)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle(String(localized: "mood.journal.title", comment: "Mood & Journal"))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.loadAllData(context: modelContext)
            }
        }
    }
}

// MARK: - Journal List View (Modern) ✨

struct JournalListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.toastManager) private var toastManager
    @Bindable var viewModel: MoodJournalViewModel

    var body: some View {
        Group {
            if viewModel.filteredJournalEntries.isEmpty {
                MoodEmptyState(
                    icon: "book.fill",
                    title: String(localized: "journal.empty.title", comment: "No journal entries yet"),
                    message: String(localized: "journal.empty.message", comment: "Start by writing your first journal entry"),
                    actionLabel: String(localized: "journal.write.button", comment: "Write Journal"),
                    action: {
                        viewModel.showingJournalEditor = true
                    }
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(viewModel.filteredJournalEntries.enumerated()), id: \.element.id) { index, entry in
                            modernJournalCard(entry)
                                .transition(.scale.combined(with: .opacity))
                                .onAppear {
                                    // Stagger animation
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75).delay(Double(index) * 0.05)) {}
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteWithFeedback(entry)
                                    } label: {
                                        Label("Sil", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        toggleFavoriteWithFeedback(entry)
                                    } label: {
                                        Label(entry.isFavorite ? String(localized: "journal.unfavorite", comment: "Remove from favorites") : String(localized: "journal.favorite", comment: "Add to favorites"), systemImage: entry.isFavorite ? "star.fill" : "star")
                                    }
                                    .tint(.yellow)
                                }
                                .contextMenu {
                                    Button {
                                        viewModel.startEditingJournal(entry)
                                    } label: {
                                        Label(String(localized: "common.edit", comment: "Edit"), systemImage: "pencil")
                                    }

                                    Button {
                                        toggleFavoriteWithFeedback(entry)
                                    } label: {
                                        Label(entry.isFavorite ? String(localized: "journal.unfavorite", comment: "Remove from favorites") : String(localized: "journal.favorite", comment: "Add to favorites"), systemImage: entry.isFavorite ? "star.fill" : "star")
                                    }

                                    Divider()

                                    Button(role: .destructive) {
                                        deleteWithFeedback(entry)
                                    } label: {
                                        Label(String(localized: "common.delete", comment: "Delete"), systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    HapticFeedback.medium()
                    viewModel.showingJournalEditor = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.brandPrimary, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
        }
        .sheet(isPresented: $viewModel.showingJournalEditor) {
            JournalEditorView(viewModel: viewModel)
        }
    }

    // MARK: - Modern Card

    private func modernJournalCard(_ entry: JournalEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            journalCardHeader(entry)

            // Title
            if let title = entry.title {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            // Preview
            Text(entry.preview)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            // Tags
            if !entry.tags.isEmpty {
                journalTags(entry.tags)
            }

            // Footer
            journalCardFooter(entry)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(entry.journalType.color.opacity(0.2), lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    private func journalCardHeader(_ entry: JournalEntry) -> some View {
        HStack {
            JournalTypePill(journalType: entry.journalType, showIcon: true)
            Spacer()
            if entry.isFavorite {
                Image(systemName: "star.fill").font(.caption).foregroundStyle(.yellow)
            }
            Text("\(entry.wordCount)").font(.caption).monospacedDigit().foregroundStyle(.secondary)
        }
    }

    private func journalTags(_ tags: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(tags.prefix(3), id: \.self) { tag in
                    Text("#\(tag)").font(.caption2).padding(.horizontal, 8).padding(.vertical, 4).background(Capsule().fill(Color.brandPrimary.opacity(0.1)))
                }
            }
        }
    }

    private func journalCardFooter(_ entry: JournalEntry) -> some View {
        HStack {
            Text(entry.formattedDate).font(.caption2).foregroundStyle(.tertiary)
            Spacer()
            Text(String(format: NSLocalizedString("journal.reading.time.format", comment: "X minutes reading time"), entry.estimatedReadingTime)).font(.caption2).foregroundStyle(.tertiary)
        }
    }

    // MARK: - Actions with Feedback

    private func deleteWithFeedback(_ entry: JournalEntry) {
        HapticFeedback.warning()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            viewModel.deleteJournalEntry(entry, context: modelContext)
        }

        toastManager.warning(
            title: "Journal Silindi",
            message: "Journal başarıyla silindi",
            emoji: "🗑️"
        )
    }

    private func toggleFavoriteWithFeedback(_ entry: JournalEntry) {
        let wasFavorite = entry.isFavorite

        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            viewModel.toggleFavorite(entry, context: modelContext)
        }

        HapticFeedback.success()

        toastManager.success(
            title: wasFavorite ? "Favoriden Çıkarıldı" : "Favorilere Eklendi",
            message: wasFavorite ? "Journal favorilerden çıkarıldı" : "Journal favorilere eklendi",
            emoji: wasFavorite ? "⭐" : "⭐"
        )
    }
}

// MARK: - Journal Editor (Modern) ✨

struct JournalEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.toastManager) private var toastManager
    @Bindable var viewModel: MoodJournalViewModel

    @State private var selectedType: JournalType = .general
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedTags: [String] = []
    @State private var linkToMood: Bool = false
    @State private var isSaving: Bool = false

    // Edit mode check
    private var isEditMode: Bool {
        viewModel.editingJournalEntry != nil
    }

    private var isValid: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Journal Type Selector (Compact Dropdown)
                    journalTypeDropdown
                        .onChange(of: selectedType) { _, newType in
                            viewModel.loadTagSuggestions(for: newType, existingTags: selectedTags)
                            HapticFeedback.light()
                        }

                    // Title (Optional) - Glassmorphism
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "journal.title.label", comment: "Title"))
                            .font(.title3)
                            .fontWeight(.bold)

                        TextField(String(localized: "journal.title.placeholder", comment: "Add title (optional)"), text: $title)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(.ultraThinMaterial)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                Color.gray.opacity(0.2),
                                                Color.gray.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    }

                    // Content - Modern Text Editor
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "journal.content.label", comment: "Content"))
                            .font(.title3)
                            .fontWeight(.bold)

                        ModernTextEditor(
                            text: $content,
                            placeholder: selectedType.aiPrompt,
                            minHeight: 250,
                            showCounter: true,
                            maxCharacters: 5000
                        )
                    }

                    // Tag Picker (Modern Pills)
                    TagPickerView(
                        selectedTags: $selectedTags,
                        suggestions: viewModel.tagSuggestions,
                        allEntries: viewModel.journalEntries
                    )

                    // Link to today's mood (Modern Toggle)
                    if viewModel.todaysMood != nil && !isEditMode {
                        moodLinkSection
                    }

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle(isEditMode ? String(localized: "journal.edit.title", comment: "Edit Journal") : String(localized: "journal.write.title", comment: "Write Journal"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        HapticFeedback.light()
                        cleanup()
                        dismiss()
                    } label: {
                        Text(String(localized: "common.cancel", comment: "Cancel"))
                            .fontWeight(.medium)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    saveButton
                }
            }
            .onAppear {
                setupEditor()
            }
        }
    }

    // MARK: - Subviews

    private var journalTypeDropdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "journal.type.label", comment: "Journal Type"))
                .font(.title3)
                .fontWeight(.bold)

            Menu {
                ForEach(JournalType.allCases, id: \.self) { type in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedType = type
                        }
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(type.emoji) \(type.displayName)")
                                    .fontWeight(.medium)
                                Text(type.aiPrompt)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            if selectedType == type {
                                Image(systemName: "checkmark.circle.fill")
                            } else {
                                Image(systemName: type.icon)
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    // Icon Circle
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        selectedType.color.opacity(0.9),
                                        selectedType.color.opacity(0.7)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)

                        Image(systemName: selectedType.icon)
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }

                    // Selected Type Info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(selectedType.emoji)
                                .font(.body)
                            Text(selectedType.displayName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.primary)

                        Text(selectedType.aiPrompt)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            selectedType.color.opacity(0.3),
                            lineWidth: 1
                        )
                )
            }
        }
    }

    private var moodLinkSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $linkToMood) {
                HStack(spacing: 12) {
                    Text(viewModel.todaysMood?.moodType.emoji ?? "😊")
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "journal.link.to.mood", comment: "Link to today's mood"))
                            .font(.subheadline)
                            .fontWeight(.medium)

                        if let mood = viewModel.todaysMood {
                            Text(mood.moodType.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .tint(.brandPrimary)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.brandPrimary.opacity(0.3), lineWidth: 1)
            )
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: linkToMood)
    }

    private var saveButton: some View {
        Button {
            saveJournal()
        } label: {
            HStack(spacing: 6) {
                if isSaving {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: isEditMode ? "checkmark" : "plus")
                }

                Text(isEditMode ? String(localized: "common.update", comment: "Update") : String(localized: "common.save", comment: "Save"))
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: isValid && !isSaving ? [
                                Color.brandPrimary,
                                Color.purple
                            ] : [
                                Color.gray.opacity(0.5),
                                Color.gray.opacity(0.3)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(
                color: isValid ? Color.brandPrimary.opacity(0.3) : .clear,
                radius: 8,
                y: 2
            )
        }
        .disabled(!isValid || isSaving)
        .buttonStyle(.plain)
    }

    // MARK: - Helper Methods

    private func setupEditor() {
        if let entry = viewModel.editingJournalEntry {
            // Edit mode - populate fields
            selectedType = entry.journalType
            title = entry.title ?? ""
            content = entry.content
            selectedTags = entry.tags
        }
        viewModel.loadTagSuggestions(for: selectedType, existingTags: selectedTags)
    }

    private func saveJournal() {
        guard !isSaving else { return }

        isSaving = true
        HapticFeedback.medium()

        Task {
            // Simulate save delay for animation
            try? await Task.sleep(nanoseconds: 500_000_000)

            await MainActor.run {
                if let entry = viewModel.editingJournalEntry {
                    // Update existing
                    viewModel.updateJournalEntry(
                        entry,
                        title: title.isEmpty ? nil : title,
                        content: content,
                        tags: selectedTags,
                        context: modelContext
                    )

                    // Success toast
                    toastManager.success(
                        title: "Journal Güncellendi",
                        message: "Değişiklikler kaydedildi",
                        emoji: "✏️"
                    )
                } else {
                    // Create new
                    viewModel.createJournalEntry(
                        content: content,
                        journalType: selectedType,
                        title: title.isEmpty ? nil : title,
                        tags: selectedTags,
                        linkToTodaysMood: linkToMood,
                        context: modelContext
                    )

                    // Success toast
                    toastManager.success(
                        title: "Journal Kaydedildi",
                        message: "\(selectedType.emoji) \(selectedType.displayName) journal'ı oluşturuldu",
                        emoji: "📝"
                    )
                }

                isSaving = false
                cleanup()

                // Delay dismiss for toast
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    dismiss()
                }
            }
        }
    }

    private func cleanup() {
        viewModel.editingJournalEntry = nil
    }
}

// MARK: - Analytics View (Basit)

struct MoodAnalyticsView: View {
    @Bindable var viewModel: MoodJournalViewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Streak Widget
                if viewModel.streakData.currentStreak > 0 {
                    MoodStreakWidget(streakData: viewModel.streakData)
                }

                // Stats Cards
                statsSection

                // Full Heatmap Calendar
                MoodHeatmapCalendar(
                    heatmapData: viewModel.heatmapData,
                    month: Date()
                )

                // Correlations
                MoodCorrelationsView(
                    goalCorrelations: viewModel.moodCorrelation.goalCorrelations,
                    friendCorrelations: viewModel.moodCorrelation.friendCorrelations,
                    locationCorrelations: viewModel.locationCorrelations
                )

                // AI Insight (iOS 26+)
                if #available(iOS 26.0, *) {
                    aiInsightSection
                }
            }
            .padding()
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("İstatistikler")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MoodStatCard(
                    title: "Ortalama Mood",
                    value: String(format: "%.1f", viewModel.moodStats.averageMood),
                    icon: "chart.line.uptrend.xyaxis",
                    color: .purple,
                    trend: viewModel.moodStats.moodTrend.emoji
                )

                MoodStatCard(
                    title: "Pozitif Günler",
                    value: "\(viewModel.moodStats.positiveCount)",
                    icon: "face.smiling",
                    color: .green,
                    trend: "\(Int(viewModel.moodStats.positivePercentage))%"
                )

                MoodStatCard(
                    title: "Bu Hafta",
                    value: "\(viewModel.moodCountThisWeek)",
                    icon: "calendar",
                    color: .blue,
                    trend: nil
                )

                MoodStatCard(
                    title: "Journal",
                    value: "\(viewModel.journalCountThisMonth)",
                    icon: "book.fill",
                    color: .orange,
                    trend: nil
                )
            }
        }
    }

    @available(iOS 26.0, *)
    private var aiInsightSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Analiz")
                .font(.headline)

            if viewModel.isLoadingAI {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if let insight = viewModel.aiInsight {
                VStack(alignment: .leading, spacing: 12) {
                    Text(insight.summary)
                        .font(.callout)
                        .fontWeight(.medium)

                    ForEach(insight.suggestions, id: \.self) { suggestion in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)

                            Text(suggestion)
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.purple.opacity(0.1))
                )
            } else {
                Button("Haftalık Analiz Oluştur") {
                    Task {
                        await viewModel.generateWeeklyAnalysis(context: modelContext)
                    }
                }
            }
        }
    }
}

#Preview {
    MoodJournalView()
        .modelContainer(for: [MoodEntry.self, JournalEntry.self])
}

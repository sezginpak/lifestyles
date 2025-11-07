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

                    JournalListViewNew(viewModel: viewModel)
                        .tag(MoodJournalViewModel.Tab.journal)

                    MoodAnalyticsViewNew(entries: viewModel.moodEntries)
                        .tag(MoodJournalViewModel.Tab.analytics)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle(String(localized: "mood.journal.title", comment: "Mood & Journal"))
            .navigationBarTitleDisplayMode(.inline)
            .task {
                // Her açılışta veriyi yenile
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

    // MARK: - Computed Properties

    private var brandGradient: LinearGradient {
        LinearGradient(
            colors: [.brandPrimary, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

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
                    LazyVStack(spacing: Spacing.medium) {
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
                                        Label(String(localized: "button.delete", comment: "Delete button"), systemImage: "trash")
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
                    // DS: Updated padding to Spacing.large
                    .padding(Spacing.large)
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
                        .foregroundStyle(brandGradient)
                }
                .scaleEffect(viewModel.showingJournalEditor ? 0.95 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.75), value: viewModel.showingJournalEditor)
            }
        }
        .sheet(isPresented: $viewModel.showingJournalEditor) {
            JournalEditorView(viewModel: viewModel)
        }
    }

    // MARK: - Modern Card (COMPACT)

    @State private var pressedCardId: UUID?

    private func modernJournalCard(_ entry: JournalEntry) -> some View {
        ZStack(alignment: .topLeading) {
            // Background Gradient (subtle)
            LinearGradient(
                colors: [
                    entry.journalType.color.opacity(0.05),
                    entry.journalType.color.opacity(0.02)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: Spacing.medium) {
                // Header Row - Type Badge + Metadata
                HStack(alignment: .center, spacing: Spacing.small) {
                    // Type Badge with gradient
                    HStack(spacing: 4) {
                        Text(entry.journalType.emoji)
                            .font(.caption)

                        Text(entry.journalType.displayName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(entry.journalType.color)
                    }
                    .padding(.horizontal, Spacing.small)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        entry.journalType.color.opacity(0.15),
                                        entry.journalType.color.opacity(0.08)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )

                    Spacer()

                    // Favorite Star (if applicable)
                    if entry.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    // Word Count Badge
                    HStack(spacing: 2) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 9))
                        Text(String(localized: "journal.word.count", defaultValue: "\(entry.wordCount)", comment: "Word count"))
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color(.tertiarySystemFill))
                    )
                }

                // Title (if exists) - Enhanced typography
                if let title = entry.title {
                    Text(title)
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .primary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .lineLimit(1)
                }

                // Preview Text - Better readability
                Text(entry.preview)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(entry.title == nil ? 3 : 2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)

                // Bottom Section - Tags + Footer
                VStack(alignment: .leading, spacing: Spacing.small) {
                    // Tags (if exists)
                    if !entry.tags.isEmpty {
                        CompactJournalTags(tags: entry.tags, typeColor: entry.journalType.color)
                    }

                    // Footer Metadata
                    HStack(spacing: Spacing.small) {
                        Image(systemName: "calendar")
                            .font(.system(size: 9))

                        Text(entry.formattedDate)
                            .font(.caption2)

                        Text("•")
                            .font(.caption2)

                        Image(systemName: "clock")
                            .font(.system(size: 9))

                        Text(String(format: NSLocalizedString("journal.reading.time.format", comment: "X minutes reading time"), entry.estimatedReadingTime))
                            .font(.caption2)
                    }
                    .foregroundStyle(.tertiary)
                }
            }
            .padding(Spacing.large)
        }
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            entry.journalType.color.opacity(0.2),
                            entry.journalType.color.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .shadow(
            color: entry.journalType.color.opacity(pressedCardId == entry.id ? 0.15 : 0.08),
            radius: pressedCardId == entry.id ? 12 : 8,
            x: 0,
            y: pressedCardId == entry.id ? 6 : 4
        )
        .scaleEffect(pressedCardId == entry.id ? 0.98 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: pressedCardId)
        .onTapGesture {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                pressedCardId = entry.id
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                    pressedCardId = nil
                }
            }
            HapticFeedback.light()
            viewModel.startEditingJournal(entry)
        }
    }

    // MARK: - Actions with Feedback

    private func deleteWithFeedback(_ entry: JournalEntry) {
        HapticFeedback.warning()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
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

        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
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

// MARK: - Journal Editor (Compact Step-by-Step) ✨

struct JournalEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.toastManager) private var toastManager
    @Bindable var viewModel: MoodJournalViewModel

    @State private var editorState = JournalEditorState()

    // Edit mode check
    private var isEditMode: Bool {
        viewModel.editingJournalEntry != nil
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress Bar
                StepProgressBar(currentStep: editorState.currentStep)

                // Step Content with TabView for smooth sliding
                TabView(selection: $editorState.currentStep) {
                    StepTypeView(state: editorState)
                        .tag(JournalStep.type)

                    StepTitleView(state: editorState)
                        .tag(JournalStep.title)

                    StepContentView(state: editorState)
                        .tag(JournalStep.content)

                    StepTagsView(state: editorState, viewModel: viewModel)
                        .tag(JournalStep.tags)

                    StepReviewView(state: editorState, viewModel: viewModel)
                        .tag(JournalStep.review)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: editorState.currentStep)

                // Navigation Buttons
                EditorNavigationButtons(
                    state: editorState,
                    viewModel: viewModel,
                    onSave: { saveJournal() },
                    onLoadTagSuggestions: {
                        viewModel.loadTagSuggestions(for: editorState.selectedType, existingTags: editorState.selectedTags)
                    }
                )
                .padding(Spacing.large)
                .background(.ultraThinMaterial)
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
                        Image(systemName: "xmark")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
            .onAppear {
                setupEditor()
            }
            .onDisappear {
                // Clean up when view disappears
                cleanup()
            }
        }
    }


    // MARK: - Helper Methods

    private func setupEditor() {
        if let entry = viewModel.editingJournalEntry {
            // Edit mode - populate fields from entry
            editorState.populate(from: entry)
        }
        viewModel.loadTagSuggestions(for: editorState.selectedType, existingTags: editorState.selectedTags)
    }

    private func saveJournal() {
        guard !editorState.isSaving else { return }

        editorState.isSaving = true
        HapticFeedback.medium()

        Task {
            // Simulate save delay for animation
            try? await Task.sleep(nanoseconds: 500_000_000)

            await MainActor.run {
                if let entry = viewModel.editingJournalEntry {
                    // Update existing
                    viewModel.updateJournalEntry(
                        entry,
                        title: editorState.title.isEmpty ? nil : editorState.title,
                        content: editorState.content,
                        tags: editorState.selectedTags,
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
                        content: editorState.content,
                        journalType: editorState.selectedType,
                        title: editorState.title.isEmpty ? nil : editorState.title,
                        tags: editorState.selectedTags,
                        linkToTodaysMood: editorState.linkToMood,
                        context: modelContext
                    )

                    // Success toast
                    toastManager.success(
                        title: "Journal Kaydedildi",
                        message: "\(editorState.selectedType.emoji) \(editorState.selectedType.displayName) journal'ı oluşturuldu",
                        emoji: "📝"
                    )
                }

                editorState.isSaving = false
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
        // Reset editor state
        editorState.reset()
    }
}

// MARK: - Analytics View (Basit)

struct MoodAnalyticsView: View {
    @Bindable var viewModel: MoodJournalViewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.large) {
                // Stats Cards (3-column)
                statsSection

                // Compact 7-day Calendar Heatmap
                compactWeekHeatmap

                // Correlations (compact)
                MoodCorrelationsView(
                    goalCorrelations: viewModel.moodCorrelation.goalCorrelations,
                    friendCorrelations: viewModel.moodCorrelation.friendCorrelations,
                    locationCorrelations: viewModel.locationCorrelations
                )

                // AI Insight (iOS 26+)
                if #available(iOS 26.0, *) {
                    compactAIInsightSection
                }
            }
            .padding(Spacing.large)
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text(String(localized: "journal.stats", comment: "Statistics"))
                .cardTitle()

            // 3-column grid with MiniStatCard
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.medium) {
                MiniStatCard(
                    title: "Streak",
                    value: "\(viewModel.streakData.currentStreak)",
                    icon: "flame.fill",
                    color: .orange
                )

                MiniStatCard(
                    title: "Ortalama",
                    value: String(format: "%.1f", viewModel.moodStats.averageMood),
                    icon: "star.fill",
                    color: .purple
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

    // MARK: - Compact Week Heatmap (7-day horizontal)

    private var compactWeekHeatmap: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text(String(localized: "journal.last.7.days", comment: "Last 7 Days"))
                .cardTitle()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.small) {
                    ForEach(0..<7, id: \.self) { dayOffset in
                        let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
                        let moodDayData = viewModel.heatmapData.first(where: {
                            Calendar.current.isDate($0.date, inSameDayAs: date)
                        })

                        // MoodDayData'dan MoodEntry oluştur
                        let moodEntry: MoodEntry? = {
                            if let moodType = moodDayData?.moodType,
                               let score = moodDayData?.averageScore {
                                return MoodEntry(
                                    moodType: moodType,
                                    intensity: Int(score.rounded()),
                                    note: nil
                                )
                            }
                            return nil
                        }()

                        MoodGridItem(mood: moodEntry, date: date)
                    }
                }
            }
        }
    }

    // MARK: - Compact AI Insight

    @available(iOS 26.0, *)
    private var compactAIInsightSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                Text(String(localized: "ai.analysis", comment: "AI Analysis"))
                    .cardTitle()
            }

            if viewModel.isLoadingAI {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if let insight = viewModel.aiInsight {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text(insight.summary)
                        .font(.caption)
                        .fontWeight(.medium)

                    ForEach(insight.suggestions.prefix(3), id: \.self) { suggestion in
                        HStack(alignment: .top, spacing: Spacing.micro) {
                            Text("💡")
                                .font(.caption2)

                            Text(suggestion)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(Spacing.medium)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.normal)
                        .fill(Color.purple.opacity(0.1))
                )
            } else {
                Button(String(localized: "button.weekly.analysis", comment: "Weekly analysis button")) {
                    Task {
                        await viewModel.generateWeeklyAnalysis(context: modelContext)
                    }
                }
                .font(.caption)
            }
        }
    }
}

#Preview {
    MoodJournalView()
        .modelContainer(for: [MoodEntry.self, JournalEntry.self])
}

//
//  JournalListViewNew.swift
//  LifeStyles
//
//  Modern journal list with masonry grid, calendar view, advanced analytics
//  Completely redesigned on 05.11.2025
//

import SwiftUI
import SwiftData

struct JournalListViewNew: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.toastManager) private var toastManager
    @Bindable var viewModel: MoodJournalViewModel

    // View mode
    @State private var viewMode: ViewMode = .masonry
    @State private var showingCalendar = false

    // Search & Filter
    @State private var searchText: String = ""
    @FocusState private var searchFocused: Bool
    @State private var selectedType: JournalType?
    @State private var showOnlyFavorites = false
    @State private var showOnlyWithImages = false

    // Sort
    @State private var sortOrder: SortOrder = .dateDescending

    // UI state
    @State private var isLoading = false
    @State private var showingStats = true

    enum ViewMode: String, CaseIterable {
        case masonry = "Masonry"
        case calendar = "Takvim"

        var icon: String {
            switch self {
            case .masonry: return "square.grid.2x2"
            case .calendar: return "calendar"
            }
        }
    }

    enum SortOrder: String, CaseIterable {
        case dateDescending = "En Yeni"
        case dateAscending = "En Eski"
        case wordCount = "En Uzun"

        var icon: String {
            switch self {
            case .dateDescending: return "arrow.down"
            case .dateAscending: return "arrow.up"
            case .wordCount: return "text.word.spacing"
            }
        }
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            // BUG FIX: Loading state'ini kaldır, direkt content göster
            if filteredAndSortedEntries.isEmpty && searchText.isEmpty && !hasActiveFilters {
                emptyState
            } else {
                mainContent
            }
        }
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $viewModel.showingJournalEditor) {
            ModernJournalEditorView(viewModel: viewModel)
        }
        .sheet(item: $viewModel.selectedJournalForDetail) { entry in
            JournalDetailView(viewModel: viewModel, entry: entry)
        }
        .onAppear {
            // Journal'lar yüklenmemişse tekrar dene
            if viewModel.journalEntries.isEmpty {
                viewModel.loadAllData(context: modelContext)
            }
        }
    }

    // MARK: - Loading View

    var loadingView: some View {
        ScrollView {
            VStack(spacing: 16) {
                MasonrySkeletonGrid()
            }
        }
    }

    // MARK: - Empty State

    var emptyState: some View {
        EnhancedEmptyState(
            title: "Henüz Journal Yok",
            message: "İlk journal'ını yazmaya başla ve düşüncelerini kaydet",
            icon: "book.closed.fill",
            actionLabel: "Yeni Journal",
            action: {
                viewModel.showingJournalEditor = true
            }
        )
    }

    // MARK: - Main Content

    var mainContent: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Stats header (toggle edilebilir)
                if showingStats {
                    JournalStatsHeader(
                        entries: viewModel.journalEntries,
                        currentMood: viewModel.currentMood
                    )
                    .padding(.horizontal)
                    .padding(.top, 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Search bar
                JournalSearchBar(
                    searchText: $searchText,
                    isFocused: $searchFocused
                )
                .padding(.horizontal)

                // Filter chips
                FilterChipGroup(
                    selectedType: $selectedType,
                    showOnlyFavorites: $showOnlyFavorites,
                    showOnlyWithImages: $showOnlyWithImages
                )

                // Content based on view mode
                if viewMode == .calendar {
                    CalendarJournalView(
                        entries: filteredAndSortedEntries,
                        onTap: { entry in
                            viewModel.selectedJournalForDetail = entry
                        },
                        onToggleFavorite: { entry in
                            toggleFavorite(entry)
                        }
                    )
                } else {
                    // Geliştirilmiş Kart Listesi
                    LazyVStack(spacing: 12) {
                        ForEach(filteredAndSortedEntries) { entry in
                            EnhancedJournalCard(
                                entry: entry,
                                onTap: {
                                    HapticFeedback.light()
                                    viewModel.selectedJournalForDetail = entry
                                },
                                onToggleFavorite: {
                                    toggleFavorite(entry)
                                }
                            )
                            .transition(.scale.combined(with: .opacity))
                            .contextMenu {
                                Button(role: .destructive) {
                                    deleteEntry(entry)
                                } label: {
                                    Label(String(localized: "button.delete", comment: "Delete button"), systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 20)
        }
        .refreshable {
            await refreshJournals()
        }
    }

    // MARK: - Masonry Grid

    var masonryGrid: some View {
        MasonryGridLayout(
            entries: filteredAndSortedEntries,
            columns: 2,
            spacing: 12,
            onTap: { entry in
                viewModel.selectedJournalForDetail = entry
            },
            onToggleFavorite: { entry in
                toggleFavorite(entry)
            },
            onDelete: { entry in
                deleteEntry(entry)
            }
        )
        .padding(.horizontal)
    }

    // MARK: - Search Empty State

    var searchEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 56))
                .foregroundColor(.secondary.opacity(0.5))

            VStack(spacing: 8) {
                Text(String(localized: "journal.no.results", comment: ""))
                    .font(.system(size: 18, weight: .semibold))

                Text(String(localized: "journal.change.criteria", comment: ""))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            if hasActiveFilters {
                Button {
                    clearAllFilters()
                } label: {
                    Text(String(localized: "journal.clear.filters", comment: ""))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.brandPrimary)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        // Leading: View mode toggle
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewMode = mode
                        }
                        HapticFeedback.light()
                    } label: {
                        Label(mode.rawValue, systemImage: mode.icon)
                    }
                }

                Divider()

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showingStats.toggle()
                    }
                } label: {
                    Label(
                        showingStats ? "İstatistikleri Gizle" : "İstatistikleri Göster",
                        systemImage: showingStats ? "eye.slash" : "eye"
                    )
                }
            } label: {
                Image(systemName: viewMode.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.brandPrimary, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }

        // Trailing: Sort + New
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: 12) {
                // Sort menu (sadece masonry mode'da)
                if viewMode == .masonry {
                    Menu {
                        ForEach(SortOrder.allCases, id: \.self) { order in
                            Button {
                                sortOrder = order
                                HapticFeedback.light()
                            } label: {
                                Label(order.rawValue, systemImage: order.icon)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }

                // New journal button
                Button {
                    HapticFeedback.medium()
                    viewModel.showingJournalEditor = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.success, .green],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
        }
    }

    // MARK: - Actions

    private func toggleFavorite(_ entry: JournalEntry) {
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

    private func deleteEntry(_ entry: JournalEntry) {
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

    private func clearAllFilters() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedType = nil
            showOnlyFavorites = false
            showOnlyWithImages = false
            searchText = ""
        }
        HapticFeedback.light()
    }

    private func refreshJournals() async {
        HapticFeedback.light()
        try? await Task.sleep(nanoseconds: 500_000_000)
        await MainActor.run {
            viewModel.loadAllData(context: modelContext)
        }
    }

    // MARK: - Computed Properties

    var hasActiveFilters: Bool {
        selectedType != nil || showOnlyFavorites || showOnlyWithImages || !searchText.isEmpty
    }

    var filteredAndSortedEntries: [JournalEntry] {
        var entries = viewModel.journalEntries

        // Search filter
        if !searchText.isEmpty {
            let lowercasedSearch = searchText.lowercased()
            entries = entries.filter { entry in
                (entry.title?.lowercased().contains(lowercasedSearch) ?? false) ||
                entry.content.lowercased().contains(lowercasedSearch) ||
                entry.tags.contains { $0.lowercased().contains(lowercasedSearch) }
            }
        }

        // Type filter
        if let type = selectedType {
            entries = entries.filter { $0.journalType == type }
        }

        // Favorites filter
        if showOnlyFavorites {
            entries = entries.filter { $0.isFavorite }
        }

        // Images filter
        if showOnlyWithImages {
            entries = entries.filter { $0.hasImage }
        }

        // Sort
        switch sortOrder {
        case .dateDescending:
            entries = entries.sorted { $0.date > $1.date }
        case .dateAscending:
            entries = entries.sorted { $0.date < $1.date }
        case .wordCount:
            entries = entries.sorted { $0.wordCount > $1.wordCount }
        }

        return entries
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: JournalEntry.self, MoodEntry.self,
        configurations: config
    )

    let viewModel = MoodJournalViewModel()

    return NavigationStack {
        JournalListViewNew(viewModel: viewModel)
            .navigationTitle(String(localized: "journal.navigation.title", comment: ""))
    }
    .modelContainer(container)
}

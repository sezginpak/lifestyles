//
//  JournalListViewNew.swift
//  LifeStyles
//
//  Created by Claude on 25.10.2025.
//  Redesigned Journal List with glassmorphism, grid/list toggle, filters
//

import SwiftUI
import SwiftData

struct JournalListViewNew: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.toastManager) private var toastManager
    @Bindable var viewModel: MoodJournalViewModel

    // View state
    @State private var viewMode: ViewMode = .list
    @State private var showingFilters = false
    @State private var filterType: JournalType?
    @State private var filterFavorites = false
    @State private var filterHasImage = false
    @State private var sortOrder: SortOrder = .dateDescending

    enum ViewMode {
        case list
        case grid
    }

    enum SortOrder {
        case dateDescending
        case dateAscending
        case wordCount

        var displayName: String {
            switch self {
            case .dateDescending: return "En Yeni"
            case .dateAscending: return "En Eski"
            case .wordCount: return "Kelime Sayısı"
            }
        }

        var icon: String {
            switch self {
            case .dateDescending: return "arrow.down"
            case .dateAscending: return "arrow.up"
            case .wordCount: return "text.word.spacing"
            }
        }
    }

    var body: some View {
        Group {
            if filteredAndSortedEntries.isEmpty {
                emptyState
            } else {
                mainContent
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    // View Mode
                    Section {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewMode = .list
                            }
                        } label: {
                            Label("Liste", systemImage: "list.bullet")
                        }

                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewMode = .grid
                            }
                        } label: {
                            Label("Grid", systemImage: "square.grid.2x2")
                        }
                    }

                    // Sort
                    Section {
                        ForEach([SortOrder.dateDescending, .dateAscending, .wordCount], id: \.self) { order in
                            Button {
                                sortOrder = order
                            } label: {
                                Label(order.displayName, systemImage: order.icon)
                            }
                        }
                    }

                    // Filters
                    Section {
                        Button {
                            showingFilters.toggle()
                        } label: {
                            Label("Filtreler", systemImage: "line.3.horizontal.decrease.circle")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
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

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    HapticFeedback.medium()
                    viewModel.showingJournalEditor = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
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
        .sheet(isPresented: $viewModel.showingJournalEditor) {
            NewJournalEditorView(viewModel: viewModel)
        }
        .sheet(item: $viewModel.selectedJournalForDetail) { entry in
            JournalDetailView(viewModel: viewModel, entry: entry)
        }
        .sheet(isPresented: $showingFilters) {
            FilterSheet(
                filterType: $filterType,
                filterFavorites: $filterFavorites,
                filterHasImage: $filterHasImage
            )
            .presentationDetents([.medium])
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        MoodEmptyState(
            icon: "book.closed.fill",
            title: "Henüz journal yok",
            message: activeFiltersCount > 0 ? "Filtrelerinize uygun journal bulunamadı" : "İlk journal'ını yazmaya başla",
            actionLabel: "Yeni Journal",
            action: {
                viewModel.showingJournalEditor = true
            }
        )
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: Spacing.large) {
                // Active Filters Bar
                if activeFiltersCount > 0 {
                    activeFiltersBar
                }

                // Hero Card (En son journal)
                if let latestEntry = filteredAndSortedEntries.first,
                   sortOrder == .dateDescending && activeFiltersCount == 0 {
                    heroCard(latestEntry)
                }

                // Content Grid/List
                if viewMode == .grid {
                    gridView
                } else {
                    listView
                }
            }
            .padding(Spacing.large)
        }
    }

    // MARK: - Active Filters Bar

    private var activeFiltersBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.small) {
                // Filter count
                Text("\(activeFiltersCount) Filtre Aktif")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                // Type filter
                if let type = filterType {
                    JournalFilterChip(
                        label: type.displayName,
                        icon: type.icon,
                        color: type.color,
                        onRemove: {
                            filterType = nil
                        }
                    )
                }

                // Favorites filter
                if filterFavorites {
                    JournalFilterChip(
                        label: "Favoriler",
                        icon: "star.fill",
                        color: .yellow,
                        onRemove: {
                            filterFavorites = false
                        }
                    )
                }

                // Has image filter
                if filterHasImage {
                    JournalFilterChip(
                        label: "Fotoğraflı",
                        icon: "photo.fill",
                        color: .blue,
                        onRemove: {
                            filterHasImage = false
                        }
                    )
                }

                // Clear all
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        clearAllFilters()
                    }
                } label: {
                    Text("Temizle")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.red)
                        .padding(.horizontal, Spacing.small)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.1))
                        )
                }
            }
        }
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, Spacing.small)
        .background(.ultraThinMaterial)
        .cornerRadius(CornerRadius.medium)
    }

    // MARK: - Hero Card

    private func heroCard(_ entry: JournalEntry) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Text(String(localized: "mood.last.journal", comment: "LAST JOURNAL"))
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .tracking(1)

                Spacer()

                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(entry.journalType.color)
            }

            GlassJournalCard(
                entry: entry,
                showImage: true,
                isHero: true,
                onTap: {
                    viewModel.selectedJournalForDetail = entry
                }
            )
        }
    }

    // MARK: - Grid View

    private var gridView: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: Spacing.medium),
                GridItem(.flexible(), spacing: Spacing.medium)
            ],
            spacing: Spacing.medium
        ) {
            ForEach(filteredAndSortedEntries, id: \.id) { entry in
                GlassJournalCard(
                    entry: entry,
                    showImage: true,
                    isHero: false,
                    onTap: {
                        viewModel.selectedJournalForDetail = entry
                    }
                )
                .contextMenu {
                    contextMenuButtons(for: entry)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    deleteButton(for: entry)
                }
                .swipeActions(edge: .leading) {
                    favoriteButton(for: entry)
                }
            }
        }
    }

    // MARK: - List View

    private var listView: some View {
        LazyVStack(spacing: Spacing.medium) {
            ForEach(filteredAndSortedEntries, id: \.id) { entry in
                GlassJournalCard(
                    entry: entry,
                    showImage: true,
                    isHero: false,
                    onTap: {
                        viewModel.selectedJournalForDetail = entry
                    }
                )
                .contextMenu {
                    contextMenuButtons(for: entry)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    deleteButton(for: entry)
                }
                .swipeActions(edge: .leading) {
                    favoriteButton(for: entry)
                }
            }
        }
    }

    // MARK: - Context Menu & Swipe Actions

    @ViewBuilder
    private func contextMenuButtons(for entry: JournalEntry) -> some View {
        Button {
            viewModel.startEditingJournal(entry)
        } label: {
            Label("Düzenle", systemImage: "pencil")
        }

        Button {
            toggleFavorite(entry)
        } label: {
            Label(entry.isFavorite ? "Favoriden Çıkar" : "Favorilere Ekle", systemImage: entry.isFavorite ? "star.slash.fill" : "star.fill")
        }

        Divider()

        Button(role: .destructive) {
            deleteEntry(entry)
        } label: {
            Label("Sil", systemImage: "trash")
        }
    }

    private func deleteButton(for entry: JournalEntry) -> some View {
        Button(role: .destructive) {
            deleteEntry(entry)
        } label: {
            Label("Sil", systemImage: "trash")
        }
    }

    private func favoriteButton(for entry: JournalEntry) -> some View {
        Button {
            toggleFavorite(entry)
        } label: {
            Label(entry.isFavorite ? "Çıkar" : "Favori", systemImage: entry.isFavorite ? "star.slash" : "star.fill")
        }
        .tint(.yellow)
    }

    // MARK: - Actions

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

    private func clearAllFilters() {
        filterType = nil
        filterFavorites = false
        filterHasImage = false
    }

    // MARK: - Computed Properties

    private var activeFiltersCount: Int {
        var count = 0
        if filterType != nil { count += 1 }
        if filterFavorites { count += 1 }
        if filterHasImage { count += 1 }
        return count
    }

    private var filteredAndSortedEntries: [JournalEntry] {
        var entries = viewModel.journalEntries

        // Apply filters
        if let type = filterType {
            entries = entries.filter { $0.journalType == type }
        }

        if filterFavorites {
            entries = entries.filter { $0.isFavorite }
        }

        if filterHasImage {
            entries = entries.filter { $0.hasImage }
        }

        // Apply sort
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

// MARK: - Journal Filter Chip

struct JournalFilterChip: View {
    let label: String
    let icon: String
    let color: Color
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
            }
        }
        .foregroundStyle(color)
        .padding(.horizontal, Spacing.small)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
    }
}

// MARK: - Filter Sheet

struct FilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filterType: JournalType?
    @Binding var filterFavorites: Bool
    @Binding var filterHasImage: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Journal Tipi") {
                    Picker("Tip", selection: $filterType) {
                        Text(String(localized: "journal.all", comment: "All")).tag(nil as JournalType?)
                        ForEach(JournalType.allCases, id: \.self) { type in
                            HStack {
                                Text(type.emoji)
                                Text(type.displayName)
                            }
                            .tag(type as JournalType?)
                        }
                    }
                }

                Section("Diğer Filtreler") {
                    Toggle("Sadece Favoriler", isOn: $filterFavorites)
                    Toggle("Fotoğraflı Journal'lar", isOn: $filterHasImage)
                }
            }
            .navigationTitle("Filtreler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Tamam") {
                        dismiss()
                    }
                }
            }
        }
    }
}

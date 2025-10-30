//
//  JournalListViewNew.swift
//  LifeStyles
//
//  Created by Claude on 30.10.2025.
//  Magazine-style Journal List with bold typography, vibrant colors & masonry layout
//

import SwiftUI
import SwiftData

struct JournalListViewNew: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.toastManager) private var toastManager
    @Bindable var viewModel: MoodJournalViewModel

    // View state
    @State private var viewMode: ViewMode = .magazine
    @State private var showingFilters = false
    @State private var filterType: JournalType?
    @State private var filterFavorites = false
    @State private var sortOrder: SortOrder = .dateDescending
    @State private var scrollOffset: CGFloat = 0
    @State private var showingSearch = false
    @State private var searchText = ""

    enum ViewMode: String, CaseIterable {
        case magazine = "Magazine"
        case timeline = "Timeline"
        case compact = "Compact"

        var icon: String {
            switch self {
            case .magazine: return "square.grid.2x2.fill"
            case .timeline: return "list.bullet.rectangle.portrait.fill"
            case .compact: return "rectangle.grid.1x2.fill"
            }
        }
    }

    enum SortOrder {
        case dateDescending
        case dateAscending
        case wordCount
        case favorites

        var displayName: String {
            switch self {
            case .dateDescending: return "En Yeni"
            case .dateAscending: return "En Eski"
            case .wordCount: return "Kelime Sayısı"
            case .favorites: return "Favoriler"
            }
        }

        var icon: String {
            switch self {
            case .dateDescending: return "arrow.down.circle.fill"
            case .dateAscending: return "arrow.up.circle.fill"
            case .wordCount: return "text.word.spacing"
            case .favorites: return "star.fill"
            }
        }
    }

    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient

            ScrollView {
                VStack(spacing: 0) {
                    // Header Section with Stats
                    headerSection
                        .padding(.horizontal, Spacing.large)
                        .padding(.top, Spacing.medium)

                    // Quick Actions Bar
                    quickActionsBar
                        .padding(.horizontal, Spacing.large)
                        .padding(.vertical, Spacing.medium)

                    // Active Filters
                    if activeFiltersCount > 0 {
                        activeFiltersBar
                            .padding(.horizontal, Spacing.large)
                            .padding(.bottom, Spacing.medium)
                    }

                    // Content
                    if filteredAndSortedEntries.isEmpty {
                        emptyState
                            .padding(.top, 60)
                    } else {
                        contentView
                            .padding(.horizontal, Spacing.large)
                    }
                }
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)

            // Floating Add Button
            floatingAddButton
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    viewModeMenu
                    Divider()
                    sortMenu
                    Divider()
                    filterMenu
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
                        .symbolEffect(.bounce, value: showingFilters)
                }
            }

            ToolbarItem(placement: .topBarLeading) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showingSearch.toggle()
                    }
                } label: {
                    Image(systemName: showingSearch ? "xmark.circle.fill" : "magnifyingglass.circle.fill")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
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
                filterFavorites: $filterFavorites
            )
            .presentationDetents([.medium])
        }
    }

    // MARK: - Background Gradient

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                filterType?.color.opacity(0.03) ?? Color.brandPrimary.opacity(0.03),
                Color(.systemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            // Search Bar (if visible)
            if showingSearch {
                HStack(spacing: Spacing.small) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Journal ara...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.body)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(Spacing.medium)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                        .fill(.ultraThinMaterial)
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Stats Cards
            HStack(spacing: Spacing.medium) {
                // Total Journals
                StatBubble(
                    value: "\(viewModel.journalEntries.count)",
                    label: "Total",
                    icon: "book.fill",
                    gradient: [.brandPrimary, .purple]
                )

                // This Month
                StatBubble(
                    value: "\(thisMonthCount)",
                    label: "Bu Ay",
                    icon: "calendar",
                    gradient: [.blue, .cyan]
                )

                // Favorites
                StatBubble(
                    value: "\(favoritesCount)",
                    label: "Favori",
                    icon: "star.fill",
                    gradient: [.orange, .yellow]
                )

                // Word Count
                StatBubble(
                    value: "\(totalWordCount / 1000)K",
                    label: "Kelime",
                    icon: "text.word.spacing",
                    gradient: [.green, .mint]
                )
            }
        }
    }

    // MARK: - Quick Actions Bar

    private var quickActionsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.small) {
                // View Mode Selector
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    QuickActionChip(
                        label: mode.rawValue,
                        icon: mode.icon,
                        isSelected: viewMode == mode,
                        color: .brandPrimary
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewMode = mode
                        }
                        HapticFeedback.light()
                    }
                }

                Divider()
                    .frame(height: 24)

                // Type Filters
                ForEach(JournalType.allCases, id: \.self) { type in
                    QuickActionChip(
                        label: type.displayName,
                        icon: type.icon,
                        emoji: type.emoji,
                        isSelected: filterType == type,
                        color: type.color
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            filterType = filterType == type ? nil : type
                        }
                        HapticFeedback.light()
                    }
                }
            }
        }
    }

    // MARK: - Active Filters Bar

    private var activeFiltersBar: some View {
        HStack(spacing: Spacing.small) {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .foregroundStyle(.brandPrimary)

            Text("\(activeFiltersCount) Filtre Aktif")
                .font(.caption)
                .fontWeight(.semibold)

            Spacer()

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    clearAllFilters()
                }
            } label: {
                Text("Temizle")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.red)
            }
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Content Views

    @ViewBuilder
    private var contentView: some View {
        switch viewMode {
        case .magazine:
            magazineView
        case .timeline:
            timelineView
        case .compact:
            compactView
        }
    }

    // MARK: - Magazine View (Masonry Grid)

    private var magazineView: some View {
        VStack(spacing: Spacing.large) {
            // Hero Card (Latest Entry)
            if let latest = filteredAndSortedEntries.first, sortOrder == .dateDescending {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    HStack {
                        Text("SON JOURNAL")
                            .font(.caption2)
                            .fontWeight(.black)
                            .tracking(1.5)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Image(systemName: "star.circle.fill")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .yellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    MagazineHeroCard(entry: latest) {
                        viewModel.selectedJournalForDetail = latest
                    }
                }
                .padding(.bottom, Spacing.medium)
            }

            // Masonry Grid
            MasonryGrid(
                items: Array(filteredAndSortedEntries.dropFirst(sortOrder == .dateDescending ? 1 : 0)),
                columns: 2,
                spacing: Spacing.medium
            ) { entry in
                MagazineCard(entry: entry) {
                    viewModel.selectedJournalForDetail = entry
                }
                .contextMenu {
                    contextMenuButtons(for: entry)
                }
            }
        }
    }

    // MARK: - Timeline View

    private var timelineView: some View {
        LazyVStack(spacing: Spacing.large) {
            ForEach(groupedByDate.keys.sorted(by: >), id: \.self) { date in
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    // Date Header
                    HStack(spacing: Spacing.small) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.brandPrimary, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 8, height: 8)

                        Text(formatDateHeader(date))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)

                        Rectangle()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(height: 1)
                    }

                    // Entries for this date
                    ForEach(groupedByDate[date] ?? [], id: \.id) { entry in
                        TimelineCard(entry: entry) {
                            viewModel.selectedJournalForDetail = entry
                        }
                        .contextMenu {
                            contextMenuButtons(for: entry)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Compact View

    private var compactView: some View {
        LazyVStack(spacing: Spacing.small) {
            ForEach(filteredAndSortedEntries, id: \.id) { entry in
                CompactCard(entry: entry) {
                    viewModel.selectedJournalForDetail = entry
                }
                .contextMenu {
                    contextMenuButtons(for: entry)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.xlarge) {
            // Animated Icon
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

                Image(systemName: "book.closed.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.brandPrimary, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: Spacing.small) {
                Text(activeFiltersCount > 0 ? "Eşleşen journal yok" : "İlk journal'ını yaz")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(activeFiltersCount > 0 ? "Filtrelerini değiştir veya yeni journal ekle" : "Düşüncelerini, deneyimlerini ve hikayelerini kaydet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xlarge)
            }

            if activeFiltersCount > 0 {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        clearAllFilters()
                    }
                } label: {
                    Text("Filtreleri Temizle")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.xlarge)
                        .padding(.vertical, Spacing.medium)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.red, .orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: .red.opacity(0.3), radius: 8, y: 4)
                }
            }
        }
    }

    // MARK: - Floating Add Button

    private var floatingAddButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    HapticFeedback.medium()
                    viewModel.showingJournalEditor = true
                } label: {
                    HStack(spacing: Spacing.small) {
                        Image(systemName: "plus")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Yeni Journal")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.large)
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
                    .shadow(color: .brandPrimary.opacity(0.4), radius: 12, y: 6)
                }
                .padding(.trailing, Spacing.large)
                .padding(.bottom, Spacing.large)
            }
        }
    }

    // MARK: - Menus

    @ViewBuilder
    private var viewModeMenu: some View {
        ForEach(ViewMode.allCases, id: \.self) { mode in
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    viewMode = mode
                }
            } label: {
                Label(mode.rawValue, systemImage: mode.icon)
            }
        }
    }

    @ViewBuilder
    private var sortMenu: some View {
        ForEach([SortOrder.dateDescending, .dateAscending, .wordCount, .favorites], id: \.self) { order in
            Button {
                sortOrder = order
            } label: {
                Label(order.displayName, systemImage: order.icon)
            }
        }
    }

    @ViewBuilder
    private var filterMenu: some View {
        Button {
            showingFilters = true
        } label: {
            Label("Filtreler", systemImage: "line.3.horizontal.decrease.circle")
        }

        Button {
            filterFavorites.toggle()
        } label: {
            Label(filterFavorites ? "Tüm Journal'lar" : "Sadece Favoriler", systemImage: "star.circle")
        }
    }

    // MARK: - Context Menu

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
        searchText = ""
    }

    // MARK: - Computed Properties

    private var activeFiltersCount: Int {
        var count = 0
        if filterType != nil { count += 1 }
        if filterFavorites { count += 1 }
        if !searchText.isEmpty { count += 1 }
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

        if !searchText.isEmpty {
            entries = entries.filter {
                $0.content.lowercased().contains(searchText.lowercased()) ||
                ($0.title?.lowercased().contains(searchText.lowercased()) ?? false) ||
                $0.tags.contains { $0.lowercased().contains(searchText.lowercased()) }
            }
        }

        // Apply sort
        switch sortOrder {
        case .dateDescending:
            entries = entries.sorted { $0.date > $1.date }
        case .dateAscending:
            entries = entries.sorted { $0.date < $1.date }
        case .wordCount:
            entries = entries.sorted { $0.wordCount > $1.wordCount }
        case .favorites:
            entries = entries.sorted { $0.isFavorite && !$1.isFavorite }
        }

        return entries
    }

    private var thisMonthCount: Int {
        viewModel.journalEntries.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }.count
    }

    private var favoritesCount: Int {
        viewModel.journalEntries.filter { $0.isFavorite }.count
    }

    private var totalWordCount: Int {
        viewModel.journalEntries.reduce(0) { $0 + $1.wordCount }
    }

    private var groupedByDate: [Date: [JournalEntry]] {
        Dictionary(grouping: filteredAndSortedEntries) { entry in
            Calendar.current.startOfDay(for: entry.date)
        }
    }

    private func formatDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Bugün"
        } else if calendar.isDateInYesterday(date) {
            return "Dün"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMMM yyyy"
            formatter.locale = Locale(identifier: "tr_TR")
            return formatter.string(from: date)
        }
    }
}

// MARK: - Stat Bubble Component

struct StatBubble: View {
    let value: String
    let label: String
    let icon: String
    let gradient: [Color]

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradient.map { $0.opacity(0.2) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                VStack(spacing: 2) {
                    Image(systemName: icon)
                        .font(.caption2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text(value)
                        .font(.caption)
                        .fontWeight(.black)
                        .monospacedDigit()
                }
            }

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Quick Action Chip

struct QuickActionChip: View {
    let label: String
    let icon: String
    var emoji: String? = nil
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let emoji = emoji {
                    Text(emoji)
                        .font(.caption)
                } else {
                    Image(systemName: icon)
                        .font(.caption2)
                }

                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(isSelected ? .white : color)
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small)
            .background(
                Capsule()
                    .fill(
                        isSelected ?
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [color.opacity(0.15), color.opacity(0.08)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .overlay(
                Capsule()
                    .strokeBorder(color.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
            )
            .shadow(color: isSelected ? color.opacity(0.3) : .clear, radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Magazine Hero Card

struct MagazineHeroCard: View {
    let entry: JournalEntry
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap()
        }) {
            ZStack {
                // Background Gradient
                LinearGradient(
                    colors: [
                        entry.journalType.color.opacity(0.3),
                        entry.journalType.color.opacity(0.1),
                        entry.journalType.color.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(alignment: .leading, spacing: Spacing.medium) {
                    // Header
                    HStack {
                        HStack(spacing: Spacing.small) {
                            Text(entry.journalType.emoji)
                                .font(.title)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.journalType.displayName)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(entry.journalType.color)

                                Text(entry.formattedDate)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        if entry.isFavorite {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                                .font(.title3)
                        }
                    }

                    // Title
                    if let title = entry.title {
                        Text(title)
                            .font(.title2)
                            .fontWeight(.black)
                            .lineLimit(2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.primary, entry.journalType.color],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }

                    // Preview
                    Text(entry.preview)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineLimit(4)

                    Spacer()

                    // Footer
                    HStack {
                        HStack(spacing: Spacing.small) {
                            Image(systemName: "text.word.spacing")
                                .font(.caption)
                            Text("\(entry.wordCount) kelime")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.secondary)

                        Spacer()

                        Image(systemName: "chevron.right.circle.fill")
                            .font(.title2)
                            .foregroundStyle(entry.journalType.color)
                    }
                }
                .padding(Spacing.xlarge)
            }
            .frame(height: 280)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xlarge, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.xlarge, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                entry.journalType.color.opacity(0.5),
                                entry.journalType.color.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: entry.journalType.color.opacity(0.3), radius: 20, y: 10)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Magazine Card

struct MagazineCard: View {
    let entry: JournalEntry
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                // Header
                HStack {
                    Text(entry.journalType.emoji)
                        .font(.title3)

                    Spacer()

                    if entry.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }

                // Title or Preview
                if let title = entry.title {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineLimit(2)
                        .foregroundStyle(entry.journalType.color)
                } else {
                    Text(entry.preview)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(4)
                }

                Spacer()

                // Footer
                VStack(alignment: .leading, spacing: Spacing.micro) {
                    Text(entry.formattedDate)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    HStack(spacing: 4) {
                        Image(systemName: "doc.text")
                            .font(.caption2)
                        Text("\(entry.wordCount)")
                            .font(.caption2)
                            .monospacedDigit()
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .padding(Spacing.large)
            .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
            .background(
                ZStack {
                    LinearGradient(
                        colors: [
                            entry.journalType.color.opacity(0.15),
                            entry.journalType.color.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    .ultraThinMaterial
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                    .strokeBorder(entry.journalType.color.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: entry.journalType.color.opacity(0.15), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Timeline Card

struct TimelineCard: View {
    let entry: JournalEntry
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap()
        }) {
            HStack(alignment: .top, spacing: Spacing.medium) {
                // Time indicator
                VStack(spacing: Spacing.micro) {
                    Text(entry.journalType.emoji)
                        .font(.title2)

                    Text(formatTime(entry.date))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 60)

                // Content
                VStack(alignment: .leading, spacing: Spacing.small) {
                    // Type Badge
                    Text(entry.journalType.displayName)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(entry.journalType.color)
                        .padding(.horizontal, Spacing.small)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(entry.journalType.color.opacity(0.15))
                        )

                    // Title
                    if let title = entry.title {
                        Text(title)
                            .font(.body)
                            .fontWeight(.bold)
                            .lineLimit(1)
                    }

                    // Preview
                    Text(entry.preview)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    // Tags
                    if !entry.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(entry.tags.prefix(3), id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.caption2)
                                        .foregroundStyle(entry.journalType.color)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule()
                                                .fill(entry.journalType.color.opacity(0.1))
                                        )
                                }
                            }
                        }
                    }

                    // Footer
                    HStack(spacing: Spacing.small) {
                        if entry.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                        }

                        Image(systemName: "text.word.spacing")
                            .font(.caption2)
                        Text("\(entry.wordCount)")
                            .font(.caption2)
                            .monospacedDigit()
                    }
                    .foregroundStyle(.tertiary)
                }
                .padding(Spacing.large)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                        .strokeBorder(entry.journalType.color.opacity(0.2), lineWidth: 1)
                )
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Compact Card

struct CompactCard: View {
    let entry: JournalEntry
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap()
        }) {
            HStack(spacing: Spacing.medium) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    entry.journalType.color.opacity(0.3),
                                    entry.journalType.color.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    Text(entry.journalType.emoji)
                        .font(.title3)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title ?? entry.preview)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    HStack(spacing: Spacing.small) {
                        Text(entry.formattedDate)
                            .font(.caption2)

                        Text("•")
                            .font(.caption2)

                        Text("\(entry.wordCount) kelime")
                            .font(.caption2)

                        if entry.isFavorite {
                            Text("•")
                                .font(.caption2)

                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                        }
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(Spacing.medium)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                    .strokeBorder(entry.journalType.color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Masonry Grid Layout

struct MasonryGrid<Content: View, Item: Identifiable>: View {
    let items: [Item]
    let columns: Int
    let spacing: CGFloat
    let content: (Item) -> Content

    init(
        items: [Item],
        columns: Int = 2,
        spacing: CGFloat = 16,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.columns = columns
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            let columnWidth = (geometry.size.width - spacing * CGFloat(columns - 1)) / CGFloat(columns)

            HStack(alignment: .top, spacing: spacing) {
                ForEach(0..<columns, id: \.self) { columnIndex in
                    LazyVStack(spacing: spacing) {
                        ForEach(itemsForColumn(columnIndex), id: \.id) { item in
                            content(item)
                                .frame(width: columnWidth)
                        }
                    }
                }
            }
        }
    }

    private func itemsForColumn(_ columnIndex: Int) -> [Item] {
        items.enumerated().compactMap { index, item in
            index % columns == columnIndex ? item : nil
        }
    }
}

// MARK: - Filter Sheet

struct FilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filterType: JournalType?
    @Binding var filterFavorites: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Journal Tipi") {
                    Picker("Tip", selection: $filterType) {
                        Text("Tümü").tag(nil as JournalType?)
                        ForEach(JournalType.allCases, id: \.self) { type in
                            HStack {
                                Text(type.emoji)
                                Text(type.displayName)
                            }
                            .tag(type as JournalType?)
                        }
                    }
                    .pickerStyle(.inline)
                }

                Section("Diğer Filtreler") {
                    Toggle("Sadece Favoriler", isOn: $filterFavorites)
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

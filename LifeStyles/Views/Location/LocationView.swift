//
//  LocationView.swift
//  LifeStyles
//
//  Modern UI/UX - iPad Compatible
//  Redesigned with glassmorphism, animations, and responsive layout
//

import SwiftUI
import SwiftData
import MapKit

struct LocationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var viewModel = LocationViewModel()
    @State private var showingHistorySheet = false
    @State private var showLocationPermissionAlert = false
    @State private var selectedActivity: ActivitySuggestion?
    @State private var showingActivityDetail = false
    @State private var showLocationUnavailableAlert = false
    @State private var searchText = ""
    @State private var showSearchBar = false
    @State private var isRefreshing = false

    // iPad Detection
    private var isIPad: Bool {
        horizontalSizeClass == .regular
    }

    // Adaptive Layout
    private var gridColumns: [GridItem] {
        if isIPad {
            return [
                GridItem(.flexible(), spacing: 20),
                GridItem(.flexible(), spacing: 20)
            ]
        } else {
            return [GridItem(.flexible())]
        }
    }

    private var horizontalPadding: CGFloat {
        isIPad ? 32 : 16
    }

    private var cardSpacing: CGFloat {
        isIPad ? 20 : 16
    }

    // Filtered activities based on search
    private var displayedActivities: [ActivitySuggestion] {
        if searchText.isEmpty {
            return viewModel.filteredActivities
        } else {
            return viewModel.filteredActivities.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.activityDescription.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Modern Gradient Background
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color.brandPrimary.opacity(0.03),
                        Color.purple.opacity(0.02)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: cardSpacing) {
                        // MARK: - Hero Section
                        VStack(spacing: 16) {
                            // Modern Current Location Card
                            ModernCurrentLocationCard()
                                .padding(.horizontal, horizontalPadding)

                            // Stats Row
                            if let stats = viewModel.activityStats {
                                ModernStatsRow(stats: stats, isIPad: isIPad)
                                    .padding(.horizontal, horizontalPadding)
                            }
                        }
                        .padding(.top, 8)

                        // MARK: - Quick Actions
                        ModernQuickActionsBar(
                            showingMap: $showingHistorySheet,
                            onGenerateActivities: {
                                HapticFeedback.medium()
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    viewModel.generateActivitiesWithTimeOfDay(context: modelContext)
                                }
                            },
                            onSetHome: {
                                guard let location = LocationService.shared.currentLocation else {
                                    showLocationUnavailableAlert = true
                                    HapticFeedback.error()
                                    return
                                }
                                HapticFeedback.success()
                                viewModel.setHomeLocation(
                                    latitude: location.coordinate.latitude,
                                    longitude: location.coordinate.longitude
                                )
                            },
                            homeLocationSet: viewModel.homeLocationSet
                        )
                        .padding(.horizontal, horizontalPadding)

                        // MARK: - Filters Section
                        VStack(spacing: 12) {
                            // Category Filters
                            ModernCategoryFilterChips(
                                selectedCategory: $viewModel.selectedCategory,
                                isIPad: isIPad
                            )

                            // Time Filters
                            ModernTimeFilterChips(
                                selectedTime: $viewModel.selectedTimeOfDay,
                                isIPad: isIPad
                            )
                        }
                        .padding(.horizontal, horizontalPadding)

                        // MARK: - Favorite Activities
                        if !viewModel.favoriteActivities.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                LocationSectionHeader(
                                    icon: "star.fill",
                                    title: String(localized: "location.my.favorites", comment: "My Favorites"),
                                    count: viewModel.favoriteActivities.count,
                                    color: .yellow
                                )
                                .padding(.horizontal, horizontalPadding)

                                LazyVGrid(columns: gridColumns, spacing: cardSpacing) {
                                    ForEach(Array(viewModel.favoriteActivities.enumerated()), id: \.element.id) { index, activity in
                                        ModernActivityCard(
                                            activity: activity,
                                            index: index,
                                            onComplete: {
                                                viewModel.completeActivityWithStats(activity, context: modelContext)
                                            },
                                            onToggleFavorite: {
                                                viewModel.toggleFavorite(activity, context: modelContext)
                                            },
                                            onTap: {
                                                selectedActivity = activity
                                                showingActivityDetail = true
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, horizontalPadding)
                            }
                        }

                        // MARK: - Suggested Activities
                        if !displayedActivities.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                LocationSectionHeader(
                                    icon: "lightbulb.fill",
                                    title: String(localized: "suggested.activities", comment: "Suggested activities section title"),
                                    count: displayedActivities.count,
                                    color: .brandPrimary
                                )
                                .padding(.horizontal, horizontalPadding)
                                .id("suggestedActivitiesHeader")

                                LazyVGrid(columns: gridColumns, spacing: cardSpacing) {
                                    ForEach(Array(displayedActivities.enumerated()), id: \.element.id) { index, activity in
                                        ModernActivityCard(
                                            activity: activity,
                                            index: index,
                                            onComplete: {
                                                viewModel.completeActivityWithStats(activity, context: modelContext)
                                            },
                                            onToggleFavorite: {
                                                viewModel.toggleFavorite(activity, context: modelContext)
                                            },
                                            onTap: {
                                                selectedActivity = activity
                                                showingActivityDetail = true
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, horizontalPadding)
                            }
                        } else if !searchText.isEmpty {
                            // Empty Search State
                            ModernEmptySearchState()
                                .padding(.vertical, 60)
                        }

                        // Home Location Warning
                        if !viewModel.homeLocationSet {
                            ModernHomeLocationWarning(
                                onSetHome: {
                                    guard let location = LocationService.shared.currentLocation else {
                                        showLocationUnavailableAlert = true
                                        HapticFeedback.error()
                                        return
                                    }
                                    HapticFeedback.success()
                                    viewModel.setHomeLocation(
                                        latitude: location.coordinate.latitude,
                                        longitude: location.coordinate.longitude
                                    )
                                }
                            )
                            .padding(.horizontal, horizontalPadding)
                        }

                        // Bottom Spacing
                        Color.clear.frame(height: 20)
                            .id("bottomSpacer")
                    }
                    .padding(.vertical)
                    .onChange(of: viewModel.suggestedActivities.count) { oldValue, newValue in
                        // Yeni aktiviteler eklendiğinde scroll yap
                        if newValue > oldValue {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                proxy.scrollTo("suggestedActivitiesHeader", anchor: .top)
                            }
                        }
                    }
                }
                .refreshable {
                    await refreshActivities()
                }
                }
            }
            .navigationTitle(String(localized: "tab.location", comment: "Location/Activities tab title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        // Search Button
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showSearchBar.toggle()
                                HapticFeedback.light()
                            }
                        } label: {
                            ModernToolbarButton(
                                icon: showSearchBar ? "magnifyingglass.circle.fill" : "magnifyingglass",
                                gradient: [.blue, .cyan]
                            )
                        }

                        // History Button
                        Button {
                            HapticFeedback.light()
                            showingHistorySheet = true
                        } label: {
                            ModernToolbarButton(
                                icon: "map.fill",
                                gradient: [.purple, .pink]
                            )
                        }
                    }
                }
            }
            .searchable(
                text: $searchText,
                isPresented: $showSearchBar,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: String(localized: "search.activities", comment: "Search activities")
            )
            .task {
                viewModel.setModelContext(modelContext)
                viewModel.updateLocationStatus()
                viewModel.updatePeriodicTrackingStatus()

                await Task.detached {
                    await viewModel.loadOrCreateStats(context: modelContext)
                    await viewModel.loadBadges(context: modelContext)
                    await viewModel.loadFavoriteActivities(context: modelContext)
                }.value

                viewModel.startTracking()

                if !viewModel.isPeriodicTrackingActive && PermissionManager.shared.hasAlwaysLocationPermission() {
                    print("📍 LocationView açıldı, otomatik başlatılıyor...")
                    viewModel.startPeriodicTracking()
                }
            }
            .sheet(item: $selectedActivity) { activity in
                ActivityDetailView(
                    activity: activity,
                    onComplete: {
                        viewModel.completeActivityWithStats(activity, context: modelContext)
                    },
                    onToggleFavorite: {
                        viewModel.toggleFavorite(activity, context: modelContext)
                    }
                )
            }
            .sheet(isPresented: $showingHistorySheet) {
                LocationHistoryView(viewModel: viewModel)
            }
            .alert(String(localized: "background.location.permission.required", comment: "Background location permission required alert title"), isPresented: $showLocationPermissionAlert) {
                Button(String(localized: "go.to.settings", comment: "Go to settings button")) {
                    PermissionManager.shared.openAppSettings()
                }
                Button(String(localized: "cancel", comment: "Cancel button"), role: .cancel) { }
            } message: {
                Text(String(localized: "background.location.permission.message", comment: "Background location permission explanation"))
            }
            .alert("Konum Alınamıyor", isPresented: $showLocationUnavailableAlert) {
                Button(String(localized: "button.ok", comment: "OK button")) { }
            } message: {
                Text(String(localized: "text.konum.bilgisi.alınamıyor.lütfen"))
            }
        }
    }

    private func refreshActivities() async {
        isRefreshing = true
        HapticFeedback.light()

        try? await Task.sleep(nanoseconds: 500_000_000)

        viewModel.generateActivitiesWithTimeOfDay(context: modelContext)

        isRefreshing = false
        HapticFeedback.success()
    }
}

// MARK: - Modern Current Location Card

struct ModernCurrentLocationCard: View {
    @State private var placesService = SavedPlacesService.shared
    @State private var currentPlace: SavedPlace?
    @State private var isAnimating = false
    @State private var visitDuration: TimeInterval = 0

    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 16) {
            // Animated Icon
            ZStack {
                // Pulse Effect
                Circle()
                    .fill(currentPlace?.color.opacity(0.2) ?? Color.gray.opacity(0.2))
                    .frame(width: 70, height: 70)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .opacity(isAnimating ? 0 : 0.6)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: false), value: isAnimating)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: currentPlace != nil ?
                                [currentPlace!.color, currentPlace!.color.opacity(0.7)] :
                                [Color.gray, Color.gray.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: (currentPlace?.color ?? .gray).opacity(0.3), radius: 12, x: 0, y: 6)

                if let place = currentPlace {
                    Text(place.emoji)
                        .font(.system(size: 32))
                } else {
                    Image(systemName: "location.slash.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                if let place = currentPlace {
                    Text(String(format: NSLocalizedString("location.at.place", comment: "At place name"), place.name))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [place.color, place.color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    if visitDuration > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.fill")
                                .font(.caption)
                            Text(formatDuration(visitDuration))
                                .font(.subheadline)
                        }
                        .foregroundStyle(.secondary)
                    }
                } else {
                    Text(String(localized: "location.unknown", comment: "Unknown Location"))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)

                    Text(String(localized: "location.not.at.saved.place", comment: "You are not at a saved place"))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            if let place = currentPlace {
                NavigationLink {
                    PlaceDetailView(place: place)
                } label: {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title2)
                        .foregroundStyle(place.color)
                        .symbolRenderingMode(.hierarchical)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: currentPlace != nil ?
                                    [currentPlace!.color.opacity(0.4), currentPlace!.color.opacity(0.1)] :
                                    [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .shadow(color: (currentPlace?.color ?? .gray).opacity(0.15), radius: 20, x: 0, y: 10)
        .onAppear {
            updateCurrentPlace()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isAnimating = true
            }
        }
        .onReceive(timer) { _ in
            updateDuration()
        }
    }

    private func updateCurrentPlace() {
        currentPlace = placesService.currentPlace
    }

    private func updateDuration() {
        // Update visit duration if needed
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if hours > 0 {
            return "\(hours) saat \(minutes) dakika"
        } else if minutes > 0 {
            return "\(minutes) dakika"
        } else {
            return "Az önce geldiniz"
        }
    }
}

// MARK: - Modern Stats Row

struct ModernStatsRow: View {
    let stats: ActivityStats
    let isIPad: Bool

    var body: some View {
        HStack(spacing: isIPad ? 20 : 12) {
            LocationStatCard(
                icon: "checkmark.circle.fill",
                value: "\(stats.thisWeekActivities)",
                label: String(localized: "stats.this.week", comment: "This week stats"),
                color: .green
            )

            LocationStatCard(
                icon: "flame.fill",
                value: "\(stats.currentStreak)",
                label: String(localized: "stats.streak", comment: "Streak stats"),
                color: .orange
            )

            LocationStatCard(
                icon: "star.fill",
                value: "\(stats.totalActivitiesCompleted)",
                label: String(localized: "stats.total", comment: "Total stats"),
                color: .yellow
            )
        }
    }
}

struct LocationStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
            }
            .scaleEffect(isAnimating ? 1.0 : 0.8)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: color.opacity(0.1), radius: 10, x: 0, y: 5)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Modern Quick Actions Bar

struct ModernQuickActionsBar: View {
    @Binding var showingMap: Bool
    let onGenerateActivities: () -> Void
    let onSetHome: () -> Void
    let homeLocationSet: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Generate Button
            Button(action: onGenerateActivities) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.subheadline)
                    Text(String(localized: "get.new.suggestions", comment: "Button to get new activity suggestions"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color.green, Color.mint],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color.green.opacity(0.3), radius: 10, x: 0, y: 5)
            }

            // Set Home Button (if not set)
            if !homeLocationSet {
                Button(action: onSetHome) {
                    Image(systemName: "house.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(
                            LinearGradient(
                                colors: [Color.orange, Color.red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: Color.orange.opacity(0.3), radius: 10, x: 0, y: 5)
                }
            }
        }
    }
}

// MARK: - Modern Category Filter Chips

struct ModernCategoryFilterChips: View {
    @Binding var selectedCategory: ActivityType?
    let isIPad: Bool

    let categories: [(ActivityType?, String, String)] = [
        (nil, "Tümü", "square.grid.2x2"),
        (.social, "Sosyal", "person.2.fill"),
        (.creative, "Yaratıcı", "paintbrush.fill"),
        (.exercise, "Egzersiz", "figure.run"),
        (.learning, "Öğrenme", "book.fill"),
        (.relax, "Dinlen", "leaf.fill")
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: isIPad ? 14 : 10) {
                ForEach(categories, id: \.1) { category, title, icon in
                    ModernFilterChip(
                        icon: icon,
                        title: title,
                        isSelected: selectedCategory == category,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedCategory = category
                                HapticFeedback.light()
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Modern Time Filter Chips

struct ModernTimeFilterChips: View {
    @Binding var selectedTime: String?
    let isIPad: Bool

    let times: [(String?, String, String)] = [
        (nil, "Her Zaman", "clock"),
        ("morning", "Sabah", "sunrise.fill"),
        ("afternoon", "Öğle", "sun.max.fill"),
        ("evening", "Akşam", "sunset.fill"),
        ("night", "Gece", "moon.stars.fill")
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: isIPad ? 14 : 10) {
                ForEach(times, id: \.1) { time, title, icon in
                    ModernFilterChip(
                        icon: icon,
                        title: title,
                        isSelected: selectedTime == time,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTime = time
                                HapticFeedback.light()
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

struct ModernFilterChip: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [Color.brandPrimary, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        LinearGradient(
                            colors: [Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? Color.clear : Color.secondary.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: isSelected ? Color.brandPrimary.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - Location Section Header

struct LocationSectionHeader: View {
    let icon: String
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }

            Text(title)
                .font(.title3)
                .fontWeight(.bold)

            Spacer()

            Text(String(localized: "text.count"))
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(color.gradient)
                )
        }
    }
}

// MARK: - Modern Activity Card

struct ModernActivityCard: View {
    let activity: ActivitySuggestion
    let index: Int
    let onComplete: () -> Void
    let onToggleFavorite: () -> Void
    let onTap: () -> Void

    @State private var isPressed = false
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header - Tappable
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    // Category Icon
                    ZStack {
                        Circle()
                            .fill(categoryColor.opacity(0.15))
                            .frame(width: 48, height: 48)

                        Image(systemName: categoryIcon)
                            .font(.title3)
                            .foregroundStyle(categoryColor)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(activity.title)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        Text(timeOfDayText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Status Badge
                    if activity.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                    }
                }

                // Description
                Text(activity.activityDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                HapticFeedback.light()
                onTap()
            }

            // Actions Row - Separate buttons (non-scrollable)
            HStack(spacing: 12) {
                // Complete Button
                Button(action: {
                    HapticFeedback.success()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        onComplete()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: activity.isCompleted ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.subheadline)
                        Text(activity.isCompleted ? "Tamamlandı" : "Tamamla")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(activity.isCompleted ? .green : .primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(activity.isCompleted ? Color.green.opacity(0.15) : Color.secondary.opacity(0.1))
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(activity.isCompleted)

                // Favorite Button
                Button(action: {
                    HapticFeedback.light()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        onToggleFavorite()
                    }
                }) {
                    Image(systemName: activity.isFavorite ? "star.fill" : "star")
                        .font(.title3)
                        .foregroundStyle(activity.isFavorite ? .yellow : .secondary)
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(activity.isFavorite ? Color.yellow.opacity(0.15) : Color.secondary.opacity(0.1))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [categoryColor.opacity(0.3), categoryColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .shadow(color: categoryColor.opacity(0.15), radius: 15, x: 0, y: 8)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .opacity(isAnimating ? 1.0 : 0.0)
        .offset(y: isAnimating ? 0 : 20)
        .onAppear {
            withAnimation(
                .spring(response: 0.6, dampingFraction: 0.7)
                .delay(Double(index) * 0.05)
            ) {
                isAnimating = true
            }
        }
    }

    private var categoryColor: Color {
        switch activity.type {
        case .social: return .blue
        case .creative: return .purple
        case .exercise: return .green
        case .learning: return .orange
        case .relax: return .mint
        case .outdoor: return .cyan
        }
    }

    private var categoryIcon: String {
        switch activity.type {
        case .social: return "person.2.fill"
        case .creative: return "paintbrush.fill"
        case .exercise: return "figure.run"
        case .learning: return "book.fill"
        case .relax: return "leaf.fill"
        case .outdoor: return "tree.fill"
        }
    }

    private var timeOfDayText: String {
        switch activity.timeOfDay {
        case "morning": return "🌅 Sabah"
        case "afternoon": return "☀️ Öğle"
        case "evening": return "🌆 Akşam"
        case "night": return "🌙 Gece"
        default: return ""
        }
    }
}

// MARK: - Modern Home Location Warning

struct ModernHomeLocationWarning: View {
    let onSetHome: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.orange, Color.red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)

                    Image(systemName: "house.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(String(localized: "home.location.not.set", comment: "Home location not set warning"))
                        .font(.headline)
                        .fontWeight(.bold)

                    Text(String(localized: "set.home.location.for.suggestions", comment: "Set home location for suggestions message"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Button(action: onSetHome) {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                    Text(String(localized: "set.current.location", comment: "Set current location button"))
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color.orange, Color.red],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.4), Color.red.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .shadow(color: Color.orange.opacity(0.2), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Modern Empty Search State

struct ModernEmptySearchState: View {
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.1), Color.cyan.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "magnifyingglass")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue, Color.cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 8) {
                Text(String(localized: "text.sonuç.bulunamadı"))
                    .font(.title2)
                    .fontWeight(.bold)

                Text(String(localized: "text.farklı.anahtar.kelimeler.deneyin"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Modern Toolbar Button

struct ModernToolbarButton: View {
    let icon: String
    let gradient: [Color]

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: gradient.map { $0.opacity(0.15) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)

            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
}

#Preview {
    LocationView()
}

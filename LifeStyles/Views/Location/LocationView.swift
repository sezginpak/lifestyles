//
//  LocationView.swift
//  LifeStyles
//
//  Created by Claude on 15.10.2025.
//

import SwiftUI
import SwiftData
import MapKit

struct LocationView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = LocationViewModel()
    @State private var showingHistorySheet = false
    @State private var showLocationPermissionAlert = false

    // Yeni state'ler
    @State private var selectedActivity: ActivitySuggestion?
    @State private var showingActivityDetail = false

    // MARK: - Computed Properties

    private var brandGradient: LinearGradient {
        LinearGradient(
            colors: [Color.brandPrimary, Color.purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var greenGradient: LinearGradient {
        LinearGradient(
            colors: [Color.green, Color.mint],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var warningGradient: LinearGradient {
        LinearGradient(
            colors: [Color.orange, Color.red],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Mevcut Durum
                    CurrentLocationCard()
                        .padding(.horizontal)

                    // İstatistik Kartı
                    if let stats = viewModel.activityStats {
                        ActivityStatsCard(stats: stats)
                            .padding(.horizontal)
                    }

                    // Streak Kartı
                    if let stats = viewModel.activityStats, stats.currentStreak > 0 {
                        StreakCard(currentStreak: stats.currentStreak)
                            .padding(.horizontal)
                    }

                    // Badge Showcase
                    if !viewModel.badges.isEmpty {
                        BadgeShowcaseCard(badges: viewModel.badges)
                            .padding(.horizontal)
                    }

                    // Kategori Filtreleri
                    CategoryFilterChips(selectedCategory: $viewModel.selectedCategory)
                        .padding(.vertical, 4)

                    // Zaman Filtreleri
                    TimeFilterChips(selectedTime: $viewModel.selectedTimeOfDay)
                        .padding(.vertical, 4)

                    // Favori Aktiviteler
                    if !viewModel.favoriteActivities.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                Text(String(localized: "location.my.favorites", comment: "My Favorites"))
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Spacer()
                                Text("\(viewModel.favoriteActivities.count)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)

                            ForEach(viewModel.favoriteActivities) { activity in
                                EnhancedActivityCard(
                                    activity: activity,
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
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Aktivite Önerileri
                    if !viewModel.filteredActivities.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            // Kompakt header
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(brandGradient)
                                        .frame(width: 28, height: 28)

                                    Image(systemName: "lightbulb.fill")
                                        .font(.caption)
                                        .foregroundStyle(.white)
                                }

                                Text(String(
                                    localized: "suggested.activities",
                                    comment: "Suggested activities section title"
                                ))
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(brandGradient)

                                Spacer()

                                // Badge - Activity count
                                Text("\(viewModel.suggestedActivities.count)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(brandGradient)
                                    .clipShape(Capsule())
                            }
                            .padding(.horizontal)

                            ForEach(viewModel.filteredActivities) { activity in
                                EnhancedActivityCard(
                                    activity: activity,
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
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Aktivite Üret Butonu - Kompakt
                    Button {
                        HapticFeedback.medium()
                        viewModel.generateActivitiesWithTimeOfDay(context: modelContext)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "lightbulb.fill")
                                .font(.subheadline)

                            Text(String(localized: "get.new.suggestions", comment: "Button to get new activity suggestions"))
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Spacer()

                            Image(systemName: "sparkles")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(greenGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: Color.green.opacity(0.25), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal)

                    // Ev Konumu Ayarlanmadı - Kompakt
                    if !viewModel.homeLocationSet {
                        VStack(spacing: 14) {
                            HStack(spacing: 12) {
                                // Icon
                                ZStack {
                                    Circle()
                                        .fill(warningGradient)
                                        .frame(width: 50, height: 50)
                                        .glowEffect(color: .orange, radius: 8)

                                    Image(systemName: "house.fill")
                                        .font(.title3)
                                        .foregroundStyle(.white)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(String(
                                        localized: "home.location.not.set",
                                        comment: "Home location not set warning"
                                    ))
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(warningGradient)

                                    Text(String(
                                        localized: "set.home.location.for.suggestions",
                                        comment: "Set home location for suggestions message"
                                    ))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                }

                                Spacer()
                            }

                            Button {
                                HapticFeedback.success()
                                if let location = LocationService.shared.currentLocation {
                                    viewModel.setHomeLocation(
                                        latitude: location.coordinate.latitude,
                                        longitude: location.coordinate.longitude
                                    )
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "location.fill")
                                        .font(.subheadline)

                                    Text(String(localized: "set.current.location", comment: "Set current location button"))
                                        .fontWeight(.semibold)
                                        .font(.subheadline)
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [Color.orange, Color.red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .shadow(color: Color.orange.opacity(0.25), radius: 8, x: 0, y: 4)
                            }
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.orange.opacity(0.3), Color.red.opacity(0.3)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                )
                        )
                        .shadow(color: Color.orange.opacity(0.12), radius: 12, x: 0, y: 6)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(String(localized: "tab.location", comment: "Location/Activities tab title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticFeedback.light()
                        showingHistorySheet = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.15), Color.cyan.opacity(0.15)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 36, height: 36)

                            Image(systemName: "map.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.blue, Color.cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .symbolRenderingMode(.hierarchical)
                        }
                    }
                    .accessibilityLabel(String(localized: "location.history", comment: "Location history button"))
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color.brandPrimary.opacity(0.02),
                        Color.purple.opacity(0.02)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .task {
                // Async olarak yükle - UI donmasını önle
                viewModel.setModelContext(modelContext)

                // Main thread işlemleri önce
                viewModel.updateLocationStatus()
                viewModel.updatePeriodicTrackingStatus()

                // Ağır işlemleri arka planda çalıştır
                await Task.detached {
                    // Background thread'de çalışacak
                    await viewModel.loadOrCreateStats(context: modelContext)
                    await viewModel.loadBadges(context: modelContext)
                    await viewModel.loadFavoriteActivities(context: modelContext)
                }.value

                // Location tracking sonra başlat
                viewModel.startTracking()

                // Otomatik başlatma
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
        }
    }
}

struct StatusCard: View {
    let isAtHome: Bool
    let hoursAtHome: Double

    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 12) {
            // Kompakt icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isAtHome ? [Color.blue, Color.cyan] : [Color.green, Color.mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .glowEffect(color: isAtHome ? .blue : .green, radius: 8)

                Image(systemName: isAtHome ? "house.fill" : "location.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .symbolEffect(.bounce, value: isAnimating)
            }
            .scaleEffect(isAnimating ? 1.0 : 0.9)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(isAtHome ? String(localized: "status.at.home", comment: "User is at home status") : String(localized: "status.outside", comment: "User is outside status"))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: isAtHome ? [Color.blue, Color.cyan] : [Color.green, Color.mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    // Status badge
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(isAtHome ? .blue : .green)
                }

                if isAtHome && hoursAtHome > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text(String(format: NSLocalizedString("hours.at.home.format", comment: "Hours spent at home format"), hoursAtHome))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: isAtHome ? [Color.blue.opacity(0.3), Color.cyan.opacity(0.3)] : [Color.green.opacity(0.3), Color.mint.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .shadow(color: (isAtHome ? Color.blue : Color.green).opacity(0.12), radius: 10, x: 0, y: 4)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isAnimating = true
            }
        }
    }
}

struct ActivityCard: View {
    let activity: ActivitySuggestion
    let onComplete: () -> Void

    @State private var isPressed = false
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 12) {
            // Kompakt icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: activity.isCompleted ?
                                [Color.green, Color.mint] :
                                [Color.brandPrimary, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .glowEffect(color: activity.isCompleted ? .green : .brandPrimary, radius: 6)

                Image(systemName: activity.isCompleted ? "checkmark" : "lightbulb.fill")
                    .font(.callout)
                    .foregroundStyle(.white)
                    .symbolEffect(.bounce, value: isAnimating)
            }
            .scaleEffect(isAnimating ? 1.0 : 0.9)

            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(activity.activityDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            // Action button
            Button {
                HapticFeedback.success()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    onComplete()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            activity.isCompleted ?
                                Color.green.opacity(0.15) :
                                Color.brandPrimary.opacity(0.15)
                        )
                        .frame(width: 36, height: 36)

                    Image(systemName: activity.isCompleted ? "checkmark.circle.fill" : "checkmark.circle")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: activity.isCompleted ?
                                    [Color.green, Color.mint] :
                                    [Color.brandPrimary, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .disabled(activity.isCompleted)
            .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: activity.isCompleted ?
                                    [Color.green.opacity(0.3), Color.mint.opacity(0.3)] :
                                    [Color.brandPrimary.opacity(0.2), Color.purple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .shadow(
            color: (activity.isCompleted ? Color.green : Color.brandPrimary).opacity(0.08),
            radius: 8,
            x: 0,
            y: 4
        )
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Current Location Card (With SavedPlaces)

struct CurrentLocationCard: View {
    @State private var placesService = SavedPlacesService.shared
    @State private var currentPlace: SavedPlace?
    @State private var isAnimating = false
    @State private var visitDuration: TimeInterval = 0

    // Timer to update duration
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: currentPlace != nil ? [currentPlace!.color, currentPlace!.color.opacity(0.7)] : [Color.gray, Color.gray.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .glowEffect(color: currentPlace?.color ?? .gray, radius: 8)

                if let place = currentPlace {
                    Text(place.emoji)
                        .font(.title2)
                        .symbolEffect(.bounce, value: isAnimating)
                } else {
                    Image(systemName: "location.slash.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
            }
            .scaleEffect(isAnimating ? 1.0 : 0.9)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if let place = currentPlace {
                        Text(String(format: NSLocalizedString("location.at.place", comment: "At place name"), place.name))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [place.color, place.color.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    } else {
                        Text(String(localized: "location.unknown", comment: "Unknown Location"))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                    }

                    // Status badge
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(currentPlace?.color ?? .gray)
                }

                if let place = currentPlace, visitDuration > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text(formatDuration(visitDuration))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else if currentPlace == nil {
                    Text(String(localized: "location.not.at.saved.place", comment: "You are not at a saved place"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Suggestions button
            if let place = currentPlace {
                NavigationLink {
                    PlaceDetailView(place: place)
                } label: {
                    Image(systemName: "info.circle.fill")
                        .font(.title3)
                        .foregroundStyle(place.color)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: currentPlace != nil ? [currentPlace!.color.opacity(0.3), currentPlace!.color.opacity(0.1)] : [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .shadow(color: (currentPlace?.color ?? .gray).opacity(0.12), radius: 10, x: 0, y: 4)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isAnimating = true
            }
            updateCurrentPlace()
        }
        .onReceive(timer) { _ in
            updateDuration()
        }
    }

    private func updateCurrentPlace() {
        currentPlace = placesService.currentPlace

        // Calculate duration if there's an ongoing visit
        //if let visit = placesService.currentVisit, visit.isOngoing {
        //     visitDuration = Date().timeIntervalSince(visit.arrivalTime)
        // }
    }

    private func updateDuration() {
        //if let visit = placesService.currentVisit, visit.isOngoing {
        //     visitDuration = Date().timeIntervalSince(visit.arrivalTime)
        // }
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

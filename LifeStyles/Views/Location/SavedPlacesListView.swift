//
//  SavedPlacesListView.swift
//  LifeStyles
//
//  Created by Claude on 25.10.2025.
//  Kayıtlı yerlerin listesi ve yönetimi
//

import SwiftUI
import SwiftData
import CoreLocation

struct SavedPlacesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \SavedPlace.lastVisitedAt, order: .reverse)
    private var allPlaces: [SavedPlace]

    @State private var searchText = ""
    @State private var selectedCategory: PlaceCategory?
    @State private var showAddPlace = false
    @State private var selectedPlace: SavedPlace?
    @State private var showPlaceDetail = false
    @State private var placeToDelete: SavedPlace?
    @State private var showDeleteAlert = false

    // Get current location for distance calculation
    @State private var currentLocation: CLLocation?

    var filteredPlaces: [SavedPlace] {
        var places = allPlaces

        // Filter by category
        if let category = selectedCategory {
            places = places.filter { $0.category == category }
        }

        // Filter by search
        if !searchText.isEmpty {
            places = places.filter { place in
                place.name.localizedCaseInsensitiveContains(searchText) ||
                (place.address?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        return places
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category Filter
                categoryFilterSection

                if filteredPlaces.isEmpty {
                    emptyStateView
                } else {
                    placesList
                }
            }
            .navigationTitle("Kayıtlı Yerler")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Yer ara...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddPlace = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showAddPlace) {
                PlacePickerMapView(initialCoordinate: currentLocation?.coordinate)
            }
            .sheet(item: $selectedPlace) { place in
                PlaceDetailView(place: place)
            }
            .alert("Yeri Sil", isPresented: $showDeleteAlert, presenting: placeToDelete) { place in
                Button("İptal", role: .cancel) {
                    placeToDelete = nil
                }
                Button("Sil", role: .destructive) {
                    deletePlace(place)
                }
            } message: { place in
                Text(String(format: NSLocalizedString("location.delete.confirm", comment: "Delete place confirmation"), place.name))
            }
            .onAppear {
                currentLocation = CLLocation(
                    latitude: SavedPlacesService.shared.currentLocation?.coordinate.latitude ?? 0,
                    longitude: SavedPlacesService.shared.currentLocation?.coordinate.longitude ?? 0
                )
            }
        }
    }

    // MARK: - Category Filter

    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.small) {
                // All filter
                CategoryFilterChip(
                    title: "Tümü",
                    icon: "mappin.circle.fill",
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }

                // Category filters
                ForEach(PlaceCategory.allCases, id: \.self) { category in
                    let count = allPlaces.filter { $0.category == category }.count
                    if count > 0 {
                        CategoryFilterChip(
                            title: category.displayName,
                            icon: category.icon,
                            count: count,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, Spacing.small)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Places List

    private var placesList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.medium) {
                ForEach(filteredPlaces) { place in
                    PlaceCard(
                        place: place,
                        currentLocation: currentLocation,
                        onTap: {
                            selectedPlace = place
                            showPlaceDetail = true
                        }
                    )
                    .contextMenu {
                        Button {
                            selectedPlace = place
                            showPlaceDetail = true
                        } label: {
                            Label("Detaylar", systemImage: "info.circle")
                        }

                        Divider()

                        Button(role: .destructive) {
                            placeToDelete = place
                            showDeleteAlert = true
                        } label: {
                            Label("Sil", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            placeToDelete = place
                            showDeleteAlert = true
                        } label: {
                            Label("Sil", systemImage: "trash")
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Spacing.large) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            VStack(spacing: Spacing.small) {
                Text(String(localized: "location.saved.places.empty", comment: "No Saved Places Yet"))
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(searchText.isEmpty ? String(localized: "location.saved.places.save.frequent", comment: "Save your frequent places") : String(localized: "common.no.results", comment: "No results found"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if searchText.isEmpty {
                Button {
                    showAddPlace = true
                } label: {
                    Label("Yer Ekle", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .padding()
                        .background(Color.brandPrimary.gradient)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
    }

    // MARK: - Actions

    private func deletePlace(_ place: SavedPlace) {
        SavedPlacesService.shared.deletePlace(place, context: modelContext)

        do {
            try modelContext.save()
            HapticFeedback.success()
        } catch {
            print("❌ Failed to delete place: \(error)")
            HapticFeedback.error()
        }

        placeToDelete = nil
    }
}

// MARK: - Place Card

struct PlaceCard: View {
    let place: SavedPlace
    let currentLocation: CLLocation?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.medium) {
                // Emoji/Icon
                ZStack {
                    Circle()
                        .fill(place.color.gradient)
                        .frame(width: 60, height: 60)

                    Text(place.emoji)
                        .font(.largeTitle)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(place.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if let address = place.address {
                        Text(address)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    HStack(spacing: Spacing.small) {
                        // Distance
                        if let location = currentLocation {
                            HStack(spacing: 2) {
                                Image(systemName: "location.fill")
                                    .font(.caption2)
                                Text(place.formattedDistance(from: location))
                                    .font(.caption2)
                            }
                            .foregroundStyle(.secondary)
                        }

                        // Visit count
                        if place.visitCount > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "person.fill")
                                    .font(.caption2)
                                Text(String(format: NSLocalizedString("location.visits.count", comment: "Visit count"), place.visitCount))
                                    .font(.caption2)
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.normal))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Filter Chip

struct CategoryFilterChip: View {
    let title: String
    let icon: String
    var count: Int? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let count = count {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.3) : Color(.tertiarySystemBackground))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.brandPrimary : Color(.tertiarySystemBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    SavedPlacesListView()
}

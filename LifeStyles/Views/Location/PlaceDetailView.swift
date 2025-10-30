//
//  PlaceDetailView.swift
//  LifeStyles
//
//  Created by Claude on 25.10.2025.
//  Kayıtlı yer detay ekranı
//

import SwiftUI
import SwiftData
import MapKit

struct PlaceDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let place: SavedPlace

    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var cameraPosition: MapCameraPosition

    init(place: SavedPlace) {
        self.place = place
        _cameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: place.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.large) {
                    mapSection
                    infoSection
                    statisticsSection
                    visitsSection
                    suggestionsSection
                }
                .padding()
            }
            .navigationTitle(place.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showEditSheet = true
                        } label: {
                            Label("Düzenle", systemImage: "pencil")
                        }

                        Divider()

                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Label("Sil", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                PlacePickerMapView(existingPlace: place)
            }
            .alert("Yeri Sil", isPresented: $showDeleteAlert) {
                Button("İptal", role: .cancel) {}
                Button("Sil", role: .destructive) {
                    deletePlace()
                }
            } message: {
                Text(String(format: NSLocalizedString("location.delete.confirm", comment: "Delete place confirmation"), place.name))
            }
        }
    }

    // MARK: - Map Section

    private var mapSection: some View {
        Map(position: $cameraPosition) {
            Annotation(place.name, coordinate: place.coordinate) {
                ZStack {
                    Circle()
                        .fill(place.color.gradient)
                        .frame(width: 50, height: 50)
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)

                    Text(place.emoji)
                        .font(.title)
                }
            }

            MapCircle(center: place.coordinate, radius: place.radius)
                .foregroundStyle(place.color.opacity(0.2))
                .stroke(place.color, lineWidth: 2)
        }
        .mapStyle(.standard(elevation: .realistic))
        .frame(height: 250)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.normal))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.normal)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text(String(localized: "location.information", comment: "Information"))
                .font(.headline)

            VStack(spacing: Spacing.small) {
                PlaceInfoRow(icon: place.category.icon, title: "Kategori", value: place.category.displayName)
                PlaceInfoRow(icon: "location.fill", title: "Adres", value: place.displayAddress)
                PlaceInfoRow(icon: "ruler", title: "Geofence Yarıçapı", value: "\(Int(place.radius)) m")

                if place.isGeofenceEnabled {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(localized: "location.notifications.active", comment: "Notifications Active"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }

                if let notes = place.notes, !notes.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "note.text")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(String(localized: "location.notes", comment: "Notes"))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                        }
                        Text(notes)
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.normal))
    }

    // MARK: - Statistics Section

    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text(String(localized: "location.place.statistics", comment: "Statistics"))
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.medium) {
                StatCard(
                    title: "Ziyaret Sayısı",
                    value: "\(place.visitCount)",
                    icon: "person.fill",
                    color: .blue
                )

                StatCard(
                    title: "Toplam Süre",
                    value: place.formattedTotalTime,
                    icon: "clock.fill",
                    color: .purple
                )

                StatCard(
                    title: "Ortalama Kalış",
                    value: place.averageVisitDuration,
                    icon: "hourglass",
                    color: .orange
                )

                StatCard(
                    title: "Son Ziyaret",
                    value: place.lastVisitedRelative,
                    icon: "calendar",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.normal))
    }

    // MARK: - Visits Section

    private var visitsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text(String(localized: "location.recent.visits", comment: "Recent visits"))
                .font(.headline)

            let recentVisits = PlaceVisitTracker.shared.getVisits(for: place, context: modelContext).prefix(5)

            if recentVisits.isEmpty {
                Text(String(localized: "location.place.no.visits", comment: "No visit records yet"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                VStack(spacing: Spacing.small) {
                    ForEach(Array(recentVisits)) { visit in
                        VisitRow(visit: visit)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.normal))
    }

    // MARK: - Suggestions Section

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text(String(localized: "location.what.to.do", comment: "What can you do here?"))
                .font(.headline)

            let suggestions = PlaceBasedSuggestions.shared.getSuggestions(for: place)

            VStack(spacing: Spacing.small) {
                ForEach(suggestions.prefix(4)) { suggestion in
                    SuggestionRow(suggestion: suggestion)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.normal))
    }

    // MARK: - Actions

    private func deletePlace() {
        SavedPlacesService.shared.deletePlace(place, context: modelContext)

        do {
            try modelContext.save()
            HapticFeedback.success()
            dismiss()
        } catch {
            print("❌ Failed to delete place: \(error)")
            HapticFeedback.error()
        }
    }
}

// MARK: - Place Info Row

struct PlaceInfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.small) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.normal))
    }
}

// MARK: - Visit Row

struct VisitRow: View {
    let visit: PlaceVisit

    var body: some View {
        HStack(spacing: Spacing.small) {
            Circle()
                .fill(Color.brandPrimary)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(visit.formattedArrival)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(visit.formattedDuration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if visit.isOngoing {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)

                    Text(String(localized: "location.ongoing", comment: "Ongoing"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Suggestion Row

struct SuggestionRow: View {
    let suggestion: PlaceSuggestion

    var body: some View {
        HStack(spacing: Spacing.medium) {
            Image(systemName: suggestion.icon)
                .font(.title3)
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(suggestion.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.normal))
    }
}

// MARK: - Preview

#Preview {
    let place = SavedPlace(
        name: "Ev",
        category: .home,
        latitude: 41.0082,
        longitude: 28.9784,
        address: "Beşiktaş, İstanbul"
    )
    place.visitCount = 42
    place.totalTimeSpent = 72000 // 20 hours

    return PlaceDetailView(place: place)
}

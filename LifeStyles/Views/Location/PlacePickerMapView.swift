//
//  PlacePickerMapView.swift
//  LifeStyles
//
//  Created by Claude on 25.10.2025.
//  Harita üzerinde pin ile yer seçimi
//

import SwiftUI
import MapKit
import CoreLocation

struct PlacePickerMapView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // Existing place to edit (nil for new place)
    let existingPlace: SavedPlace?

    // Map state
    @State private var cameraPosition: MapCameraPosition
    @State private var selectedCoordinate: CLLocationCoordinate2D
    @State private var address: String = "Konum alınıyor..."

    // Form state
    @State private var placeName: String
    @State private var selectedCategory: PlaceCategory
    @State private var selectedEmoji: String
    @State private var selectedColor: String
    @State private var radius: Double
    @State private var isGeofenceEnabled: Bool
    @State private var notifyOnEntry: Bool
    @State private var notifyOnExit: Bool
    @State private var notes: String

    // UI state
    @State private var isGeocodingAddress = false
    @State private var showEmojiPicker = false
    @State private var showSaveConfirmation = false

    init(existingPlace: SavedPlace? = nil, initialCoordinate: CLLocationCoordinate2D? = nil) {
        self.existingPlace = existingPlace

        let coordinate = existingPlace?.coordinate ?? initialCoordinate ?? CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784) // Istanbul

        _selectedCoordinate = State(initialValue: coordinate)
        _cameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )))

        // Initialize form with existing or default values
        _placeName = State(initialValue: existingPlace?.name ?? "")
        _selectedCategory = State(initialValue: existingPlace?.category ?? .custom)
        _selectedEmoji = State(initialValue: existingPlace?.emoji ?? "📍")
        _selectedColor = State(initialValue: existingPlace?.colorHex ?? PlaceCategory.custom.defaultColor)
        _radius = State(initialValue: existingPlace?.radius ?? 100)
        _isGeofenceEnabled = State(initialValue: existingPlace?.isGeofenceEnabled ?? true)
        _notifyOnEntry = State(initialValue: existingPlace?.notifyOnEntry ?? true)
        _notifyOnExit = State(initialValue: existingPlace?.notifyOnExit ?? false)
        _notes = State(initialValue: existingPlace?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Map View
                mapSection
                    .frame(height: 300)

                // Form
                ScrollView {
                    VStack(spacing: Spacing.large) {
                        basicInfoSection
                        categorySection
                        geofencingSection
                        notesSection
                    }
                    .padding()
                }
            }
            .navigationTitle(existingPlace == nil ? "Yeni Yer Ekle" : "Yeri Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(existingPlace == nil ? "Kaydet" : "Güncelle") {
                        savePlace()
                    }
                    .fontWeight(.semibold)
                    .disabled(placeName.isEmpty)
                }
            }
            .alert("Yer Kaydedildi", isPresented: $showSaveConfirmation) {
                Button("Tamam") {
                    dismiss()
                }
            } message: {
                Text(String(format: NSLocalizedString("location.place.saved.message", comment: "Place saved"), placeName))
            }
            .onAppear {
                // Reverse geocode initial location
                reverseGeocode(coordinate: selectedCoordinate)
            }
        }
    }

    // MARK: - Map Section

    private var mapSection: some View {
        ZStack {
            Map(position: $cameraPosition) {
                // Center pin (fixed position)
                Annotation("", coordinate: selectedCoordinate) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: selectedColor).gradient)
                            .frame(width: 50, height: 50)
                            .shadow(color: .black.opacity(0.2), radius: 4, y: 2)

                        Text(selectedEmoji)
                            .font(.title)
                    }
                }

                // Radius circle
                MapCircle(center: selectedCoordinate, radius: radius)
                    .foregroundStyle(Color(hex: selectedColor).opacity(0.2))
                    .stroke(Color(hex: selectedColor), lineWidth: 2)
            }
            .mapStyle(.standard(elevation: .realistic))
            .onMapCameraChange { context in
                // Update selected coordinate as map moves
                selectedCoordinate = context.region.center

                // Debounced reverse geocoding
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    reverseGeocode(coordinate: context.region.center)
                }
            }

            // Crosshair guide (optional - helps center selection)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "location.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())

                        Text(address)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.7))
                            .clipShape(Capsule())
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 200)
                    }
                    Spacer()
                }
                .padding(.bottom, 16)
            }
        }
    }

    // MARK: - Basic Info Section

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text(String(localized: "location.place.basic.info", comment: "Basic Information"))
                .font(.headline)

            // Name
            HStack {
                Text(String(localized: "location.place.name", comment: "Name"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                TextField("Yer adı", text: $placeName)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 200)
            }

            // Emoji
            HStack {
                Text(String(localized: "location.place.emoji", comment: "Emoji"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    showEmojiPicker = true
                } label: {
                    Text(selectedEmoji)
                        .font(.title2)
                        .frame(width: 50, height: 50)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.normal))
                }
                .popover(isPresented: $showEmojiPicker) {
                    PlaceEmojiPickerView(selectedEmoji: $selectedEmoji, category: selectedCategory)
                }
            }

            // Color
            HStack {
                Text(String(localized: "location.place.color", comment: "Color"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                ColorPickerRow(selectedColor: $selectedColor)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.normal))
    }

    // MARK: - Category Section

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text(String(localized: "location.place.category", comment: "Category"))
                .font(.headline)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: Spacing.small) {
                ForEach(PlaceCategory.allCases, id: \.self) { category in
                    PlaceCategoryButton(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                        selectedEmoji = category.defaultEmoji
                        selectedColor = category.defaultColor
                        HapticFeedback.light()
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.normal))
    }

    // MARK: - Geofencing Section

    private var geofencingSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text(String(localized: "location.place.geofencing", comment: "Geofencing"))
                .font(.headline)

            Toggle("Geofencing Aktif", isOn: $isGeofenceEnabled)

            if isGeofenceEnabled {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    HStack {
                        Text(String(localized: "location.place.radius", comment: "Radius"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: NSLocalizedString("location.radius.meters", comment: "Radius in meters"), Int(radius)))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    Slider(value: $radius, in: 50...500, step: 25)
                        .tint(Color(hex: selectedColor))
                }

                Divider()

                Toggle("Girişte Bildirim", isOn: $notifyOnEntry)
                Toggle("Çıkışta Bildirim", isOn: $notifyOnExit)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.normal))
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text(String(localized: "location.place.notes.optional", comment: "Notes Optional"))
                .font(.headline)

            TextField("Notlarınız...", text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.roundedBorder)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.normal))
    }

    // MARK: - Actions

    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        isGeocodingAddress = true

        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                isGeocodingAddress = false

                if let placemark = placemarks?.first {
                    // Build address string
                    var components: [String] = []

                    if let street = placemark.thoroughfare {
                        components.append(street)
                    }
                    if let subLocality = placemark.subLocality {
                        components.append(subLocality)
                    }
                    if let locality = placemark.locality {
                        components.append(locality)
                    }

                    address = components.isEmpty ? "Adres bulunamadı" : components.joined(separator: ", ")

                    // Auto-suggest name if empty
                    if placeName.isEmpty {
                        if let name = placemark.name {
                            placeName = name
                        }
                    }
                } else {
                    address = "Adres bulunamadı"
                }
            }
        }
    }

    private func savePlace() {
        if let existing = existingPlace {
            // Update existing place
            existing.name = placeName
            existing.emoji = selectedEmoji
            existing.colorHex = selectedColor
            existing.category = selectedCategory
            existing.updateLocation(latitude: selectedCoordinate.latitude, longitude: selectedCoordinate.longitude, address: address)
            existing.radius = radius
            existing.isGeofenceEnabled = isGeofenceEnabled
            existing.notifyOnEntry = notifyOnEntry
            existing.notifyOnExit = notifyOnExit
            existing.notes = notes.isEmpty ? nil : notes

            // Re-setup geofencing
            SavedPlacesService.shared.updateGeofencing(for: existing)
        } else {
            // Create new place
            let place = SavedPlace(
                name: placeName,
                emoji: selectedEmoji,
                colorHex: selectedColor,
                category: selectedCategory,
                latitude: selectedCoordinate.latitude,
                longitude: selectedCoordinate.longitude,
                address: address,
                radius: radius,
                isGeofenceEnabled: isGeofenceEnabled,
                notifyOnEntry: notifyOnEntry,
                notifyOnExit: notifyOnExit,
                notes: notes.isEmpty ? nil : notes
            )

            modelContext.insert(place)

            // Setup geofencing
            SavedPlacesService.shared.setupGeofencing(for: place)
        }

        do {
            try modelContext.save()
            HapticFeedback.success()
            showSaveConfirmation = true
        } catch {
            print("❌ Failed to save place: \(error)")
            HapticFeedback.error()
        }
    }
}

// MARK: - Category Button

struct PlaceCategoryButton: View {
    let category: PlaceCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: category.icon)
                    .font(.title3)
                Text(category.displayName)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color(hex: category.defaultColor).opacity(0.2) : Color(.tertiarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.normal)
                    .stroke(isSelected ? Color(hex: category.defaultColor) : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.normal))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Color Picker Row

struct ColorPickerRow: View {
    @Binding var selectedColor: String

    let colors = [
        "3B82F6", // Blue
        "8B5CF6", // Purple
        "EC4899", // Pink
        "EF4444", // Red
        "F59E0B", // Amber
        "10B981", // Green
        "14B8A6", // Teal
        "6366F1", // Indigo
    ]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(colors, id: \.self) { colorHex in
                Circle()
                    .fill(Color(hex: colorHex))
                    .frame(width: 30, height: 30)
                    .overlay(
                        Circle()
                            .stroke(selectedColor == colorHex ? Color.primary : Color.clear, lineWidth: 2)
                    )
                    .onTapGesture {
                        selectedColor = colorHex
                        HapticFeedback.light()
                    }
            }
        }
    }
}

// MARK: - Emoji Picker

struct PlaceEmojiPickerView: View {
    @Binding var selectedEmoji: String
    let category: PlaceCategory
    @Environment(\.dismiss) private var dismiss

    let emojisByCategory: [PlaceCategory: [String]] = [
        .home: ["🏠", "🏡", "🏘️", "🏢", "🏚️", "🛏️"],
        .work: ["💼", "🏢", "🏭", "🏗️", "💻", "📊"],
        .gym: ["💪", "🏋️", "🤸", "🧘", "🏃", "⚽"],
        .cafe: ["☕", "🍵", "🧋", "🥤", "🍰", "🥐"],
        .shopping: ["🛒", "🛍️", "👕", "👗", "👟", "💄"],
        .restaurant: ["🍽️", "🍕", "🍔", "🍜", "🍱", "🍣"],
        .park: ["🌳", "🌲", "🏞️", "🌄", "⛰️", "🎋"],
        .school: ["🎓", "📚", "🏫", "✏️", "📖", "🎒"],
        .hospital: ["🏥", "💊", "💉", "🩺", "⚕️", "🚑"],
        .custom: ["📍", "⭐", "❤️", "🎯", "🔖", "📌"],
    ]

    var body: some View {
        VStack(spacing: Spacing.medium) {
            Text(String(localized: "location.place.emoji.select", comment: "Select Emoji"))
                .font(.headline)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: Spacing.medium) {
                ForEach(emojisByCategory[category] ?? emojisByCategory[.custom]!, id: \.self) { emoji in
                    Text(emoji)
                        .font(.largeTitle)
                        .frame(width: 50, height: 50)
                        .background(selectedEmoji == emoji ? Color(.tertiarySystemBackground) : Color.clear)
                        .clipShape(Circle())
                        .onTapGesture {
                            selectedEmoji = emoji
                            HapticFeedback.light()
                            dismiss()
                        }
                }
            }
        }
        .padding()
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    PlacePickerMapView()
}

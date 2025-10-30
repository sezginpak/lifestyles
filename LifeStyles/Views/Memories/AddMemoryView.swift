//
//  AddMemoryView.swift
//  LifeStyles
//
//  Created by Claude on 26.10.2025.
//  Add/Edit Memory Form - Instagram-style Modern Design
//

import SwiftUI
import SwiftData
import PhotosUI
import CoreLocation
import Photos

struct AddMemoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: MemoriesViewModel

    // Form State
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var loadedImages: [UIImage] = []
    @State private var title: String = ""
    @State private var selectedDate: Date = Date()
    @State private var notes: String = ""
    @State private var tags: [String] = []
    @State private var tagInput: String = ""
    @State private var selectedFriends: [Friend] = []
    @State private var selectedLocation: CLLocationCoordinate2D?
    @State private var locationName: String?

    // UI State
    @State private var showingLocationPicker = false
    @State private var showingFriendsPicker = false
    @State private var showingCamera = false
    @State private var showingMediaPicker = false
    @State private var selectedMedia: [MediaItem] = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGray6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Main content
                ScrollView {
                    VStack(spacing: 0) {
                        // MARK: - Photo Section (Top)
                        photosSectionModern

                        // MARK: - Details Card (Bottom)
                        detailsCard
                    }
                }
            }
            .navigationTitle(loadedImages.isEmpty ? "Yeni Anı" : "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .symbolRenderingMode(.hierarchical)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveMemory()
                    } label: {
                        if loadedImages.isEmpty {
                            Text("Kaydet")
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Kaydet")
                                .fontWeight(.semibold)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.teal, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                    }
                    .disabled(loadedImages.isEmpty)
                }
            }
            .alert("Hata", isPresented: $showError) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)

                            Text("Kaydediliyor...")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                        }
                        .padding(32)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                        )
                    }
                }
            }
            .sheet(isPresented: $showingCamera) {
                ImageVideoPicker(
                    selectedMedia: $selectedMedia,
                    sourceType: .camera,
                    mediaTypes: ["public.image"]
                )
                .ignoresSafeArea()
            }
            .onChange(of: selectedMedia.count) { oldCount, newCount in
                if newCount > oldCount {
                    loadMediaItems(selectedMedia)
                }
            }
        }
    }

    // MARK: - Modern Photos Section

    private var photosSectionModern: some View {
        VStack(spacing: 0) {
            if loadedImages.isEmpty {
                // Empty State - Large and prominent
                VStack(spacing: 24) {
                    Spacer()

                    // Icon with gradient
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.teal.opacity(0.2), .blue.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)

                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 50))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.teal, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    VStack(spacing: 8) {
                        Text(String(localized: "memories.add.title", comment: "Add your memories"))
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(String(localized: "memories.add.subtitle", comment: "Immortalize special moments"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    // Action buttons
                    HStack(spacing: 16) {
                        // Camera button
                        Button {
                            HapticFeedback.medium()
                            showingCamera = true
                        } label: {
                            VStack(spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 80, height: 80)
                                        .shadow(color: .teal.opacity(0.3), radius: 10, y: 5)

                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 32))
                                        .foregroundStyle(.teal)
                                }

                                Text("Kamera")
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                            }
                        }

                        // Gallery button
                        PhotosPicker(
                            selection: $selectedPhotos,
                            maxSelectionCount: 10,
                            matching: .images
                        ) {
                            VStack(spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 80, height: 80)
                                        .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)

                                    Image(systemName: "photo.stack.fill")
                                        .font(.system(size: 32))
                                        .foregroundStyle(.blue)
                                }

                                Text("Galeri")
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                    .padding(.top, 8)

                    Spacer()
                }
                .frame(height: 500)
                .onChange(of: selectedPhotos) { _, newItems in
                    loadPhotos(from: newItems)
                }
            } else {
                // Photo Grid - Instagram style
                TabView {
                    ForEach(Array(loadedImages.enumerated()), id: \.offset) { index, image in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 400)
                                .clipped()

                            // Delete button with glassmorphism
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    loadedImages.remove(at: index)
                                    if index < selectedPhotos.count {
                                        selectedPhotos.remove(at: index)
                                    }
                                }
                                HapticFeedback.light()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                    )
                            }
                            .padding(16)
                        }
                    }
                }
                .frame(height: 400)
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                // Add more photos button
                if loadedImages.count < 10 {
                    HStack(spacing: 12) {
                        // Camera
                        Button {
                            HapticFeedback.light()
                            showingCamera = true
                        } label: {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Kamera")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(
                                LinearGradient(
                                    colors: [.teal, .teal.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: .teal.opacity(0.4), radius: 8, y: 4)
                        }

                        // Gallery
                        PhotosPicker(
                            selection: $selectedPhotos,
                            maxSelectionCount: 10 - loadedImages.count,
                            matching: .images
                        ) {
                            HStack {
                                Image(systemName: "photo.fill")
                                Text("Galeri")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: .blue.opacity(0.4), radius: 8, y: 4)
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
        }
    }

    // MARK: - Details Card

    private var detailsCard: some View {
        VStack(spacing: 0) {
            // Card with glassmorphism
            VStack(spacing: 24) {
                // Title field
                VStack(alignment: .leading, spacing: 8) {
                    Label("Başlık", systemImage: "text.quote")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    TextField("Anınıza bir başlık verin...", text: $title)
                        .font(.body)
                        .padding(16)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Date picker
                VStack(alignment: .leading, spacing: 8) {
                    Label("Tarih", systemImage: "calendar")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(.teal)
                }

                // Location
                Button {
                    showingLocationPicker = true
                } label: {
                    HStack {
                        Label(locationName ?? "Konum Ekle", systemImage: "mappin.circle.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Spacer()

                        if selectedLocation != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.teal)
                        }

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(.primary)
                    .padding(16)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Friends
                Button {
                    showingFriendsPicker = true
                } label: {
                    HStack {
                        Label("Arkadaşlar", systemImage: "person.2.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Spacer()

                        if !selectedFriends.isEmpty {
                            Text("\(selectedFriends.count)")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [.teal, .blue],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                        }

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(.primary)
                    .padding(16)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Tags
                VStack(alignment: .leading, spacing: 12) {
                    Label("Etiketler", systemImage: "tag.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    HStack {
                        TextField("Etiket ekle", text: $tagInput)
                            .textFieldStyle(.plain)
                            .onSubmit {
                                addTag()
                            }

                        if !tagInput.isEmpty {
                            Button {
                                addTag()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.teal, .blue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Tags display
                    if !tags.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(tags, id: \.self) { tag in
                                HStack(spacing: 6) {
                                    Text("#\(tag)")
                                        .font(.caption)
                                        .fontWeight(.medium)

                                    Button {
                                        withAnimation(.spring(response: 0.3)) {
                                            tags.removeAll { $0 == tag }
                                        }
                                        HapticFeedback.light()
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption2)
                                    }
                                }
                                .foregroundStyle(.teal)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.teal.opacity(0.15))
                                )
                            }
                        }
                    }
                }

                // Notes
                VStack(alignment: .leading, spacing: 8) {
                    Label("Notlar", systemImage: "note.text")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    TextEditor(text: $notes)
                        .frame(height: 100)
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 20, y: -5)
            )
            .padding(.top, -20)
        }
        .sheet(isPresented: $showingFriendsPicker) {
            FriendsPickerView(selectedFriends: $selectedFriends)
        }
        .sheet(isPresented: $showingLocationPicker) {
            MemoryLocationPickerView(
                selectedLocation: $selectedLocation,
                locationName: $locationName
            )
        }
    }

    // MARK: - Actions

    private func loadPhotos(from items: [PhotosPickerItem]) {
        Task {
            isLoading = true
            defer { isLoading = false }

            var images: [UIImage] = []

            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    images.append(image)
                }
            }

            await MainActor.run {
                self.loadedImages = images
            }

            // Galeriden seçilen ilk fotoğrafın konum bilgisini oku (eğer henüz konum seçilmediyse)
            if selectedLocation == nil, let firstItem = items.first, let identifier = firstItem.itemIdentifier {
                extractLocationFromPhoto(identifier: identifier)
            }
        }
    }

    private func extractLocationFromPhoto(identifier: String) {
        let fetchOptions = PHFetchOptions()
        let results = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: fetchOptions)

        guard let asset = results.firstObject, let location = asset.location else {
            return
        }

        // Konum bulundu, UI'ı güncelle
        Task { @MainActor in
            selectedLocation = location.coordinate

            // Reverse geocoding ile konum adını al
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                guard let placemark = placemarks?.first else { return }

                Task { @MainActor in
                    var locationParts: [String] = []
                    if let name = placemark.name {
                        locationParts.append(name)
                    }
                    if let locality = placemark.locality {
                        locationParts.append(locality)
                    }

                    self.locationName = locationParts.isEmpty ? "Fotoğraftan Alındı" : locationParts.joined(separator: ", ")
                }
            }
        }
    }

    private func loadMediaItems(_ items: [MediaItem]) {
        guard !items.isEmpty else { return }

        // Kameradan gelen fotoğrafları loadedImages'e ekle
        for item in items {
            if item.type == .photo, let image = UIImage(data: item.data) {
                withAnimation {
                    loadedImages.append(image)
                }
            }
        }

        // Kameradan fotoğraf çekildiğinde otomatik olarak mevcut konumu ekle
        if selectedLocation == nil, let currentLocation = LocationService.shared.currentLocation {
            selectedLocation = currentLocation.coordinate

            // Reverse geocoding ile konum adını al
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(currentLocation) { placemarks, error in
                guard let placemark = placemarks?.first else { return }

                Task { @MainActor in
                    // Konum adını oluştur
                    var locationParts: [String] = []
                    if let name = placemark.name {
                        locationParts.append(name)
                    }
                    if let locality = placemark.locality {
                        locationParts.append(locality)
                    }

                    self.locationName = locationParts.isEmpty ? "Mevcut Konum" : locationParts.joined(separator: ", ")
                }
            }
        }

        // MediaItem array'ini temizle
        selectedMedia.removeAll()
        HapticFeedback.success()
    }

    private func addTag() {
        let trimmed = tagInput.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }

        withAnimation(.spring(response: 0.3)) {
            tags.append(trimmed)
            tagInput = ""
        }

        HapticFeedback.light()
    }

    private func saveMemory() {
        guard !loadedImages.isEmpty else {
            errorMessage = "En az bir fotoğraf seçmelisiniz"
            showError = true
            return
        }

        isLoading = true

        Task {
            await MainActor.run {
                viewModel.createMemory(
                    title: title.isEmpty ? nil : title,
                    photos: loadedImages,
                    date: selectedDate,
                    location: selectedLocation,
                    locationName: locationName,
                    notes: notes.isEmpty ? nil : notes,
                    tags: tags,
                    friends: selectedFriends.isEmpty ? nil : selectedFriends,
                    context: modelContext
                )

                HapticFeedback.success()
                isLoading = false
                dismiss()
            }
        }
    }
}

// MARK: - Supporting Views

struct FriendsPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedFriends: [Friend]

    @State private var friends: [Friend] = []

    var body: some View {
        NavigationStack {
            List {
                ForEach(friends, id: \.id) { friend in
                    Button {
                        toggleSelection(friend)
                    } label: {
                        HStack {
                            Text(friend.avatarEmoji ?? "👤")
                                .font(.title3)

                            Text(friend.name)
                                .foregroundStyle(.primary)

                            Spacer()

                            if selectedFriends.contains(where: { $0.id == friend.id }) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.teal)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Arkadaş Seç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Tamam") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                fetchFriends()
            }
        }
    }

    private func fetchFriends() {
        let descriptor = FetchDescriptor<Friend>(
            sortBy: [SortDescriptor(\.name)]
        )

        do {
            friends = try modelContext.fetch(descriptor)
        } catch {
            print("❌ Failed to fetch friends: \(error)")
        }
    }

    private func toggleSelection(_ friend: Friend) {
        if let index = selectedFriends.firstIndex(where: { $0.id == friend.id }) {
            selectedFriends.remove(at: index)
        } else {
            selectedFriends.append(friend)
        }
        HapticFeedback.light()
    }
}

struct MemoryLocationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedLocation: CLLocationCoordinate2D?
    @Binding var locationName: String?

    @State private var searchText: String = ""

    var body: some View {
        NavigationStack {
            VStack {
                Text(String(localized: "memories.location.picker.coming.soon", comment: "Location picker coming soon"))
                    .foregroundStyle(.secondary)
                    .padding()

                if let location = selectedLocation {
                    Text("Lat: \(location.latitude)")
                    Text("Lon: \(location.longitude)")
                }

                Spacer()
            }
            .navigationTitle("Konum Seç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    AddMemoryView(viewModel: MemoriesViewModel())
        .modelContainer(for: [Memory.self, Friend.self])
}

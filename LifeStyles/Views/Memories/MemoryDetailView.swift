//
//  MemoryDetailView.swift
//  LifeStyles
//
//  Created by Claude on 26.10.2025.
//  Memory Detail & Full-Screen Photo Carousel - Instagram Style
//

import SwiftUI
import SwiftData
import MapKit

struct MemoryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let memory: Memory
    @Bindable var viewModel: MemoriesViewModel

    @State private var currentPhotoIndex: Int = 0
    @State private var showingDeleteAlert = false
    @State private var showingEditSheet = false
    @State private var showingShareSheet = false
    @State private var scrollOffset: CGFloat = 0
    @State private var showingFullScreenPhoto = false

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 0) {
                        // MARK: - Hero Photo Carousel
                        photoCarouselSection(geo)
                            .background(
                                GeometryReader { geometry in
                                    Color.clear.preference(
                                        key: ScrollOffsetKey.self,
                                        value: geometry.frame(in: .named("scroll")).minY
                                    )
                                }
                            )

                        // MARK: - Content Card
                        contentCard
                            .padding(.top, -30)
                    }
                }
                .coordinateSpace(name: "scroll")
            }
            .ignoresSafeArea(edges: .top)
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        HapticFeedback.light()
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: .black.opacity(0.2), radius: 5)
                            )
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            toggleFavorite()
                        } label: {
                            Label(
                                memory.isFavorite ? "Favoriden Çıkar" : "Favorilere Ekle",
                                systemImage: memory.isFavorite ? "star.slash" : "star.fill"
                            )
                        }

                        Button {
                            HapticFeedback.light()
                            showingShareSheet = true
                        } label: {
                            Label("Paylaş", systemImage: "square.and.arrow.up")
                        }

                        Divider()

                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("Sil", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: .black.opacity(0.2), radius: 5)
                            )
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .alert("Anıyı Sil", isPresented: $showingDeleteAlert) {
                Button("İptal", role: .cancel) {}
                Button("Sil", role: .destructive) {
                    deleteMemory()
                }
            } message: {
                Text(String(localized: "memories.delete.confirm", comment: "Delete confirmation"))
            }
            .onPreferenceChange(ScrollOffsetKey.self) { value in
                scrollOffset = value
            }
            .fullScreenCover(isPresented: $showingFullScreenPhoto) {
                FullScreenPhotoView(
                    photos: memory.photos,
                    currentIndex: $currentPhotoIndex
                )
            }
        }
    }

    // MARK: - Photo Carousel Section

    private func photoCarouselSection(_ geo: GeometryProxy) -> some View {
        TabView(selection: $currentPhotoIndex) {
            ForEach(Array(memory.photos.enumerated()), id: \.offset) { index, photoData in
                if let uiImage = UIImage(data: photoData) {
                    ZStack {
                        // Blurred background
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .blur(radius: 50)
                            .overlay(Color.black.opacity(0.3))

                        // Main image
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .onTapGesture {
                                showingFullScreenPhoto = true
                            }
                    }
                    .tag(index)
                }
            }
        }
        .frame(height: 500)
        .tabViewStyle(.page(indexDisplayMode: .never))
        .overlay(alignment: .bottom) {
            // Custom Page Indicators
            if memory.photoCount > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<memory.photoCount, id: \.self) { index in
                        Circle()
                            .fill(index == currentPhotoIndex ? Color.white : Color.white.opacity(0.4))
                            .frame(width: index == currentPhotoIndex ? 8 : 6, height: index == currentPhotoIndex ? 8 : 6)
                            .animation(.spring(response: 0.3), value: currentPhotoIndex)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
                .padding(.bottom, 40)
            }
        }
        .overlay(alignment: .topTrailing) {
            // Favorite badge
            if memory.isFavorite {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                    Text("Favori")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.yellow)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
                .padding(16)
            }
        }
    }

    // MARK: - Content Card

    private var contentCard: some View {
        VStack(spacing: 20) {
            // Title & Date
            if let title = memory.title, !title.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.title)
                        .fontWeight(.bold)

                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text(memory.formattedDate)
                            .font(.subheadline)

                        if memory.relativeDate != memory.formattedDate {
                            Text("•")
                                .font(.caption)
                            Text(memory.relativeDate)
                                .font(.subheadline)
                        }
                    }
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
                )
            } else {
                // Date only
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text(memory.formattedDate)
                        .font(.subheadline)

                    if memory.relativeDate != memory.formattedDate {
                        Text("•")
                            .font(.caption)
                        Text(memory.relativeDate)
                            .font(.subheadline)
                    }
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
                )
            }

            // Location Map (if available)
            if memory.hasLocation {
                locationCard
            }

            // Friends
            if let friends = memory.friends, !friends.isEmpty {
                friendsCard(friends)
            }

            // Tags
            if !memory.tags.isEmpty {
                tagsCard
            }

            // Notes
            if let notes = memory.notes, !notes.isEmpty {
                notesCard(notes)
            }

            // Metadata
            metadataCard
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 20, y: -10)
        )
    }

    // MARK: - Location Card with Map

    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "location.fill")
                    .font(.caption)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.teal, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("Konum")
                    .font(.headline)

                Spacer()

                if let locationName = memory.locationName {
                    Text(locationName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            // Interactive Map
            if let coordinate = memory.coordinate {
                Map(initialPosition: .region(
                    MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                )) {
                    Marker(memory.locationName ?? "Anı Konumu", coordinate: coordinate)
                        .tint(.teal)
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .allowsHitTesting(false)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        )
    }

    // MARK: - Friends Card

    private func friendsCard(_ friends: [Friend]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.caption)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.teal, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text(String(localized: "memories.friends", comment: "Friends"))
                    .font(.headline)

                Spacer()

                Text("\(friends.count)")
                    .font(.caption)
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

            // Horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(friends, id: \.id) { friend in
                        VStack(spacing: 6) {
                            Text(friend.avatarEmoji ?? "👤")
                                .font(.largeTitle)
                                .frame(width: 60, height: 60)
                                .background(
                                    Circle()
                                        .fill(Color.teal.opacity(0.1))
                                )

                            Text(friend.name)
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        )
    }

    // MARK: - Tags Card

    private var tagsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "tag.fill")
                    .font(.caption)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.teal, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("Etiketler")
                    .font(.headline)
            }

            FlowLayout(spacing: 8) {
                ForEach(memory.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.subheadline)
                        .fontWeight(.medium)
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
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        )
    }

    // MARK: - Notes Card

    private func notesCard(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.quote")
                    .font(.caption)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.teal, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("Notlar")
                    .font(.headline)
            }

            Text(notes)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        )
    }

    // MARK: - Metadata Card

    private var metadataCard: some View {
        VStack(spacing: 12) {
            metadataRow(
                icon: "photo.stack",
                label: "Fotoğraf",
                value: "\(memory.photoCount)",
                gradient: true
            )

            Divider()

            metadataRow(
                icon: "eye",
                label: "Görüntülenme",
                value: "\(memory.viewCount)"
            )

            Divider()

            metadataRow(
                icon: "calendar.badge.plus",
                label: "Oluşturulma",
                value: formatDate(memory.createdAt)
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        )
    }

    private func metadataRow(icon: String, label: String, value: String, gradient: Bool = false) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(
                    gradient ?
                    AnyShapeStyle(LinearGradient(
                        colors: [.teal, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )) :
                    AnyShapeStyle(.secondary)
                )
                .frame(width: 24)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }

    // MARK: - Actions

    private func toggleFavorite() {
        HapticFeedback.light()
        viewModel.toggleFavorite(memory, context: modelContext)
    }

    private func deleteMemory() {
        HapticFeedback.medium()
        viewModel.deleteMemory(memory, context: modelContext)
        dismiss()
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
}

// MARK: - Full Screen Photo View

struct FullScreenPhotoView: View {
    @Environment(\.dismiss) private var dismiss
    let photos: [Data]
    @Binding var currentIndex: Int

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(Array(photos.enumerated()), id: \.offset) { index, photoData in
                    if let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .tag(index)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                            )
                    }
                    .padding(20)
                }
                Spacer()
            }

            // Page indicator
            VStack {
                Spacer()
                if photos.count > 1 {
                    Text("\(currentIndex + 1) / \(photos.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                        )
                        .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Scroll Offset Key

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    @Previewable @State var viewModel = MemoriesViewModel()

    let memory = Memory(
        title: "Yaz Tatili",
        photos: [],
        date: Date(),
        notes: "Harika bir gün geçirdik!",
        tags: ["tatil", "deniz", "güneş"],
        isFavorite: true
    )

    MemoryDetailView(memory: memory, viewModel: viewModel)
        .modelContainer(for: [Memory.self, Friend.self])
}

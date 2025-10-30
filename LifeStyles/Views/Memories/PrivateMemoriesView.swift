//
//  PrivateMemoriesView.swift
//  LifeStyles
//
//  Created by Claude on 26.10.2025.
//  Gizli Klasör - Private Memories with Face ID Protection
//

import SwiftUI
import SwiftData
import MapKit

struct PrivateMemoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: MemoriesViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // View Mode Picker
                Picker("View Mode", selection: $viewModel.selectedViewMode) {
                    ForEach(MemoriesViewModel.ViewMode.allCases, id: \.self) { mode in
                        Label(mode.rawValue, systemImage: mode.icon)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                TabView(selection: $viewModel.selectedViewMode) {
                    PrivateMemoryGridView(viewModel: viewModel)
                        .tag(MemoriesViewModel.ViewMode.grid)

                    PrivateMemoryTimelineView(viewModel: viewModel)
                        .tag(MemoriesViewModel.ViewMode.timeline)

                    PrivateMemoryMapView(viewModel: viewModel)
                        .tag(MemoriesViewModel.ViewMode.map)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("🔒 Gizli Klasör")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        HapticFeedback.medium()
                        viewModel.lockPrivateMemories()
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                            Text("Kapat")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.red)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        // Private memory count badge
                        Text("\(viewModel.privateMemoryCount)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(.red.gradient)
                            )

                        Button {
                            HapticFeedback.medium()
                            viewModel.showingAddMemory = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.red, .pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .sheet(isPresented: $viewModel.showingAddMemory) {
                AddPrivateMemoryView(viewModel: viewModel)
            }
            .sheet(item: $viewModel.selectedMemory) { memory in
                PrivateMemoryDetailView(memory: memory, viewModel: viewModel)
            }
        }
    }
}

// MARK: - Private Memory Grid View

struct PrivateMemoryGridView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: MemoriesViewModel

    let columns = [
        GridItem(.flexible(), spacing: Spacing.medium),
        GridItem(.flexible(), spacing: Spacing.medium)
    ]

    var body: some View {
        Group {
            if viewModel.filteredMemories.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: Spacing.medium) {
                        ForEach(viewModel.filteredMemories, id: \.id) { memory in
                            PrivateMemoryCard(memory: memory)
                                .onTapGesture {
                                    viewModel.selectedMemory = memory
                                }
                                .contextMenu {
                                    Button {
                                        viewModel.toggleFavorite(memory, context: modelContext)
                                    } label: {
                                        Label(
                                            memory.isFavorite ? "Favoriden Çıkar" : "Favorilere Ekle",
                                            systemImage: memory.isFavorite ? "star.slash" : "star.fill"
                                        )
                                    }

                                    Button {
                                        viewModel.togglePrivateStatus(memory, context: modelContext)
                                    } label: {
                                        Label("Gizliden Çıkar", systemImage: "lock.open")
                                    }

                                    Divider()

                                    Button(role: .destructive) {
                                        viewModel.deleteMemory(memory, context: modelContext)
                                    } label: {
                                        Label("Sil", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding(Spacing.large)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.xlarge) {
            Image(systemName: "lock.square.stack")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.red, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: Spacing.small) {
                Text(String(localized: "memories.private.empty.title", comment: "No private memories"))
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(String(localized: "memories.private.empty.message", comment: "Create private memory"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                HapticFeedback.medium()
                viewModel.showingAddMemory = true
            } label: {
                Text(String(localized: "memories.private.create", comment: "Create private memory"))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.xxlarge)
                    .padding(.vertical, Spacing.medium)
                    .background(
                        LinearGradient(
                            colors: [.red, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
            }
        }
        .padding(40)
    }
}

// MARK: - Private Memory Card

struct PrivateMemoryCard: View {
    let memory: Memory

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail
            if let firstPhotoData = memory.photos.first,
               let uiImage = UIImage(data: firstPhotoData) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))

                    // Lock badge
                    Circle()
                        .fill(.red)
                        .frame(width: 28, height: 28)
                        .overlay {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.white)
                        }
                        .padding(8)
                }
            } else {
                // Placeholder
                ZStack {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.red.opacity(0.3), .pink.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 140)

                    Image(systemName: "lock.square.stack")
                        .font(.system(size: 40))
                        .foregroundStyle(.red.opacity(0.6))
                }
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            }

            // Info
            VStack(alignment: .leading, spacing: Spacing.micro) {
                if let title = memory.title, !title.isEmpty {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .foregroundStyle(.primary)
                } else {
                    Text(String(localized: "memories.untitled", comment: "Untitled memory"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(memory.relativeDate)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                // Metadata
                HStack(spacing: Spacing.small) {
                    if memory.photoCount > 1 {
                        HStack(spacing: 2) {
                            Image(systemName: "photo.stack")
                                .font(.caption2)
                            Text("\(memory.photoCount)")
                                .font(.caption2)
                        }
                    }

                    if memory.hasLocation {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    if memory.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }
                .foregroundStyle(.secondary)
            }
            .padding(Spacing.small)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        .shadow(color: .red.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Private Memory Timeline View

struct PrivateMemoryTimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: MemoriesViewModel

    var body: some View {
        Group {
            if viewModel.filteredMemories.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        ForEach(groupedMemories.keys.sorted(by: >), id: \.self) { key in
                            Section {
                                ForEach(groupedMemories[key] ?? [], id: \.id) { memory in
                                    TimelineMemoryRow(memory: memory)
                                        .onTapGesture {
                                            viewModel.selectedMemory = memory
                                        }
                                        .contextMenu {
                                            Button {
                                                viewModel.toggleFavorite(memory, context: modelContext)
                                            } label: {
                                                Label(
                                                    memory.isFavorite ? "Favoriden Çıkar" : "Favorilere Ekle",
                                                    systemImage: memory.isFavorite ? "star.slash" : "star.fill"
                                                )
                                            }

                                            Button {
                                                viewModel.togglePrivateStatus(memory, context: modelContext)
                                            } label: {
                                                Label("Gizliden Çıkar", systemImage: "lock.open")
                                            }

                                            Divider()

                                            Button(role: .destructive) {
                                                viewModel.deleteMemory(memory, context: modelContext)
                                            } label: {
                                                Label("Sil", systemImage: "trash")
                                            }
                                        }
                                }
                            } header: {
                                SectionHeader(text: key)
                            }
                        }
                    }
                }
            }
        }
    }

    private var groupedMemories: [String: [Memory]] {
        Dictionary(grouping: viewModel.filteredMemories) { memory in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            formatter.locale = Locale(identifier: "tr_TR")
            return formatter.string(from: memory.date)
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.xlarge) {
            Image(systemName: "lock.doc")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.red, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: Spacing.small) {
                Text(String(localized: "memories.private.empty.title", comment: "No private memories"))
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(String(localized: "memories.private.timeline.empty", comment: "Timeline message"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
    }
}

// MARK: - Private Memory Map View

struct PrivateMemoryMapView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: MemoriesViewModel
    @State private var selectedMemoryId: UUID?

    var body: some View {
        Group {
            if memoriesWithLocation.isEmpty {
                emptyState
            } else {
                ZStack(alignment: .bottom) {
                    Map(selection: $selectedMemoryId) {
                        ForEach(memoriesWithLocation, id: \.id) { memory in
                            if let coordinate = memory.coordinate {
                                Annotation(
                                    memory.title ?? "Gizli Anı",
                                    coordinate: coordinate
                                ) {
                                    PrivateMemoryMapAnnotation(memory: memory)
                                        .onTapGesture {
                                            withAnimation {
                                                selectedMemoryId = memory.id
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .mapStyle(.standard(elevation: .realistic))

                    // Selected Memory Card
                    if let selectedMemoryId = selectedMemoryId,
                       let memory = memoriesWithLocation.first(where: { $0.id == selectedMemoryId }) {
                        MemoryMapCard(memory: memory)
                            .padding(Spacing.large)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .onTapGesture {
                                viewModel.selectedMemory = memory
                            }
                    }
                }
            }
        }
    }

    private var memoriesWithLocation: [Memory] {
        viewModel.filteredMemories.filter { $0.hasLocation }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.xlarge) {
            Image(systemName: "map.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.red, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: Spacing.small) {
                Text(String(localized: "memories.location.empty.title", comment: "No locations"))
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(String(localized: "memories.location.empty.message", comment: "Location map message"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
    }
}

// MARK: - Private Memory Map Annotation

struct PrivateMemoryMapAnnotation: View {
    let memory: Memory

    var body: some View {
        ZStack {
            if let firstPhotoData = memory.photos.first,
               let uiImage = UIImage(data: firstPhotoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(.red, lineWidth: 3)
                    }
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.red, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.white)
                    }
                    .overlay {
                        Circle()
                            .stroke(.white, lineWidth: 3)
                    }
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            }

            // Lock badge
            Circle()
                .fill(.red)
                .frame(width: 16, height: 16)
                .overlay {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.white)
                }
                .offset(x: 16, y: -16)
        }
    }
}

// MARK: - Placeholder Views

struct AddPrivateMemoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: MemoriesViewModel

    var body: some View {
        NavigationStack {
            Text(String(localized: "memories.private.create", comment: "Create private memory"))
                .navigationTitle("Yeni Gizli Anı")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("İptal") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

struct PrivateMemoryDetailView: View {
    let memory: Memory
    @Bindable var viewModel: MemoriesViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Text(String(localized: "memories.private.detail", comment: "Private memory detail"))
                .navigationTitle(memory.displayTitle)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Kapat") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

#Preview {
    PrivateMemoriesView(viewModel: MemoriesViewModel())
        .modelContainer(for: [Memory.self, Friend.self])
}

//
//  MemoriesView.swift
//  LifeStyles
//
//  Created by Claude on 26.10.2025.
//  Memory & Photo Timeline - Main Container
//

import SwiftUI
import SwiftData
import MapKit

struct MemoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = MemoriesViewModel()
    @State private var showingAuthError: Bool = false
    @State private var tapCount: Int = 0
    @State private var tapTimer: Timer?

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
                    MemoryGridView(viewModel: viewModel)
                        .tag(MemoriesViewModel.ViewMode.grid)

                    MemoryTimelineView(viewModel: viewModel)
                        .tag(MemoriesViewModel.ViewMode.timeline)

                    MemoryMapView(viewModel: viewModel)
                        .tag(MemoriesViewModel.ViewMode.map)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("📸 Anılar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        handlePlusButtonTap()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.teal, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            }
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
            .sheet(isPresented: $viewModel.showingAddMemory) {
                AddMemoryView(viewModel: viewModel)
            }
            .sheet(item: $viewModel.selectedMemory) { memory in
                MemoryDetailView(memory: memory, viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showPrivateMemories) {
                // Reset unlock durumunu sheet kapandığında
                viewModel.lockPrivateMemories()
            } content: {
                PrivateMemoriesView(viewModel: viewModel)
            }
            .alert("Kimlik Doğrulama Hatası", isPresented: $showingAuthError) {
                Button("Tamam", role: .cancel) {}
            } message: {
                if let error = viewModel.authenticationError {
                    Text(error)
                }
            }
        }
    }

    // MARK: - Triple Tap Handler

    private func handlePlusButtonTap() {
        tapCount += 1

        // Timer'ı iptal et ve yeniden başlat
        tapTimer?.invalidate()

        // 3. tıklama - Gizli klasörü aç
        if tapCount == 3 {
            HapticFeedback.success()
            tapCount = 0
            tapTimer = nil

            Task {
                let success = await viewModel.authenticateForPrivate()
                if success {
                    viewModel.showPrivateMemories = true
                } else {
                    showingAuthError = true
                }
            }
            return
        }

        // 2. tıklama - Hafif titreşim
        if tapCount == 2 {
            HapticFeedback.light()
        }

        // 0.5 saniye bekle, eğer 3. tıklama gelmezse normal davranış
        tapTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            if tapCount < 3 {
                // Normal tıklama - Add memory sheet aç
                HapticFeedback.medium()
                viewModel.showingAddMemory = true
            }
            tapCount = 0
        }
    }
}

// MARK: - Memory Grid View

struct MemoryGridView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: MemoriesViewModel
    @State private var tapTracker = TapTracker()

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
                            MemoryCard(memory: memory)
                                .onTapGesture {
                                    handleMemoryTap(memory)
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
                                        HapticFeedback.medium()
                                        viewModel.togglePrivateStatus(memory, context: modelContext)
                                    } label: {
                                        Label("Gizliye Taşı", systemImage: "lock.fill")
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

    private func handleMemoryTap(_ memory: Memory) {
        let count = tapTracker.registerTap(for: memory.id)

        switch count {
        case 1:
            // İlk tıklama - Detay aç
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if tapTracker.getTapCount(for: memory.id) == 1 {
                    viewModel.selectedMemory = memory
                    tapTracker.reset(for: memory.id)
                }
            }
        case 2:
            HapticFeedback.light()
        case 3:
            // 3. tıklama - Gizliye al
            HapticFeedback.success()
            Task {
                let success = await viewModel.authenticateForPrivate()
                if success {
                    viewModel.togglePrivateStatus(memory, context: modelContext)
                    tapTracker.reset(for: memory.id)
                }
            }
        default:
            break
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.xlarge) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.teal, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: Spacing.small) {
                Text(String(localized: "memories.empty.title", comment: "No memories"))
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(String(localized: "memories.empty.message", comment: "Create first memory"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                HapticFeedback.medium()
                viewModel.showingAddMemory = true
            } label: {
                Text(String(localized: "memories.create", comment: "Create memory"))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.xxlarge)
                    .padding(.vertical, Spacing.medium)
                    .background(
                        LinearGradient(
                            colors: [.teal, .blue],
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

// MARK: - Memory Timeline View

struct MemoryTimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: MemoriesViewModel
    @State private var tapTracker = TapTracker()

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
                                            handleMemoryTap(memory)
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
                                                HapticFeedback.medium()
                                                viewModel.togglePrivateStatus(memory, context: modelContext)
                                            } label: {
                                                Label("Gizliye Taşı", systemImage: "lock.fill")
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

    private func handleMemoryTap(_ memory: Memory) {
        let count = tapTracker.registerTap(for: memory.id)

        switch count {
        case 1:
            // İlk tıklama - Detay aç
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if tapTracker.getTapCount(for: memory.id) == 1 {
                    viewModel.selectedMemory = memory
                    tapTracker.reset(for: memory.id)
                }
            }
        case 2:
            HapticFeedback.light()
        case 3:
            // 3. tıklama - Gizliye al
            HapticFeedback.success()
            Task {
                let success = await viewModel.authenticateForPrivate()
                if success {
                    viewModel.togglePrivateStatus(memory, context: modelContext)
                    tapTracker.reset(for: memory.id)
                }
            }
        default:
            break
        }
    }

    // Group memories by "Month Year" (e.g., "Ekim 2025")
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
            Image(systemName: "clock")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.teal, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: Spacing.small) {
                Text(String(localized: "memories.empty.title", comment: "No memories"))
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(String(localized: "memories.empty.message", comment: "Create first memory"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let text: String

    var body: some View {
        HStack {
            Text(text)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, Spacing.medium)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Timeline Memory Row

struct TimelineMemoryRow: View {
    let memory: Memory

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.medium) {
            // Date Badge
            VStack(spacing: 2) {
                Text(dayNumber)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(monthAbbreviation)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 50)

            // Timeline Dot & Line
            VStack(spacing: 0) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.teal, .blue],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 12, height: 12)
                    .overlay {
                        Circle()
                            .stroke(.white, lineWidth: 3)
                    }

                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 12)

            // Content Card
            VStack(alignment: .leading, spacing: Spacing.small) {
                // Thumbnail
                if let firstPhotoData = memory.photos.first,
                   let uiImage = UIImage(data: firstPhotoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                }

                // Title
                if let title = memory.title, !title.isEmpty {
                    Text(title)
                        .font(.headline)
                        .lineLimit(2)
                }

                // Metadata
                HStack(spacing: Spacing.small) {
                    if memory.photoCount > 1 {
                        HStack(spacing: 2) {
                            Image(systemName: "photo.stack")
                                .font(.caption2)
                            Text("\(memory.photoCount)")
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                    }

                    if memory.hasLocation {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.teal)
                    }

                    if memory.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }

                    if let friends = memory.friends, !friends.isEmpty {
                        HStack(spacing: 2) {
                            Image(systemName: "person.2.fill")
                                .font(.caption2)
                            Text("\(friends.count)")
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .padding(.horizontal, Spacing.large)
        .padding(.bottom, Spacing.medium)
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: memory.date)
    }

    private var monthAbbreviation: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: memory.date).uppercased()
    }
}

// MARK: - Memory Map View

struct MemoryMapView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: MemoriesViewModel
    @State private var selectedMemoryId: UUID?

    var body: some View {
        Group {
            if memoriesWithLocation.isEmpty {
                emptyState
            } else {
                ZStack(alignment: .bottom) {
                    // Map
                    Map(selection: $selectedMemoryId) {
                        ForEach(memoriesWithLocation, id: \.id) { memory in
                            if let coordinate = memory.coordinate {
                                Annotation(
                                    memory.title ?? "Anı",
                                    coordinate: coordinate
                                ) {
                                    MemoryMapAnnotation(memory: memory)
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
                    .mapControls {
                        MapUserLocationButton()
                        MapCompass()
                        MapScaleView()
                    }

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
            Image(systemName: "map")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.teal, .blue],
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

// MARK: - Memory Map Annotation

struct MemoryMapAnnotation: View {
    let memory: Memory

    var body: some View {
        ZStack {
            // Photo thumbnail in circle
            if let firstPhotoData = memory.photos.first,
               let uiImage = UIImage(data: firstPhotoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(.white, lineWidth: 3)
                    }
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            } else {
                // Default pin
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.teal, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.white)
                    }
                    .overlay {
                        Circle()
                            .stroke(.white, lineWidth: 3)
                    }
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            }

            // Favorite star badge
            if memory.isFavorite {
                Circle()
                    .fill(.yellow)
                    .frame(width: 16, height: 16)
                    .overlay {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.white)
                    }
                    .offset(x: 16, y: -16)
            }
        }
    }
}

// MARK: - Memory Map Card

struct MemoryMapCard: View {
    let memory: Memory

    var body: some View {
        HStack(spacing: Spacing.medium) {
            // Thumbnail
            if let firstPhotoData = memory.photos.first,
               let uiImage = UIImage(data: firstPhotoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            }

            // Info
            VStack(alignment: .leading, spacing: Spacing.micro) {
                if let title = memory.title, !title.isEmpty {
                    Text(title)
                        .font(.headline)
                        .lineLimit(1)
                }

                if let locationName = memory.locationName {
                    HStack(spacing: 2) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption2)
                        Text(locationName)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundStyle(.teal)
                }

                Text(memory.formattedDate)
                    .font(.caption)
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

                    if memory.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }

                    if let friends = memory.friends, !friends.isEmpty {
                        HStack(spacing: 2) {
                            Image(systemName: "person.2.fill")
                                .font(.caption2)
                            Text("\(friends.count)")
                                .font(.caption2)
                        }
                    }
                }
                .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.medium)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Tap Tracker

@Observable
class TapTracker {
    private var tapCounts: [UUID: Int] = [:]
    private var timers: [UUID: Timer] = [:]

    func registerTap(for id: UUID) -> Int {
        // Timer'ı iptal et
        timers[id]?.invalidate()

        // Tap count artır
        let currentCount = (tapCounts[id] ?? 0) + 1
        tapCounts[id] = currentCount

        // 1 saniye sonra reset
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            self?.reset(for: id)
        }
        timers[id] = timer

        return currentCount
    }

    func getTapCount(for id: UUID) -> Int {
        return tapCounts[id] ?? 0
    }

    func reset(for id: UUID) {
        tapCounts[id] = nil
        timers[id]?.invalidate()
        timers[id] = nil
    }
}

#Preview {
    MemoriesView()
        .modelContainer(for: [Memory.self, Friend.self])
}

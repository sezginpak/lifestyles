//
//  MemoriesViewModel.swift
//  LifeStyles
//
//  Created by Claude on 26.10.2025.
//  Memory & Photo Timeline ViewModel
//

import Foundation
import SwiftData
import CoreLocation
import UIKit

@Observable
class MemoriesViewModel {
    var memories: [Memory] = []
    var selectedViewMode: ViewMode = .grid
    var searchText: String = ""
    var filterTags: [String] = []
    var filterFriends: [Friend] = []
    var sortOption: SortOption = .dateDescending
    var showingAddMemory: Bool = false
    var selectedMemory: Memory?

    // Private Memories (Gizli Klasör)
    var showPrivateMemories: Bool = false
    var isPrivateUnlocked: Bool = false
    var authenticationError: String?

    private var modelContext: ModelContext?
    private let authService = BiometricAuthService.shared

    enum ViewMode: String, CaseIterable {
        case grid = "Grid"
        case timeline = "Timeline"
        case map = "Map"

        var icon: String {
            switch self {
            case .grid: return "square.grid.2x2"
            case .timeline: return "list.bullet"
            case .map: return "map"
            }
        }
    }

    enum SortOption: String, CaseIterable {
        case dateDescending = "En Yeni"
        case dateAscending = "En Eski"
        case favorite = "Favoriler"
        case photoCount = "Fotoğraf Sayısı"

        var icon: String {
            switch self {
            case .dateDescending: return "arrow.down"
            case .dateAscending: return "arrow.up"
            case .favorite: return "star.fill"
            case .photoCount: return "photo.stack"
            }
        }
    }

    // MARK: - Computed Properties

    var filteredMemories: [Memory] {
        var result = memories

        // Private filter: Normal view'da private olanları gösterme
        if !showPrivateMemories {
            result = result.filter { !$0.isPrivate }
        } else {
            // Gizli view'da sadece private olanları göster
            result = result.filter { $0.isPrivate }
        }

        // Search filter
        if !searchText.isEmpty {
            result = result.filter { memory in
                if let title = memory.title, title.localizedCaseInsensitiveContains(searchText) {
                    return true
                }
                if let notes = memory.notes, notes.localizedCaseInsensitiveContains(searchText) {
                    return true
                }
                if memory.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) }) {
                    return true
                }
                return false
            }
        }

        // Tag filter
        if !filterTags.isEmpty {
            result = result.filter { memory in
                filterTags.allSatisfy { filterTag in
                    memory.tags.contains(filterTag)
                }
            }
        }

        // Friend filter
        if !filterFriends.isEmpty {
            result = result.filter { memory in
                guard let memoryFriends = memory.friends else { return false }
                return filterFriends.allSatisfy { filterFriend in
                    memoryFriends.contains(where: { $0.id == filterFriend.id })
                }
            }
        }

        // Sort
        return sortMemories(result, by: sortOption)
    }

    var favoriteMemories: [Memory] {
        memories.filter { $0.isFavorite }
    }

    var memoriesWithLocation: [Memory] {
        memories.filter { $0.hasLocation }
    }

    /// Sadece private memoryler
    var privateMemories: [Memory] {
        memories.filter { $0.isPrivate }
    }

    /// Private memory sayısı
    var privateMemoryCount: Int {
        privateMemories.count
    }

    // MARK: - Setup

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        fetchMemories()
    }

    // MARK: - CRUD Operations

    func fetchMemories() {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<Memory>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            memories = try context.fetch(descriptor)
            print("✅ \(memories.count) memory loaded")
        } catch {
            print("❌ Failed to fetch memories: \(error)")
        }
    }

    func createMemory(
        title: String?,
        photos: [UIImage],
        videos: [Data] = [],
        videoThumbnails: [Data] = [],
        date: Date,
        location: CLLocationCoordinate2D?,
        locationName: String?,
        notes: String?,
        tags: [String],
        friends: [Friend]?,
        context: ModelContext
    ) {
        // Convert UIImages to Data with optimization
        let photoDataArray = photos.compactMap { image -> Data? in
            // Resize to max 1920x1080
            let resized = image.resizeToFit(maxSize: CGSize(width: 1920, height: 1080))
            return resized.jpegData(compressionQuality: 0.8)
        }

        // Generate thumbnails
        let thumbnailDataArray = photos.compactMap { image -> Data? in
            let thumbnail = image.resizeToFit(maxSize: CGSize(width: 300, height: 300))
            return thumbnail.jpegData(compressionQuality: 0.6)
        }

        let memory = Memory(
            title: title,
            photos: photoDataArray,
            thumbnails: thumbnailDataArray,
            videos: videos,
            videoThumbnails: videoThumbnails.isEmpty ? nil : videoThumbnails,
            date: date,
            latitude: location?.latitude,
            longitude: location?.longitude,
            locationName: locationName,
            notes: notes,
            tags: tags,
            friends: friends
        )

        context.insert(memory)

        do {
            try context.save()
            fetchMemories()
            print("✅ Memory created with \(photos.count) photos and \(videos.count) videos")
        } catch {
            print("❌ Failed to create memory: \(error)")
        }
    }

    func updateMemory(_ memory: Memory, context: ModelContext) {
        do {
            try context.save()
            fetchMemories()
            print("✅ Memory updated")
        } catch {
            print("❌ Failed to update memory: \(error)")
        }
    }

    func deleteMemory(_ memory: Memory, context: ModelContext) {
        context.delete(memory)

        do {
            try context.save()
            fetchMemories()
            print("✅ Memory deleted")
        } catch {
            print("❌ Failed to delete memory: \(error)")
        }
    }

    func toggleFavorite(_ memory: Memory, context: ModelContext) {
        memory.isFavorite.toggle()
        updateMemory(memory, context: context)
    }

    // MARK: - Sorting

    private func sortMemories(_ memories: [Memory], by option: SortOption) -> [Memory] {
        switch option {
        case .dateDescending:
            return memories.sorted { $0.date > $1.date }
        case .dateAscending:
            return memories.sorted { $0.date < $1.date }
        case .favorite:
            return memories.sorted { lhs, rhs in
                if lhs.isFavorite == rhs.isFavorite {
                    return lhs.date > rhs.date
                }
                return lhs.isFavorite && !rhs.isFavorite
            }
        case .photoCount:
            return memories.sorted { lhs, rhs in
                if lhs.photoCount == rhs.photoCount {
                    return lhs.date > rhs.date
                }
                return lhs.photoCount > rhs.photoCount
            }
        }
    }

    // MARK: - Location Integration

    func getMemoriesNear(location: CLLocationCoordinate2D, radius: Double = 1000) -> [Memory] {
        memoriesWithLocation.filter { memory in
            guard let memoryCoord = memory.coordinate else { return false }
            let distance = location.distance(to: memoryCoord)
            return distance <= radius
        }
    }

    // MARK: - Friend Integration

    func getMemoriesWith(friend: Friend) -> [Memory] {
        memories.filter { memory in
            memory.friends?.contains(where: { $0.id == friend.id }) ?? false
        }
    }

    // MARK: - Journal Integration

    func createMemoryFromJournal(_ journalEntry: JournalEntry, context: ModelContext) {
        var photos: [Data] = []

        // Extract photo from journal if exists
        if let imageData = journalEntry.imageData {
            photos = [imageData]
        }

        let memory = Memory(
            title: journalEntry.title,
            photos: photos,
            date: journalEntry.date,
            notes: journalEntry.content,
            tags: journalEntry.tags,
            journalEntry: journalEntry
        )

        context.insert(memory)
        journalEntry.memory = memory

        do {
            try context.save()
            fetchMemories()
            print("✅ Memory created from journal")
        } catch {
            print("❌ Failed to create memory from journal: \(error)")
        }
    }

    // MARK: - Private Memories (Gizli Klasör)

    /// Face ID/Touch ID ile gizli klasöre erişim
    @MainActor
    func authenticateForPrivate() async -> Bool {
        authenticationError = nil

        // Biyometrik mevcut mu kontrol et
        let biometricType = authService.biometricType
        if biometricType == .none {
            authenticationError = "Bu cihazda Face ID/Touch ID mevcut değil"
            return false
        }

        // Authentication yap
        let result = await authService.authenticate()

        switch result {
        case .success:
            isPrivateUnlocked = true
            print("✅ Private memories unlocked")
            return true

        case .failure(let error):
            isPrivateUnlocked = false
            authenticationError = error.localizedDescription
            print("❌ Authentication failed: \(error.localizedDescription)")
            return false
        }
    }

    /// Memory'yi gizli klasöre taşı / çıkar
    func togglePrivateStatus(_ memory: Memory, context: ModelContext) {
        memory.isPrivate.toggle()
        updateMemory(memory, context: context)

        if memory.isPrivate {
            print("🔒 Memory moved to private folder")
        } else {
            print("🔓 Memory moved to public folder")
        }
    }

    /// Gizli klasörü kapat (lock)
    func lockPrivateMemories() {
        isPrivateUnlocked = false
        showPrivateMemories = false
        print("🔒 Private memories locked")
    }
}

// MARK: - CLLocationCoordinate2D Extension

extension CLLocationCoordinate2D {
    func distance(to coordinate: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: latitude, longitude: longitude)
        let location2 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return location1.distance(from: location2)
    }
}

// MARK: - UIImage Extension

extension UIImage {
    func resizeToFit(maxSize: CGSize) -> UIImage {
        let widthRatio = maxSize.width / size.width
        let heightRatio = maxSize.height / size.height
        let ratio = min(widthRatio, heightRatio)

        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

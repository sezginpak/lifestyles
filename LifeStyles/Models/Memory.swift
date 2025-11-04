//
//  Memory.swift
//  LifeStyles
//
//  Created by Claude on 26.10.2025.
//  Memory & Photo Timeline data model
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class Memory {
    var id: UUID = UUID()
    var title: String?
    var photos: [Data] = []              // Orijinal fotoğraflar (CloudKit senkron)
    var thumbnails: [Data]?         // Optimize edilmiş küçük versiyonlar
    var videos: [Data] = []              // Video dosyaları (CloudKit senkron)
    var videoThumbnails: [Data]?    // Video thumbnail'ları
    var date: Date = Date()                  // Memory tarihi (kullanıcının seçtiği)
    var createdAt: Date = Date()             // Oluşturulma tarihi (sistem)

    // Location
    var latitude: Double?
    var longitude: Double?
    var locationName: String?       // Reverse geocoding ile elde edilen adres

    // Content
    var notes: String?
    var tags: [String] = []

    // Relations
    @Relationship(deleteRule: .nullify)
    var friends: [Friend]?

    @Relationship(deleteRule: .nullify)
    var journalEntry: JournalEntry?

    // Metadata
    var isFavorite: Bool = false
    var viewCount: Int = 0
    var isPrivate: Bool = false             // Gizli klasörde mi? (Face ID korumalı)

    init(
        id: UUID = UUID(),
        title: String? = nil,
        photos: [Data] = [],
        thumbnails: [Data]? = nil,
        videos: [Data] = [],
        videoThumbnails: [Data]? = nil,
        date: Date = Date(),
        createdAt: Date = Date(),
        latitude: Double? = nil,
        longitude: Double? = nil,
        locationName: String? = nil,
        notes: String? = nil,
        tags: [String] = [],
        friends: [Friend]? = nil,
        journalEntry: JournalEntry? = nil,
        isFavorite: Bool = false,
        viewCount: Int = 0,
        isPrivate: Bool = false
    ) {
        self.id = id
        self.title = title
        self.photos = photos
        self.thumbnails = thumbnails
        self.videos = videos
        self.videoThumbnails = videoThumbnails
        self.date = date
        self.createdAt = createdAt
        self.latitude = latitude
        self.longitude = longitude
        self.locationName = locationName
        self.notes = notes
        self.tags = tags
        self.friends = friends
        self.journalEntry = journalEntry
        self.isFavorite = isFavorite
        self.viewCount = viewCount
        self.isPrivate = isPrivate
    }
}

// MARK: - Computed Properties

extension Memory {
    /// Koordinat var mı?
    var hasLocation: Bool {
        latitude != nil && longitude != nil
    }

    /// CLLocationCoordinate2D dönüşümü
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    /// Fotoğraf sayısı
    var photoCount: Int {
        photos.count
    }

    /// Video sayısı
    var videoCount: Int {
        videos.count
    }

    /// Toplam medya sayısı (foto + video)
    var mediaCount: Int {
        photos.count + videos.count
    }

    /// Video var mı?
    var hasVideos: Bool {
        !videos.isEmpty
    }

    /// Arkadaş sayısı
    var friendCount: Int {
        friends?.count ?? 0
    }

    /// Tag sayısı
    var tagCount: Int {
        tags.count
    }

    /// Tarih formatı (UI için)
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }

    /// Relative tarih (Bugün, Dün, vs.)
    var relativeDate: String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return String(localized: "memory.date.today", comment: "Today")
        } else if calendar.isDateInYesterday(date) {
            return String(localized: "memory.date.yesterday", comment: "Yesterday")
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            return String(localized: "memory.date.this.week", comment: "This Week")
        } else {
            return formattedDate
        }
    }

    /// Preview için başlık veya placeholder
    var displayTitle: String {
        if let title = title, !title.isEmpty {
            return title
        }
        return String(localized: "memory.untitled", comment: "Untitled Memory")
    }
}

// MARK: - Helper Methods

extension Memory {
    /// Koordinat ayarla
    func setLocation(coordinate: CLLocationCoordinate2D, name: String? = nil) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.locationName = name
    }

    /// Koordinat temizle
    func clearLocation() {
        self.latitude = nil
        self.longitude = nil
        self.locationName = nil
    }

    /// Arkadaş ekle
    func addFriend(_ friend: Friend) {
        if friends == nil {
            friends = []
        }
        if !friends!.contains(where: { $0.id == friend.id }) {
            friends?.append(friend)
        }
    }

    /// Arkadaş çıkar
    func removeFriend(_ friend: Friend) {
        friends?.removeAll(where: { $0.id == friend.id })
    }

    /// Tag ekle
    func addTag(_ tag: String) {
        let normalized = tag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !normalized.isEmpty && !tags.contains(normalized) {
            tags.append(normalized)
        }
    }

    /// Tag çıkar
    func removeTag(_ tag: String) {
        tags.removeAll(where: { $0 == tag })
    }

    /// View count artır
    func incrementViewCount() {
        viewCount += 1
    }
}

//
//  SavedPlace.swift
//  LifeStyles
//
//  Created by Claude on 25.10.2025.
//  Kullanıcının kaydettiği özel yerler (Ev, İş, Spor Salonu vb.)
//

import Foundation
import SwiftData
import CoreLocation
import SwiftUI

// MARK: - Place Category

enum PlaceCategory: String, Codable, CaseIterable {
    case home = "home"
    case work = "work"
    case gym = "gym"
    case cafe = "cafe"
    case shopping = "shopping"
    case restaurant = "restaurant"
    case park = "park"
    case school = "school"
    case hospital = "hospital"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .home: return "Ev"
        case .work: return "İş"
        case .gym: return "Spor Salonu"
        case .cafe: return "Cafe"
        case .shopping: return "Alışveriş"
        case .restaurant: return "Restoran"
        case .park: return "Park"
        case .school: return "Okul"
        case .hospital: return "Hastane"
        case .custom: return "Özel"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .work: return "building.2.fill"
        case .gym: return "figure.run"
        case .cafe: return "cup.and.saucer.fill"
        case .shopping: return "cart.fill"
        case .restaurant: return "fork.knife"
        case .park: return "tree.fill"
        case .school: return "graduationcap.fill"
        case .hospital: return "cross.case.fill"
        case .custom: return "mappin.circle.fill"
        }
    }

    var defaultEmoji: String {
        switch self {
        case .home: return "🏠"
        case .work: return "💼"
        case .gym: return "💪"
        case .cafe: return "☕"
        case .shopping: return "🛒"
        case .restaurant: return "🍽️"
        case .park: return "🌳"
        case .school: return "🎓"
        case .hospital: return "🏥"
        case .custom: return "📍"
        }
    }

    var defaultColor: String {
        switch self {
        case .home: return "3B82F6" // Blue
        case .work: return "8B5CF6" // Purple
        case .gym: return "EF4444" // Red
        case .cafe: return "F59E0B" // Amber
        case .shopping: return "EC4899" // Pink
        case .restaurant: return "F97316" // Orange
        case .park: return "10B981" // Green
        case .school: return "6366F1" // Indigo
        case .hospital: return "14B8A6" // Teal
        case .custom: return "6B7280" // Gray
        }
    }
}

// MARK: - SavedPlace Model

@Model
final class SavedPlace {
    var id: UUID = UUID()
    var name: String = ""
    var emoji: String = "📍"
    var colorHex: String = "6B7280"
    var categoryRaw: String = "custom"

    // Location
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var address: String?

    // Geofencing
    var radius: Double = 100.0 // meters (50-500)
    var isGeofenceEnabled: Bool = true
    var notifyOnEntry: Bool = true
    var notifyOnExit: Bool = false

    // Statistics
    var visitCount: Int = 0
    var totalTimeSpent: TimeInterval = 0 // seconds

    // Metadata
    var createdAt: Date = Date()
    var lastVisitedAt: Date?

    // Notes
    var notes: String?

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \PlaceVisit.place)
    var visits: [PlaceVisit]?

    init(
        id: UUID = UUID(),
        name: String,
        emoji: String? = nil,
        colorHex: String? = nil,
        category: PlaceCategory,
        latitude: Double,
        longitude: Double,
        address: String? = nil,
        radius: Double = 100,
        isGeofenceEnabled: Bool = true,
        notifyOnEntry: Bool = true,
        notifyOnExit: Bool = false,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji ?? category.defaultEmoji
        self.colorHex = colorHex ?? category.defaultColor
        self.categoryRaw = category.rawValue
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.radius = radius
        self.isGeofenceEnabled = isGeofenceEnabled
        self.notifyOnEntry = notifyOnEntry
        self.notifyOnExit = notifyOnExit
        self.visitCount = 0
        self.totalTimeSpent = 0
        self.createdAt = Date()
        self.notes = notes
    }

    // MARK: - Computed Properties

    var category: PlaceCategory {
        get { PlaceCategory(rawValue: categoryRaw) ?? .custom }
        set { categoryRaw = newValue.rawValue }
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var color: Color {
        Color(hex: colorHex)
    }

    /// CLCircularRegion for geofencing
    var region: CLCircularRegion {
        let region = CLCircularRegion(
            center: coordinate,
            radius: radius,
            identifier: id.uuidString
        )
        region.notifyOnEntry = notifyOnEntry
        region.notifyOnExit = notifyOnExit
        return region
    }

    /// Formatted address or coordinates
    var displayAddress: String {
        address ?? String(format: "%.4f, %.4f", latitude, longitude)
    }

    /// Average visit duration (formatted)
    var averageVisitDuration: String {
        guard visitCount > 0 else {
            return "Henüz ziyaret yok"
        }
        let average = totalTimeSpent / Double(visitCount)
        return formatDuration(average)
    }

    /// Total time spent (formatted)
    var formattedTotalTime: String {
        formatDuration(totalTimeSpent)
    }

    /// Last visited time (relative)
    var lastVisitedRelative: String {
        guard let lastVisit = lastVisitedAt else {
            return "Hiç ziyaret edilmedi"
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.localizedString(for: lastVisit, relativeTo: Date())
    }

    // MARK: - Helper Methods

    /// Distance from a given location
    func distance(from location: CLLocation) -> Double {
        let placeLocation = CLLocation(latitude: latitude, longitude: longitude)
        return location.distance(from: placeLocation)
    }

    /// Formatted distance
    func formattedDistance(from location: CLLocation) -> String {
        let meters = distance(from: location)

        if meters < 1000 {
            return String(format: "%.0f m", meters)
        } else {
            return String(format: "%.1f km", meters / 1000)
        }
    }

    /// Is the location within geofence radius?
    func contains(location: CLLocation) -> Bool {
        distance(from: location) <= radius
    }

    /// Increment visit count
    func recordVisit(duration: TimeInterval) {
        visitCount += 1
        totalTimeSpent += duration
        lastVisitedAt = Date()
    }

    /// Update location
    func updateLocation(
        latitude: Double,
        longitude: Double,
        address: String?
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
    }

    // MARK: - Private Helpers

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if hours > 0 {
            return "\(hours) saat \(minutes) dakika"
        } else if minutes > 0 {
            return "\(minutes) dakika"
        } else {
            return "1 dakikadan az"
        }
    }
}

// MARK: - PlaceVisit Model

@Model
final class PlaceVisit {
    var id: UUID = UUID()
    var arrivalTime: Date = Date()
    var departureTime: Date?
    var duration: TimeInterval = 0 // computed on departure

    // Relationship
    var place: SavedPlace?

    init(
        id: UUID = UUID(),
        arrivalTime: Date = Date(),
        place: SavedPlace? = nil
    ) {
        self.id = id
        self.arrivalTime = arrivalTime
        self.duration = 0
        self.place = place
    }

    /// End visit and calculate duration
    func endVisit() {
        departureTime = Date()
        if let departure = departureTime {
            duration = departure.timeIntervalSince(arrivalTime)
        }
    }

    /// Is this visit still ongoing?
    var isOngoing: Bool {
        departureTime == nil
    }

    /// Formatted arrival time
    var formattedArrival: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: arrivalTime)
    }

    /// Formatted duration
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if isOngoing {
            return "Devam ediyor..."
        } else if hours > 0 {
            return "\(hours) saat \(minutes) dakika"
        } else if minutes > 0 {
            return "\(minutes) dakika"
        } else {
            return "1 dakikadan az"
        }
    }
}

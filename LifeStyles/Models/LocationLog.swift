//
//  LocationLog.swift
//  LifeStyles
//
//  Created by Claude on 15.10.2025.
//

import Foundation
import SwiftData
import CoreLocation

enum LocationType: String, Codable {
    case home = "home"
    case work = "work"
    case other = "other"
}

@Model
final class LocationLog {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var locationTypeRaw: String = "other"
    var durationInMinutes: Int = 10 // Bu lokasyonda ne kadar kaldı - DEFAULT 10 dakika
    var accuracy: Double = 0 // Konum doğruluğu (metre)
    var altitude: Double = 0 // Rakım
    var address: String? = nil // Reverse geocoding ile elde edilen adres

    @Relationship(deleteRule: .nullify)
    var relatedMood: MoodEntry?

    init(
        id: UUID = UUID(),
        timestamp: Date,
        latitude: Double,
        longitude: Double,
        locationType: LocationType,
        durationInMinutes: Int = 0,
        accuracy: Double = 0,
        altitude: Double = 0,
        address: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.locationTypeRaw = locationType.rawValue
        self.durationInMinutes = durationInMinutes
        self.accuracy = accuracy
        self.altitude = altitude
        self.address = address
    }

    var locationType: LocationType {
        get { LocationType(rawValue: locationTypeRaw) ?? .other }
        set { locationTypeRaw = newValue.rawValue }
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    // Okunabilir tarih formatı
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        formatter.locale = Locale.current // Sistem diline göre otomatik
        return formatter.string(from: timestamp)
    }

    // Gün içi saat
    var timeOfDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale.current // Sistem diline göre otomatik
        return formatter.string(from: timestamp)
    }
}

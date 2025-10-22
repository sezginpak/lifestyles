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
    var id: UUID
    var timestamp: Date
    var latitude: Double
    var longitude: Double
    var locationTypeRaw: String
    var durationInMinutes: Int // Bu lokasyonda ne kadar kaldı
    var accuracy: Double // Konum doğruluğu (metre)
    var altitude: Double // Rakım
    var address: String? // Reverse geocoding ile elde edilen adres

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

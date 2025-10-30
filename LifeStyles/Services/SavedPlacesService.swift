//
//  SavedPlacesService.swift
//  LifeStyles
//
//  Created by Claude on 25.10.2025.
//  Kayıtlı yerlerin yönetimi ve geofencing servisi
//

import Foundation
import CoreLocation
import SwiftData
import UserNotifications

@Observable
class SavedPlacesService: NSObject, CLLocationManagerDelegate {
    static let shared = SavedPlacesService()

    private let locationManager = CLLocationManager()
    private var modelContext: ModelContext?

    // Current state
    private(set) var currentPlace: SavedPlace?
    private(set) var nearbyPlaces: [SavedPlace] = []
    private(set) var currentLocation: CLLocation?

    // Visit tracking
    private var currentVisit: PlaceVisit?
    private var visitStartTime: Date?

    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    // MARK: - Setup

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        setupAllGeofences()
    }

    // MARK: - Geofencing

    /// Setup geofencing for a specific place
    func setupGeofencing(for place: SavedPlace) {
        guard place.isGeofenceEnabled else {
            print("⚠️ Geofencing disabled for \(place.name)")
            return
        }

        // Remove existing geofence (if any)
        if let existing = locationManager.monitoredRegions.first(where: { $0.identifier == place.id.uuidString }) {
            locationManager.stopMonitoring(for: existing)
        }

        // Add new geofence
        let region = place.region
        locationManager.startMonitoring(for: region)

        print("✅ Geofencing enabled for \(place.name) (\(Int(place.radius))m radius)")
    }

    /// Remove geofencing for a specific place
    func removeGeofencing(for place: SavedPlace) {
        if let region = locationManager.monitoredRegions.first(where: { $0.identifier == place.id.uuidString }) {
            locationManager.stopMonitoring(for: region)
            print("🗑️ Geofencing removed for \(place.name)")
        }
    }

    /// Update geofencing (when place settings change)
    func updateGeofencing(for place: SavedPlace) {
        removeGeofencing(for: place)

        if place.isGeofenceEnabled {
            setupGeofencing(for: place)
        }
    }

    /// Setup geofences for all saved places
    func setupAllGeofences() {
        guard let context = modelContext else {
            print("⚠️ ModelContext not set")
            return
        }

        // Fetch all places
        let descriptor = FetchDescriptor<SavedPlace>()
        guard let places = try? context.fetch(descriptor) else {
            print("⚠️ Failed to fetch saved places")
            return
        }

        // Setup geofence for each enabled place
        for place in places where place.isGeofenceEnabled {
            setupGeofencing(for: place)
        }

        print("✅ Setup geofences for \(places.filter(\.isGeofenceEnabled).count) places")
    }

    /// Remove all geofences
    func removeAllGeofences() {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        print("🗑️ All geofences removed")
    }

    // MARK: - Place Detection

    /// Get current place based on location
    func getCurrentPlace(location: CLLocation? = nil) -> SavedPlace? {
        guard let context = modelContext else { return nil }

        let searchLocation = location ?? currentLocation
        guard let searchLocation = searchLocation else { return nil }

        // Fetch all places
        let descriptor = FetchDescriptor<SavedPlace>()
        guard let places = try? context.fetch(descriptor) else {
            return nil
        }

        // Find place containing current location
        return places.first { place in
            place.contains(location: searchLocation)
        }
    }

    /// Get nearby places within a distance
    func getNearbyPlaces(within meters: Double = 1000, location: CLLocation? = nil) -> [SavedPlace] {
        guard let context = modelContext else { return [] }

        let searchLocation = location ?? currentLocation
        guard let searchLocation = searchLocation else { return [] }

        // Fetch all places
        let descriptor = FetchDescriptor<SavedPlace>()
        guard let places = try? context.fetch(descriptor) else {
            return []
        }

        // Filter and sort by distance
        return places
            .filter { $0.distance(from: searchLocation) <= meters }
            .sorted { $0.distance(from: searchLocation) < $1.distance(from: searchLocation) }
    }

    /// Get all saved places
    func getAllPlaces() -> [SavedPlace] {
        guard let context = modelContext else { return [] }

        let descriptor = FetchDescriptor<SavedPlace>(
            sortBy: [SortDescriptor(\.lastVisitedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Visit Tracking

    /// Start tracking a visit to a place
    private func startVisit(place: SavedPlace) {
        // End previous visit if any
        if let ongoing = currentVisit {
            endVisit(ongoing)
        }

        guard let context = modelContext else { return }

        // Create new visit
        let visit = PlaceVisit(arrivalTime: Date(), place: place)
        context.insert(visit)

        currentVisit = visit
        currentPlace = place
        visitStartTime = Date()

        print("📍 Started visit to \(place.name)")

        // Send entry notification if enabled
        if place.notifyOnEntry {
            sendPlaceNotification(place: place, isEntry: true)
        }
    }

    /// End the current visit
    private func endVisit(_ visit: PlaceVisit) {
        guard let context = modelContext else { return }

        visit.endVisit()

        // Update place statistics
        if let place = visit.place {
            place.recordVisit(duration: visit.duration)
        }

        try? context.save()

        if let place = visit.place {
            print("📍 Ended visit to \(place.name) (duration: \(visit.formattedDuration))")

            // Send exit notification if enabled
            if place.notifyOnExit {
                sendPlaceNotification(place: place, isEntry: false)
            }
        }

        currentVisit = nil
        currentPlace = nil
        visitStartTime = nil
    }

    // MARK: - Notifications

    private func sendPlaceNotification(place: SavedPlace, isEntry: Bool) {
        let content = UNMutableNotificationContent()

        if isEntry {
            content.title = "\(place.emoji) \(place.name)'a vardın"
            content.body = getEntryMessage(for: place)
        } else {
            content.title = "\(place.emoji) \(place.name)'dan ayrıldın"
            content.body = getExitMessage(for: place)
        }

        content.sound = .default
        content.badge = 1

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to send notification: \(error)")
            }
        }
    }

    private func getEntryMessage(for place: SavedPlace) -> String {
        switch place.category {
        case .home:
            let messages = [
                "Evinin rahatlığına hoş geldin!",
                "Güzel bir gün geçirdin mi?",
                "Dinlenme zamanı!",
            ]
            return messages.randomElement() ?? "Hoş geldin!"

        case .work:
            let messages = [
                "İyi çalışmalar!",
                "Bugün harika bir gün olacak!",
                "Focus mode'u açmayı unutma!",
            ]
            return messages.randomElement() ?? "İyi çalışmalar!"

        case .gym:
            let messages = [
                "Antrenman zamanı! 💪",
                "Bugün kendini zorla!",
                "Başarılı bir antrenman dilerim!",
            ]
            return messages.randomElement() ?? "İyi antrenmanlar!"

        default:
            return "Hoş geldin!"
        }
    }

    private func getExitMessage(for place: SavedPlace) -> String {
        guard let duration = visitStartTime?.timeIntervalSinceNow else {
            return "Görüşmek üzere!"
        }

        let hours = Int(-duration) / 3600
        let minutes = (Int(-duration) % 3600) / 60

        if hours > 0 {
            return "\(hours) saat \(minutes) dakika kaldın"
        } else if minutes > 0 {
            return "\(minutes) dakika kaldın"
        } else {
            return "Kısa bir ziyaretti!"
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location

        // Update nearby places
        nearbyPlaces = getNearbyPlaces()

        // Check if entered a new place (without geofence trigger)
        if currentPlace == nil {
            if let place = getCurrentPlace(location: location) {
                startVisit(place: place)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let context = modelContext else { return }

        print("📍 Entered region: \(region.identifier)")

        // Find the place
        let placeId = UUID(uuidString: region.identifier)
        guard let placeId = placeId else { return }

        let descriptor = FetchDescriptor<SavedPlace>(
            predicate: #Predicate { $0.id == placeId }
        )

        guard let place = try? context.fetch(descriptor).first else {
            print("⚠️ Place not found for region: \(region.identifier)")
            return
        }

        // Start visit
        startVisit(place: place)
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("📍 Exited region: \(region.identifier)")

        // End current visit if matches
        if let visit = currentVisit, visit.place?.id.uuidString == region.identifier {
            endVisit(visit)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location manager error: \(error.localizedDescription)")
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("❌ Monitoring failed for region \(region?.identifier ?? "unknown"): \(error.localizedDescription)")
    }

    // MARK: - Public API

    /// Start location updates
    func startMonitoring() {
        locationManager.startUpdatingLocation()
        print("✅ SavedPlacesService monitoring started")
    }

    /// Stop location updates
    func stopMonitoring() {
        locationManager.stopUpdatingLocation()
        print("⏸️ SavedPlacesService monitoring stopped")
    }

    /// Delete a place
    func deletePlace(_ place: SavedPlace, context: ModelContext) {
        // End visit if currently at this place
        if currentPlace?.id == place.id, let visit = currentVisit {
            endVisit(visit)
        }

        // Remove geofencing
        removeGeofencing(for: place)

        // Delete from context
        context.delete(place)

        print("🗑️ Deleted place: \(place.name)")
    }
}

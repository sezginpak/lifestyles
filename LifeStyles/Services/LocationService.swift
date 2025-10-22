//
//  LocationService.swift
//  LifeStyles
//
//  Created by Claude on 15.10.2025.
//

import Foundation
import CoreLocation
import SwiftData

@Observable
class LocationService: NSObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    private let locationManager = CLLocationManager()
    private(set) var currentLocation: CLLocation?
    private(set) var isAtHome: Bool = false
    private(set) var homeLocation: CLLocationCoordinate2D?
    private(set) var timeSpentAtHome: TimeInterval = 0

    private var lastLocationUpdate: Date?
    private let homeRadiusMeters: Double = 100 // Ev yarıçapı (metre)

    // Periyodik konum kayıt sistemi
    private var locationTimer: Timer?
    private let locationTrackingInterval: TimeInterval = 15 * 60 // 15 dakika (PRODUCTION)
    private var modelContext: ModelContext?
    private(set) var isPeriodicTrackingActive: Bool = false
    private(set) var lastRecordedLocation: Date?
    private(set) var totalLocationsRecorded: Int = 0

    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        loadTrackingState()
    }

    // İzin durumunu kontrol et
    func checkPermission() -> CLAuthorizationStatus {
        locationManager.authorizationStatus
    }

    // İzin iste
    func requestPermission() {
        locationManager.requestAlwaysAuthorization()
    }

    // Konum takibini başlat
    func startTracking() {
        locationManager.startUpdatingLocation()
    }

    // Konum takibini durdur
    func stopTracking() {
        locationManager.stopUpdatingLocation()
    }

    // Ev konumunu ayarla
    func setHomeLocation(_ coordinate: CLLocationCoordinate2D) {
        homeLocation = coordinate
        UserDefaults.standard.set(coordinate.latitude, forKey: "homeLatitude")
        UserDefaults.standard.set(coordinate.longitude, forKey: "homeLongitude")
        setupGeofencing()
    }

    // Kaydedilmiş ev konumunu yükle
    func loadHomeLocation() {
        let latitude = UserDefaults.standard.double(forKey: "homeLatitude")
        let longitude = UserDefaults.standard.double(forKey: "homeLongitude")

        if latitude != 0 && longitude != 0 {
            homeLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            setupGeofencing()
        }
    }

    // Geofencing kur
    private func setupGeofencing() {
        guard let home = homeLocation else { return }

        // Önce eski geofence'leri temizle
        for region in locationManager.monitoredRegions {
            if region.identifier == "home" {
                locationManager.stopMonitoring(for: region)
            }
        }

        let region = CLCircularRegion(
            center: home,
            radius: homeRadiusMeters,
            identifier: "home"
        )
        region.notifyOnEntry = true
        region.notifyOnExit = true

        locationManager.startMonitoring(for: region)
    }

    // Evde mi kontrol et
    private func checkIfAtHome(_ location: CLLocation) -> Bool {
        guard let home = homeLocation else { return false }
        let homeLocation = CLLocation(latitude: home.latitude, longitude: home.longitude)
        return location.distance(from: homeLocation) <= homeRadiusMeters
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        isAtHome = checkIfAtHome(location)

        // Evde kalınan süreyi hesapla
        if isAtHome {
            if let lastUpdate = lastLocationUpdate {
                timeSpentAtHome += Date().timeIntervalSince(lastUpdate)
            }
        } else {
            timeSpentAtHome = 0
        }

        lastLocationUpdate = Date()
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region.identifier == "home" {
            isAtHome = true
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region.identifier == "home" {
            isAtHome = false
            timeSpentAtHome = 0
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // İzin durumu değiştiğinde yapılacak işlemler
    }

    // MARK: - Periyodik Konum Takibi

    // ModelContext'i ayarla (ViewModel'den çağrılmalı)
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // Periyodik takibi başlat
    func startPeriodicTracking() {
        // Konum güncellemelerini başlat (her durumda)
        locationManager.startUpdatingLocation()

        // Eğer zaten aktifse ve Timer varsa, çıkış yap
        if isPeriodicTrackingActive && locationTimer != nil {
            return
        }

        isPeriodicTrackingActive = true
        saveTrackingState()

        // İlk kaydı hemen yap
        recordCurrentLocation()

        // Timer'ı başlat
        locationTimer = Timer.scheduledTimer(
            withTimeInterval: locationTrackingInterval,
            repeats: true
        ) { [weak self] _ in
            self?.recordCurrentLocation()
        }

        // Timer'ın arka planda da çalışması için
        RunLoop.current.add(locationTimer!, forMode: .common)

        print("✅ Periyodik konum takibi başlatıldı (15 dakikada bir)")
    }

    // Periyodik takibi durdur
    func stopPeriodicTracking() {
        // Timer'ı durdur
        locationTimer?.invalidate()
        locationTimer = nil

        // Konum güncellemelerini durdur
        locationManager.stopUpdatingLocation()

        isPeriodicTrackingActive = false
        saveTrackingState()
        print("⏹️ Periyodik konum takibi durduruldu")
    }

    // Mevcut konumu kaydet
    private func recordCurrentLocation() {
        // Debug: Kontrolleri ayrı ayrı yap
        if modelContext == nil {
            print("⚠️ HATA: ModelContext yok! setModelContext() çağrıldı mı?")
            return
        }

        // currentLocation yoksa locationManager.location'ı kullan
        let location = currentLocation ?? locationManager.location

        if location == nil {
            print("⚠️ HATA: Konum alınamadı! GPS kapalı olabilir.")
            return
        }

        guard let context = modelContext,
              let loc = location else {
            print("⚠️ Konum kaydedilemedi: Context veya konum yok")
            return
        }

        // Konum tipini belirle
        let locationType: LocationType = isAtHome ? .home : .other

        // Yeni kayıt oluştur
        let log = LocationLog(
            timestamp: Date(),
            latitude: loc.coordinate.latitude,
            longitude: loc.coordinate.longitude,
            locationType: locationType,
            accuracy: loc.horizontalAccuracy,
            altitude: loc.altitude
        )

        context.insert(log)

        do {
            try context.save()
            lastRecordedLocation = Date()
            totalLocationsRecorded += 1
            saveTrackingState()
            print("✅ Konum kaydedildi: \(log.formattedDate) - \(locationType.rawValue)")

            // Arka planda reverse geocoding yap
            Task {
                await reverseGeocodeLocation(log: log, context: context)
            }
        } catch {
            print("❌ Konum kaydetme hatası: \(error.localizedDescription)")
        }
    }

    // Reverse geocoding - Koordinattan adres bilgisi al
    @MainActor
    private func reverseGeocodeLocation(log: LocationLog, context: ModelContext) async {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: log.latitude, longitude: log.longitude)

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)

            if let placemark = placemarks.first {
                // Adres bilgisini oluştur
                var addressComponents: [String] = []

                if let name = placemark.name {
                    addressComponents.append(name)
                }
                if let thoroughfare = placemark.thoroughfare {
                    addressComponents.append(thoroughfare)
                }
                if let locality = placemark.locality {
                    addressComponents.append(locality)
                }
                if let administrativeArea = placemark.administrativeArea {
                    addressComponents.append(administrativeArea)
                }

                let address = addressComponents.joined(separator: ", ")

                // Log'u güncelle
                log.address = address.isEmpty ? "Bilinmeyen Konum" : address

                try? context.save()
            }
        } catch {
            log.address = "Adres alınamadı"
            try? context.save()
        }
    }

    // Takip durumunu kaydet
    private func saveTrackingState() {
        UserDefaults.standard.set(isPeriodicTrackingActive, forKey: "periodicTrackingActive")
        UserDefaults.standard.set(lastRecordedLocation, forKey: "lastRecordedLocation")
        UserDefaults.standard.set(totalLocationsRecorded, forKey: "totalLocationsRecorded")
    }

    // Takip durumunu yükle
    private func loadTrackingState() {
        isPeriodicTrackingActive = UserDefaults.standard.bool(forKey: "periodicTrackingActive")
        lastRecordedLocation = UserDefaults.standard.object(forKey: "lastRecordedLocation") as? Date
        totalLocationsRecorded = UserDefaults.standard.integer(forKey: "totalLocationsRecorded")
    }

    // Konum geçmişini getir
    func fetchLocationHistory(for date: Date? = nil, context: ModelContext) -> [LocationLog] {
        let descriptor: FetchDescriptor<LocationLog>

        if let date = date {
            // Belirli bir güne ait kayıtları getir
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            descriptor = FetchDescriptor<LocationLog>(
                predicate: #Predicate { log in
                    log.timestamp >= startOfDay && log.timestamp < endOfDay
                },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
        } else {
            // Tüm kayıtları getir
            descriptor = FetchDescriptor<LocationLog>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
        }

        do {
            return try context.fetch(descriptor)
        } catch {
            print("❌ Konum geçmişi getirme hatası: \(error)")
            return []
        }
    }

    // Son N günün konum sayısını getir
    func getLocationCountForLastDays(_ days: Int, context: ModelContext) -> Int {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!

        let descriptor = FetchDescriptor<LocationLog>(
            predicate: #Predicate { log in
                log.timestamp >= startDate
            }
        )

        do {
            let logs = try context.fetch(descriptor)
            return logs.count
        } catch {
            print("❌ Konum sayısı getirme hatası: \(error)")
            return 0
        }
    }
}

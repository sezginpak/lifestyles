//
//  LocationService.swift
//  LifeStyles
//
//  Created by Claude on 15.10.2025.
//

import Foundation
import CoreLocation
import SwiftData
import UIKit
import UserNotifications

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

    // Thread safety için serial queue
    private let syncQueue = DispatchQueue(label: "com.lifestyles.locationservice.sync")

    // Periyodik konum kayıt sistemi
    private var locationTimer: Timer?
    private let locationTrackingInterval: TimeInterval = 10 * 60 // 10 dakika - Timer arka planda çalışmaz, yedek sistem
    private let locationDistanceThreshold: Double = 20 // 20 metre - Bu mesafe içindeyse aynı yer sayılır
    private var modelContext: ModelContext?
    private var _isPeriodicTrackingActive: Bool = false
    private(set) var lastRecordedLocation: Date?
    private(set) var totalLocationsRecorded: Int = 0

    // Arka plan task yönetimi
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    // Thread-safe isPeriodicTrackingActive accessor
    var isPeriodicTrackingActive: Bool {
        get {
            syncQueue.sync { _isPeriodicTrackingActive }
        }
        set {
            syncQueue.sync { _isPeriodicTrackingActive = newValue }
        }
    }

    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer // Pil dostu
        locationManager.activityType = .other // iOS power management için
        locationManager.pausesLocationUpdatesAutomatically = false // Manuel kontrol
        locationManager.showsBackgroundLocationIndicator = true // iOS 11+ şeffaflık
        loadTrackingState()
    }

    deinit {
        // Timer'ı güvenli şekilde temizle - DEADLOCK ÖNLEMİ
        if Thread.isMainThread {
            locationTimer?.invalidate()
            locationTimer = nil
        } else {
            DispatchQueue.main.async { [weak locationTimer] in
                locationTimer?.invalidate()
            }
        }
        // Location updates'i durdur
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
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

        // Arka planda da kayıt yap (Significant location change tetiklendiyse)
        if isPeriodicTrackingActive {
            // Son kayıttan bu yana yeterli zaman geçmişse kaydet
            let shouldRecord: Bool
            if let lastRecorded = lastRecordedLocation {
                let timeSinceLastRecord = Date().timeIntervalSince(lastRecorded)
                shouldRecord = timeSinceLastRecord >= (5 * 60) // 5 dakikada bir minimum
            } else {
                shouldRecord = true // İlk kayıt
            }

            if shouldRecord {
                Task { @MainActor in
                    await recordCurrentLocation()
                    print("📍 Arka plan konum güncellemesi kaydedildi")
                }
            }
        }
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
        let status = manager.authorizationStatus
        print("🔐 Konum izin durumu değişti: \(status.rawValue)")

        switch status {
        case .notDetermined:
            print("ℹ️ Konum izni henüz belirlenmedi")
        case .restricted:
            print("⚠️ Konum servisi kısıtlı (Parental Controls)")
            sendLocationErrorNotification(message: "Konum servisi kısıtlı. Ayarları kontrol edin.")
        case .denied:
            print("❌ Konum izni reddedildi")
            sendLocationErrorNotification(message: "Konum izni reddedildi. Lütfen Ayarlar > Gizlilik > Konum Servisleri'nden izin verin.")
        case .authorizedWhenInUse:
            print("✅ Konum izni verildi (Sadece kullanırken)")
            print("⚠️ Arka plan konum takibi için 'Always' izni gerekli")
        case .authorizedAlways:
            print("✅ Konum izni verildi (Her zaman)")
            // Tracking aktifse ve daha önce başlatılmışsa tekrar başlat
            if isPeriodicTrackingActive {
                locationManager.allowsBackgroundLocationUpdates = true
            }
        @unknown default:
            print("⚠️ Bilinmeyen izin durumu")
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Konum servisi hatası: \(error.localizedDescription)")

        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                print("❌ Konum servisi izin hatası")
                sendLocationErrorNotification(message: "Konum izni reddedildi")
            case .locationUnknown:
                print("⚠️ Konum belirlenemiyor (GPS sinyal sorunu)")
            case .network:
                print("⚠️ Ağ bağlantısı sorunu")
            default:
                print("⚠️ Diğer konum hatası: \(clError.code.rawValue)")
            }
        }
    }

    // Konum hata bildirimi gönder
    private func sendLocationErrorNotification(message: String) {
        Task { @MainActor in
            let content = UNMutableNotificationContent()
            content.title = "Konum Servisi Uyarısı"
            content.body = message
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "location_error_\(Date().timeIntervalSince1970)",
                content: content,
                trigger: nil // Hemen gönder
            )

            do {
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                print("❌ Bildirim gönderilemedi: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Periyodik Konum Takibi

    // ModelContext'i ayarla (ViewModel'den çağrılmalı)
    @MainActor
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // Periyodik takibi başlat
    func startPeriodicTracking() {
        // Thread-safe flag kontrolü
        let alreadyActive = syncQueue.sync { () -> Bool in
            if _isPeriodicTrackingActive {
                return true
            }
            _isPeriodicTrackingActive = true
            return false
        }

        if alreadyActive {
            print("⚠️ Periodic tracking already active")
            return
        }

        // İzin kontrolü - ALWAYS izni gerekli
        guard locationManager.authorizationStatus == .authorizedAlways else {
            print("❌ Arka plan konum izni yok! 'Always' izni gerekli.")
            syncQueue.sync {
                _isPeriodicTrackingActive = false
            }
            return
        }

        // Arka plan güncellemelerini etkinleştir
        locationManager.allowsBackgroundLocationUpdates = true

        // ARKA PLAN İÇİN EN ÖNEMLİ: Significant Location Changes
        // Bu, arka planda sürekli çalışır ve kullanıcı ~500m hareket edince tetiklenir
        locationManager.startMonitoringSignificantLocationChanges()
        print("✅ Significant Location Changes başlatıldı (Arka plan için)")

        // Normal konum güncellemelerini de başlat (uygulama açıkken daha sık)
        locationManager.startUpdatingLocation()

        saveTrackingState()

        // İlk kaydı hemen yap
        Task { @MainActor in
            await recordCurrentLocation()
        }

        // Timer - Sadece uygulama açıkken çalışır (yedek sistem)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                print("❌ Self deallocated during timer creation")
                return
            }

            // Eski timer varsa önce temizle
            self.locationTimer?.invalidate()
            self.locationTimer = nil

            // Timer'ı başlat (sadece foreground için)
            self.locationTimer = Timer.scheduledTimer(
                withTimeInterval: self.locationTrackingInterval,
                repeats: true
            ) { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    await self.recordCurrentLocation()
                }
            }

            // Timer'ı RunLoop'a ekle
            if let timer = self.locationTimer {
                RunLoop.main.add(timer, forMode: .common)
                print("✅ Timer başlatıldı (10 dakikada bir - sadece foreground)")
            } else {
                print("❌ Timer oluşturulamadı")
            }
        }
    }

    // Periyodik takibi durdur
    func stopPeriodicTracking() {
        // Thread-safe flag güncelleme
        syncQueue.sync {
            _isPeriodicTrackingActive = false
        }

        // Timer'ı main thread'de durdur
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.locationTimer?.invalidate()
            self.locationTimer = nil
        }

        // Konum güncellemelerini durdur
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()

        saveTrackingState()
        print("⏹️ Periyodik konum takibi durduruldu")
    }

    // Mevcut konumu kaydet - Akıllı süre takibi ile
    @MainActor
    private func recordCurrentLocation() async {
        // Background task başlat - iOS suspend etmesin
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }

        defer {
            endBackgroundTask()
        }

        // Debug: Kontrolleri ayrı ayrı yap
        guard let context = modelContext else {
            print("⚠️ HATA: ModelContext yok! setModelContext() çağrıldı mı?")
            return
        }

        // currentLocation yoksa locationManager.location'ı kullan
        guard let loc = currentLocation ?? locationManager.location else {
            print("⚠️ HATA: Konum alınamadı! GPS kapalı olabilir.")
            return
        }

        // Konum tipini belirle
        let locationType: LocationType = isAtHome ? .home : .other

        // Son kaydı kontrol et
        if let lastLog = getLastLocationLog(context: context) {
            // Mesafeyi hesapla
            let lastLocation = CLLocation(latitude: lastLog.latitude, longitude: lastLog.longitude)
            let distance = loc.distance(from: lastLocation)

            // Eğer 20 metre içindeyse, mevcut kaydın süresini uzat
            if distance <= locationDistanceThreshold {
                let timeDiff = Date().timeIntervalSince(lastLog.timestamp)
                let minutesDiff = Int(timeDiff / 60)

                // Timestamp'i güncelle - son görüldüğü zaman
                lastLog.timestamp = Date()
                lastLog.durationInMinutes += minutesDiff

                do {
                    try context.save()
                    lastRecordedLocation = Date()
                    print("⏱️ Aynı konumdasınız. Süre güncellendi: +\(minutesDiff) dk (Toplam: \(lastLog.durationInMinutes) dk)")
                    print("📍 Mesafe: \(Int(distance))m < \(Int(locationDistanceThreshold))m threshold")
                    return
                } catch {
                    print("❌ Süre güncelleme hatası: \(error.localizedDescription)")
                }
            } else {
                print("🚶 Yeni konuma geçildi (Mesafe: \(Int(distance))m > \(Int(locationDistanceThreshold))m)")
            }
        }

        // Yeni kayıt oluştur (ya ilk kayıt ya da yeni konum)
        // Başlangıç süresi 0 - Her güncellemede artar
        let log = LocationLog(
            timestamp: Date(),
            latitude: loc.coordinate.latitude,
            longitude: loc.coordinate.longitude,
            locationType: locationType,
            durationInMinutes: 0, // İlk süre 0, her güncellemede artacak
            accuracy: loc.horizontalAccuracy,
            altitude: loc.altitude
        )

        context.insert(log)

        do {
            try context.save()
            lastRecordedLocation = Date()
            totalLocationsRecorded += 1
            saveTrackingState()
            print("✅ Yeni konum kaydedildi: \(log.formattedDate) - \(locationType.rawValue)")

            // Arka planda reverse geocoding yap
            await reverseGeocodeLocation(log: log, context: context)
        } catch {
            print("❌ Konum kaydetme hatası: \(error.localizedDescription)")
        }
    }

    // Background task'i temizle
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }

    // Son LocationLog kaydını getir
    private func getLastLocationLog(context: ModelContext) -> LocationLog? {
        let descriptor = FetchDescriptor<LocationLog>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        do {
            let logs = try context.fetch(descriptor)
            return logs.first
        } catch {
            print("❌ Son konum getirme hatası: \(error)")
            return nil
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

                do {
                    try context.save()
                } catch {
                    print("❌ Address save error: \(error.localizedDescription)")
                }
            }
        } catch {
            print("❌ Reverse geocoding error: \(error.localizedDescription)")
            log.address = "Adres alınamadı"
            try? context.save()
        }
    }

    // Takip durumunu kaydet
    private func saveTrackingState() {
        let isActive = syncQueue.sync { _isPeriodicTrackingActive }
        UserDefaults.standard.set(isActive, forKey: "periodicTrackingActive")
        UserDefaults.standard.set(lastRecordedLocation, forKey: "lastRecordedLocation")
        UserDefaults.standard.set(totalLocationsRecorded, forKey: "totalLocationsRecorded")
    }

    // Takip durumunu yükle
    private func loadTrackingState() {
        let isActive = UserDefaults.standard.bool(forKey: "periodicTrackingActive")
        syncQueue.sync {
            _isPeriodicTrackingActive = isActive
        }
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
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                print("❌ Failed to calculate end of day")
                return []
            }

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
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) else {
            print("❌ Failed to calculate start date")
            return 0
        }

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

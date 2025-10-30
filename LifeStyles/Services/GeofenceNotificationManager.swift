//
//  GeofenceNotificationManager.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Location-based notification management with geofencing
//

import Foundation
import CoreLocation
import UserNotifications

// MARK: - Geofence Notification Manager

@Observable
class GeofenceNotificationManager: NSObject {

    static let shared = GeofenceNotificationManager()

    private let locationManager = CLLocationManager()
    private let defaults = UserDefaults.standard
    private let notificationService = NotificationService.shared
    private let scheduler = NotificationScheduler.shared

    private override init() {
        super.init()
        setupLocationManager()
    }

    // MARK: - Location Manager Setup

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 50 // 50 metre değişim
    }

    // MARK: - Home Geofence

    /// Home geofence'i etkinleştir
    func setupHomeGeofence(latitude: Double, longitude: Double, radius: CLLocationDistance = 100) {
        // Önce eski geofence'leri temizle
        removeAllGeofences()

        // Home konumu kaydet
        defaults.set(latitude, forKey: UserDefaults.GeofenceKeys.homeGeofenceLatitude)
        defaults.set(longitude, forKey: UserDefaults.GeofenceKeys.homeGeofenceLongitude)
        defaults.set(radius, forKey: UserDefaults.GeofenceKeys.homeGeofenceRadius)
        defaults.set(true, forKey: UserDefaults.GeofenceKeys.homeGeofenceEnabled)

        // Geofence region oluştur
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = CLCircularRegion(
            center: center,
            radius: radius,
            identifier: "home-geofence"
        )

        region.notifyOnEntry = true
        region.notifyOnExit = true

        // Monitoring başlat
        locationManager.startMonitoring(for: region)

        print("✅ Home geofence kuruldu: \(latitude), \(longitude) - \(radius)m")
    }

    /// Home geofence'i kaldır
    func removeHomeGeofence() {
        defaults.set(false, forKey: UserDefaults.GeofenceKeys.homeGeofenceEnabled)
        removeAllGeofences()
        print("🗑️ Home geofence kaldırıldı")
    }

    /// Tüm geofence'leri kaldır
    func removeAllGeofences() {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
    }

    // MARK: - Location Service Integration

    /// LocationService'ten home location alıp geofence kur
    func syncWithLocationService() {
        let locationService = LocationService.shared

        if let homeLocation = locationService.homeLocation {
            setupHomeGeofence(
                latitude: homeLocation.latitude,
                longitude: homeLocation.longitude,
                radius: 100
            )
        }
    }

    // MARK: - Time at Home Tracking

    /// Evde geçirilen süreyi güncelle
    private func updateTimeAtHome() {
        let now = Date()

        if let lastEntry = defaults.object(forKey: UserDefaults.GeofenceKeys.lastHomeEntry) as? Date {
            let hoursAtHome = now.timeIntervalSince(lastEntry) / 3600
            defaults.set(hoursAtHome, forKey: UserDefaults.GeofenceKeys.hoursAtHome)

            // 6 saatten fazla evdeyse hatırlatıcı gönder
            if hoursAtHome >= 6 {
                sendGoOutsideReminder(hoursAtHome: Int(hoursAtHome))
            }
        }
    }

    // MARK: - Notifications

    /// "Dışarı çık" hatırlatıcısı
    private func sendGoOutsideReminder(hoursAtHome: Int) {
        // Cooldown kontrolü - Son 2 saat içinde gönderildiyse tekrar gönderme
        let lastSentKey = "lastGoOutsideNotification"
        if let lastSent = defaults.object(forKey: lastSentKey) as? Date {
            let hoursSinceLastNotification = Date().timeIntervalSince(lastSent) / 3600
            if hoursSinceLastNotification < 2 {
                print("⏳ Go outside bildirimi cooldown'da (son \(Int(hoursSinceLastNotification * 60)) dakika önce gönderildi)")
                return
            }
        }

        Task {
            let content = NotificationCategoryManager.createContent(
                title: "Dışarı Çıkma Zamanı! 🌞",
                body: "\(hoursAtHome) saattir evdesiniz. Biraz hava almaya ne dersiniz?",
                category: .goOutside
            )

            // Emoji attachment ekle
            content.addRichMedia(emoji: "🌞", category: .goOutside)

            do {
                try await scheduler.sendImmediateNotification(
                    identifier: "go-outside", // Sabit ID - tekrar oluşmayı engellemek için
                    content: content,
                    priority: .normal,
                    respectQuietHours: true
                )

                // Son gönderim zamanını kaydet
                defaults.set(Date(), forKey: lastSentKey)
                print("✅ Go outside bildirimi gönderildi (\(hoursAtHome) saat)")
            } catch {
                print("❌ Go outside notification hatası: \(error)")
            }
        }
    }

    /// Eve giriş bildirimi
    private func sendHomeEntryNotification() {
        // Cooldown kontrolü - Son 30 dakika içinde gönderildiyse tekrar gönderme
        let lastSentKey = "lastHomeEntryNotification"
        if let lastSent = defaults.object(forKey: lastSentKey) as? Date {
            let minutesSinceLastNotification = Date().timeIntervalSince(lastSent) / 60
            if minutesSinceLastNotification < 30 {
                print("⏳ Home entry bildirimi cooldown'da")
                return
            }
        }

        Task {
            let content = NotificationCategoryManager.createContent(
                title: "Hoş Geldiniz! 🏠",
                body: "Eve hoş geldiniz. Hedeflerinizi kontrol etmeyi unutmayın!",
                category: .geofenceHome
            )

            content.addRichMedia(emoji: "🏠", category: .geofenceHome)

            do {
                try await scheduler.sendImmediateNotification(
                    identifier: "home-entry", // Sabit ID
                    content: content,
                    priority: .low,
                    respectQuietHours: true
                )

                defaults.set(Date(), forKey: lastSentKey)
                print("✅ Home entry bildirimi gönderildi")
            } catch {
                print("❌ Home entry notification hatası: \(error)")
            }
        }
    }

    /// Evden çıkış bildirimi
    private func sendHomeExitNotification() {
        // Cooldown kontrolü - Son 30 dakika içinde gönderildiyse tekrar gönderme
        let lastSentKey = "lastHomeExitNotification"
        if let lastSent = defaults.object(forKey: lastSentKey) as? Date {
            let minutesSinceLastNotification = Date().timeIntervalSince(lastSent) / 60
            if minutesSinceLastNotification < 30 {
                print("⏳ Home exit bildirimi cooldown'da")
                return
            }
        }

        Task {
            let content = NotificationCategoryManager.createContent(
                title: "İyi Günler! 👋",
                body: "Güzel bir gün geçirin! Aktivitelerinizi kaydetmeyi unutmayın.",
                category: .geofenceHome
            )

            content.addRichMedia(emoji: "👋", category: .geofenceHome)

            do {
                try await scheduler.sendImmediateNotification(
                    identifier: "home-exit", // Sabit ID
                    content: content,
                    priority: .low,
                    respectQuietHours: true
                )

                defaults.set(Date(), forKey: lastSentKey)
                print("✅ Home exit bildirimi gönderildi")
            } catch {
                print("❌ Home exit notification hatası: \(error)")
            }
        }
    }

    // MARK: - State Check

    /// Kullanıcı şu an evde mi?
    func isUserAtHome() -> Bool {
        guard let lastEntry = defaults.object(forKey: UserDefaults.GeofenceKeys.lastHomeEntry) as? Date,
              let lastExit = defaults.object(forKey: UserDefaults.GeofenceKeys.lastHomeExit) as? Date else {
            return false
        }

        return lastEntry > lastExit
    }

    /// Evde geçirilen süre (saat cinsinden)
    func getHoursAtHome() -> Double {
        return defaults.double(forKey: UserDefaults.GeofenceKeys.hoursAtHome)
    }
}

// MARK: - CLLocationManagerDelegate

extension GeofenceNotificationManager: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard region.identifier == "home-geofence" else { return }

        print("🏠 Home geofence ENTER")

        // Giriş zamanını kaydet
        defaults.set(Date(), forKey: UserDefaults.GeofenceKeys.lastHomeEntry)

        // Bildirim gönder
        sendHomeEntryNotification()
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard region.identifier == "home-geofence" else { return }

        print("👋 Home geofence EXIT")

        // Çıkış zamanını kaydet
        defaults.set(Date(), forKey: UserDefaults.GeofenceKeys.lastHomeExit)

        // Evde geçirilen süreyi güncelle
        updateTimeAtHome()

        // Bildirim gönder
        sendHomeExitNotification()
    }

    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("✅ Geofence monitoring başladı: \(region.identifier)")

        // İlk durum kontrolü
        manager.requestState(for: region)
    }

    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        switch state {
        case .inside:
            print("📍 Kullanıcı şu an bölge içinde: \(region.identifier)")
            if region.identifier == "home-geofence" {
                defaults.set(Date(), forKey: UserDefaults.GeofenceKeys.lastHomeEntry)
            }
        case .outside:
            print("📍 Kullanıcı şu an bölge dışında: \(region.identifier)")
        case .unknown:
            print("❓ Bölge durumu bilinmiyor: \(region.identifier)")
        }
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("❌ Geofence monitoring hatası: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            print("✅ Konum izni verildi, geofence kurulabilir")
            syncWithLocationService()
        case .denied, .restricted:
            print("⛔ Konum izni reddedildi, geofence kurulamaz")
            removeAllGeofences()
        case .notDetermined:
            print("⏳ Konum izni henüz belirlenmedi")
        @unknown default:
            break
        }
    }
}

//
//  PermissionManager.swift
//  LifeStyles
//
//  Created by Claude on 15.10.2025.
//

import Foundation
import CoreLocation
import Contacts
import UserNotifications
import UIKit

@Observable
class PermissionManager {
    static let shared = PermissionManager()

    var locationPermissionStatus: PermissionStatus = .notDetermined
    var contactsPermissionStatus: PermissionStatus = .notDetermined
    var notificationsPermissionStatus: PermissionStatus = .notDetermined

    enum PermissionStatus: Equatable {
        case notDetermined
        case denied
        case authorized
        case restricted
    }

    private init() {
        updateAllPermissions()
    }

    // MARK: - Konum İzni

    func requestLocationPermission() async -> Bool {
        LocationService.shared.requestPermission()

        // Biraz bekle ki sistem izin dialogu gösterebilsin
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 saniye

        let status = LocationService.shared.checkPermission()
        await MainActor.run {
            locationPermissionStatus = convertCLAuthorizationStatus(status)
        }

        // Eğer "Kullanım sırasında" izni verilmişse, kullanıcıyı bilgilendir
        if status == .authorizedWhenInUse {
            // "Her zaman" izni için kullanıcıyı ayarlara yönlendir
            return true // İlk aşama başarılı
        }

        return locationPermissionStatus == .authorized
    }

    func checkLocationPermission() -> PermissionStatus {
        let status = LocationService.shared.checkPermission()
        locationPermissionStatus = convertCLAuthorizationStatus(status)
        return locationPermissionStatus
    }

    func hasAlwaysLocationPermission() -> Bool {
        let status = LocationService.shared.checkPermission()
        return status == .authorizedAlways
    }

    func hasWhenInUseLocationPermission() -> Bool {
        let status = LocationService.shared.checkPermission()
        return status == .authorizedWhenInUse || status == .authorizedAlways
    }

    private func convertCLAuthorizationStatus(_ status: CLAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorizedAlways, .authorizedWhenInUse:
            return .authorized
        @unknown default:
            return .notDetermined
        }
    }

    // MARK: - Rehber İzni

    func requestContactsPermission() async -> Bool {
        let store = CNContactStore()
        do {
            let granted = try await store.requestAccess(for: .contacts)
            await MainActor.run {
                contactsPermissionStatus = granted ? .authorized : .denied
            }
            return granted
        } catch {
            print("❌ Contacts permission error: \(error.localizedDescription)")
            await MainActor.run {
                contactsPermissionStatus = .denied
            }
            return false
        }
    }

    func checkContactsPermission() -> PermissionStatus {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        switch status {
        case .notDetermined:
            contactsPermissionStatus = .notDetermined
        case .restricted:
            contactsPermissionStatus = .restricted
        case .denied:
            contactsPermissionStatus = .denied
        case .authorized:
            contactsPermissionStatus = .authorized
        @unknown default:
            contactsPermissionStatus = .notDetermined
        }
        return contactsPermissionStatus
    }

    // MARK: - Bildirim İzni

    func requestNotificationsPermission() async -> Bool {
        do {
            let granted = try await NotificationService.shared.requestPermission()
            await MainActor.run {
                notificationsPermissionStatus = granted ? .authorized : .denied
            }
            return granted
        } catch {
            print("❌ Notifications permission error: \(error.localizedDescription)")
            await MainActor.run {
                notificationsPermissionStatus = .denied
            }
            return false
        }
    }

    func checkNotificationsPermission() async -> PermissionStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()

        switch settings.authorizationStatus {
        case .notDetermined:
            notificationsPermissionStatus = .notDetermined
        case .denied:
            notificationsPermissionStatus = .denied
        case .authorized, .provisional, .ephemeral:
            notificationsPermissionStatus = .authorized
        @unknown default:
            notificationsPermissionStatus = .notDetermined
        }

        return notificationsPermissionStatus
    }

    // MARK: - Tüm İzinleri Güncelle

    func updateAllPermissions() {
        _ = checkLocationPermission()
        _ = checkContactsPermission()

        Task {
            _ = await checkNotificationsPermission()
        }
    }

    // MARK: - Ayarlar'a Yönlendir

    func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

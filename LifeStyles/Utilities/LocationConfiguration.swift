//
//  LocationConfiguration.swift
//  LifeStyles
//
//  Created by Claude on 06.11.2025.
//  Konum servisi için merkezi konfigürasyon
//

import Foundation
import CoreLocation

enum LocationConfiguration {
    // MARK: - Mesafe ve Konum Eşikleri

    /// Aynı konum olarak kabul edilecek maksimum mesafe (metre)
    /// Servis ve UI'da tutarlı kullanım için tek kaynak
    static let sameLocationThreshold: CLLocationDistance = 30.0

    /// Ev bölgesi yarıçapı (metre)
    static let homeRadiusMeters: Double = 100.0

    // MARK: - Zaman Aralıkları

    /// Periyodik konum kaydı aralığı (saniye) - Foreground
    /// Uyarı: Timer sadece uygulama açıkken çalışır
    static let locationTrackingInterval: TimeInterval = 10 * 60 // 10 dakika

    /// Background'da minimum kayıt aralığı (saniye)
    /// Significant location change için minimum bekleme süresi
    static let backgroundMinimumInterval: TimeInterval = 5 * 60 // 5 dakika

    /// Süre güncelleme için kontrol aralığı (saniye)
    /// Aynı konumda kalma süresini güncellemek için
    static let durationUpdateInterval: TimeInterval = 1 * 60 // 1 dakika

    // MARK: - Background Task

    /// Background task maksimum süresi (saniye)
    /// iOS 30 saniye izin verir, güvenli marj için 25
    static let backgroundTaskTimeout: TimeInterval = 25.0

    /// Reverse geocoding timeout (saniye)
    static let geocodingTimeout: TimeInterval = 10.0

    /// Reverse geocoding retry sayısı
    static let geocodingMaxRetries: Int = 3

    /// Retry arasında bekleme süresi (saniye)
    static let geocodingRetryDelay: TimeInterval = 2.0

    // MARK: - Konum Doğruluğu

    /// Kabul edilebilir maksimum konum hatası (metre)
    /// Bundan büyük accuracy değerleri reddedilir
    static let maxAcceptableAccuracy: Double = 100.0

    /// İdeal konum doğruluğu (metre)
    /// Bu değerin altındaki konumlar "yüksek kalite" olarak işaretlenir
    static let idealAccuracy: Double = 20.0

    // MARK: - Bildirimler

    /// Konum servisi hatası bildirimi gecikme süresi (saniye)
    /// Aynı hatanın tekrar tekrar bildirilmesini önler
    static let errorNotificationCooldown: TimeInterval = 15 * 60 // 15 dakika

    // MARK: - Performans

    /// Batch save için minimum kayıt sayısı
    /// Bu kadar kayıt biriktiğinde toplu kaydet
    static let batchSaveThreshold: Int = 5

    /// Eski kayıtları temizleme süresi (gün)
    /// Bundan eski kayıtlar otomatik silinebilir (opsiyonel)
    static let oldRecordCleanupDays: Int = 90

    // MARK: - Debug/Test Modları

    #if DEBUG
    /// Debug modda daha sık güncelleme (sadece development)
    static let debugTrackingInterval: TimeInterval = 30 // 30 saniye
    #endif
}

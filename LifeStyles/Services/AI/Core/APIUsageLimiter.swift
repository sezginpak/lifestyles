//
//  APIUsageLimiter.swift
//  LifeStyles
//
//  Client-side rate limiting for API usage
//  Created by Claude on 04.11.2025.
//

import Foundation

/// Client-side rate limiter - Kötüye kullanımı önler
class APIUsageLimiter {
    static let shared = APIUsageLimiter()

    // MARK: - Limits (5$ = ~20K requests ile hesaplandı)

    /// Günlük maksimum request sayısı (güvenli limit) - %50 artırıldı
    private let maxRequestsPerDay = 150

    /// Saatlik maksimum request sayısı (spam önleme) - %50 artırıldı
    private let maxRequestsPerHour = 30

    /// Dakikalık maksimum request sayısı (burst önleme) - %50 artırıldı
    private let maxRequestsPerMinute = 8

    // MARK: - UserDefaults Keys

    private let requestTimestampsKey = "api_request_timestamps"

    private init() {}

    // MARK: - Rate Limiting

    /// Request yapılabilir mi kontrol et
    func canMakeRequest() -> (allowed: Bool, reason: String?) {
        let now = Date()
        let timestamps = getRequestTimestamps()

        // 1 dakika kontrolü
        let oneMinuteAgo = now.addingTimeInterval(-60)
        let requestsLastMinute = timestamps.filter { $0 > oneMinuteAgo }.count
        if requestsLastMinute >= maxRequestsPerMinute {
            return (false, "Çok hızlı istek yapıyorsunuz. Lütfen 1 dakika bekleyin.")
        }

        // 1 saat kontrolü
        let oneHourAgo = now.addingTimeInterval(-3600)
        let requestsLastHour = timestamps.filter { $0 > oneHourAgo }.count
        if requestsLastHour >= maxRequestsPerHour {
            return (false, "Saatlik limit aşıldı. Lütfen biraz bekleyin.")
        }

        // 24 saat kontrolü
        let oneDayAgo = now.addingTimeInterval(-86400)
        let requestsLastDay = timestamps.filter { $0 > oneDayAgo }.count
        if requestsLastDay >= maxRequestsPerDay {
            return (false, "Günlük limit aşıldı. Yarın tekrar deneyin.")
        }

        return (true, nil)
    }

    /// Request kaydını yap
    func recordRequest() {
        var timestamps = getRequestTimestamps()
        timestamps.append(Date())

        // Son 24 saati sakla (performans için)
        let oneDayAgo = Date().addingTimeInterval(-86400)
        timestamps = timestamps.filter { $0 > oneDayAgo }

        saveRequestTimestamps(timestamps)
    }

    // MARK: - Stats

    /// Bugünkü request sayısı
    var requestsToday: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return getRequestTimestamps().filter { $0 >= today }.count
    }

    /// Bu saatteki request sayısı
    var requestsThisHour: Int {
        let oneHourAgo = Date().addingTimeInterval(-3600)
        return getRequestTimestamps().filter { $0 > oneHourAgo }.count
    }

    /// Kalan günlük quota
    var remainingDailyQuota: Int {
        return max(0, maxRequestsPerDay - requestsToday)
    }

    /// Kalan saatlik quota
    var remainingHourlyQuota: Int {
        return max(0, maxRequestsPerHour - requestsThisHour)
    }

    // MARK: - Persistence

    private func getRequestTimestamps() -> [Date] {
        guard let data = UserDefaults.standard.array(forKey: requestTimestampsKey) as? [Double] else {
            return []
        }
        return data.map { Date(timeIntervalSince1970: $0) }
    }

    private func saveRequestTimestamps(_ timestamps: [Date]) {
        let data = timestamps.map { $0.timeIntervalSince1970 }
        UserDefaults.standard.set(data, forKey: requestTimestampsKey)
    }

    /// Tüm kayıtları temizle (debugging için)
    func resetUsage() {
        UserDefaults.standard.removeObject(forKey: requestTimestampsKey)
    }
}

// MARK: - Error Type

enum RateLimitError: LocalizedError {
    case limitExceeded(String)

    var errorDescription: String? {
        switch self {
        case .limitExceeded(let reason):
            return reason
        }
    }
}

//
//  MobilityAnalyticsService.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Phase 2: Mobility analytics extracted from DashboardViewModel
//

import Foundation
import SwiftData

@Observable
@MainActor
class MobilityAnalyticsService {

    // MARK: - Mobility Metrics

    struct MobilityMetrics {
        let uniqueLocations: Int
        let hoursOutside: Double
        let mobilityScore: Int
        let homePercentage: Double
        let totalLogs: Int
    }

    // MARK: - Public Methods

    /// Mobilite verilerini analiz et
    func analyzeMobility(context: ModelContext, days: Int = 7) async throws -> MobilityMetrics {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) else {
            throw MobilityAnalyticsError.dateCalculationFailed
        }

        let logs = try fetchLocationLogs(from: startDate, context: context)
        return calculateMobilityMetrics(from: logs)
    }

    /// Günlük mobilite trendi hesapla
    func calculateDailyMobilityTrend(context: ModelContext, days: Int = 7) async throws -> [Double] {
        let calendar = Calendar.current
        var trendData: [Double] = []

        for dayOffset in (0..<days).reversed() {
            guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else {
                print("⚠️ [MobilityAnalytics] Trend tarih hesaplanamadı: dayOffset \(dayOffset)")
                continue
            }
            let dayStart = calendar.startOfDay(for: targetDate)
            guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                print("⚠️ [MobilityAnalytics] Trend gün sonu hesaplanamadı")
                continue
            }

            let locationDescriptor = FetchDescriptor<LocationLog>(
                predicate: #Predicate { log in
                    log.timestamp >= dayStart && log.timestamp < dayEnd
                }
            )

            let logs = try context.fetch(locationDescriptor)
            let uniqueCoords = Set(logs.map { "\(Int($0.latitude * 100)),\(Int($0.longitude * 100))" })
            let score = min(Double(uniqueCoords.count) * 10.0, 100.0)
            trendData.append(score)
        }

        return trendData.isEmpty ? [0.0] : trendData
    }

    /// Diversity score hesapla (0-100)
    func calculateDiversityScore(logs: [LocationLog]) -> Int {
        // 200m hassasiyetinde benzersiz lokasyon sayısı
        let coordinates = logs.map { "\(Int($0.latitude * 5)),\(Int($0.longitude * 5))" }
        let uniqueLocations = Set(coordinates).count

        // 15 yer = 100%, gerçekçi formül
        let locationDiversity = min(Double(uniqueLocations) / 15.0, 1.0)
        return Int(locationDiversity * 100)
    }

    /// Aktivite skoru hesapla (mobilite + dışarıda geçirilen süre)
    func calculateActivityScore(metrics: MobilityMetrics) -> Int {
        // Mobilite skoru zaten 0-100 arası
        return metrics.mobilityScore
    }

    // MARK: - Private Helpers

    private func fetchLocationLogs(from date: Date, context: ModelContext) throws -> [LocationLog] {
        let descriptor = FetchDescriptor<LocationLog>(
            predicate: #Predicate { log in log.timestamp >= date }
        )
        return try context.fetch(descriptor)
    }

    private func calculateMobilityMetrics(from logs: [LocationLog]) -> MobilityMetrics {
        print("📍 [MobilityAnalytics] Total logs (7 gün): \(logs.count)")

        // Benzersiz lokasyon sayısı - 200m hassasiyet
        let coordinates = logs.map { "\(Int($0.latitude * 5)),\(Int($0.longitude * 5))" }
        let uniqueLocations = Set(coordinates).count
        print("   Benzersiz lokasyonlar (200m): \(uniqueLocations)")

        // Dışarıda geçirilen süre
        let outsideLogs = logs.filter { $0.locationType != .home }
        let hoursOutside = Double(outsideLogs.count) * 0.5 // Her log ~30 dakika
        print("   Dışarıda log sayısı: \(outsideLogs.count)")
        print("   Dışarıda saat: \(String(format: "%.1f", hoursOutside))")

        // Ev yüzdesi
        let homeLogs = logs.filter { $0.locationType == .home }
        let homePercentage = logs.isEmpty ? 0.0 : Double(homeLogs.count) / Double(logs.count)

        // Mobilite skoru (0-100)
        let mobilityScore = calculateDiversityScore(logs: logs)
        print("   Mobilite Skoru: \(mobilityScore)")
        print("   ---")

        return MobilityMetrics(
            uniqueLocations: uniqueLocations,
            hoursOutside: hoursOutside,
            mobilityScore: mobilityScore,
            homePercentage: homePercentage,
            totalLogs: logs.count
        )
    }
}

// MARK: - Errors

enum MobilityAnalyticsError: Error, LocalizedError {
    case dateCalculationFailed

    var errorDescription: String? {
        switch self {
        case .dateCalculationFailed:
            return "Tarih hesaplama hatası"
        }
    }
}

//
//  ContactAnalyticsService.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Phase 1: Contact Analytics Extraction from DashboardViewModel
//

import Foundation
import SwiftData

/// İletişim analitiklerini yöneten service
/// Sorumluluğu: İletişim trendleri, istatistikler, sosyal skorlar
@Observable
@MainActor
class ContactAnalyticsService {

    // MARK: - Data Models

    /// İletişim trend verileri
    struct ContactTrends {
        /// Bu haftaki iletişim sayısı
        let thisWeekCount: Int

        /// Geçen haftaki iletişim sayısı
        let lastWeekCount: Int

        /// Trend yüzdesi (pozitif = artış, negatif = azalış)
        let trendPercentage: Double

        /// Son iletişimin ruh hali emoji'si
        let lastMood: String

        var hasPositiveTrend: Bool {
            return trendPercentage > 0
        }

        var trendDescription: String {
            if trendPercentage > 0 {
                return "↑ +\(Int(abs(trendPercentage)))%"
            } else if trendPercentage < 0 {
                return "↓ -\(Int(abs(trendPercentage)))%"
            } else {
                return "→ 0%"
            }
        }
    }

    // MARK: - Error Handling

    /// Fetch işlemlerinde oluşan hatalar
    var errors: [String: String] = [:]

    // MARK: - Main Analytics Method

    /// İletişim trendlerini analiz eder (son 7 gün)
    /// - Parameters:
    ///   - context: SwiftData ModelContext
    ///   - days: Analiz edilecek gün sayısı (varsayılan: 7)
    /// - Returns: ContactTrends verisi
    /// - Throws: Critical hatalar fırlatılır, minor hatalar errors dictionary'sine eklenir
    func analyzeContactTrends(context: ModelContext, days: Int = 7) async throws -> ContactTrends {
        errors.removeAll()

        let calendar = Calendar.current
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -days, to: Date()) else {
            let error = "Haftalık tarih hesaplanamadı"
            errors["contact_trends_date"] = error
            print("⚠️ [ContactAnalyticsService] \(error)")
            throw NSError(domain: "ContactAnalyticsService", code: 1, userInfo: [NSLocalizedDescriptionKey: error])
        }

        do {
            // Bu hafta iletişim kurulan arkadaşları fetch et
            let historyDescriptor = FetchDescriptor<ContactHistory>(
                predicate: #Predicate { history in
                    history.date >= sevenDaysAgo
                },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )

            let histories = try context.fetch(historyDescriptor)
            let thisWeekCount = Set(histories.compactMap { $0.friend?.id }).count

            // Son iletişimin mood'unu al
            let lastMood: String
            if let lastHistory = histories.first, let mood = lastHistory.mood {
                lastMood = mood.emoji
            } else {
                lastMood = ""
            }

            // Önceki haftayla karşılaştır
            guard let fourteenDaysAgo = calendar.date(byAdding: .day, value: -(days * 2), to: Date()) else {
                let error = "İki haftalık tarih hesaplanamadı"
                errors["contact_trends_comparison_date"] = error
                print("⚠️ [ContactAnalyticsService] \(error)")
                // Karşılaştırma olmadan devam et
                let trends = ContactTrends(
                    thisWeekCount: thisWeekCount,
                    lastWeekCount: 0,
                    trendPercentage: 0.0,
                    lastMood: lastMood
                )
                return trends
            }

            let previousWeekHistories = histories.filter { $0.date < sevenDaysAgo && $0.date >= fourteenDaysAgo }
            let lastWeekCount = Set(previousWeekHistories.compactMap { $0.friend?.id }).count

            // Trend yüzdesini hesapla
            let trendPercentage: Double
            if lastWeekCount > 0 {
                trendPercentage = ((Double(thisWeekCount) - Double(lastWeekCount)) / Double(lastWeekCount)) * 100
            } else {
                trendPercentage = 0.0
            }

            let trends = ContactTrends(
                thisWeekCount: thisWeekCount,
                lastWeekCount: lastWeekCount,
                trendPercentage: trendPercentage,
                lastMood: lastMood
            )

            print("✅ [ContactAnalyticsService] Trends analiz edildi:")
            print("   - Bu hafta: \(thisWeekCount) kişi")
            print("   - Geçen hafta: \(lastWeekCount) kişi")
            print("   - Trend: \(trends.trendDescription)")
            print("   - Son mood: \(lastMood)")

            return trends

        } catch {
            let errorMessage = error.localizedDescription
            errors["contact_trends"] = errorMessage
            print("❌ [ContactAnalyticsService] Contact trends fetch hatası: \(errorMessage)")
            throw error
        }
    }

    // MARK: - Score Calculations

    /// Sosyal skor hesaplar (0-100)
    /// - Parameters:
    ///   - totalContacts: Toplam arkadaş sayısı
    ///   - weeklyContacts: Bu hafta iletişim kurulan arkadaş sayısı
    /// - Returns: 0-100 arası sosyal skor
    func calculateSocialScore(totalContacts: Int, weeklyContacts: Int) -> Int {
        // Eğer hiç arkadaş yoksa, 0 puan
        guard totalContacts > 0 else {
            print("💬 [ContactAnalyticsService] Sosyal Skor: 0 (Arkadaş yok)")
            return 0
        }

        print("💬 [ContactAnalyticsService] İletişim Debug:")
        print("   Total arkadaş: \(totalContacts)")
        print("   Bu hafta iletişim: \(weeklyContacts)")

        // Bu haftaki iletişim sayısı - ANA AĞIRLIK %100
        // 0 iletişim = 0 puan, 5+ iletişim = 100 puan
        let contactScore = min(Double(weeklyContacts) / 5.0, 1.0) * 100

        let score = Int(contactScore)
        print("   Sosyal Skor: \(score)")
        print("   ---")

        return score
    }

    /// Günlük iletişim trend verisi (son 7 gün)
    /// - Parameter context: SwiftData ModelContext
    /// - Returns: 7 elemanlı array (her gün için iletişim sayısı)
    func getDailyContactTrend(context: ModelContext) async throws -> [Double] {
        let calendar = Calendar.current
        var trendData: [Double] = []

        do {
            for dayOffset in (0...6).reversed() {
                guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else {
                    print("⚠️ [ContactAnalyticsService] Contacts trend tarih hesaplanamadı: dayOffset \(dayOffset)")
                    errors["daily_trend_date_\(dayOffset)"] = "Tarih hesaplama hatası"
                    continue
                }

                let dayStart = calendar.startOfDay(for: targetDate)
                guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                    print("⚠️ [ContactAnalyticsService] Contacts trend gün sonu hesaplanamadı")
                    errors["daily_trend_end_\(dayOffset)"] = "Gün sonu hesaplama hatası"
                    continue
                }

                let historyDescriptor = FetchDescriptor<ContactHistory>(
                    predicate: #Predicate { history in
                        history.date >= dayStart && history.date < dayEnd
                    }
                )

                let contacts = try context.fetch(historyDescriptor)
                trendData.append(Double(contacts.count))
            }

            return trendData.isEmpty ? [0.0] : trendData

        } catch {
            let errorMessage = error.localizedDescription
            errors["contacts_trend_daily"] = errorMessage
            print("❌ [ContactAnalyticsService] Contacts trend data fetch hatası: \(errorMessage)")
            throw error
        }
    }

    // MARK: - Helper Methods

    /// Error durumunu kontrol eder
    func hasErrors() -> Bool {
        return !errors.isEmpty
    }

    /// Genel error mesajı döndürür
    func getErrorMessage() -> String? {
        guard hasErrors() else { return nil }
        return "İletişim verileri yüklenirken hata oluştu."
    }

    /// Analytics verilerini sıfırlar
    func reset() {
        errors.removeAll()
    }
}

//
//  MoodAnalyticsService.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Mood analytics ve korelasyon hesaplamaları
//

import Foundation
import SwiftData

@Observable
class MoodAnalyticsService {
    static let shared = MoodAnalyticsService()

    private init() {}

    // MARK: - Mood Stats

    /// Belirli bir tarih aralığındaki mood istatistikleri
    func calculateMoodStats(entries: [MoodEntry], period: TimePeriod = .month) -> MoodStats {
        guard !entries.isEmpty else { return .empty() }

        // Ortalama mood skoru
        let totalScore = entries.reduce(0.0) { $0 + $1.score }
        let averageMood = totalScore / Double(entries.count)

        // Mood dağılımı
        var distribution: [MoodType: Int] = [:]
        for entry in entries {
            distribution[entry.moodType, default: 0] += 1
        }

        // Pozitif/negatif sayım
        let positiveCount = entries.filter { $0.moodType.isPositive }.count
        let negativeCount = entries.filter { $0.moodType.isNegative }.count

        // En iyi ve en kötü gün
        let bestDay = entries.max(by: { $0.score < $1.score })?.date
        let worstDay = entries.min(by: { $0.score < $1.score })?.date

        // Trend hesaplama (son hafta vs önceki hafta)
        let trend = calculateTrend(entries: entries)

        return MoodStats(
            averageMood: averageMood,
            moodDistribution: distribution,
            moodTrend: trend,
            bestDay: bestDay,
            worstDay: worstDay,
            positiveCount: positiveCount,
            negativeCount: negativeCount,
            totalEntries: entries.count
        )
    }

    /// Trend hesaplama
    private func calculateTrend(entries: [MoodEntry]) -> TrendType {
        guard entries.count >= 7 else { return .neutral }

        let calendar = Calendar.current
        let now = Date()

        // Son 7 gün
        let lastWeekEntries = entries.filter {
            calendar.dateComponents([.day], from: $0.date, to: now).day ?? 0 <= 7
        }

        // Önceki 7 gün
        let previousWeekEntries = entries.filter {
            let days = calendar.dateComponents([.day], from: $0.date, to: now).day ?? 0
            return days > 7 && days <= 14
        }

        guard !lastWeekEntries.isEmpty, !previousWeekEntries.isEmpty else { return .neutral }

        let lastWeekAvg = lastWeekEntries.reduce(0.0) { $0 + $1.score } / Double(lastWeekEntries.count)
        let previousWeekAvg = previousWeekEntries.reduce(0.0) { $0 + $1.score } / Double(previousWeekEntries.count)

        let difference = lastWeekAvg - previousWeekAvg

        if difference > 0.3 {
            return .improving
        } else if difference < -0.3 {
            return .declining
        } else {
            return .neutral
        }
    }

    // MARK: - Mood-Goal Correlation

    /// Goal tamamlama sonrası mood değişimi (Tarih bazlı eşleştirme)
    /// Goal tamamlandıktan sonra (aynı gün veya sonraki gün) kaydedilen mood'ları analiz eder
    func calculateGoalCorrelations(moodEntries: [MoodEntry], context: ModelContext) -> [MoodGoalCorrelation] {
        do {
            // Tüm goal'ları çek
            let goalDescriptor = FetchDescriptor<Goal>()
            let goals = try context.fetch(goalDescriptor)

            var correlations: [MoodGoalCorrelation] = []
            let calendar = Calendar.current

            for goal in goals {
                // Sadece tamamlanmış goal'ları analiz et
                guard goal.isCompleted else { continue }

                // Goal tamamlama tarihi (targetDate veya completedAt)
                let completionDate = goal.targetDate
                let completionDay = calendar.startOfDay(for: completionDate)

                // Tamamlanma tarihinden sonraki 2 gün içinde kaydedilen mood'ları bul
                guard let nextDay = calendar.date(byAdding: .day, value: 2, to: completionDay) else {
                    continue
                }

                // Goal tamamlandıktan sonraki mood'lar
                let moodsAfterGoal = moodEntries.filter { mood in
                    mood.date >= completionDay && mood.date < nextDay
                }

                // En az 1 mood olmalı
                guard !moodsAfterGoal.isEmpty else { continue }

                // Baseline: goal tamamlanmadan önceki mood'lar
                let moodsBeforeGoal = moodEntries.filter { mood in
                    mood.date < completionDay
                }

                // Baseline en az 3 olmalı
                guard moodsBeforeGoal.count >= 3 else {
                    // Yeterli baseline yoksa genel ortalama ile karşılaştır
                    let correlation = calculateCorrelationWithBaseline(
                        moodScores: moodsAfterGoal.map { $0.score },
                        baseline: moodEntries.map { $0.score }
                    )

                    correlations.append(MoodGoalCorrelation(
                        goal: goal,
                        correlationScore: correlation,
                        sampleSize: moodsAfterGoal.count
                    ))
                    continue
                }

                // Korelasyon hesapla: tamamlama sonrası mood'lar vs önceki mood'lar
                let correlation = calculateCorrelationWithBaseline(
                    moodScores: moodsAfterGoal.map { $0.score },
                    baseline: moodsBeforeGoal.map { $0.score }
                )

                correlations.append(MoodGoalCorrelation(
                    goal: goal,
                    correlationScore: correlation,
                    sampleSize: moodsAfterGoal.count
                ))

                print("🎯 [MoodAnalytics] \(goal.title): Korelasyon=\(String(format: "%.2f", correlation)), n=\(moodsAfterGoal.count)")
            }

            // Korelasyon skoru en yüksek olandan sırala
            return correlations.sorted { abs($0.correlationScore) > abs($1.correlationScore) }

        } catch {
            print("❌ Goal correlation error: \(error)")
            return []
        }
    }

    // MARK: - Mood-Friend Correlation

    /// Friend iletişimi sonrası mood değişimi (Tarih bazlı eşleştirme)
    /// Arkadaş ile iletişim kurulduktan sonra (aynı gün veya sonraki gün) kaydedilen mood'ları analiz eder
    func calculateFriendCorrelations(moodEntries: [MoodEntry], context: ModelContext) -> [MoodFriendCorrelation] {
        do {
            // Tüm friend'leri çek
            let friendDescriptor = FetchDescriptor<Friend>()
            let friends = try context.fetch(friendDescriptor)

            var correlations: [MoodFriendCorrelation] = []
            let calendar = Calendar.current

            for friend in friends {
                // Bu arkadaşla olan tüm iletişim geçmişini al
                guard let contactHistories = friend.contactHistory, !contactHistories.isEmpty else {
                    continue
                }

                // İletişim tarihlerine göre mood'ları eşleştir
                var relatedMoodScores: [Double] = []

                for history in contactHistories {
                    // İletişim tarihinden sonraki 24 saat içinde kaydedilen mood'ları bul
                    let contactDate = calendar.startOfDay(for: history.date)
                    guard let nextDay = calendar.date(byAdding: .day, value: 2, to: contactDate) else {
                        continue
                    }

                    // İletişim günü veya sonraki gün kaydedilen mood'lar
                    let moodsAfterContact = moodEntries.filter { mood in
                        mood.date >= contactDate && mood.date < nextDay
                    }

                    // Bu mood'ların skorlarını ekle
                    relatedMoodScores.append(contentsOf: moodsAfterContact.map { $0.score })
                }

                // En az 3 veri noktası gerekli
                guard relatedMoodScores.count >= 3 else { continue }

                // Bu arkadaşla iletişim olmayan günlerdeki mood'ları baseline olarak kullan
                let contactDates = Set(contactHistories.map { calendar.startOfDay(for: $0.date) })

                // Baseline: iletişim olmayan günlerdeki tüm mood'lar
                let baselineMoods = moodEntries.filter { mood in
                    let moodDay = calendar.startOfDay(for: mood.date)
                    // İletişim günü değil ve sonraki gün de değil
                    return !contactDates.contains(moodDay) &&
                           !contactDates.contains(calendar.date(byAdding: .day, value: -1, to: moodDay) ?? moodDay)
                }

                // Baseline en az 3 olmalı
                guard baselineMoods.count >= 3 else {
                    // Yeterli baseline yoksa genel ortalama ile karşılaştır
                    let correlation = calculateCorrelationWithBaseline(
                        moodScores: relatedMoodScores,
                        baseline: moodEntries.map { $0.score }
                    )

                    correlations.append(MoodFriendCorrelation(
                        friend: friend,
                        correlationScore: correlation,
                        sampleSize: relatedMoodScores.count
                    ))
                    continue
                }

                // Korelasyon hesapla: iletişim sonrası mood'lar vs baseline mood'lar
                let correlation = calculateCorrelationWithBaseline(
                    moodScores: relatedMoodScores,
                    baseline: baselineMoods.map { $0.score }
                )

                correlations.append(MoodFriendCorrelation(
                    friend: friend,
                    correlationScore: correlation,
                    sampleSize: relatedMoodScores.count
                ))

                print("👥 [MoodAnalytics] \(friend.name): Korelasyon=\(String(format: "%.2f", correlation)), n=\(relatedMoodScores.count)")
            }

            // Korelasyon skoru en yüksek olandan sırala
            return correlations.sorted { abs($0.correlationScore) > abs($1.correlationScore) }

        } catch {
            print("❌ Friend correlation error: \(error)")
            return []
        }
    }

    /// Mood skorları ile baseline arasında karşılaştırma yap
    /// Pozitif değer: iletişim sonrası mood daha iyi
    /// Negatif değer: iletişim sonrası mood daha kötü
    private func calculateCorrelationWithBaseline(moodScores: [Double], baseline: [Double]) -> Double {
        guard !moodScores.isEmpty, !baseline.isEmpty else { return 0 }

        let moodAvg = moodScores.reduce(0, +) / Double(moodScores.count)
        let baselineAvg = baseline.reduce(0, +) / Double(baseline.count)

        // Ortalamalar arasındaki fark
        let difference = moodAvg - baselineAvg

        // -1.0 ile +1.0 arası normalize et
        // MoodEntry.score range: -2.0...+2.0, maksimum fark: 4.0
        let normalized = max(-1.0, min(1.0, difference / 2.0))

        return normalized
    }

    /// Basit korelasyon hesaplama (normalized)
    private func calculateCorrelation(moodScores: [Double], baseline: [Double]) -> Double {
        guard !moodScores.isEmpty, !baseline.isEmpty else { return 0 }

        let moodAvg = moodScores.reduce(0, +) / Double(moodScores.count)
        let baselineAvg = baseline.reduce(0, +) / Double(baseline.count)

        let difference = moodAvg - baselineAvg

        // -1.0 ile +1.0 arası normalize et
        // Maksimum fark 4.0 olabilir (-2 ile +2 arası)
        return max(-1.0, min(1.0, difference / 2.0))
    }

    // MARK: - Heatmap Data

    /// Son N günün heatmap verisi
    func generateHeatmapData(entries: [MoodEntry], days: Int = 30) -> [MoodDayData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var heatmapData: [MoodDayData] = []

        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                continue
            }

            // O güne ait mood'ları bul
            let dayEntries = entries.filter {
                calendar.isDate($0.date, inSameDayAs: date)
            }

            if dayEntries.isEmpty {
                // Veri yok
                heatmapData.append(MoodDayData(
                    date: date,
                    moodType: nil,
                    averageScore: nil
                ))
            } else if dayEntries.count == 1 {
                // Tek kayıt
                heatmapData.append(MoodDayData(
                    date: date,
                    moodType: dayEntries.first?.moodType,
                    averageScore: dayEntries.first?.score
                ))
            } else {
                // Birden fazla kayıt - ortalama al
                let avgScore = dayEntries.reduce(0.0) { $0 + $1.score } / Double(dayEntries.count)
                let dominantMood = dayEntries.max(by: { $0.score < $1.score })?.moodType

                heatmapData.append(MoodDayData(
                    date: date,
                    moodType: dominantMood,
                    averageScore: avgScore
                ))
            }
        }

        return heatmapData.reversed() // Eskiden yeniye doğru
    }

    // MARK: - Time Period Helper

    enum TimePeriod {
        case week
        case month
        case quarter
        case year

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            case .year: return 365
            }
        }
    }

    /// Belirli bir periyottaki mood'ları filtrele
    func filterEntriesByPeriod(entries: [MoodEntry], period: TimePeriod) -> [MoodEntry] {
        let calendar = Calendar.current
        let now = Date()

        return entries.filter {
            let daysDiff = calendar.dateComponents([.day], from: $0.date, to: now).day ?? 0
            return daysDiff <= period.days
        }
    }

    // MARK: - Mood-Location Correlation

    /// Location bazlı mood korelasyonu hesapla
    func calculateLocationCorrelations(moodEntries: [MoodEntry], context: ModelContext) -> [MoodLocationCorrelation] {
        // Location'ları çek
        let locationDescriptor = FetchDescriptor<LocationLog>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        guard let locations = try? context.fetch(locationDescriptor) else {
            print("❌ Location fetch error")
            return []
        }

        // Location'ları placemark'a göre grupla
        var locationGroups: [String: [LocationLog]] = [:]

        for location in locations {
            if let placemark = location.address {
                locationGroups[placemark, default: []].append(location)
            }
        }

        var correlations: [MoodLocationCorrelation] = []

        for (placemark, locationGroup) in locationGroups {
            // Bu location'la ilişkili mood'ları bul
            let relatedMoods = moodEntries.filter { mood in
                guard let moodLocation = mood.relatedLocation else { return false }
                return moodLocation.address == placemark
            }

            guard relatedMoods.count >= 3 else { continue } // En az 3 veri noktası gerekli

            // Mood skoru hesapla
            let avgScore = relatedMoods.reduce(0.0) { $0 + $1.score } / Double(relatedMoods.count)

            // Mood dağılımı
            var distribution: [MoodType: Int] = [:]
            for mood in relatedMoods {
                distribution[mood.moodType, default: 0] += 1
            }

            // Correlation oluştur
            if let firstLocation = locationGroup.first {
                correlations.append(MoodLocationCorrelation(
                    location: firstLocation,
                    averageMoodScore: avgScore,
                    visitCount: relatedMoods.count,
                    moodDistribution: distribution
                ))
            }
        }

        // Sırala (en pozitif/negatif olan başta)
        return correlations.sorted { abs($0.averageMoodScore) > abs($1.averageMoodScore) }
    }

    /// En pozitif location
    func getMostPositiveLocation(correlations: [MoodLocationCorrelation]) -> MoodLocationCorrelation? {
        correlations.filter { $0.isPositive }.max(by: { $0.averageMoodScore < $1.averageMoodScore })
    }

    /// En negatif location
    func getMostNegativeLocation(correlations: [MoodLocationCorrelation]) -> MoodLocationCorrelation? {
        correlations.filter { !$0.isPositive }.min(by: { $0.averageMoodScore < $1.averageMoodScore })
    }
}

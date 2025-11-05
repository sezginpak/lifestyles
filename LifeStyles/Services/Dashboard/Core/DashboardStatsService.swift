//
//  DashboardStatsService.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Phase 1: Basic Stats Extraction from DashboardViewModel
//

import Foundation
import SwiftData

/// Temel Dashboard istatistiklerini yöneten service
/// Sorumluluğu: Friend, Goal, Habit sayıları ve temel metrikler
@Observable
@MainActor
class DashboardStatsService {

    // MARK: - Published Stats

    /// Toplam arkadaş sayısı
    private(set) var totalContacts: Int = 0

    /// İletişim kurulması gereken arkadaş sayısı
    private(set) var contactsNeedingAttention: Int = 0

    /// Aktif hedef sayısı
    private(set) var activeGoals: Int = 0

    /// En uzun alışkanlık serisi
    private(set) var currentStreak: Int = 0

    // MARK: - Error Handling

    /// Fetch işlemlerinde oluşan hatalar (key: error_type, value: error_message)
    var errors: [String: String] = [:]

    /// Bazı veriler yüklendi ama hata var mı?
    private(set) var hasPartialErrors: Bool = false

    // MARK: - Main Loading Method

    /// Tüm temel istatistikleri yükler
    /// - Parameter context: SwiftData ModelContext
    /// - Throws: Critical hatalar fırlatılır, minor hatalar errors dictionary'sine eklenir
    func loadBasicStats(context: ModelContext) async throws {
        // Reset errors
        errors.removeAll()
        hasPartialErrors = false

        // Paralel olarak tüm istatistikleri yükle
        async let friendsCount = fetchFriendsCount(context: context)
        async let friendsNeedingAttention = fetchFriendsNeedingAttention(context: context)
        async let activeGoalsCount = fetchActiveGoalsCount(context: context)
        async let longestStreak = fetchLongestStreak(context: context)

        // Sonuçları bekle
        let results = await (friendsCount, friendsNeedingAttention, activeGoalsCount, longestStreak)

        // Sonuçları ata
        totalContacts = results.0
        contactsNeedingAttention = results.1
        activeGoals = results.2
        currentStreak = results.3

        print("✅ [DashboardStatsService] Stats yüklendi:")
        print("   - Total Contacts: \(totalContacts)")
        print("   - Needs Attention: \(contactsNeedingAttention)")
        print("   - Active Goals: \(activeGoals)")
        print("   - Current Streak: \(currentStreak)")

        if !errors.isEmpty {
            print("⚠️ [DashboardStatsService] \(errors.count) hata ile yüklendi:")
            errors.forEach { key, value in
                print("   - \(key): \(value)")
            }
        }
    }

    // MARK: - Private Fetch Methods

    /// Toplam arkadaş sayısını fetch eder
    private func fetchFriendsCount(context: ModelContext) async -> Int {
        do {
            let friendDescriptor = FetchDescriptor<Friend>()
            let count = try context.fetchCount(friendDescriptor)
            return count
        } catch {
            print("❌ [DashboardStatsService] Friend count fetch hatası: \(error.localizedDescription)")
            errors["friends_count"] = error.localizedDescription
            hasPartialErrors = true
            return 0
        }
    }

    /// İletişim gereken arkadaş sayısını fetch eder
    private func fetchFriendsNeedingAttention(context: ModelContext) async -> Int {
        do {
            let friendsDescriptor = FetchDescriptor<Friend>()
            let friends = try context.fetch(friendsDescriptor)
            let needsAttention = friends.filter { $0.needsContact }.count
            return needsAttention
        } catch {
            print("❌ [DashboardStatsService] Friends needing attention fetch hatası: \(error.localizedDescription)")
            errors["friends_attention"] = error.localizedDescription
            hasPartialErrors = true
            return 0
        }
    }

    /// Aktif hedef sayısını fetch eder
    private func fetchActiveGoalsCount(context: ModelContext) async -> Int {
        do {
            let goalDescriptor = FetchDescriptor<Goal>(
                predicate: #Predicate { !$0.isCompleted }
            )
            let count = try context.fetchCount(goalDescriptor)
            return count
        } catch {
            print("❌ [DashboardStatsService] Active goals fetch hatası: \(error.localizedDescription)")
            errors["active_goals"] = error.localizedDescription
            hasPartialErrors = true
            return 0
        }
    }

    /// En uzun alışkanlık serisini fetch eder
    private func fetchLongestStreak(context: ModelContext) async -> Int {
        do {
            let habitDescriptor = FetchDescriptor<Habit>(
                predicate: #Predicate { $0.isActive }
            )
            let habits = try context.fetch(habitDescriptor)
            let maxStreak = habits.map { $0.currentStreak }.max() ?? 0
            return maxStreak
        } catch {
            print("❌ [DashboardStatsService] Habits streak fetch hatası: \(error.localizedDescription)")
            errors["habit_streak"] = error.localizedDescription
            hasPartialErrors = true
            return 0
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

        if hasPartialErrors {
            return "Bazı veriler yüklenemedi. Lütfen daha sonra tekrar deneyin."
        }

        return "Veriler yüklenirken hata oluştu."
    }

    /// Stats'ları sıfırlar (test için yararlı)
    func reset() {
        totalContacts = 0
        contactsNeedingAttention = 0
        activeGoals = 0
        currentStreak = 0
        errors.removeAll()
        hasPartialErrors = false
    }
}

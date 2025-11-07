//
//  QuickQuestionService.swift
//  LifeStyles
//
//  Created by Claude on 2025-01-05.
//  Hızlı sorular cache yönetimi ve koordinasyonu
//

import Foundation
import SwiftData

/// Hızlı sorular servisini yöneten ana koordinatör
@Observable
class QuickQuestionService {
    static let shared = QuickQuestionService()

    private let generator = QuickQuestionGenerator.shared
    private let limiter = APIUsageLimiter.shared
    private let usageManager = AIUsageManager.shared
    private let premiumManager = PremiumManager.shared

    // Cache settings
    private let cacheExpirationSeconds: TimeInterval = 14400 // 4 saat
    private let maxQuestionsPerCategory = 6
    private let minQuestionsPerCategory = 4

    private init() {}

    // MARK: - Main Public API

    /// Hızlı sorular getir (cache'den veya yeni üret)
    func getQuestions(
        for category: QuickQuestionCategory,
        friend: Friend? = nil,
        chatHistory: [ChatMessage] = [],
        modelContext: ModelContext,
        forceRefresh: Bool = false
    ) async -> [QuickQuestion] {

        // 1. Cache kontrolü (force refresh değilse)
        if !forceRefresh {
            if let cached = try? getCachedQuestions(
                category: category,
                friend: friend,
                modelContext: modelContext
            ), !cached.isEmpty {
                print("✅ Cache'den \(cached.count) hızlı soru yüklendi")
                return cached
            }
        }

        // 2. Yeni sorular üret
        return await refreshQuestions(
            for: category,
            friend: friend,
            chatHistory: chatHistory,
            modelContext: modelContext
        )
    }

    /// Soruları zorla yenile
    func refreshQuestions(
        for category: QuickQuestionCategory,
        friend: Friend? = nil,
        chatHistory: [ChatMessage] = [],
        modelContext: ModelContext
    ) async -> [QuickQuestion] {

        // API limit kontrolü
        guard canGenerateQuestions() else {
            print("⚠️ API limiti aşıldı, varsayılan sorular kullanılıyor")
            return QuickQuestion.defaultQuestions(for: category)
        }

        // Eski soruları temizle
        clearExpiredQuestions(category: category, friend: friend, modelContext: modelContext)

        // Yeni sorular üret
        do {
            let questions = try await generator.generateQuestions(
                for: category,
                friend: friend,
                chatHistory: chatHistory,
                modelContext: modelContext
            )

            // SwiftData'ya kaydet
            saveQuestions(questions, modelContext: modelContext)

            print("✅ \(questions.count) yeni hızlı soru üretildi ve kaydedildi")
            return questions

        } catch {
            print("❌ Hızlı soru üretimi hatası: \(error.localizedDescription)")
            // Fallback
            return QuickQuestion.defaultQuestions(for: category)
        }
    }

    // MARK: - Cache Management

    /// Cache'den soruları getir (expired olmayanlar)
    private func getCachedQuestions(
        category: QuickQuestionCategory,
        friend: Friend?,
        modelContext: ModelContext
    ) throws -> [QuickQuestion] {

        let now = Date()
        let categoryRaw = category.rawValue

        var predicate: Predicate<QuickQuestion>

        if let friend = friend {
            // Friend-specific sorular
            let friendId = friend.id
            predicate = #Predicate<QuickQuestion> { question in
                question.categoryRaw == categoryRaw &&
                question.requiresFriend == true &&
                question.isActive == true &&
                question.expiresAt > now
            }
        } else {
            // Genel sorular
            predicate = #Predicate<QuickQuestion> { question in
                question.categoryRaw == categoryRaw &&
                question.requiresFriend == false &&
                question.isActive == true &&
                question.expiresAt > now
            }
        }

        let descriptor = FetchDescriptor<QuickQuestion>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.priority, order: .reverse)]
        )

        return try modelContext.fetch(descriptor)
    }

    /// Expired soruları temizle
    private func clearExpiredQuestions(
        category: QuickQuestionCategory,
        friend: Friend?,
        modelContext: ModelContext
    ) {

        do {
            let now = Date()
            let categoryRaw = category.rawValue

            var predicate: Predicate<QuickQuestion>

            if friend != nil {
                predicate = #Predicate<QuickQuestion> { question in
                    question.categoryRaw == categoryRaw &&
                    question.requiresFriend == true &&
                    (question.expiresAt <= now || question.isActive == false)
                }
            } else {
                predicate = #Predicate<QuickQuestion> { question in
                    question.categoryRaw == categoryRaw &&
                    question.requiresFriend == false &&
                    (question.expiresAt <= now || question.isActive == false)
                }
            }

            let descriptor = FetchDescriptor<QuickQuestion>(predicate: predicate)
            let expiredQuestions = try modelContext.fetch(descriptor)

            for question in expiredQuestions {
                modelContext.delete(question)
            }

            if !expiredQuestions.isEmpty {
                try modelContext.save()
                print("🗑️ \(expiredQuestions.count) expired soru silindi")
            }

        } catch {
            print("❌ Expired sorular temizlenemedi: \(error.localizedDescription)")
        }
    }

    /// Soruları SwiftData'ya kaydet
    private func saveQuestions(_ questions: [QuickQuestion], modelContext: ModelContext) {
        for question in questions {
            modelContext.insert(question)
        }

        do {
            try modelContext.save()
        } catch {
            print("❌ Sorular kaydedilemedi: \(error.localizedDescription)")
        }
    }

    // MARK: - Limit Checks

    /// API limiti kontrol et
    private func canGenerateQuestions() -> Bool {
        // Premium kullanıcılar sınırsız
        if premiumManager.isPremium {
            return true
        }

        // Free kullanıcılar için limit kontrolü
        let (allowed, reason) = limiter.canMakeRequest()

        if !allowed {
            print("⚠️ API limiti: \(reason ?? "Bilinmeyen")")
            return false
        }

        return true
    }

    // MARK: - Batch Operations

    /// Birden fazla kategori için soruları getir
    func getQuestionsForCategories(
        _ categories: [QuickQuestionCategory],
        friend: Friend? = nil,
        chatHistory: [ChatMessage] = [],
        modelContext: ModelContext
    ) async -> [QuickQuestion] {

        var allQuestions: [QuickQuestion] = []

        for category in categories {
            let questions = await getQuestions(
                for: category,
                friend: friend,
                chatHistory: chatHistory,
                modelContext: modelContext
            )
            allQuestions.append(contentsOf: questions)
        }

        // Priority'ye göre sırala ve limitle
        return allQuestions
            .sorted { $0.priority > $1.priority }
            .prefix(maxQuestionsPerCategory)
            .map { $0 }
    }

    // MARK: - Smart Category Selection

    /// Kullanıcının durumuna göre en uygun kategorileri seç
    func suggestCategories(
        friend: Friend?,
        modelContext: ModelContext
    ) async -> [QuickQuestionCategory] {

        var categories: [QuickQuestionCategory] = []

        if let friend = friend {
            // Friend-specific kategoriler
            categories.append(.friendChat)

            if friend.relationshipTypeRaw == "partner" {
                categories.append(.relationshipAdvice)
            }

            if friend.needsContact {
                categories.append(.emergency)
            } else {
                categories.append(.motivation)
            }

        } else {
            // Genel mod kategorileri
            categories.append(.generalChat)

            // Aktif hedef var mı?
            if await hasActiveGoals(modelContext: modelContext) {
                categories.append(.goalTracking)
            }

            // Son mood kaydı var mı?
            if await hasRecentMood(modelContext: modelContext) {
                categories.append(.moodCheck)
            }

            // Günlük insight ekle
            categories.append(.dailyInsight)
        }

        return categories
    }

    // MARK: - Helper Queries

    private func hasActiveGoals(modelContext: ModelContext) async -> Bool {
        let predicate = #Predicate<Goal> { goal in
            goal.isCompleted == false
        }
        let descriptor = FetchDescriptor<Goal>(predicate: predicate)

        do {
            let goals = try modelContext.fetch(descriptor)
            return !goals.isEmpty
        } catch {
            return false
        }
    }

    private func hasRecentMood(modelContext: ModelContext) async -> Bool {
        let oneDayAgo = Date().addingTimeInterval(-86400)

        let predicate = #Predicate<MoodEntry> { mood in
            mood.date > oneDayAgo
        }
        let descriptor = FetchDescriptor<MoodEntry>(predicate: predicate)

        do {
            let moods = try modelContext.fetch(descriptor)
            return !moods.isEmpty
        } catch {
            return false
        }
    }

    // MARK: - Analytics

    /// En çok tıklanan soruları getir
    func getMostClickedQuestions(limit: Int = 5, modelContext: ModelContext) -> [QuickQuestion] {
        let descriptor = FetchDescriptor<QuickQuestion>(
            sortBy: [SortDescriptor(\.timesClicked, order: .reverse)]
        )

        do {
            let questions = try modelContext.fetch(descriptor)
            return Array(questions.prefix(limit))
        } catch {
            return []
        }
    }

    /// Kullanıcı feedback'i kaydet
    func recordQuestionFeedback(
        questionId: UUID,
        rating: Double,
        modelContext: ModelContext
    ) {
        do {
            let predicate = #Predicate<QuickQuestion> { question in
                question.id == questionId
            }
            let descriptor = FetchDescriptor<QuickQuestion>(predicate: predicate)
            let questions = try modelContext.fetch(descriptor)

            if let question = questions.first {
                question.recordFeedback(rating: rating)
                try modelContext.save()
                print("✅ Feedback kaydedildi: \(rating)")
            }

        } catch {
            print("❌ Feedback kaydedilemedi: \(error.localizedDescription)")
        }
    }

    // MARK: - Maintenance

    /// Tüm expired soruları temizle (maintenance task)
    func cleanupAllExpiredQuestions(modelContext: ModelContext) {
        do {
            let now = Date()
            let predicate = #Predicate<QuickQuestion> { question in
                question.expiresAt <= now
            }

            let descriptor = FetchDescriptor<QuickQuestion>(predicate: predicate)
            let expiredQuestions = try modelContext.fetch(descriptor)

            for question in expiredQuestions {
                modelContext.delete(question)
            }

            if !expiredQuestions.isEmpty {
                try modelContext.save()
                print("🗑️ Toplam \(expiredQuestions.count) expired soru temizlendi")
            }

        } catch {
            print("❌ Cleanup hatası: \(error.localizedDescription)")
        }
    }

    /// Tüm soruları sıfırla (debug/test için)
    func resetAllQuestions(modelContext: ModelContext) {
        do {
            let descriptor = FetchDescriptor<QuickQuestion>()
            let allQuestions = try modelContext.fetch(descriptor)

            for question in allQuestions {
                modelContext.delete(question)
            }

            try modelContext.save()
            print("🗑️ Tüm sorular sıfırlandı (\(allQuestions.count) adet)")

        } catch {
            print("❌ Reset hatası: \(error.localizedDescription)")
        }
    }
}

// MARK: - Convenience Extensions

extension QuickQuestionService {
    /// Smart refresh - sadece gerekirse yenile
    func smartRefresh(
        for category: QuickQuestionCategory,
        friend: Friend? = nil,
        chatHistory: [ChatMessage] = [],
        modelContext: ModelContext
    ) async -> [QuickQuestion] {

        // Önce cache kontrol et
        if let cached = try? getCachedQuestions(
            category: category,
            friend: friend,
            modelContext: modelContext
        ) {

            // Yeterli soru var mı?
            if cached.count >= minQuestionsPerCategory {
                print("✅ Yeterli cache var (\(cached.count) soru)")
                return cached
            }
        }

        // Cache yetersiz, yenile
        return await refreshQuestions(
            for: category,
            friend: friend,
            chatHistory: chatHistory,
            modelContext: modelContext
        )
    }
}

//
//  SmartSuggestionService.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Phase 2: Smart suggestions extracted from DashboardViewModel
//

import Foundation
import SwiftData

@Observable
@MainActor
class SmartSuggestionService {

    private let goalService = GoalService.shared
    var suggestions: [GoalSuggestion] = []

    // MARK: - Public Methods

    /// Smart önerileri yükle
    func loadSuggestions(
        context: ModelContext,
        friends: [Friend],
        locations: [LocationLog],
        habits: [Habit]
    ) async throws {
        // GoalService ile smart önerileri oluştur
        let generatedSuggestions = goalService.generateSmartSuggestions(
            friends: friends,
            locationLogs: locations,
            habits: habits
        )

        suggestions = generatedSuggestions
    }

    /// AI ile personalize öneriler yükle
    func loadAISuggestions(context: ModelContext) async throws {
        // UserProgress al
        let progressDescriptor = FetchDescriptor<UserProgress>()
        let userProgress = try context.fetch(progressDescriptor).first

        // AI provider ile öneriler üret
        let aiProvider = AIGoalSuggestionProvider()

        do {
            let aiSuggestions = try await aiProvider.generatePersonalizedSuggestions(
                context: context,
                userProgress: userProgress,
                count: 2
            )

            // Mevcut önerilerle birleştir
            suggestions.append(contentsOf: aiSuggestions)
            // Relevance'a göre sırala
            suggestions.sort { $0.relevanceScore > $1.relevanceScore }

        } catch {
            print("❌ [SmartSuggestion] AI önerileri yüklenemedi: \(error)")
            if let nsError = error as NSError? {
                print("   Error domain: \(nsError.domain)")
                print("   Error code: \(nsError.code)")
            }
            throw SmartSuggestionError.aiGenerationFailed(error)
        }
    }

    /// Öneriyi kabul et ve Goal'a dönüştür
    func acceptSuggestion(_ suggestion: GoalSuggestion, context: ModelContext) throws {
        // Goal oluştur
        let goal = Goal(
            title: suggestion.title,
            goalDescription: suggestion.description,
            category: suggestion.category,
            targetDate: suggestion.suggestedTargetDate
        )

        context.insert(goal)

        // AcceptedSuggestion kaydı oluştur
        let accepted = AcceptedSuggestion(
            from: suggestion,
            convertedGoalId: goal.id
        )
        context.insert(accepted)

        // Listeden kaldır
        suggestions.removeAll { $0.id == suggestion.id }

        do {
            try context.save()
            print("✅ [SmartSuggestion] Öneri kabul edildi: \(suggestion.title)")
        } catch {
            print("❌ [SmartSuggestion] Öneri kabul edilirken hata: \(error)")
            throw SmartSuggestionError.acceptFailed(error)
        }
    }

    /// Öneriyi reddet/dismiss et
    func dismissSuggestion(_ suggestion: GoalSuggestion, context: ModelContext) throws {
        // AcceptedSuggestion olarak kaydet ama dismissed flag'i true
        let dismissed = AcceptedSuggestion(from: suggestion)
        dismissed.isDismissed = true
        context.insert(dismissed)

        // Listeden kaldır
        suggestions.removeAll { $0.id == suggestion.id }

        do {
            try context.save()
            print("🚫 [SmartSuggestion] Öneri reddedildi: \(suggestion.title)")
        } catch {
            print("❌ [SmartSuggestion] Öneri reddedilirken hata: \(error)")
            throw SmartSuggestionError.dismissFailed(error)
        }
    }

    /// Kabul edilen öneri için progress al
    func getAcceptedSuggestionProgress(for suggestionTitle: String, context: ModelContext) -> Double? {
        let descriptor = FetchDescriptor<AcceptedSuggestion>(
            predicate: #Predicate { $0.suggestionTitle == suggestionTitle && !$0.isDismissed }
        )

        guard let accepted = try? context.fetch(descriptor).first,
              let goalId = accepted.convertedGoalId else {
            return nil
        }

        // Goal'un progress'ini al
        let goalDescriptor = FetchDescriptor<Goal>(
            predicate: #Predicate { $0.id == goalId }
        )

        guard let goal = try? context.fetch(goalDescriptor).first else {
            return nil
        }

        return goal.progress
    }

    /// Tüm önerileri yenile (hem rule-based hem AI)
    func refreshAllSuggestions(context: ModelContext) async throws {
        // Önce rule-based suggestions
        let friendDescriptor = FetchDescriptor<Friend>()
        let friends = try context.fetch(friendDescriptor)

        let calendar = Calendar.current
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else {
            throw SmartSuggestionError.dateCalculationFailed
        }

        let locationDescriptor = FetchDescriptor<LocationLog>(
            predicate: #Predicate { $0.timestamp >= sevenDaysAgo }
        )
        let locationLogs = try context.fetch(locationDescriptor)

        let habitDescriptor = FetchDescriptor<Habit>(predicate: #Predicate { $0.isActive })
        let habits = try context.fetch(habitDescriptor)

        // Smart önerileri oluştur
        try await loadSuggestions(
            context: context,
            friends: friends,
            locations: locationLogs,
            habits: habits
        )

        // Sonra AI suggestions ekle
        try await loadAISuggestions(context: context)
    }

    /// Öneri sayısını getir
    var suggestionCount: Int {
        return suggestions.count
    }

    /// Önerileri temizle
    func clearSuggestions() {
        suggestions.removeAll()
    }
}

// MARK: - Errors

enum SmartSuggestionError: Error, LocalizedError {
    case aiGenerationFailed(Error)
    case acceptFailed(Error)
    case dismissFailed(Error)
    case dateCalculationFailed

    var errorDescription: String? {
        switch self {
        case .aiGenerationFailed(let error):
            return "AI öneri oluşturma hatası: \(error.localizedDescription)"
        case .acceptFailed(let error):
            return "Öneri kabul hatası: \(error.localizedDescription)"
        case .dismissFailed(let error):
            return "Öneri reddetme hatası: \(error.localizedDescription)"
        case .dateCalculationFailed:
            return "Tarih hesaplama hatası"
        }
    }
}

//
//  DraftManager.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//

import Foundation

/// Hedef draft modeli
struct GoalDraft: Codable, Equatable {
    var title: String
    var description: String
    var emoji: String
    var category: GoalCategory
    var targetDate: Date
    var reminderEnabled: Bool
    var currentStep: Int

    static var empty: GoalDraft {
        GoalDraft(
            title: "",
            description: "",
            emoji: "🎯",
            category: .personal,
            targetDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
            reminderEnabled: true,
            currentStep: 1
        )
    }
}

/// Alışkanlık draft modeli
struct HabitDraft: Codable, Equatable {
    var name: String
    var description: String
    var emoji: String
    var frequency: HabitFrequency
    var targetCount: Int
    var reminderTime: Date?
    var currentStep: Int

    static var empty: HabitDraft {
        HabitDraft(
            name: "",
            description: "",
            emoji: "⭐",
            frequency: .daily,
            targetCount: 1,
            reminderTime: nil,
            currentStep: 1
        )
    }
}

/// Draft yönetim servisi - Otomatik kaydetme ve geri yükleme
@Observable
class DraftManager {
    static let shared = DraftManager()

    private let goalDraftKey = "com.lifestyles.draft.goal"
    private let habitDraftKey = "com.lifestyles.draft.habit"
    private let userDefaults = UserDefaults.standard

    private init() {}

    // MARK: - Goal Draft

    /// Hedef draft'ını kaydet
    func saveDraftGoal(_ draft: GoalDraft) {
        guard let encoded = try? JSONEncoder().encode(draft) else {
            print("❌ Goal draft encoding hatası")
            return
        }

        userDefaults.set(encoded, forKey: goalDraftKey)
        print("✅ Goal draft kaydedildi (Step \(draft.currentStep))")
    }

    /// Hedef draft'ını yükle
    func loadDraftGoal() -> GoalDraft? {
        guard let data = userDefaults.data(forKey: goalDraftKey),
              let decoded = try? JSONDecoder().decode(GoalDraft.self, from: data) else {
            return nil
        }

        print("✅ Goal draft yüklendi (Step \(decoded.currentStep))")
        return decoded
    }

    /// Hedef draft'ını sil
    func clearDraftGoal() {
        userDefaults.removeObject(forKey: goalDraftKey)
        print("🗑️ Goal draft temizlendi")
    }

    /// Draft var mı kontrol et
    func hasDraftGoal() -> Bool {
        return userDefaults.data(forKey: goalDraftKey) != nil
    }

    // MARK: - Habit Draft

    /// Alışkanlık draft'ını kaydet
    func saveDraftHabit(_ draft: HabitDraft) {
        guard let encoded = try? JSONEncoder().encode(draft) else {
            print("❌ Habit draft encoding hatası")
            return
        }

        userDefaults.set(encoded, forKey: habitDraftKey)
        print("✅ Habit draft kaydedildi (Step \(draft.currentStep))")
    }

    /// Alışkanlık draft'ını yükle
    func loadDraftHabit() -> HabitDraft? {
        guard let data = userDefaults.data(forKey: habitDraftKey),
              let decoded = try? JSONDecoder().decode(HabitDraft.self, from: data) else {
            return nil
        }

        print("✅ Habit draft yüklendi (Step \(decoded.currentStep))")
        return decoded
    }

    /// Alışkanlık draft'ını sil
    func clearDraftHabit() {
        userDefaults.removeObject(forKey: habitDraftKey)
        print("🗑️ Habit draft temizlendi")
    }

    /// Draft var mı kontrol et
    func hasDraftHabit() -> Bool {
        return userDefaults.data(forKey: habitDraftKey) != nil
    }

    // MARK: - Temizleme

    /// Tüm draft'ları temizle
    func clearAllDrafts() {
        clearDraftGoal()
        clearDraftHabit()
        print("🗑️ Tüm draft'lar temizlendi")
    }
}

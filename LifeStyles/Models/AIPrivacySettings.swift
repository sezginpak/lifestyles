//
//  AIPrivacySettings.swift
//  LifeStyles
//
//  AI Privacy & Data Sharing Settings
//  Created by Claude on 22.10.2025.
//

import Foundation

// MARK: - AI Privacy Settings

/// Kullanıcının AI ile veri paylaşım tercihlerini yöneten model
@Observable
class AIPrivacySettings {
    static let shared = AIPrivacySettings()

    // MARK: - Feature Toggles

    /// Morning Insight özelliği aktif mi?
    var morningInsightEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "ai_morning_insight_enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "ai_morning_insight_enabled") }
    }

    /// AI Chat genel olarak aktif mi?
    var aiChatEnabled: Bool {
        get {
            // Varsayılan olarak açık
            UserDefaults.standard.object(forKey: "ai_chat_enabled") as? Bool ?? true
        }
        set { UserDefaults.standard.set(newValue, forKey: "ai_chat_enabled") }
    }

    // MARK: - Data Sharing Preferences

    /// Arkadaş bilgilerini AI ile paylaş
    var shareFriendsData: Bool {
        get {
            UserDefaults.standard.object(forKey: "ai_share_friends") as? Bool ?? true
        }
        set { UserDefaults.standard.set(newValue, forKey: "ai_share_friends") }
    }

    /// Hedef ve alışkanlık bilgilerini AI ile paylaş
    var shareGoalsAndHabits: Bool {
        get {
            UserDefaults.standard.object(forKey: "ai_share_goals_habits") as? Bool ?? true
        }
        set { UserDefaults.standard.set(newValue, forKey: "ai_share_goals_habits") }
    }

    /// Ruh hali verilerini AI ile paylaş
    var shareMoodData: Bool {
        get {
            UserDefaults.standard.object(forKey: "ai_share_mood") as? Bool ?? true
        }
        set { UserDefaults.standard.set(newValue, forKey: "ai_share_mood") }
    }

    /// Konum verilerini AI ile paylaş
    var shareLocationData: Bool {
        get {
            UserDefaults.standard.object(forKey: "ai_share_location") as? Bool ?? true
        }
        set { UserDefaults.standard.set(newValue, forKey: "ai_share_location") }
    }

    // MARK: - Chat Context Mode

    var chatContextMode: ChatContextMode {
        get {
            let rawValue = UserDefaults.standard.string(forKey: "ai_chat_context_mode") ?? "smart"
            return ChatContextMode(rawValue: rawValue) ?? .smart
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "ai_chat_context_mode")
        }
    }

    // MARK: - Consent

    /// Kullanıcı AI consent'ini verdi mi?
    var hasGivenAIConsent: Bool {
        get { UserDefaults.standard.bool(forKey: "ai_consent_given") }
        set { UserDefaults.standard.set(newValue, forKey: "ai_consent_given") }
    }

    /// Consent verilme tarihi
    var consentDate: Date? {
        get { UserDefaults.standard.object(forKey: "ai_consent_date") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "ai_consent_date") }
    }

    // MARK: - Transparency

    /// Son AI isteğinde kullanılan veri sayısı
    var lastRequestDataCount: DataUsageCount? {
        get {
            guard let data = UserDefaults.standard.data(forKey: "ai_last_data_count"),
                  let count = try? JSONDecoder().decode(DataUsageCount.self, from: data) else {
                return nil
            }
            return count
        }
        set {
            if let count = newValue,
               let data = try? JSONEncoder().encode(count) {
                UserDefaults.standard.set(data, forKey: "ai_last_data_count")
            } else {
                UserDefaults.standard.removeObject(forKey: "ai_last_data_count")
            }
        }
    }

    private init() {}

    // MARK: - Consent Methods

    /// Kullanıcıdan AI consent'i al
    func giveConsent() {
        hasGivenAIConsent = true
        consentDate = Date()
    }

    /// Consent'i geri çek
    func revokeConsent() {
        hasGivenAIConsent = false
        consentDate = nil

        // Tüm AI özelliklerini kapat
        morningInsightEnabled = false
        aiChatEnabled = false
    }

    /// Tüm veri paylaşımını kapat
    func disableAllDataSharing() {
        shareFriendsData = false
        shareGoalsAndHabits = false
        shareMoodData = false
        shareLocationData = false
    }

    /// Tüm veri paylaşımını aç
    func enableAllDataSharing() {
        shareFriendsData = true
        shareGoalsAndHabits = true
        shareMoodData = true
        shareLocationData = true
    }

    // MARK: - Helper

    /// Kaç tür veri paylaşılıyor?
    var enabledDataTypesCount: Int {
        var count = 0
        if shareFriendsData { count += 1 }
        if shareGoalsAndHabits { count += 1 }
        if shareMoodData { count += 1 }
        if shareLocationData { count += 1 }
        return count
    }
}

// MARK: - Chat Context Mode

enum ChatContextMode: String, Codable, CaseIterable {
    case smart = "smart"      // Intent-based (varsayılan)
    case full = "full"        // Her zaman tüm context
    case minimal = "minimal"  // Sadece soru, context yok

    var displayName: String {
        switch self {
        case .smart: return "Akıllı (Önerilen)"
        case .full: return "Tam Context"
        case .minimal: return "Minimal"
        }
    }

    var description: String {
        switch self {
        case .smart: return "Soruya göre gerekli veriyi paylaşır"
        case .full: return "Her zaman tüm verilerinizi paylaşır"
        case .minimal: return "Sadece soruyu gönderir, veri paylaşmaz"
        }
    }
}

// MARK: - Data Usage Count

/// AI isteğinde kullanılan veri sayısı (transparency için)
struct DataUsageCount: Codable {
    let friendsCount: Int
    let goalsCount: Int
    let habitsCount: Int
    let hasMoodData: Bool
    let hasLocationData: Bool
    let timestamp: Date

    var totalItems: Int {
        friendsCount + goalsCount + habitsCount
    }

    var summary: String {
        var parts: [String] = []

        if friendsCount > 0 {
            parts.append("\(friendsCount) arkadaş")
        }
        if goalsCount > 0 {
            parts.append("\(goalsCount) hedef")
        }
        if habitsCount > 0 {
            parts.append("\(habitsCount) alışkanlık")
        }
        if hasMoodData {
            parts.append("ruh hali")
        }
        if hasLocationData {
            parts.append("konum")
        }

        if parts.isEmpty {
            return "Veri paylaşılmadı"
        }

        return parts.joined(separator: ", ")
    }
}

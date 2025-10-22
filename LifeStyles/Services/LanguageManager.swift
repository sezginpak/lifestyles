//
//  LanguageManager.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Çok dilli destek yönetimi
//

import Foundation
import SwiftUI

/// Desteklenen diller
enum AppLanguage: String, CaseIterable, Identifiable {
    case turkish = "tr"
    case english = "en"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .turkish: return "Türkçe"
        case .english: return "English"
        }
    }

    var flag: String {
        switch self {
        case .turkish: return "🇹🇷"
        case .english: return "🇬🇧"
        }
    }

    var locale: Locale {
        Locale(identifier: rawValue)
    }
}

@Observable
class LanguageManager {
    static let shared = LanguageManager()

    private let userDefaultsKey = "app_language"

    var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: userDefaultsKey)
            // Locale'i güncelle
            updateLocale()
        }
    }

    private init() {
        // Kaydedilmiş dil varsa onu kullan, yoksa sistem dilini kontrol et
        if let savedLanguage = UserDefaults.standard.string(forKey: userDefaultsKey),
           let language = AppLanguage(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            // Sistem dilini kontrol et
            let systemLanguage = Locale.current.language.languageCode?.identifier ?? "tr"
            self.currentLanguage = AppLanguage(rawValue: systemLanguage) ?? .turkish
        }

        updateLocale()
    }

    private func updateLocale() {
        // Bundle'ın locale'ini güncelle (SwiftUI için)
        UserDefaults.standard.set([currentLanguage.rawValue], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }

    /// Mevcut dil için localized string al
    func localizedString(_ key: String, comment: String = "") -> String {
        // SwiftUI String Catalog kullanıyoruz, bu yüzden bu fonksiyon isteğe bağlı
        // Ama özel durumlar için kullanılabilir
        return NSLocalizedString(key, comment: comment)
    }

    /// AI promptları için dil kodu
    var languageCodeForAI: String {
        switch currentLanguage {
        case .turkish: return "tr"
        case .english: return "en"
        }
    }

    /// Dil değiştir ve uygulamayı yeniden başlat (gerekirse)
    func changeLanguage(to language: AppLanguage) {
        guard language != currentLanguage else { return }
        currentLanguage = language

        // Notification gönder (ViewModeller güncellenebilir)
        NotificationCenter.default.post(name: .languageDidChange, object: nil)
    }
}

// MARK: - Notification Name Extension

extension Notification.Name {
    static let languageDidChange = Notification.Name("languageDidChange")
}

// MARK: - String Extension for Localization Helper

extension String {
    /// Dil yöneticisi üzerinden localized string al
    var localized: String {
        String(localized: String.LocalizationValue(self))
    }

    /// Parametreli localization
    func localized(with arguments: CVarArg...) -> String {
        String(format: self.localized, arguments: arguments)
    }
}

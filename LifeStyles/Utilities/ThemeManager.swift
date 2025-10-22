//
//  ThemeManager.swift
//  LifeStyles
//
//  Dark/Light mode yönetimi ve tema ayarları
//

import SwiftUI
import Combine

// MARK: - Theme Manager

@Observable
class ThemeManager {
    // MARK: - Singleton

    static let shared = ThemeManager()

    // MARK: - Properties

    var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedTheme")
            updateAppearance()
        }
    }

    var isDarkMode: Bool {
        switch currentTheme {
        case .light:
            return false
        case .dark:
            return true
        case .system:
            return UITraitCollection.current.userInterfaceStyle == .dark
        }
    }

    // MARK: - Initialization

    private init() {
        // Kayıtlı temayı yükle veya varsayılan olarak sistem temasını kullan
        if let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme"),
           let theme = AppTheme(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .system
        }
    }

    // MARK: - Methods

    /// Tema değiştir
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
    }

    /// Sistem temasını geçiş yap (light <-> dark)
    func toggleTheme() {
        switch currentTheme {
        case .light:
            currentTheme = .dark
        case .dark:
            currentTheme = .light
        case .system:
            // Sistem teması ise, mevcut durum tersine çevir
            currentTheme = isDarkMode ? .light : .dark
        }
    }

    /// Uygulama görünümünü güncelle
    private func updateAppearance() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentTheme {
            case .light:
                window.overrideUserInterfaceStyle = .light
            case .dark:
                window.overrideUserInterfaceStyle = .dark
            case .system:
                window.overrideUserInterfaceStyle = .unspecified
            }
        }
    }
}

// MARK: - App Theme Enum

enum AppTheme: String, CaseIterable, Identifiable {
    case light = "light"
    case dark = "dark"
    case system = "system"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light:
            return "Açık"
        case .dark:
            return "Koyu"
        case .system:
            return "Sistem"
        }
    }

    var icon: String {
        switch self {
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        case .system:
            return "circle.lefthalf.filled"
        }
    }
}

// MARK: - Environment Key

struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue = ThemeManager.shared
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}

// MARK: - Theme Colors Helper

extension Color {
    /// Mevcut tema için dinamik background rengi
    static var adaptiveBackground: Color {
        Color(UIColor.systemBackground)
    }

    /// Mevcut tema için dinamik secondary background rengi
    static var adaptiveSecondaryBackground: Color {
        Color(UIColor.secondarySystemBackground)
    }

    /// Mevcut tema için dinamik tertiary background rengi
    static var adaptiveTertiaryBackground: Color {
        Color(UIColor.tertiarySystemBackground)
    }

    /// Mevcut tema için dinamik text rengi
    static var adaptiveText: Color {
        Color(UIColor.label)
    }

    /// Mevcut tema için dinamik secondary text rengi
    static var adaptiveSecondaryText: Color {
        Color(UIColor.secondaryLabel)
    }
}



//
//  AppColors.swift
//  LifeStyles
//
//  Modern renk paleti - Dark/Light mode destekli
//  Motivasyonel ve enerji veren renkler
//  iOS 26 dynamic color sistemi ile güncellenmiş
//  Not: Asset catalog yerine direkt hex değerleri kullanılıyor
//

import SwiftUI

// MARK: - iOS 26 Dynamic Color Support

@available(iOS 26.0, *)
extension Color {
    /// iOS 26 Dynamic Color - Liquid Glass ile uyumlu
    static func dynamicColor(
        light: String,
        dark: String,
        liquidGlassOptimized: Bool = true
    ) -> Color {
        Color(
            UIColor { traitCollection in
                switch traitCollection.userInterfaceStyle {
                case .dark:
                    return UIColor(Color(hex: dark))
                default:
                    return UIColor(Color(hex: light))
                }
            }
        )
    }

    /// iOS 26 Liquid Glass için optimize edilmiş adaptive color
    static var liquidGlassBackground: Color {
        dynamicColor(
            light: "F9FAFB",
            dark: "1F2937",
            liquidGlassOptimized: true
        )
    }
}

extension Color {
    // MARK: - Ana Marka Renkleri

    /// Ana marka rengi - Canlı mor/mavi gradient tonu
    static let brandPrimary = Color(hex: "6366F1") // Indigo

    /// İkincil marka rengi - Mor/pembe tonları
    static let brandSecondary = Color(hex: "8B5CF6") // Purple

    /// Accent rengi - Pembe
    static let accentSecondary = Color(hex: "EC4899") // Pink

    /// Üçüncül renk - Canlı turuncu
    static let brandAccent = Color(hex: "F59E0B") // Amber

    /// Destructive/silme rengi - Kırmızı
    static let destructive = Color(hex: "EF4444") // Red

    // MARK: - Gradient Renkleri

    /// Dashboard ana gradient (Mavi-Mor-Pembe)
    static let gradientPrimary: [Color] = [
        Color(hex: "6366F1"), // Indigo
        Color(hex: "8B5CF6"), // Purple
        Color(hex: "EC4899")  // Pink
    ]

    /// Motivasyon gradient (Turuncu-Pembe)
    static let gradientMotivation: [Color] = [
        Color(hex: "F59E0B"), // Amber
        Color(hex: "EF4444")  // Red
    ]

    /// Başarı gradient (Yeşil tonları)
    static let gradientSuccess: [Color] = [
        Color(hex: "10B981"), // Emerald
        Color(hex: "059669")  // Green
    ]

    /// Enerji gradient (Turuncu-Sarı)
    static let gradientEnergy: [Color] = [
        Color(hex: "F59E0B"), // Amber
        Color(hex: "FBBF24")  // Yellow
    ]

    /// Cool gradient (Mavi tonları)
    static let gradientCool: [Color] = [
        Color(hex: "3B82F6"), // Blue
        Color(hex: "06B6D4")  // Cyan
    ]

    // MARK: - Semantik Renkler

    /// Başarı durumu (yeşil)
    static let success = Color(hex: "10B981")

    /// Uyarı durumu (sarı)
    static let warning = Color(hex: "F59E0B")

    /// Hata durumu (kırmızı)
    static let error = Color(hex: "EF4444")

    /// Bilgi durumu (mavi)
    static let info = Color(hex: "3B82F6")

    // MARK: - Card Renkleri

    /// Istatistik kartı rengi (iletişim)
    static let cardCommunication = Color(hex: "3B82F6") // Blue

    /// Istatistik kartı rengi (aktivite)
    static let cardActivity = Color(hex: "10B981") // Green

    /// Istatistik kartı rengi (hedefler)
    static let cardGoals = Color(hex: "F59E0B") // Amber

    /// Istatistik kartı rengi (alışkanlıklar)
    static let cardHabits = Color(hex: "EF4444") // Red

    /// Istatistik kartı rengi (motivasyon)
    static let cardMotivation = Color(hex: "8B5CF6") // Purple

    // MARK: - Background Renkleri (Dynamic - Dark Mode Destekli)

    /// Ana arkaplan rengi - Otomatik dark/light mode
    static var backgroundPrimary: Color {
        Color(UIColor.systemBackground)
    }

    /// İkincil arkaplan rengi - Otomatik dark/light mode
    static var backgroundSecondary: Color {
        Color(UIColor.secondarySystemBackground)
    }

    /// Üçüncül arkaplan rengi - Otomatik dark/light mode
    static var backgroundTertiary: Color {
        Color(UIColor.tertiarySystemBackground)
    }

    /// Surface/yüzey rengi (kartlar için) - Otomatik dark/light mode
    static var surfaceSecondary: Color {
        Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor.systemGray5
            default:
                return UIColor.systemGray6
            }
        })
    }

    /// Adaptive background - Otomatik dark/light mode
    static var adaptiveBackground: Color {
        Color(UIColor.systemBackground)
    }

    /// Adaptive secondary background - Otomatik dark/light mode
    static var adaptiveSecondaryBackground: Color {
        Color(UIColor.secondarySystemBackground)
    }

    // MARK: - Text Renkleri (Dynamic - Dark Mode Destekli)

    /// Ana text rengi - Otomatik dark/light mode
    static var textPrimary: Color {
        Color(UIColor.label)
    }

    /// İkincil text rengi - Otomatik dark/light mode
    static var textSecondary: Color {
        Color(UIColor.secondaryLabel)
    }

    /// Üçüncül text rengi (açık) - Otomatik dark/light mode
    static var textTertiary: Color {
        Color(UIColor.tertiaryLabel)
    }

    // MARK: - Yardımcı Fonksiyonlar

    /// Hex string'den Color oluştur
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Gradient Extension

extension LinearGradient {
    /// Dashboard ana gradient
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: Color.gradientPrimary,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Motivasyon gradient
    static var motivationGradient: LinearGradient {
        LinearGradient(
            colors: Color.gradientMotivation,
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// Başarı gradient
    static var successGradient: LinearGradient {
        LinearGradient(
            colors: Color.gradientSuccess,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Enerji gradient
    static var energyGradient: LinearGradient {
        LinearGradient(
            colors: Color.gradientEnergy,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Cool gradient
    static var coolGradient: LinearGradient {
        LinearGradient(
            colors: Color.gradientCool,
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Shadow Styles

extension View {
    /// Soft shadow (hafif gölge)
    func softShadow(radius: CGFloat = 8, opacity: Double = 0.08) -> some View {
        self.shadow(color: .black.opacity(opacity), radius: radius, x: 0, y: 4)
    }

    /// Medium shadow (orta gölge)
    func mediumShadow(radius: CGFloat = 12, opacity: Double = 0.12) -> some View {
        self.shadow(color: .black.opacity(opacity), radius: radius, x: 0, y: 6)
    }

    /// Strong shadow (belirgin gölge)
    func strongShadow(radius: CGFloat = 20, opacity: Double = 0.18) -> some View {
        self.shadow(color: .black.opacity(opacity), radius: radius, x: 0, y: 10)
    }

    /// Glow effect (parlama efekti)
    func glowEffect(color: Color = .brandPrimary, radius: CGFloat = 10) -> some View {
        self.shadow(color: color.opacity(0.5), radius: radius, x: 0, y: 0)
    }

    /// iOS 26 Enhanced Glow - Liquid Glass için optimize edilmiş
    @ViewBuilder
    func enhancedGlow(color: Color = .brandPrimary, radius: CGFloat = 10) -> some View {
        if #available(iOS 26.0, *) {
            // iOS 26: Daha güçlü ve yumuşak glow efekti
            self
                .shadow(color: color.opacity(0.4), radius: radius * 0.5, x: 0, y: 0)
                .shadow(color: color.opacity(0.3), radius: radius, x: 0, y: 0)
                .shadow(color: color.opacity(0.2), radius: radius * 1.5, x: 0, y: 0)
        } else {
            // iOS 15-25: Standart glow
            self.shadow(color: color.opacity(0.5), radius: radius, x: 0, y: 0)
        }
    }
}

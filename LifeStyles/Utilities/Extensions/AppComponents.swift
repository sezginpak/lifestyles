//
//  AppComponents.swift
//  LifeStyles
//
//  Reusable UI bileşenleri
//  Modern, animasyonlu ve profesyonel tasarımlar
//

import SwiftUI
import UIKit

// MARK: - Haptic Feedback

/// Haptic feedback yardımcı sınıfı
struct HapticFeedback {
    
    /// Cihazın haptic feedback desteklediğini kontrol eder
    private static var isHapticsAvailable: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return true
        #endif
    }
    
    /// Hafif haptic feedback
    static func light() {
        guard isHapticsAvailable else { return }
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
    }
    
    /// Orta şiddette haptic feedback
    static func medium() {
        guard isHapticsAvailable else { return }
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
    }
    
    /// Güçlü haptic feedback
    static func heavy() {
        guard isHapticsAvailable else { return }
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
    }
    
    /// Başarı haptic feedback
    static func success() {
        guard isHapticsAvailable else { return }
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.prepare()
        notificationFeedback.notificationOccurred(.success)
    }
    
    /// Uyarı haptic feedback
    static func warning() {
        guard isHapticsAvailable else { return }
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.prepare()
        notificationFeedback.notificationOccurred(.warning)
    }
    
    /// Hata haptic feedback
    static func error() {
        guard isHapticsAvailable else { return }
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.prepare()
        notificationFeedback.notificationOccurred(.error)
    }
    
    /// Seçim haptic feedback
    static func selection() {
        guard isHapticsAvailable else { return }
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.prepare()
        selectionFeedback.selectionChanged()
    }
}

// MARK: - Modern Stat Card

/// Modern istatistik kartı - gradient background, icon ve animasyon
struct ModernStatCard: View {
    let title: String
    let value: String
    let icon: String
    let gradient: LinearGradient
    var iconColor: Color = .white
    var showBadge: Bool = false
    var badgeText: String = ""

    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.small) {
            // Icon ve Badge
            HStack {
                // Icon container
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(iconColor)
                }

                Spacer()

                // Badge (opsiyonel)
                if showBadge && !badgeText.isEmpty {
                    Text(badgeText)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.25))
                        .clipShape(Capsule())
                }
            }

            Spacer()

            // Value ve Title - Daha kompakt
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
            }
        }
        .padding(AppConstants.Spacing.medium)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
        .gradientCard(gradient: gradient)
        .scaleEffect(isAnimating ? 1.0 : 0.9)
        .opacity(isAnimating ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Glass Stat Card

/// Glass morph istatistik kartı - yarı saydam, blur efekti
struct GlassStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var trend: TrendDirection = .neutral
    var trendValue: String = ""

    enum TrendDirection {
        case up, down, neutral
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.medium) {
            // Icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .glowEffect(color: color, radius: 8)

            Spacer()

            // Value ve trend
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                if !trendValue.isEmpty {
                    HStack(spacing: 2) {
                        Image(systemName: trend == .up ? "arrow.up" : trend == .down ? "arrow.down" : "minus")
                            .font(.caption)
                        Text(trendValue)
                            .font(.caption)
                    }
                    .foregroundStyle(trend == .up ? .green : trend == .down ? .red : .secondary)
                }
            }

            // Title
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppConstants.Spacing.large)
        .frame(height: 140)
        .glassCard(tintColor: color, opacity: 0.15)
    }
}

// MARK: - Alert/Info Card

/// Bildirim/Uyarı kartı
struct ModernAlertCard: View {
    let title: String
    let message: String
    let icon: String
    var type: AlertType = .info
    var action: (() -> Void)? = nil
    var actionLabel: String = "Git"

    enum AlertType {
        case info, success, warning, error

        var color: Color {
            switch self {
            case .info: return Color.info
            case .success: return Color.success
            case .warning: return Color.warning
            case .error: return Color.error
            }
        }

        var gradient: LinearGradient {
            switch self {
            case .info: return LinearGradient.coolGradient
            case .success: return LinearGradient.successGradient
            case .warning: return LinearGradient.energyGradient
            case .error: return LinearGradient.motivationGradient
            }
        }
    }

    var body: some View {
        HStack(spacing: AppConstants.Spacing.medium) {
            // Icon
            ZStack {
                Circle()
                    .fill(type.color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(type.color)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            // Action button (opsiyonel)
            if let action = action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(type.color)
                }
            }
        }
        .padding(AppConstants.Spacing.large)
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card, style: .continuous)
                .stroke(type.color.opacity(0.3), lineWidth: 1.5)
        )
    }
}

// MARK: - Progress Card

/// İlerleme kartı - hedefler ve alışkanlıklar için
struct ProgressCard: View {
    let title: String
    let subtitle: String?
    let progress: Double // 0.0 - 1.0
    let icon: String
    let color: Color
    var showPercentage: Bool = true
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.medium) {
            HStack {
                // Icon
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)

                Spacer()

                // Percentage (opsiyonel)
                if showPercentage {
                    Text(String(format: NSLocalizedString("common.percentage", comment: "Percentage format"), Int(progress * 100)))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(color)
                }

                // Action button (opsiyonel)
                if let action = action {
                    Button(action: action) {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Title
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            // Subtitle (opsiyonel)
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(color.opacity(0.15))
                        .frame(height: 8)

                    // Progress
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * max(0, min(1, progress)), height: 8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding(AppConstants.Spacing.large)
        .cardStyle()
    }
}


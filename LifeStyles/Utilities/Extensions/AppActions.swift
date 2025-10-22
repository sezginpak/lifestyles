//
//  AppActions.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Refactored from AppComponents.swift - Action buttons and UI elements
//

import SwiftUI

// MARK: - Action Button

/// Modern action button - icon ve label ile
struct ModernActionButton: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    let gradient: LinearGradient
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            action()
        }) {
            HStack(spacing: AppConstants.Spacing.medium) {
                // Icon
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(.white)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(AppConstants.Spacing.large)
            .gradientCard(gradient: gradient)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Quick Action Button

/// Hızlı aksiyon butonu - küçük, icon odaklı
struct AppQuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppConstants.Spacing.small) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 60, height: 60)

                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                }

                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Streak Badge

/// Seri (streak) göstergesi - alışkanlıklar için
struct StreakBadgeView: View {
    let days: Int
    var size: BadgeSize = .medium

    enum BadgeSize {
        case small, medium, large

        var iconSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 18
            case .large: return 24
            }
        }

        var textSize: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 16
            case .large: return 20
            }
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: size.iconSize))

            Text("\(days)")
                .font(.system(size: size.textSize, weight: .bold, design: .rounded))
        }
        .foregroundStyle(
            LinearGradient(
                colors: [.orange, .red],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.orange.opacity(0.15))
        )
    }
}

// MARK: - Empty State View

/// Boş durum görünümü
struct ModernEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: AppConstants.Spacing.large) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.brandPrimary.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundStyle(Color.brandPrimary)
            }

            // Content
            VStack(spacing: AppConstants.Spacing.small) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Action button (opsiyonel)
            if let actionLabel = actionLabel, let action = action {
                Button(action: action) {
                    HStack {
                        Image(systemName: "plus")
                        Text(actionLabel)
                    }
                    .fontWeight(.semibold)
                }
                .buttonStyle(SecondaryButtonStyle(color: Color.brandPrimary))
                .padding(.horizontal, 40)
            }
        }
        .padding(AppConstants.Spacing.huge)
    }
}

// MARK: - Section Header

/// Modern section başlığı
struct ModernSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var action: (() -> Void)? = nil
    var actionLabel: String = "Tümünü Gör"

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let action = action {
                Button(action: action) {
                    HStack(spacing: 4) {
                        Text(actionLabel)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundStyle(Color.brandPrimary)
                }
            }
        }
        .padding(.horizontal, AppConstants.Spacing.large)
    }
}

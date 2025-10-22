//
//  AIActionComponents.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//

import SwiftUI

/// AI önerilen aksiyon butonu
struct AIActionButton: View {
    let title: String
    let icon: String
    let accentColor: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))

                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(color: accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

/// Outline stil AI aksiyon butonu
struct AIActionButtonOutlined: View {
    let title: String
    let icon: String
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))

                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(accentColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(accentColor, lineWidth: 1.5)
                    .background(accentColor.opacity(0.05))
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// AI loading view - Shimmer efekt ile
struct AILoadingView: View {
    let message: String

    @State private var shimmerOffset: CGFloat = -1

    var body: some View {
        VStack(spacing: 16) {
            // AI icon with shimmer
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.2), .blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)

                Image(systemName: "sparkles")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.5), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .offset(x: shimmerOffset * 100)
                    .mask(Circle())
            )

            VStack(spacing: 8) {
                Text(message)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)

                AITypingIndicator()
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                shimmerOffset = 1
            }
        }
    }
}

/// Skeleton loading - İçerik yüklenirken
struct AISkeletonView: View {
    @State private var animateGradient = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title skeleton
            RoundedRectangle(cornerRadius: 8)
                .fill(skeletonGradient)
                .frame(height: 20)
                .frame(maxWidth: 200)

            // Content skeletons
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 6)
                    .fill(skeletonGradient)
                    .frame(height: 14)
            }

            RoundedRectangle(cornerRadius: 6)
                .fill(skeletonGradient)
                .frame(height: 14)
                .frame(maxWidth: 150)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
    }

    private var skeletonGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.secondary.opacity(animateGradient ? 0.15 : 0.25),
                Color.secondary.opacity(animateGradient ? 0.25 : 0.15)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

/// AI badge - "AI Powered" göstergesi
struct AIBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.system(size: 10, weight: .semibold))

            Text("AI")
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundStyle(
            LinearGradient(
                colors: [.purple, .blue],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [.purple.opacity(0.15), .blue.opacity(0.15)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
    }
}

/// Empty state - AI önerisi yok
struct AIEmptyState: View {
    let message: String
    let icon: String
    var action: (() -> Void)?
    var actionTitle: String = "Yenile"

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.secondary)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let action = action {
                AIActionButtonOutlined(
                    title: actionTitle,
                    icon: "arrow.clockwise",
                    accentColor: .blue,
                    action: action
                )
            }
        }
        .padding()
    }
}

/// AI error view
struct AIErrorView: View {
    let error: Error
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.orange)

            VStack(spacing: 8) {
                Text(String(localized: "ai.error", comment: "AI Error"))
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            AIActionButton(
                title: "Tekrar Dene",
                icon: "arrow.clockwise",
                accentColor: .blue,
                action: retry
            )
        }
        .padding()
    }
}

// MARK: - Preview

#Preview("AI Action Components") {
    ScrollView {
        VStack(spacing: 24) {
            AIActionButton(
                title: "Hedef Oluştur",
                icon: "target",
                accentColor: .blue,
                action: {}
            )

            AIActionButtonOutlined(
                title: "Daha Fazla",
                icon: "ellipsis",
                accentColor: .purple,
                action: {}
            )

            AILoadingView(message: "AI düşünüyor...")

            AISkeletonView()
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

            AIBadge()

            AIEmptyState(
                message: "Henüz AI önerisi yok",
                icon: "sparkles",
                action: {}
            )

            AIErrorView(
                error: NSError(domain: "AI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Bağlantı hatası"]),
                retry: {}
            )
        }
        .padding()
    }
}

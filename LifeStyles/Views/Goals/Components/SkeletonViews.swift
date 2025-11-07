//
//  SkeletonViews.swift
//  LifeStyles
//
//  Created by Claude on 5.11.2025.
//  Loading skeleton screens for Goals
//

import SwiftUI

// MARK: - Goal Skeleton Card

struct GoalSkeletonCard: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 16) {
            // Ring Skeleton
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 60)
                .shimmer()

            // Content Skeleton
            VStack(alignment: .leading, spacing: 8) {
                // Title
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 16)
                    .frame(maxWidth: .infinity)
                    .shimmer()

                // Badges
                HStack(spacing: 8) {
                    ForEach(0..<3) { _ in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 60, height: 24)
                            .shimmer()
                    }
                }
            }

            Spacer()

            // Button Skeleton
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 32, height: 32)
                .shimmer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Habit Skeleton Card

struct HabitSkeletonCard: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 16)
                    .shimmer()

                Spacer()

                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 32, height: 32)
                    .shimmer()
            }

            // Heatmap Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 10), spacing: 4) {
                ForEach(0..<30, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 20)
                        .shimmer()
                }
            }

            // Stats
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 12)
                    .shimmer()

                Spacer()

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 12)
                    .shimmer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Dashboard Skeleton

struct DashboardSkeletonCard: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 16) {
            // Title
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.3))
                .frame(width: 150, height: 20)
                .shimmer()

            // Stats Row
            HStack(spacing: 20) {
                ForEach(0..<3) { _ in
                    VStack(spacing: 8) {
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 50, height: 50)
                            .shimmer()

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 60, height: 12)
                            .shimmer()
                    }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.6),
                    Color.purple.opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Note: Using existing ShimmerModifier from AppStyles.swift

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(.secondary.opacity(0.5))

            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if let actionTitle = actionTitle, let action = action {
                Button {
                    action()
                } label: {
                    Text(actionTitle)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}

// MARK: - Error View

struct GoalErrorStateView: View {
    let title: String
    let message: String
    let retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.red.opacity(0.7))

            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if let retryAction = retryAction {
                Button {
                    retryAction()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text(String(localized: "error.retry", comment: ""))
                    }
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.1))
                    .foregroundStyle(.red)
                    .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    let message: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
        }
    }
}

// MARK: - Previews

#Preview("Skeleton Cards") {
    VStack(spacing: 16) {
        GoalSkeletonCard()
        HabitSkeletonCard()
        DashboardSkeletonCard()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Empty State") {
    EmptyStateView(
        icon: "target",
        title: "Henüz Hedef Yok",
        message: "İlk hedefini ekleyerek başla! Hedefler seni motivasyonlu tutmana yardımcı olacak.",
        actionTitle: "Hedef Ekle",
        action: { print("Add goal") }
    )
}

#Preview("Error State") {
    GoalErrorStateView(
        title: "Bir Hata Oluştu",
        message: "Hedefler yüklenirken bir sorun oluştu. Lütfen tekrar deneyin.",
        retryAction: { print("Retry") }
    )
}

#Preview("Loading Overlay") {
    ZStack {
        Color(.systemGroupedBackground)

        LoadingOverlay(message: "Hedefler yükleniyor...")
    }
}

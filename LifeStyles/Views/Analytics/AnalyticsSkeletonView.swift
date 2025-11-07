//
//  AnalyticsSkeletonView.swift
//  LifeStyles
//
//  Created by Claude on 06.11.2025.
//  Skeleton loading views for analytics
//

import SwiftUI

// MARK: - Main Skeleton View

struct AnalyticsSkeletonView: View {
    @State private var isAnimating = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Overview skeleton
                SkeletonCard(height: 200)
                    .padding(.horizontal)

                // Stats grid skeleton
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    SkeletonCard(height: 140)
                    SkeletonCard(height: 140)
                    SkeletonCard(height: 140)
                    SkeletonCard(height: 140)
                }
                .padding(.horizontal)

                // Large card skeleton
                SkeletonCard(height: 300)
                    .padding(.horizontal)

                // Another section
                SkeletonCard(height: 250)
                    .padding(.horizontal)

                Color.clear.frame(height: 20)
            }
            .padding(.vertical)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Skeleton Card

struct SkeletonCard: View {
    let height: CGFloat
    @State private var isAnimating = false

    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(.systemGray6),
                        Color(.systemGray5),
                        Color(.systemGray6)
                    ],
                    startPoint: isAnimating ? .leading : .trailing,
                    endPoint: isAnimating ? .trailing : .leading
                )
            )
            .frame(height: height)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Mini Card Skeleton

struct AnalyticsMiniCardSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 36, height: 36)

                Spacer()
            }

            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.systemGray5))
                .frame(height: 24)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray6))
                .frame(height: 16)
                .frame(maxWidth: 100)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        .redacted(reason: .placeholder)
        .shimmering()
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        AnalyticsSkeletonView()
            .navigationTitle(String(localized: "nav.analizler"))
            .navigationBarTitleDisplayMode(.large)
    }
}

//
//  JournalSkeletonView.swift
//  LifeStyles
//
//  Skeleton loading state for journals
//  Created by Claude on 05.11.2025.
//

import SwiftUI

struct JournalSkeletonView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header skeleton
            HStack {
                Circle()
                    .fill(skeletonGradient)
                    .frame(width: 36, height: 36)

                Capsule()
                    .fill(skeletonGradient)
                    .frame(width: 80, height: 20)

                Spacer()

                Circle()
                    .fill(skeletonGradient)
                    .frame(width: 20, height: 20)
            }

            // Title skeleton
            Capsule()
                .fill(skeletonGradient)
                .frame(height: 18)
                .frame(maxWidth: 200)

            // Content skeleton
            VStack(alignment: .leading, spacing: 6) {
                Capsule()
                    .fill(skeletonGradient)
                    .frame(height: 14)

                Capsule()
                    .fill(skeletonGradient)
                    .frame(height: 14)
                    .frame(maxWidth: 250)

                Capsule()
                    .fill(skeletonGradient)
                    .frame(height: 14)
                    .frame(maxWidth: 180)
            }

            // Tags skeleton
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { _ in
                    Capsule()
                        .fill(skeletonGradient)
                        .frame(width: 60, height: 24)
                }
            }

            Spacer()

            // Footer skeleton
            HStack {
                Capsule()
                    .fill(skeletonGradient)
                    .frame(width: 80, height: 12)

                Spacer()

                Capsule()
                    .fill(skeletonGradient)
                    .frame(width: 60, height: 12)
            }
        }
        .padding(16)
        .frame(height: 220)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }

    var skeletonGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.gray.opacity(isAnimating ? 0.1 : 0.2),
                Color.gray.opacity(isAnimating ? 0.2 : 0.1),
                Color.gray.opacity(isAnimating ? 0.1 : 0.2)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Masonry Skeleton Grid

struct MasonrySkeletonGrid: View {
    let columns: Int = 2

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: columns),
            spacing: 12
        ) {
            ForEach(0..<6, id: \.self) { index in
                JournalSkeletonView()
                    .frame(height: skeletonHeight(for: index))
            }
        }
        .padding()
    }

    func skeletonHeight(for index: Int) -> CGFloat {
        let heights: [CGFloat] = [200, 250, 220, 240, 210, 230]
        return heights[index % heights.count]
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            JournalSkeletonView()
            JournalSkeletonView()
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

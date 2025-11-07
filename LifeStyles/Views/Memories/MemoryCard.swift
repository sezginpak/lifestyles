//
//  MemoryCard.swift
//  LifeStyles
//
//  Created by Claude on 26.10.2025.
//  Memory Card Component
//

import SwiftUI

struct MemoryCard: View {
    let memory: Memory
    var isCompact: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                // Photo Background
                if let firstPhotoData = memory.photos.first,
                   let uiImage = UIImage(data: firstPhotoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.width)
                        .clipped()
                } else {
                    // Placeholder
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.teal.opacity(0.3), .blue.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: geometry.size.width, height: geometry.size.width)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                }

                // Gradient Overlay
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Content
                VStack(alignment: .leading, spacing: Spacing.micro) {
                    // Title
                    if let title = memory.title {
                        Text(title)
                            .font(isCompact ? .subheadline : .headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }

                    // Metadata
                    HStack(spacing: Spacing.small) {
                        // Date
                        Text(memory.relativeDate)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.9))

                        if memory.photoCount > 1 {
                            Text("•")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.5))

                            HStack(spacing: 2) {
                                Image(systemName: "photo.stack")
                                    .font(.caption2)
                                Text(String(localized: "memory.photo.count", defaultValue: "\(memory.photoCount)", comment: "Photo count"))
                                    .font(.caption2)
                            }
                            .foregroundStyle(.white.opacity(0.9))
                        }

                        if memory.hasLocation {
                            Text("•")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.5))

                            Image(systemName: "mappin.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.9))
                        }

                        Spacer()

                        if memory.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                        }
                    }
                }
                .padding(Spacing.medium)
            }
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
            .shadow(
                color: .black.opacity(0.15),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

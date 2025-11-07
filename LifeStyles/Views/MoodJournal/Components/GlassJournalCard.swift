//
//  GlassJournalCard.swift
//  LifeStyles
//
//  Created by Claude on 25.10.2025.
//  Glassmorphism journal card component
//

import SwiftUI

struct GlassJournalCard: View {
    let entry: JournalEntry
    let showImage: Bool
    let isHero: Bool // Hero card (daha büyük, featured)
    var onTap: () -> Void

    @State private var isPressed = false

    init(
        entry: JournalEntry,
        showImage: Bool = true,
        isHero: Bool = false,
        onTap: @escaping () -> Void
    ) {
        self.entry = entry
        self.showImage = showImage
        self.isHero = isHero
        self.onTap = onTap
    }

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap()
        }) {
            if isHero {
                heroCard
            } else {
                standardCard
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    // MARK: - Hero Card (Featured)

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // Image (if exists)
            if showImage, let imageData = entry.imageThumbnailData ?? entry.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(alignment: .topTrailing) {
                        // Badges
                        HStack(spacing: Spacing.small) {
                            if entry.hasTemplate {
                                Image(systemName: "doc.text.fill")
                                    .font(.caption)
                                    .foregroundStyle(.white)
                                    .padding(Spacing.small)
                                    .background(Circle().fill(.ultraThinMaterial))
                            }

                            if entry.isFavorite {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundStyle(.yellow)
                                    .padding(Spacing.small)
                                    .background(Circle().fill(.ultraThinMaterial))
                            }
                        }
                        .padding(Spacing.medium)
                    }
            }

            // Content
            VStack(alignment: .leading, spacing: Spacing.small) {
                // Header
                HStack(spacing: Spacing.small) {
                    Text(entry.journalType.emoji)
                        .font(.title2)

                    Text(entry.journalType.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(entry.journalType.color)
                        .padding(.horizontal, Spacing.small)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(entry.journalType.color.opacity(0.15))
                        )

                    Spacer()

                    Text(entry.formattedDate)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                // Title
                if let title = entry.title {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .lineLimit(2)
                }

                // Preview
                Text(entry.preview)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)

                // Tags
                if !entry.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.small) {
                            ForEach(entry.tags.prefix(5), id: \.self) { tag in
                                Text(String(localized: "journal.tag.format", defaultValue: "#\(tag)", comment: "Tag format"))
                                    .font(.caption)
                                    .foregroundStyle(entry.journalType.color)
                                    .padding(.horizontal, Spacing.small)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(entry.journalType.color.opacity(0.1))
                                    )
                            }
                        }
                    }
                }

                // Footer
                HStack(spacing: Spacing.small) {
                    Image(systemName: "text.word.spacing")
                        .font(.caption2)
                    Text(String(localized: "journal.word.count", defaultValue: "\(entry.wordCount)", comment: "Word count"))
                        .font(.caption2)

                    Text("•")
                        .font(.caption2)

                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(String(format: NSLocalizedString("journal.reading.time.format", comment: "%d min"), entry.estimatedReadingTime))
                        .font(.caption2)
                }
                .foregroundStyle(.tertiary)
            }
            .padding(Spacing.large)
        }
        .glassmorphismCard(
            cornerRadius: CornerRadius.rounded
        )
        .shadow(color: entry.journalType.color.opacity(0.15), radius: 20, y: 10)
    }

    // MARK: - Standard Card (Modern Compact)

    private var standardCard: some View {
        ZStack(alignment: .topLeading) {
            // Background Gradient (subtle)
            LinearGradient(
                colors: [
                    entry.journalType.color.opacity(0.05),
                    entry.journalType.color.opacity(0.02)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HStack(alignment: .top, spacing: Spacing.medium) {
                // Thumbnail (if exists)
                if showImage, let imageData = entry.imageThumbnailData ?? entry.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 90, height: 90)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            entry.journalType.color.opacity(0.3),
                                            entry.journalType.color.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                }

                // Content
                VStack(alignment: .leading, spacing: Spacing.small) {
                    // Header - Type Badge + Metadata
                    HStack(alignment: .center, spacing: Spacing.small) {
                        // Type Badge with gradient
                        HStack(spacing: 4) {
                            Text(entry.journalType.emoji)
                                .font(.caption)

                            Text(entry.journalType.displayName)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(entry.journalType.color)
                        }
                        .padding(.horizontal, Spacing.small)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            entry.journalType.color.opacity(0.15),
                                            entry.journalType.color.opacity(0.08)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )

                        Spacer()

                        // Favorite Star (if applicable)
                        if entry.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }

                        // Word Count Badge
                        HStack(spacing: 2) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 9))
                            Text(String(localized: "journal.word.count", defaultValue: "\(entry.wordCount)", comment: "Word count"))
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color(.tertiarySystemFill))
                        )
                    }

                    // Title (if exists) - Enhanced typography
                    if let title = entry.title {
                        Text(title)
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.primary, .primary.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .lineLimit(1)
                    }

                    // Preview Text - Better readability
                    Text(entry.preview)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(entry.title == nil ? 3 : 2)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 0)

                    // Bottom Section - Tags + Footer
                    VStack(alignment: .leading, spacing: Spacing.micro) {
                        // Tags (if exists)
                        if !entry.tags.isEmpty {
                            HStack(spacing: 4) {
                                ForEach(entry.tags.prefix(3), id: \.self) { tag in
                                    HStack(spacing: 2) {
                                        Image(systemName: "tag.fill")
                                            .font(.system(size: 8))
                                        Text(tag)
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundStyle(entry.journalType.color)
                                    .padding(.horizontal, Spacing.small)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        entry.journalType.color.opacity(0.12),
                                                        entry.journalType.color.opacity(0.06)
                                                    ],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    )
                                }

                                if entry.tags.count > 3 {
                                    Text(String(localized: "journal.tag.more", defaultValue: "+\(entry.tags.count - 3)", comment: "More tags"))
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundStyle(entry.journalType.color.opacity(0.6))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(
                                            Capsule()
                                                .fill(entry.journalType.color.opacity(0.08))
                                        )
                                }
                            }
                        }

                        // Footer Metadata
                        HStack(spacing: Spacing.small) {
                            Image(systemName: "calendar")
                                .font(.system(size: 9))

                            Text(entry.formattedDate)
                                .font(.caption2)

                            Text("•")
                                .font(.caption2)

                            Image(systemName: "clock")
                                .font(.system(size: 9))

                            Text(String(format: NSLocalizedString("journal.reading.time.format", comment: "X minutes reading time"), entry.estimatedReadingTime))
                                .font(.caption2)
                        }
                        .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(Spacing.large)
        }
        .frame(height: 170)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            entry.journalType.color.opacity(0.2),
                            entry.journalType.color.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .shadow(
            color: entry.journalType.color.opacity(isPressed ? 0.15 : 0.08),
            radius: isPressed ? 12 : 8,
            x: 0,
            y: isPressed ? 6 : 4
        )
    }
}

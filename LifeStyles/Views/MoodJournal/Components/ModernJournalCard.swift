//
//  ModernJournalCard.swift
//  LifeStyles
//
//  Modern Apple Notes style journal card
//  Created by Claude on 30.10.2025.
//

import SwiftUI

struct ModernJournalCard: View {
    let entry: JournalEntry
    let onTap: () -> Void
    let onToggleFavorite: () -> Void

    @State private var isPressed = false
    @State private var isFavoriteAnimating = false

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap()
        }) {
            cardContent
        }
        .buttonStyle(ScaleButtonStyle())
    }

    var cardContent: some View {
        ZStack {
            // Gradient arka plan
            gradientBackground
                .blur(radius: 20)

            // Glassmorphism layer
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(lineWidth: 1)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )

            // İçerik
            VStack(alignment: .leading, spacing: 12) {
                // Header: Type badge + Favorite
                header

                // Hero image (varsa)
                if entry.hasImage {
                    heroImage
                }

                // Title + Content preview
                textContent

                // Tags
                if !entry.tags.isEmpty {
                    tagSection
                }

                // Stickers overlay
                if entry.hasStickers {
                    stickerOverlay
                }

                Spacer()

                // Footer: Metadata
                footer
            }
            .padding(16)
        }
        .frame(height: entry.hasImage ? 320 : 200)
        .shadow(color: typeColor.opacity(0.2), radius: 12, x: 0, y: 8)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    // MARK: - Gradient Background

    var gradientBackground: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    var gradientColors: [Color] {
        switch entry.journalType {
        case .general:
            return [Color.blue, Color.purple]
        case .gratitude:
            return [Color.purple, Color.pink]
        case .achievement:
            return [Color.orange, Color.red]
        case .lesson:
            return [Color.green, Color.teal]
        }
    }

    var typeColor: Color {
        gradientColors.first ?? .blue
    }

    // MARK: - Header

    var header: some View {
        HStack {
            // Type badge
            HStack(spacing: 4) {
                Text(entry.journalType.emoji)
                    .font(.system(size: 14))

                Text(entry.journalType.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(typeColor.opacity(0.9))
            )
            .shadow(color: typeColor.opacity(0.3), radius: 4)

            Spacer()

            // Favorite button
            Button(action: {
                isFavoriteAnimating = true
                HapticFeedback.success()
                onToggleFavorite()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isFavoriteAnimating = false
                }
            }) {
                Image(systemName: entry.isFavorite ? "star.fill" : "star")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        LinearGradient(
                            colors: entry.isFavorite ? [Color.yellow, Color.orange] : [Color.gray.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(isFavoriteAnimating ? 1.3 : 1.0)
                    .rotationEffect(.degrees(isFavoriteAnimating ? 360 : 0))
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isFavoriteAnimating)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // MARK: - Hero Image

    @ViewBuilder
    var heroImage: some View {
        if let imageData = entry.imageData,
           let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        }
    }

    // MARK: - Text Content

    var textContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Title
            if let title = entry.title, !title.isEmpty {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }

            // Content preview
            Text(entry.preview)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .lineLimit(entry.hasImage ? 2 : 3)
                .multilineTextAlignment(.leading)
        }
    }

    // MARK: - Tags

    var tagSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(entry.tags.prefix(5), id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(typeColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(typeColor.opacity(0.15))
                        )
                }
            }
        }
    }

    // MARK: - Sticker Overlay

    var stickerOverlay: some View {
        ZStack {
            ForEach(entry.stickers) { sticker in
                Text(sticker.emoji)
                    .font(.system(size: 24 * sticker.scale))
                    .rotationEffect(.degrees(sticker.rotation))
                    .position(
                        x: sticker.position.x * 300, // Card width proxy
                        y: sticker.position.y * 50   // Sticker section height
                    )
                    .shadow(radius: 2)
            }
        }
        .frame(height: 50)
    }

    // MARK: - Footer

    var footer: some View {
        HStack(spacing: 12) {
            // Date
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.system(size: 11))
                Text(formattedDate)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.secondary)

            // Word count
            HStack(spacing: 4) {
                Image(systemName: "doc.text")
                    .font(.system(size: 11))
                Text("\(entry.wordCount) kelime")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.secondary)

            // Reading time
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 11))
                Text("\(entry.estimatedReadingTime) dk")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.secondary)

            Spacer()

            // Mood badge (if exists)
            if let mood = entry.moodEntry {
                Text(mood.moodType.emoji)
                    .font(.system(size: 16))
                    .padding(6)
                    .background(Circle().fill(.ultraThinMaterial))
            }
        }
    }

    // MARK: - Helpers

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.doesRelativeDateFormatting = true
        return formatter.string(from: entry.date)
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            // General journal
            ModernJournalCard(
                entry: JournalEntry(
                    title: "Güzel Bir Gün",
                    content: "Bugün harika bir gündü. Sabah erken kalktım ve koşuya çıktım. Hava çok güzeldi, kuşlar cıvıldıyordu...",
                    journalType: .general,
                    tags: ["sabah", "koşu", "doğa"],
                    isFavorite: true
                ),
                onTap: {},
                onToggleFavorite: {}
            )

            // Gratitude journal
            ModernJournalCard(
                entry: JournalEntry(
                    title: "Minnettar Olduğum Şeyler",
                    content: "Ailem, sağlığım ve bu güzel günler için minnettarım...",
                    journalType: .gratitude,
                    tags: ["minnettar", "aile"],
                    isFavorite: false
                ),
                onTap: {},
                onToggleFavorite: {}
            )

            // Achievement journal
            ModernJournalCard(
                entry: JournalEntry(
                    title: "İlk Maratonum",
                    content: "Hayatımın ilk maratonunu tamamladım! 42 km koştum ve bitirdim. İnanılmaz bir deneyimdi...",
                    journalType: .achievement,
                    tags: ["maraton", "spor", "başarı"],
                    isFavorite: true
                ),
                onTap: {},
                onToggleFavorite: {}
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

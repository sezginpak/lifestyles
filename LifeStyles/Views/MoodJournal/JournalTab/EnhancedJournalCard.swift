//
//  EnhancedJournalCard.swift
//  LifeStyles
//
//  Modern Pinterest-style journal card for masonry layout
//  Created by Claude on 05.11.2025.
//

import SwiftUI

struct EnhancedJournalCard: View {
    let entry: JournalEntry
    let onTap: () -> Void
    let onToggleFavorite: () -> Void

    @State private var isPressed = false
    @State private var isFavoriteAnimating = false
    @State private var imageHeight: CGFloat = 200

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap()
        }) {
            cardContent
        }
        .buttonStyle(PlainButtonStyle())
    }

    var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hero image (varsa)
            if entry.hasImage {
                heroImage
            }

            // Content area
            VStack(alignment: .leading, spacing: 12) {
                // Header: Type + Favorite
                header

                // Title + Content
                textContent

                // Tags
                if !entry.tags.isEmpty {
                    tagSection
                }

                // Footer: Metadata + Mood
                footer
            }
            .padding(16)
        }
        .background(cardBackground)
        .cornerRadius(20)
        .shadow(color: entry.journalType.color.opacity(0.15), radius: 8, x: 0, y: 4)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }

    // MARK: - Card Background

    var cardBackground: some View {
        ZStack {
            // Base glassmorphism
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)

            // Gradient border
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            entry.journalType.color.opacity(0.3),
                            entry.journalType.color.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )

            // Subtle inner glow
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            entry.journalType.color.opacity(0.03),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }

    // MARK: - Header

    var header: some View {
        HStack(alignment: .center, spacing: 8) {
            // Type emoji badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                entry.journalType.color.opacity(0.2),
                                entry.journalType.color.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)

                Text(entry.journalType.emoji)
                    .font(.system(size: 18))
            }

            // Type name
            Text(entry.journalType.displayName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(entry.journalType.color)

            Spacer()

            // Favorite button
            Button(action: {
                isFavoriteAnimating = true
                HapticFeedback.success()
                onToggleFavorite()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    isFavoriteAnimating = false
                }
            }) {
                Image(systemName: entry.isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(
                        entry.isFavorite ?
                            LinearGradient(
                                colors: [.red, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [.gray.opacity(0.4), .gray.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .scaleEffect(isFavoriteAnimating ? 1.4 : 1.0)
                    .rotationEffect(.degrees(isFavoriteAnimating ? 360 : 0))
                    .animation(.spring(response: 0.5, dampingFraction: 0.5), value: isFavoriteAnimating)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // MARK: - Hero Image

    @ViewBuilder
    var heroImage: some View {
        if let imageData = entry.imageData,
           let uiImage = UIImage(data: imageData) {
            GeometryReader { geo in
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: imageHeight)
                    .clipped()
            }
            .frame(height: imageHeight)
            .overlay(
                // Gradient overlay for better text readability
                LinearGradient(
                    colors: [
                        Color.clear,
                        entry.journalType.color.opacity(0.1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .onAppear {
                // Calculate dynamic image height based on aspect ratio
                if let image = UIImage(data: imageData) {
                    let aspectRatio = image.size.height / image.size.width
                    imageHeight = min(max(aspectRatio * 300, 150), 300)
                }
            }
        }
    }

    // MARK: - Text Content

    var textContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Title
            if let title = entry.title, !title.isEmpty {
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Content preview
            Text(entry.preview)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .lineLimit(entry.title != nil ? 3 : 4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Tags

    var tagSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(entry.tags.prefix(4), id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(entry.journalType.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(entry.journalType.color.opacity(0.12))
                        )
                }

                if entry.tags.count > 4 {
                    Text("+\(entry.tags.count - 4)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.gray.opacity(0.12))
                        )
                }
            }
        }
    }

    // MARK: - Footer

    var footer: some View {
        HStack(spacing: 0) {
            // Date
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.system(size: 10))
                Text(formattedDate)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.secondary)

            Spacer()

            // Word count badge
            HStack(spacing: 4) {
                Image(systemName: "doc.text")
                    .font(.system(size: 10))
                Text("\(entry.wordCount)")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.secondary)

            // Mood badge (if exists)
            if let mood = entry.moodEntry {
                Spacer()
                Text(mood.moodType.emoji)
                    .font(.system(size: 18))
                    .padding(6)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Circle()
                                    .strokeBorder(mood.moodType.color.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
        }
    }

    // MARK: - Helpers

    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "tr_TR")

        let now = Date()
        let calendar = Calendar.current

        // Eğer bugün ise
        if calendar.isDateInToday(entry.date) {
            let components = calendar.dateComponents([.hour, .minute], from: entry.date)
            if let hour = components.hour, let minute = components.minute {
                return String(format: "%02d:%02d", hour, minute)
            }
        }

        // Eğer bu hafta ise
        if calendar.isDate(entry.date, equalTo: now, toGranularity: .weekOfYear) {
            let weekdayFormatter = DateFormatter()
            weekdayFormatter.dateFormat = "EEEE"
            weekdayFormatter.locale = Locale(identifier: "tr_TR")
            return weekdayFormatter.string(from: entry.date)
        }

        // Diğer durumlar
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMM"
        dateFormatter.locale = Locale(identifier: "tr_TR")
        return dateFormatter.string(from: entry.date)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            EnhancedJournalCard(
                entry: JournalEntry(
                    title: "Muhteşem Bir Sabah",
                    content: "Bugün erken kalktım ve koşuya çıktım. Hava harikaydı, güneş yeni doğuyordu. Şehir henüz uyanmamıştı, sokaklarda sadece ben vardım. Bu an için minnettarım.",
                    journalType: .general,
                    tags: ["sabah", "koşu", "minnet"],
                    isFavorite: true
                ),
                onTap: {},
                onToggleFavorite: {}
            )
            .frame(width: 170)

            EnhancedJournalCard(
                entry: JournalEntry(
                    title: "İlk Maratonum",
                    content: "Hayatımın ilk 42 km'sini koştum! İnanılmaz bir deneyimdi. Zorlandığım anlar oldu ama bitirmek muhteşemdi.",
                    journalType: .achievement,
                    tags: ["maraton", "başarı"],
                    isFavorite: false
                ),
                onTap: {},
                onToggleFavorite: {}
            )
            .frame(width: 170)
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

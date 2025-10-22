//
//  DateIdeasSection.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//

import SwiftUI

struct DateIdeasSection: View {
    let friend: Friend

    @State private var selectedCategory: DateCategory = .romantic
    @State private var showingRandomIdea = false
    @State private var randomIdea: DateIdea?

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text(String(localized: "date.ideas.title", comment: "Date Ideas"))
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    generateRandomIdea()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text(String(localized: "date.ideas.random", comment: "Random"))
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.2))
                    .foregroundStyle(.purple)
                    .clipShape(Capsule())
                }
            }

            // Category Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(DateCategory.allCases) { category in
                        CategoryChip(
                            category: category,
                            isSelected: selectedCategory == category
                        ) {
                            withAnimation {
                                selectedCategory = category
                            }
                        }
                    }
                }
            }

            // Date Ideas
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(selectedCategory.ideas) { idea in
                        DateIdeaCard(idea: idea, category: selectedCategory)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showingRandomIdea) {
            if let idea = randomIdea {
                RandomIdeaView(idea: idea, category: selectedCategory)
            }
        }
    }

    private func generateRandomIdea() {
        let allIdeas = DateCategory.allCases.flatMap { $0.ideas }
        randomIdea = allIdeas.randomElement()
        showingRandomIdea = true
        HapticFeedback.success()
    }
}

// MARK: - Date Category

enum DateCategory: String, CaseIterable, Identifiable {
    case romantic = "romantic"
    case adventure = "adventure"
    case relaxed = "relaxed"
    case cultural = "cultural"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .romantic: return String(localized: "date.category.romantic", comment: "Romantic")
        case .adventure: return String(localized: "date.category.adventure", comment: "Adventure")
        case .relaxed: return String(localized: "date.category.relaxed", comment: "Relaxed")
        case .cultural: return String(localized: "date.category.cultural", comment: "Cultural")
        }
    }

    var emoji: String {
        switch self {
        case .romantic: return "🌹"
        case .adventure: return "⚡"
        case .relaxed: return "☕"
        case .cultural: return "🎨"
        }
    }

    var color: Color {
        switch self {
        case .romantic: return .pink
        case .adventure: return .orange
        case .relaxed: return .blue
        case .cultural: return .purple
        }
    }

    var ideas: [DateIdea] {
        switch self {
        case .romantic:
            return [
                DateIdea(title: "Gün Batımı İzle", description: "Güzel bir manzara bulun ve birlikte gün batımını izleyin", icon: "sunset.fill"),
                DateIdea(title: "Piknik Yap", description: "Park'ta romantik bir piknik organize edin", icon: "basket.fill"),
                DateIdea(title: "Yıldızlara Bak", description: "Şehir dışına çıkıp yıldızları izleyin", icon: "sparkles"),
                DateIdea(title: "Evde Yemek Pişir", description: "Birlikte yemek yapın ve romantik bir akşam geçirin", icon: "fork.knife"),
                DateIdea(title: "Plaj Yürüyüşü", description: "Sahilde el ele yürüyüş yapın", icon: "figure.walk"),
                DateIdea(title: "Mumlar Eşliğinde Akşam Yemeği", description: "Evde veya restoranda romantik bir akşam yemeği", icon: "flame.fill")
            ]

        case .adventure:
            return [
                DateIdea(title: "Hiking", description: "Doğa yürüyüşü yapın, yeni rotalar keşfedin", icon: "figure.hiking"),
                DateIdea(title: "Escape Room", description: "Birlikte bir escape room deneyimi yaşayın", icon: "key.fill"),
                DateIdea(title: "Bisiklet Turu", description: "Şehirde veya doğada bisiklet sürün", icon: "bicycle"),
                DateIdea(title: "Kaya Tırmanışı", description: "Tırmanış duvarında yeteneklerinizi test edin", icon: "figure.climbing"),
                DateIdea(title: "Su Sporları", description: "Kano, sörf veya jet ski deneyin", icon: "figure.surfing"),
                DateIdea(title: "Kamp", description: "Doğada bir gece kamp yapın", icon: "tent.fill")
            ]

        case .relaxed:
            return [
                DateIdea(title: "Kahve İçmeye Git", description: "Sevdiğiniz kafe'de sohbet edin", icon: "cup.and.saucer.fill"),
                DateIdea(title: "Film İzle", description: "Evde veya sinemada film izleyin", icon: "film.fill"),
                DateIdea(title: "Kitap Kafe", description: "Kitap kafe'de birlikte kitap okuyun", icon: "book.fill"),
                DateIdea(title: "Spa Günü", description: "Birlikte spa'ya gidin, rahatlayın", icon: "sparkles"),
                DateIdea(title: "Oyun Oyna", description: "Evde masa oyunları veya video oyunları oynayın", icon: "gamecontroller.fill"),
                DateIdea(title: "Brunch", description: "Hafta sonu keyifli bir brunch yapın", icon: "cup.and.saucer.fill")
            ]

        case .cultural:
            return [
                DateIdea(title: "Müze Ziyareti", description: "İlginizi çeken bir müzeyi gezin", icon: "building.columns.fill"),
                DateIdea(title: "Sergi", description: "Sanat sergisi veya fotoğraf sergisi ziyaret edin", icon: "photo.on.rectangle.angled"),
                DateIdea(title: "Konser", description: "Canlı müzik dinleyin, konser'e gidin", icon: "music.note"),
                DateIdea(title: "Tiyatro", description: "Tiyatro oyunu izleyin", icon: "theatermasks.fill"),
                DateIdea(title: "Tarihi Mekan", description: "Şehrinizin tarihi mekanlarını keşfedin", icon: "location.fill"),
                DateIdea(title: "Kitap Fuarı", description: "Kitap fuarını birlikte gezin", icon: "books.vertical.fill")
            ]
        }
    }
}

// MARK: - Date Idea

struct DateIdea: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
}

// MARK: - Category Chip

struct CategoryChip: View {
    let category: DateCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(category.emoji)
                    .font(.body)
                Text(category.displayName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected ?
                category.color.opacity(0.2) :
                Color(.tertiarySystemBackground)
            )
            .foregroundStyle(isSelected ? category.color : .secondary)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Date Idea Card

struct DateIdeaCard: View {
    let idea: DateIdea
    let category: DateCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Icon
            Image(systemName: idea.icon)
                .font(.title2)
                .foregroundStyle(category.color.gradient)
                .frame(width: 44, height: 44)
                .background(category.color.opacity(0.1))
                .clipShape(Circle())

            // Title
            Text(idea.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)

            // Description
            Text(idea.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 160, height: 150, alignment: .topLeading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Random Idea View

struct RandomIdeaView: View {
    @Environment(\.dismiss) private var dismiss

    let idea: DateIdea
    let category: DateCategory

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Icon
                Image(systemName: idea.icon)
                    .font(.system(size: 80))
                    .foregroundStyle(category.color.gradient)

                // Title
                Text(idea.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                // Description
                Text(idea.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Category Badge
                HStack(spacing: 6) {
                    Text(category.emoji)
                    Text(category.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(category.color.opacity(0.2))
                .foregroundStyle(category.color)
                .clipShape(Capsule())

                Spacer()

                // Close Button
                Button {
                    dismiss()
                } label: {
                    Text(String(localized: "common.close", comment: "Close"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(category.color)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ScrollView {
        DateIdeasSection(
            friend: Friend(name: "Partner", relationshipType: .partner)
        )
        .padding()
    }
}

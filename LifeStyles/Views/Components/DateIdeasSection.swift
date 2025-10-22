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
                DateIdea(title: String(localized: "date.idea.romantic.sunset.title", comment: "Watch Sunset"), description: String(localized: "date.idea.romantic.sunset.description", comment: "Find a beautiful view and watch the sunset together"), icon: "sunset.fill"),
                DateIdea(title: String(localized: "date.idea.romantic.picnic.title", comment: "Picnic"), description: String(localized: "date.idea.romantic.picnic.description", comment: "Organize a romantic picnic in the park"), icon: "basket.fill"),
                DateIdea(title: String(localized: "date.idea.romantic.stargazing.title", comment: "Stargazing"), description: String(localized: "date.idea.romantic.stargazing.description", comment: "Go outside the city and watch the stars"), icon: "sparkles"),
                DateIdea(title: String(localized: "date.idea.romantic.cooking.title", comment: "Cook at Home"), description: String(localized: "date.idea.romantic.cooking.description", comment: "Cook together and have a romantic evening"), icon: "fork.knife"),
                DateIdea(title: String(localized: "date.idea.romantic.beach.title", comment: "Beach Walk"), description: String(localized: "date.idea.romantic.beach.description", comment: "Walk hand in hand on the beach"), icon: "figure.walk"),
                DateIdea(title: String(localized: "date.idea.romantic.candlelight.title", comment: "Candlelight Dinner"), description: String(localized: "date.idea.romantic.candlelight.description", comment: "Have a romantic dinner at home or restaurant"), icon: "flame.fill")
            ]

        case .adventure:
            return [
                DateIdea(title: String(localized: "date.idea.adventure.hiking.title", comment: "Hiking"), description: String(localized: "date.idea.adventure.hiking.description", comment: "Go hiking and discover new routes"), icon: "figure.hiking"),
                DateIdea(title: String(localized: "date.idea.adventure.escaperoom.title", comment: "Escape Room"), description: String(localized: "date.idea.adventure.escaperoom.description", comment: "Experience an escape room together"), icon: "key.fill"),
                DateIdea(title: String(localized: "date.idea.adventure.biking.title", comment: "Bike Tour"), description: String(localized: "date.idea.adventure.biking.description", comment: "Ride bikes in the city or nature"), icon: "bicycle"),
                DateIdea(title: String(localized: "date.idea.adventure.climbing.title", comment: "Rock Climbing"), description: String(localized: "date.idea.adventure.climbing.description", comment: "Test your skills at the climbing wall"), icon: "figure.climbing"),
                DateIdea(title: String(localized: "date.idea.adventure.watersports.title", comment: "Water Sports"), description: String(localized: "date.idea.adventure.watersports.description", comment: "Try kayaking, surfing or jet ski"), icon: "figure.surfing"),
                DateIdea(title: String(localized: "date.idea.adventure.camping.title", comment: "Camping"), description: String(localized: "date.idea.adventure.camping.description", comment: "Camp for a night in nature"), icon: "tent.fill")
            ]

        case .relaxed:
            return [
                DateIdea(title: String(localized: "date.idea.relaxed.coffee.title", comment: "Coffee Date"), description: String(localized: "date.idea.relaxed.coffee.description", comment: "Chat at your favorite cafe"), icon: "cup.and.saucer.fill"),
                DateIdea(title: String(localized: "date.idea.relaxed.movie.title", comment: "Watch Movie"), description: String(localized: "date.idea.relaxed.movie.description", comment: "Watch a movie at home or cinema"), icon: "film.fill"),
                DateIdea(title: String(localized: "date.idea.relaxed.bookcafe.title", comment: "Book Cafe"), description: String(localized: "date.idea.relaxed.bookcafe.description", comment: "Read books together at a book cafe"), icon: "book.fill"),
                DateIdea(title: String(localized: "date.idea.relaxed.spa.title", comment: "Spa Day"), description: String(localized: "date.idea.relaxed.spa.description", comment: "Go to spa together and relax"), icon: "sparkles"),
                DateIdea(title: String(localized: "date.idea.relaxed.gaming.title", comment: "Play Games"), description: String(localized: "date.idea.relaxed.gaming.description", comment: "Play board games or video games at home"), icon: "gamecontroller.fill"),
                DateIdea(title: String(localized: "date.idea.relaxed.brunch.title", comment: "Brunch"), description: String(localized: "date.idea.relaxed.brunch.description", comment: "Enjoy a nice brunch on the weekend"), icon: "cup.and.saucer.fill")
            ]

        case .cultural:
            return [
                DateIdea(title: String(localized: "date.idea.cultural.museum.title", comment: "Museum Visit"), description: String(localized: "date.idea.cultural.museum.description", comment: "Visit a museum you're interested in"), icon: "building.columns.fill"),
                DateIdea(title: String(localized: "date.idea.cultural.exhibition.title", comment: "Exhibition"), description: String(localized: "date.idea.cultural.exhibition.description", comment: "Visit an art or photography exhibition"), icon: "photo.on.rectangle.angled"),
                DateIdea(title: String(localized: "date.idea.cultural.concert.title", comment: "Concert"), description: String(localized: "date.idea.cultural.concert.description", comment: "Listen to live music, go to a concert"), icon: "music.note"),
                DateIdea(title: String(localized: "date.idea.cultural.theater.title", comment: "Theater"), description: String(localized: "date.idea.cultural.theater.description", comment: "Watch a theater play"), icon: "theatermasks.fill"),
                DateIdea(title: String(localized: "date.idea.cultural.historical.title", comment: "Historical Place"), description: String(localized: "date.idea.cultural.historical.description", comment: "Discover historical places in your city"), icon: "location.fill"),
                DateIdea(title: String(localized: "date.idea.cultural.bookfair.title", comment: "Book Fair"), description: String(localized: "date.idea.cultural.bookfair.description", comment: "Visit the book fair together"), icon: "books.vertical.fill")
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

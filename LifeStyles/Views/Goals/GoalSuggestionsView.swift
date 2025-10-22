//
//  GoalSuggestionsView.swift
//  LifeStyles
//
//  Created by Claude on 16.10.2025.
//

import SwiftUI
import SwiftData

struct GoalSuggestionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: GoalsViewModel

    let friends: [Friend]
    let locationLogs: [LocationLog]

    @State private var isGenerating = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        Color.cardGoals.opacity(0.1),
                        Color.cardGoals.opacity(0.05),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if isGenerating {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(Color.cardGoals)

                        Text(String(localized: "goal.suggestions.generating", comment: "Generating smart goals..."))
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                } else if viewModel.goalSuggestions.isEmpty {
                    // Boş durum
                    VStack(spacing: 20) {
                        Image(systemName: "lightbulb.max.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.cardGoals, Color.cardGoals.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        VStack(spacing: 8) {
                            Text(String(localized: "goal.suggestions.empty.title", comment: "No suggestions yet"))
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(String(localized: "goal.suggestions.empty.message", comment: "We'll suggest personalized goals as we collect more data."))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }

                        Button {
                            generateSuggestions()
                        } label: {
                            Label("Yeniden Oluştur", systemImage: "arrow.clockwise")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding()
                                .background(Color.cardGoals)
                                .clipShape(Capsule())
                        }
                        .padding(.top)
                    }
                } else {
                    // Öneriler listesi
                    ScrollView {
                        VStack(spacing: 20) {
                            // Header
                            VStack(spacing: 8) {
                                HStack {
                                    Image(systemName: "sparkles")
                                        .font(.title2)
                                        .foregroundStyle(Color.cardGoals)

                                    Text(String(localized: "goal.suggestions.personalized", comment: "Personalized goals"))
                                        .font(.title2)
                                        .fontWeight(.bold)

                                    Spacer()
                                }

                                Text(String(format: NSLocalizedString("goal.suggestions.count.format", comment: "X goal suggestions based on your activities"), viewModel.goalSuggestions.count))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal)
                            .padding(.top)

                            // Öneriler
                            ForEach(viewModel.goalSuggestions) { suggestion in
                                GoalSuggestionCard(
                                    suggestion: suggestion,
                                    onAccept: {
                                        viewModel.acceptSuggestion(suggestion, context: modelContext)
                                    }
                                )
                                .padding(.horizontal)
                            }

                            // Yeniden oluştur butonu
                            Button {
                                generateSuggestions()
                            } label: {
                                Label("Yeni Öneriler Oluştur", systemImage: "arrow.clockwise")
                                    .font(.headline)
                                    .foregroundStyle(Color.cardGoals)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.cardGoals.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.horizontal)
                            .padding(.vertical)
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "goal.suggestions.title", comment: "Goal Suggestions"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
            .task {
                if viewModel.goalSuggestions.isEmpty {
                    generateSuggestions()
                }
            }
        }
    }

    private func generateSuggestions() {
        isGenerating = true

        // Gerçek uygulamada bu async olabilir
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            viewModel.generateSmartGoalSuggestions(
                friends: friends,
                locationLogs: locationLogs
            )
            isGenerating = false
        }
    }
}

// MARK: - Hedef Öneri Kartı

struct GoalSuggestionCard: View {
    let suggestion: GoalSuggestion
    let onAccept: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .top, spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.cardGoals.opacity(0.2),
                                    Color.cardGoals.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: categoryIcon)
                        .font(.title3)
                        .foregroundStyle(Color.cardGoals)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    HStack(spacing: 4) {
                        Image(systemName: sourceIcon)
                            .font(.caption2)
                        Text(sourceText)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer()

                // Zorluk göstergesi
                HStack(spacing: 4) {
                    Text(suggestion.estimatedDifficulty.emoji)
                    Text(suggestion.estimatedDifficulty.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Capsule())
            }

            // Açıklama
            Text(suggestion.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Detaylar
            HStack(spacing: 12) {
                // Hedef tarih
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text(suggestion.suggestedTargetDate, style: .date)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)

                Spacer()

                // Kategori
                HStack(spacing: 4) {
                    Image(systemName: "tag.fill")
                        .font(.caption)
                    Text(suggestion.category.displayName)
                        .font(.caption)
                }
                .foregroundStyle(Color.cardGoals)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.cardGoals.opacity(0.1))
                .clipShape(Capsule())
            }

            // Aksiyon butonları
            HStack(spacing: 12) {
                Button {
                    // Öneriyi reddet
                    HapticFeedback.light()
                } label: {
                    Text(String(localized: "goal.suggestions.not.interested", comment: "Not interested"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    onAccept()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Hedefe Ekle")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.cardGoals, Color.cardGoals.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }

    // Kaynak ikonu
    private var sourceIcon: String {
        switch suggestion.source {
        case .contact: return "person.2.fill"
        case .location: return "location.fill"
        case .habit: return "flame.fill"
        case .manual: return "hand.raised.fill"
        case .ai: return "brain.head.profile"
        }
    }

    // Kaynak metni
    private var sourceText: String {
        switch suggestion.source {
        case .contact: return "Kişi Verileri"
        case .location: return "Konum Verileri"
        case .habit: return "Alışkanlık Verileri"
        case .manual: return "Manuel"
        case .ai: return "AI Önerisi"
        }
    }

    // Kategori ikonu
    private var categoryIcon: String {
        switch suggestion.category {
        case .health: return "heart.fill"
        case .social: return "person.2.fill"
        case .career: return "briefcase.fill"
        case .personal: return "star.fill"
        case .fitness: return "figure.run"
        case .other: return "target"
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Goal.self, Friend.self, LocationLog.self, configurations: config)

    let viewModel = GoalsViewModel()

    return GoalSuggestionsView(
        viewModel: viewModel,
        friends: [],
        locationLogs: []
    )
    .modelContainer(container)
}

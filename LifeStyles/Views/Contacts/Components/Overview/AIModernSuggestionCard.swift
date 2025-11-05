//
//  AIModernSuggestionCard.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Extracted from FriendDetailTabs.swift - AI Suggestion Card Component
//

import SwiftUI

/// Modern AI öneri kartı
struct AIModernSuggestionCard: View {
    let friend: Friend
    @State private var aiSuggestionText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.2), .blue.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)

                    Image(systemName: "brain.head.profile")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text("AI Önerisi")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                if aiSuggestionText.isEmpty {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            Text(aiSuggestionText.isEmpty ? generateAISuggestion() : aiSuggestionText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.08), Color.blue.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .onAppear {
            loadAISuggestion()
        }
    }

    // MARK: - Helper Methods

    private func loadAISuggestion() {
        guard aiSuggestionText.isEmpty else { return }

        Task {
            do {
                let suggestion: String

                if #available(iOS 26.0, *) {
                    suggestion = try await FriendAIService.shared.generateSuggestion(for: friend)
                } else {
                    suggestion = await FriendAIServiceFallback.shared.generateSuggestion(for: friend)
                }

                await MainActor.run {
                    aiSuggestionText = suggestion
                }
            } catch {
                print("❌ AI öneri yüklenemedi: \(error)")
            }
        }
    }

    private func generateAISuggestion() -> String {
        let suggestions = [
            "Bugün güzel bir gün! Belki kahve içmek için arayabilirsiniz.",
            "Hafta sonu yaklaşıyor, birlikte bir aktivite planlayabilirsiniz.",
            "Son zamanlarda yoğun görünüyorsunuz. Kısa bir mesaj atın!",
            "Düzenli iletişiminiz harika! Bu şekilde devam edin.",
            "Bir süredir görüşmediniz. Nasıl olduklarını öğrenebilirsiniz."
        ]

        // Defensive programming: Array bounds check
        let defaultSuggestion = "İletişim zamanı! Bir mesaj gönderin."

        let index: Int
        if friend.needsContact {
            index = 4
        } else if friend.daysRemaining <= 2 {
            index = 2
        } else if currentStreak > 5 {
            index = 3
        } else {
            index = 0
        }

        guard index < suggestions.count else {
            print("⚠️ Array index out of bounds: \(index)")
            return defaultSuggestion
        }

        return suggestions[index]
    }

    private var currentStreak: Int {
        guard let history = friend.contactHistory, !history.isEmpty else { return 0 }

        let sorted = history.sorted(by: { $0.date > $1.date })
        var streak = 0
        var lastDate = Date()

        for item in sorted {
            let daysDiff = Calendar.current.dateComponents([.day], from: item.date, to: lastDate).day ?? 0
            if daysDiff <= friend.frequency.days + 1 {
                streak += 1
                lastDate = item.date
            } else {
                break
            }
        }

        return streak
    }
}

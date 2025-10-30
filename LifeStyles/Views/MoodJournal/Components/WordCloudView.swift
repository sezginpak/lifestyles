//
//  WordCloudView.swift
//  LifeStyles
//
//  Created by Claude on 25.10.2025.
//  Word cloud visualization for journal analytics
//

import SwiftUI

struct WordCloudView: View {
    let entries: [JournalEntry]
    let maxWords: Int

    @State private var wordFrequencies: [(word: String, count: Int)] = []

    init(entries: [JournalEntry], maxWords: Int = 20) {
        self.entries = entries
        self.maxWords = maxWords
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text(String(localized: "wordcloud.most.used", comment: "Most Used Words"))
                .cardTitle()

            if wordFrequencies.isEmpty {
                emptyState
            } else {
                wordCloud
            }
        }
        .onAppear {
            calculateWordFrequencies()
        }
        .onChange(of: entries.count) { _, _ in
            calculateWordFrequencies()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.small) {
            Image(systemName: "text.word.spacing")
                .font(.title2)
                .foregroundStyle(.tertiary)

            Text(String(localized: "wordcloud.not.enough.data", comment: "Not enough data yet"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .glassmorphismCard()
    }

    // MARK: - Word Cloud

    private var wordCloud: some View {
        FlowLayout(spacing: Spacing.small) {
            ForEach(Array(wordFrequencies.prefix(maxWords).enumerated()), id: \.element.word) { index, item in
                WordBubble(
                    word: item.word,
                    count: item.count,
                    maxCount: wordFrequencies.first?.count ?? 1,
                    rank: index
                )
            }
        }
        .padding(Spacing.large)
        .glassmorphismCard()
    }

    // MARK: - Word Frequency Calculation

    private func calculateWordFrequencies() {
        var wordCounts: [String: Int] = [:]

        // Collect all words from entries
        for entry in entries {
            let content = entry.content.lowercased()
            let words = content.components(separatedBy: .whitespacesAndNewlines)

            for word in words {
                // Clean word (remove punctuation)
                let cleanedWord = word.components(separatedBy: .punctuationCharacters).joined()

                // Filter out short words and common words
                guard cleanedWord.count > 3,
                      !isCommonWord(cleanedWord) else {
                    continue
                }

                wordCounts[cleanedWord, default: 0] += 1
            }
        }

        // Sort by frequency
        wordFrequencies = wordCounts
            .sorted { $0.value > $1.value }
            .map { (word: $0.key, count: $0.value) }
    }

    // MARK: - Common Words Filter (Turkish)

    private func isCommonWord(_ word: String) -> Bool {
        let commonWords = [
            "bir", "ve", "için", "ile", "bu", "da", "de", "olan", "gibi",
            "daha", "çok", "ancak", "ama", "bana", "beni", "benim", "seni",
            "onun", "onlar", "bunlar", "şunlar", "şey", "yer", "zaman",
            "sonra", "önce", "artık", "hala", "sadece", "yani", "yine",
            "bile", "kadar", "çünkü", "ise", "işte", "nasıl", "neden",
            "nerede", "kimse", "hiç", "her", "bazı", "tüm", "bütün"
        ]

        return commonWords.contains(word)
    }
}

// MARK: - Word Bubble

struct WordBubble: View {
    let word: String
    let count: Int
    let maxCount: Int
    let rank: Int

    private var fontSize: Font {
        let ratio = Double(count) / Double(maxCount)

        if ratio > 0.7 {
            return .title
        } else if ratio > 0.4 {
            return .title3
        } else if ratio > 0.2 {
            return .body
        } else {
            return .callout
        }
    }

    private var color: Color {
        let colors: [Color] = [
            .brandPrimary,
            .purple,
            .pink,
            .orange,
            .blue,
            .green
        ]

        return colors[rank % colors.count]
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(word)
                .font(fontSize)
                .fontWeight(.medium)

            if count > 1 {
                Text("\(count)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(color)
        .padding(.horizontal, Spacing.small)
        .padding(.vertical, Spacing.micro)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        let sampleEntries = [
            JournalEntry(
                content: "Bugün harika bir gün geçirdim. Arkadaşlarımla buluştum ve çok eğlendik. Hava çok güzeldi.",
                journalType: .general
            ),
            JournalEntry(
                content: "Kendimi geliştirmek için kitap okumaya başladım. Motivasyon çok önemli.",
                journalType: .achievement
            ),
            JournalEntry(
                content: "Sabah koşusu yapmak beni çok mutlu ediyor. Sağlık her şeyden önemli.",
                journalType: .gratitude
            )
        ]

        var body: some View {
            ScrollView {
                WordCloudView(entries: sampleEntries)
                    .padding()
            }
        }
    }

    return PreviewWrapper()
}

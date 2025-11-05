//
//  MasonryGridLayout.swift
//  LifeStyles
//
//  Pinterest-style masonry grid layout
//  Created by Claude on 05.11.2025.
//

import SwiftUI

struct MasonryGridLayout: View {
    let entries: [JournalEntry]
    let columns: Int
    let spacing: CGFloat
    let onTap: (JournalEntry) -> Void
    let onToggleFavorite: (JournalEntry) -> Void
    let onDelete: (JournalEntry) -> Void

    @State private var columnHeights: [CGFloat]
    @State private var appearedItems: Set<UUID> = []

    init(
        entries: [JournalEntry],
        columns: Int = 2,
        spacing: CGFloat = 12,
        onTap: @escaping (JournalEntry) -> Void,
        onToggleFavorite: @escaping (JournalEntry) -> Void,
        onDelete: @escaping (JournalEntry) -> Void
    ) {
        self.entries = entries
        self.columns = columns
        self.spacing = spacing
        self.onTap = onTap
        self.onToggleFavorite = onToggleFavorite
        self.onDelete = onDelete
        self._columnHeights = State(initialValue: Array(repeating: 0, count: columns))
    }

    var body: some View {
        GeometryReader { geometry in
            let columnWidth = (geometry.size.width - CGFloat(columns - 1) * spacing) / CGFloat(columns)

            ScrollView {
                ZStack(alignment: .topLeading) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        EnhancedJournalCard(
                            entry: entry,
                            onTap: {
                                onTap(entry)
                            },
                            onToggleFavorite: {
                                onToggleFavorite(entry)
                            }
                        )
                        .frame(width: columnWidth)
                        .offset(x: xOffset(for: index, columnWidth: columnWidth),
                               y: yOffset(for: index, entry: entry))
                        .opacity(appearedItems.contains(entry.id) ? 1 : 0)
                        .scaleEffect(appearedItems.contains(entry.id) ? 1 : 0.8)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.7)
                            .delay(Double(index) * 0.05),
                            value: appearedItems.contains(entry.id)
                        )
                        .contextMenu {
                            contextMenuButtons(for: entry)
                        }
                        .onAppear {
                            if !appearedItems.contains(entry.id) {
                                appearedItems.insert(entry.id)
                            }
                        }
                    }
                }
                .frame(height: columnHeights.max() ?? 0)
                .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Layout Calculations

    private func shortestColumn() -> Int {
        guard let minHeight = columnHeights.min(),
              let minIndex = columnHeights.firstIndex(of: minHeight) else {
            return 0
        }
        return minIndex
    }

    private func xOffset(for index: Int, columnWidth: CGFloat) -> CGFloat {
        let column = index % columns
        return CGFloat(column) * (columnWidth + spacing)
    }

    private func yOffset(for index: Int, entry: JournalEntry) -> CGFloat {
        let column = index % columns
        let cardHeight = estimatedHeight(for: entry)

        // Update column height
        DispatchQueue.main.async {
            if index < entries.count {
                columnHeights[column] += cardHeight + spacing
            }
        }

        return columnHeights[column] - cardHeight
    }

    private func estimatedHeight(for entry: JournalEntry) -> CGFloat {
        var height: CGFloat = 0

        // Image height
        if entry.hasImage, let imageData = entry.imageData, let image = UIImage(data: imageData) {
            let aspectRatio = image.size.height / image.size.width
            let imageHeight = min(max(aspectRatio * 300, 150), 300)
            height += imageHeight
        }

        // Header height (type + favorite)
        height += 52

        // Title height (if exists)
        if let title = entry.title, !title.isEmpty {
            let titleLines = min(ceil(CGFloat(title.count) / 20), 2)
            height += titleLines * 22 + 6
        }

        // Content preview height
        let previewLines = entry.title != nil ? 3 : 4
        height += CGFloat(previewLines) * 18 + 6

        // Tags height (if exists)
        if !entry.tags.isEmpty {
            height += 32 + 12
        }

        // Footer height
        height += 28

        // Padding
        height += 32

        return height
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func contextMenuButtons(for entry: JournalEntry) -> some View {
        Button {
            onTap(entry)
        } label: {
            Label("Görüntüle", systemImage: "eye")
        }

        Button {
            onToggleFavorite(entry)
        } label: {
            Label(
                entry.isFavorite ? "Favoriden Çıkar" : "Favorilere Ekle",
                systemImage: entry.isFavorite ? "heart.slash" : "heart.fill"
            )
        }

        Divider()

        Button(role: .destructive) {
            onDelete(entry)
        } label: {
            Label("Sil", systemImage: "trash")
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleEntries = [
        JournalEntry(
            title: "Güzel Bir Gün",
            content: "Bugün harika bir gündü. Sabah erken kalktım.",
            journalType: .general,
            tags: ["sabah"],
            isFavorite: true
        ),
        JournalEntry(
            title: "Minnettar",
            content: "Ailem için minnettarım.",
            journalType: .gratitude,
            tags: ["aile", "minnet"]
        ),
        JournalEntry(
            title: "Başarı",
            content: "Projemi tamamladım! Çok mutluyum. Bu uzun bir yolculuktu ve sonunda hedefe ulaştım.",
            journalType: .achievement,
            tags: ["proje", "başarı"]
        ),
        JournalEntry(
            content: "Bugün bir şey öğrendim: Sabır en önemli erdem.",
            journalType: .lesson,
            tags: ["ders"]
        )
    ]

    return MasonryGridLayout(
        entries: sampleEntries,
        onTap: { _ in },
        onToggleFavorite: { _ in },
        onDelete: { _ in }
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

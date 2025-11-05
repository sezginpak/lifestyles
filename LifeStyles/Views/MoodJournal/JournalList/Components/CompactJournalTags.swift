//
//  CompactJournalTags.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Compact tag display helper for journal cards
//

import SwiftUI

struct CompactJournalTags: View {
    let tags: [String]
    let typeColor: Color
    let maxVisible: Int

    init(tags: [String], typeColor: Color, maxVisible: Int = 3) {
        self.tags = tags
        self.typeColor = typeColor
        self.maxVisible = maxVisible
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(tags.prefix(maxVisible), id: \.self) { tag in
                HStack(spacing: 2) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 8))
                    Text(tag)
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundStyle(typeColor)
                .padding(.horizontal, Spacing.small)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    typeColor.opacity(0.12),
                                    typeColor.opacity(0.06)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .overlay(
                    Capsule()
                        .strokeBorder(typeColor.opacity(0.2), lineWidth: 0.5)
                )
            }

            if tags.count > maxVisible {
                Text(String(format: NSLocalizedString("mood.more.tags", comment: "More tags count"), tags.count - maxVisible))
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(typeColor.opacity(0.6))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(typeColor.opacity(0.08))
                    )
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        CompactJournalTags(
            tags: ["Öğrenci", "Motivasyon", "Başarı"],
            typeColor: .blue
        )

        CompactJournalTags(
            tags: ["İş", "Stres", "Hedef", "Zaman Yönetimi", "Verimlilik"],
            typeColor: .purple
        )

        CompactJournalTags(
            tags: ["Mutluluk"],
            typeColor: .green
        )
    }
    .padding()
}

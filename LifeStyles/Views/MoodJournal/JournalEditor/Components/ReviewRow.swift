//
//  ReviewRow.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Review step info row component
//

import SwiftUI

struct ReviewRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    VStack(spacing: Spacing.large) {
        ReviewRow(
            icon: "doc.text",
            label: "Tip",
            value: "📝 Genel",
            color: .blue
        )

        ReviewRow(
            icon: "text.cursor",
            label: "Başlık",
            value: "Bugünkü Düşüncelerim",
            color: .secondary
        )
    }
    .padding()
}

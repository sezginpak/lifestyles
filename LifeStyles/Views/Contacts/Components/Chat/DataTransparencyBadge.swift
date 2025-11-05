//
//  DataTransparencyBadge.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//

import SwiftUI

struct DataTransparencyBadge: View {
    let dataCount: DataUsageCount
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "info.circle.fill")
                    .font(.caption2)
                Text(dataCount.summary)
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.tertiarySystemBackground))
            .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    DataTransparencyBadge(
        dataCount: DataUsageCount(
            friendsCount: 2,
            goalsCount: 1,
            habitsCount: 3,
            hasMoodData: true,
            hasLocationData: false,
            timestamp: Date()
        ),
        action: {}
    )
    .padding()
}

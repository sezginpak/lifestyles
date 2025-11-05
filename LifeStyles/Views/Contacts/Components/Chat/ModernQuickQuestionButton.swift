//
//  ModernQuickQuestionButton.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//

import SwiftUI

struct ModernQuickQuestionButton: View {
    let icon: String
    let question: String
    let gradient: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.body)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(question)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
            )
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        ModernQuickQuestionButton(
            icon: "message.fill",
            question: "Mesaj taslağı oluştur",
            gradient: [.blue, .cyan],
            action: {}
        )

        ModernQuickQuestionButton(
            icon: "heart.fill",
            question: "Randevu fikri ver",
            gradient: [.pink, .red],
            action: {}
        )
    }
    .padding()
}

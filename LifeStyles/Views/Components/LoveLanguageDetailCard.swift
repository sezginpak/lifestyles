//
//  LoveLanguageDetailCard.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//

import SwiftUI

struct LoveLanguageDetailCard: View {
    let friend: Friend

    private var loveLanguage: LoveLanguage? {
        friend.loveLanguage
    }

    var body: some View {
        if let language = loveLanguage {
            VStack(spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "friends.love.language", comment: "Love Language"))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            Text(language.emoji)
                                .font(.title2)

                            Text(language.displayName)
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                    }

                    Spacer()

                    Image(systemName: "heart.fill")
                        .font(.title2)
                        .foregroundStyle(.pink.gradient)
                }

                // Description
                Text(language.detailedDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()

                // Tips
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                        Text(String(localized: "love.language.tips", comment: "Application Tips"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(language.tips, id: \.self) { tip in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundStyle(.pink)
                                Text(tip)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.purple.opacity(0.1), Color.pink.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.purple.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            ForEach(LoveLanguage.allCases, id: \.self) { language in
                LoveLanguageDetailCard(
                    friend: Friend(
                        name: "Partner",
                        relationshipType: .partner,
                        loveLanguage: language
                    )
                )
                .padding()
            }
        }
    }
}

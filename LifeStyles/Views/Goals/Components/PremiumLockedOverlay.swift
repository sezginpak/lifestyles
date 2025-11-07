//
//  PremiumLockedOverlay.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Premium içerik üzerine konacak blur + lock overlay
//

import SwiftUI

struct PremiumLockedOverlay: View {
    let title: String
    let onTap: () -> Void

    var body: some View {
        ZStack {
            // Blur Background
            Rectangle()
                .fill(.ultraThinMaterial)

            // Premium Badge
            VStack(spacing: 12) {
                // Crown Icon
                Image(systemName: "crown.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .yellow.opacity(0.3), radius: 10)

                // Title
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                // Premium Badge
                Text(String(localized: "premium.badge.title"))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())

                // CTA
                Text(String(localized: "premium.unlock.tap"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - ViewModifier for easy application

struct PremiumLockable: ViewModifier {
    let isLocked: Bool
    let title: String
    let onUnlockTap: () -> Void

    func body(content: Content) -> some View {
        ZStack {
            content
                .blur(radius: isLocked ? 8 : 0)

            if isLocked {
                PremiumLockedOverlay(title: title, onTap: onUnlockTap)
            }
        }
    }
}

extension View {
    func premiumLocked(_ isLocked: Bool, title: String, onUnlock: @escaping () -> Void) -> some View {
        self.modifier(PremiumLockable(isLocked: isLocked, title: title, onUnlockTap: onUnlock))
    }
}

#Preview {
    VStack {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.blue.gradient)
            .frame(height: 200)
            .overlay {
                Text(String(localized: "premium.hidden.content", comment: "Hidden premium content"))
                    .font(.title)
                    .foregroundStyle(.white)
            }
            .premiumLocked(true, title: "Gelişmiş Analizler") {
                print("Premium unlock tapped")
            }
    }
    .padding()
}

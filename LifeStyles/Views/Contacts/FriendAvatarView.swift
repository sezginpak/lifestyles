//
//  FriendAvatarView.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Reusable avatar component for displaying friend profile images
//

import SwiftUI

/// Profil fotoğrafı, emoji veya baş harfi gösteren tekrar kullanılabilir avatar componenti
struct FriendAvatarView: View {
    let friend: Friend
    let size: CGFloat
    let showBadge: Bool

    init(friend: Friend, size: CGFloat = 50, showBadge: Bool = false) {
        self.friend = friend
        self.size = size
        self.showBadge = showBadge
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    friend.isImportant ?
                    Color.orange.opacity(0.15) :
                    Color.blue.opacity(0.15)
                )
                .frame(width: size, height: size)

            // Öncelik sırası: profil fotoğrafı > emoji > baş harf
            if let imageData = friend.profileImageData,
               let uiImage = UIImage(data: imageData) {
                // Profil fotoğrafı
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if let emoji = friend.avatarEmoji {
                // Emoji avatar
                Text(emoji)
                    .font(.system(size: size * 0.5))
            } else {
                // Baş harf
                Text(String(friend.name.prefix(1)).uppercased())
                    .font(.system(size: size * 0.4))
                    .fontWeight(.bold)
                    .foregroundStyle(friend.isImportant ? .orange : .blue)
            }

            // Önemli badge
            if showBadge && friend.isImportant && friend.profileImageData != nil {
                Circle()
                    .fill(Color.orange)
                    .frame(width: size * 0.28, height: size * 0.28)
                    .overlay(
                        Image(systemName: "star.fill")
                            .font(.system(size: size * 0.14))
                            .foregroundStyle(.white)
                    )
                    .offset(x: size * 0.35, y: -size * 0.35)
            }
        }
    }
}

/// Gelişmiş avatar componenti (FriendDetailView için)
struct FriendAvatarAdvancedView: View {
    let friend: Friend
    let size: CGFloat
    let accentColor: Color

    init(friend: Friend, size: CGFloat = 90, accentColor: Color = .blue) {
        self.friend = friend
        self.size = size
        self.accentColor = accentColor
    }

    var body: some View {
        ZStack {
            // Outer ring - animated
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            accentColor.opacity(0.3),
                            accentColor.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: size + 10, height: size + 10)

            // Avatar Circle with gradient background
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            accentColor.opacity(0.4),
                            accentColor.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: accentColor.opacity(0.3), radius: 12, x: 0, y: 6)

            // Avatar Content
            if let imageData = friend.profileImageData,
               let uiImage = UIImage(data: imageData) {
                // Profil fotoğrafı
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if let emoji = friend.avatarEmoji {
                // Emoji avatar
                Text(emoji)
                    .font(.system(size: size * 0.48))
            } else {
                // Baş harf
                Text(String(friend.name.prefix(1)).uppercased())
                    .font(.system(size: size * 0.4))
                    .fontWeight(.bold)
                    .foregroundStyle(accentColor)
            }

            // Special badge for partner
            if friend.isPartner {
                Circle()
                    .fill(Color.red)
                    .frame(width: size * 0.31, height: size * 0.31)
                    .overlay(
                        Text("❤️")
                            .font(.system(size: size * 0.15))
                    )
                    .offset(x: size * 0.39, y: -size * 0.39)
            } else if friend.isImportant {
                Circle()
                    .fill(Color.orange)
                    .frame(width: size * 0.31, height: size * 0.31)
                    .overlay(
                        Image(systemName: "star.fill")
                            .font(.system(size: size * 0.13))
                            .foregroundStyle(.white)
                    )
                    .offset(x: size * 0.39, y: -size * 0.39)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Profil fotoğrafı olmayan örnekler
        FriendAvatarView(
            friend: Friend(
                name: "Ahmet Yılmaz",
                isImportant: true,
                avatarEmoji: "👨‍💼"
            ),
            size: 60,
            showBadge: true
        )

        // Emoji olmayan örnek (baş harf gösterir)
        FriendAvatarView(
            friend: Friend(name: "Zeynep Demir"),
            size: 50
        )

        // Gelişmiş avatar
        FriendAvatarAdvancedView(
            friend: Friend(
                name: "Partner",
                isImportant: true,
                relationshipType: .partner
            ),
            size: 90,
            accentColor: .pink
        )
    }
    .padding()
}

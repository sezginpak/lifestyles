//
//  StickerPaletteView.swift
//  LifeStyles
//
//  Sticker/Emoji picker for journal entries
//  Created by Claude on 30.10.2025.
//

import SwiftUI

struct StickerPaletteView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (String) -> Void

    @State private var selectedCategory: StickerCategory = .emotions
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category picker
                categoryPicker

                Divider()

                // Sticker grid
                stickerGrid
            }
            .navigationTitle("Sticker Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Sticker ara...")
        }
    }

    // MARK: - Category Picker

    var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(StickerCategory.allCases, id: \.self) { category in
                    categoryChip(category)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }

    func categoryChip(_ category: StickerCategory) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedCategory = category
            }
            HapticFeedback.light()
        }) {
            HStack(spacing: 6) {
                Text(category.icon)
                    .font(.system(size: 16))

                Text(category.name)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(selectedCategory == category ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(selectedCategory == category ? category.color : Color(.systemGray6))
            )
            .shadow(
                color: selectedCategory == category ? category.color.opacity(0.3) : .clear,
                radius: 8
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Sticker Grid

    var stickerGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 60), spacing: 12)],
                spacing: 12
            ) {
                ForEach(filteredStickers, id: \.self) { sticker in
                    stickerButton(sticker)
                }
            }
            .padding(16)
        }
    }

    func stickerButton(_ emoji: String) -> some View {
        Button(action: {
            onSelect(emoji)
            HapticFeedback.success()
            dismiss()
        }) {
            Text(emoji)
                .font(.system(size: 40))
                .frame(width: 60, height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
        }
        .buttonStyle(BouncyButtonStyle())
    }

    // MARK: - Filtered Stickers

    var filteredStickers: [String] {
        let stickers = selectedCategory.stickers

        if searchText.isEmpty {
            return stickers
        }

        // Search by emoji or category
        return stickers.filter { emoji in
            // Simple search - could be enhanced with emoji descriptions
            true // For now, show all when searching
        }
    }
}

// MARK: - Sticker Category

enum StickerCategory: String, CaseIterable {
    case emotions = "Duygular"
    case activities = "Aktiviteler"
    case weather = "Hava Durumu"
    case special = "Özel"

    var name: String { rawValue }

    var icon: String {
        switch self {
        case .emotions: return "😊"
        case .activities: return "🎉"
        case .weather: return "☀️"
        case .special: return "⭐"
        }
    }

    var color: Color {
        switch self {
        case .emotions: return .pink
        case .activities: return .blue
        case .weather: return .cyan
        case .special: return .purple
        }
    }

    var stickers: [String] {
        switch self {
        case .emotions:
            return [
                "😊", "😃", "😄", "😁", "😆",
                "😅", "🤣", "😂", "🙂", "🙃",
                "😉", "😌", "😍", "🥰", "😘",
                "😗", "😙", "😚", "😋", "😛",
                "😝", "😜", "🤪", "🤨", "🧐",
                "🤓", "😎", "🥳", "😏", "😒",
                "😞", "😔", "😟", "😕", "🙁",
                "☹️", "😣", "😖", "😫", "😩",
                "🥺", "😢", "😭", "😤", "😠",
                "😡", "🤬", "🤯", "😳", "🥵",
                "🥶", "😱", "😨", "😰", "😥"
            ]
        case .activities:
            return [
                "⚽", "🏀", "🏈", "⚾", "🎾",
                "🏐", "🏉", "🥏", "🎱", "🏓",
                "🏸", "🏒", "🏑", "🥍", "🏏",
                "⛳", "🏹", "🎣", "🤿", "🥊",
                "🥋", "🎽", "🛹", "🛼", "🛷",
                "⛸️", "🥌", "🎿", "⛷️", "🏂",
                "🪂", "🏋️", "🤼", "🤸", "🤺",
                "⛹️", "🤾", "🏌️", "🏇", "🧘",
                "🏊", "🚴", "🚵", "🧗", "🤠"
            ]
        case .weather:
            return [
                "☀️", "🌤️", "⛅", "🌥️", "☁️",
                "🌦️", "🌧️", "⛈️", "🌩️", "🌨️",
                "❄️", "☃️", "⛄", "🌬️", "💨",
                "🌪️", "🌫️", "🌈", "☂️", "⚡",
                "💧", "💦", "🌊", "🔥", "✨",
                "⭐", "🌟", "💫", "🌙", "🌛",
                "🌜", "🌕", "🌖", "🌗", "🌘"
            ]
        case .special:
            return [
                "❤️", "🧡", "💛", "💚", "💙",
                "💜", "🖤", "🤍", "🤎", "💔",
                "❣️", "💕", "💞", "💓", "💗",
                "💖", "💘", "💝", "💟", "☮️",
                "✝️", "☪️", "🕉️", "☸️", "✡️",
                "🔯", "🕎", "☯️", "☦️", "🛐",
                "⭐", "🌟", "✨", "💫", "🔥",
                "💧", "💎", "👑", "🎁", "🎀",
                "🎉", "🎊", "🎈", "🏆", "🥇"
            ]
        }
    }
}

// MARK: - Bouncy Button Style

struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.2 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    StickerPaletteView { emoji in
        print("Selected: \(emoji)")
    }
}

//
//  EmojiPickerView.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//

import SwiftUI

/// Kategorize emoji seçici view
struct EmojiPickerView: View {
    @Binding var selectedEmoji: String
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: EmojiCategory = .activities
    @State private var searchText = ""

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 7)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Emoji ara...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.adaptiveSecondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()

                // Category tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(EmojiCategory.allCases, id: \.self) { category in
                            CategoryButton(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 12)

                Divider()

                // Emoji grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredEmojis, id: \.self) { emoji in
                            EmojiButton(
                                emoji: emoji,
                                isSelected: selectedEmoji == emoji
                            ) {
                                selectedEmoji = emoji
                                HapticFeedback.selection()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    dismiss()
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Emoji Seç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Tamam") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var filteredEmojis: [String] {
        let emojis = selectedCategory.emojis

        if searchText.isEmpty {
            return emojis
        }

        // Basit search - emoji'nin Unicode name'i ile eşleştirme yapabilirdik
        // Şimdilik sadece kategori filtrelemesi yeterli
        return emojis
    }
}

// MARK: - Emoji Category Button
private struct CategoryButton: View {
    let category: EmojiCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(category.icon)
                    .font(.title2)
                Text(category.name)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.brandPrimary.opacity(0.15) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.brandPrimary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Emoji Button
private struct EmojiButton: View {
    let emoji: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(emoji)
                .font(.system(size: 36))
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(isSelected ? Color.brandPrimary.opacity(0.2) : Color.clear)
                )
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.brandPrimary : Color.clear, lineWidth: 2)
                )
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(response: 0.3), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Emoji Categories
enum EmojiCategory: String, CaseIterable {
    case faces = "Yüzler"
    case activities = "Aktiviteler"
    case health = "Sağlık"
    case learning = "Öğrenme"
    case goals = "Hedefler"
    case nature = "Doğa"
    case food = "Yemek"
    case objects = "Nesneler"

    var name: String { rawValue }

    var icon: String {
        switch self {
        case .faces: return "😀"
        case .activities: return "🏃"
        case .health: return "💪"
        case .learning: return "📚"
        case .goals: return "🎯"
        case .nature: return "🌳"
        case .food: return "🍎"
        case .objects: return "⚡"
        }
    }

    var emojis: [String] {
        switch self {
        case .faces:
            return ["😀", "😃", "😄", "😁", "😆", "😅", "🤣", "😂", "🙂", "🙃", "😉", "😊", "😇",
                    "🥰", "😍", "🤩", "😘", "😗", "😚", "😙", "🥲", "😋", "😛", "😜", "🤪", "😝",
                    "🤗", "🤭", "🤫", "🤔", "🤐", "🤨", "😐", "😑", "😶", "😏", "😒", "🙄", "😬",
                    "🤥", "😌", "😔", "😪", "😴", "🥱"]

        case .activities:
            return ["🏃", "🏃‍♀️", "🚶", "🚶‍♀️", "🏋️", "🏋️‍♀️", "🤸", "🤸‍♀️", "⛹️", "⛹️‍♀️",
                    "🤺", "🤾", "🏌️", "🏇", "🧘", "🧘‍♀️", "🏄", "🏄‍♀️", "🏊", "🏊‍♀️", "🤽", "🤽‍♀️",
                    "🚣", "🚣‍♀️", "🧗", "🧗‍♀️", "🚵", "🚵‍♀️", "🚴", "🚴‍♀️", "🏆", "🥇", "🥈", "🥉",
                    "🏅", "🎯", "🎪", "🎭", "🎨", "🎬", "🎤", "🎧", "🎼", "🎹", "🥁", "🎸"]

        case .health:
            return ["💪", "🦵", "🦶", "👂", "👃", "🧠", "🫀", "🫁", "🦷", "🦴", "👀", "👁️", "💊",
                    "💉", "🩹", "🩺", "🩻", "🔬", "🧬", "🧪", "🌡️", "🏥", "⚕️", "❤️", "🧡",
                    "💛", "💚", "💙", "💜", "🤍", "🖤", "🤎", "❤️‍🔥", "❤️‍🩹", "💔", "💕", "💞",
                    "💓", "💗", "💖", "💘", "💝", "💟"]

        case .learning:
            return ["📚", "📖", "📕", "📗", "📘", "📙", "📓", "📔", "📒", "📃", "📄", "📰", "🗞️",
                    "📜", "📋", "📊", "📈", "📉", "🗒️", "🗓️", "📆", "📅", "📇", "🗃️", "🗳️", "🗄️",
                    "📁", "📂", "🗂️", "📌", "📍", "📎", "🖇️", "📏", "📐", "✂️", "🖊️", "🖋️",
                    "✒️", "🖍️", "📝", "✏️", "🔍", "🔎", "🔬", "🔭", "🎓", "🎒"]

        case .goals:
            return ["🎯", "🏆", "🥇", "🥈", "🥉", "🏅", "🎖️", "🏵️", "🎗️", "🎫", "🎟️", "🎪",
                    "🎭", "🎨", "🎬", "📈", "📊", "💼", "💰", "💵", "💴", "💶", "💷", "💸",
                    "💳", "💎", "⚖️", "🔧", "🔨", "⚙️", "🛠️", "⚡", "💡", "🔦", "🔥", "⭐",
                    "✨", "💫", "🌟", "🌠", "🚀", "🛸", "⚓", "⛵", "🚁", "🎆"]

        case .nature:
            return ["🌳", "🌲", "🌴", "🌵", "🌾", "🌿", "☘️", "🍀", "🍁", "🍂", "🍃", "🪴", "🌱",
                    "🌺", "🌻", "🌼", "🌷", "🌹", "🥀", "🏵️", "💐", "🌸", "💮", "🏔️", "⛰️",
                    "🌋", "🗻", "🏕️", "🏖️", "🏜️", "🏝️", "🏞️", "🌅", "🌄", "🌠", "🎇", "🎆",
                    "🌇", "🌆", "🌃", "🌌", "🌉", "🌁", "☀️", "🌤️", "⛅", "🌥️"]

        case .food:
            return ["🍎", "🍏", "🍐", "🍊", "🍋", "🍌", "🍉", "🍇", "🍓", "🫐", "🍈", "🍒", "🍑",
                    "🥭", "🍍", "🥥", "🥝", "🍅", "🥑", "🥦", "🥬", "🥒", "🌶️", "🫑", "🌽",
                    "🥕", "🧄", "🧅", "🥔", "🍠", "🥐", "🥯", "🍞", "🥖", "🥨", "🧀", "🥚",
                    "🍳", "🧈", "🥞", "🧇", "🥓", "🥩", "🍗", "🍖", "🦴", "🌭"]

        case .objects:
            return ["⚡", "🔥", "💥", "✨", "🌟", "⭐", "💫", "🔆", "🔅", "💡", "🔦", "🏮",
                    "🔔", "🔕", "📢", "📣", "📯", "📻", "📱", "📲", "☎️", "📞", "📟", "📠",
                    "🔋", "🔌", "💻", "🖥️", "🖨️", "⌨️", "🖱️", "🖲️", "💾", "💿", "📀", "🧮",
                    "🎥", "🎬", "📽️", "📺", "📷", "📸", "📹", "📼", "🔍", "🔎", "🕯️"]
        }
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var emoji = "🎯"

    Button {
        // Preview içinde sheet açmak için
    } label: {
        Text(emoji)
            .font(.system(size: 48))
    }
    .sheet(isPresented: .constant(true)) {
        EmojiPickerView(selectedEmoji: $emoji)
    }
}

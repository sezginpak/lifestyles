//
//  FilterChipGroup.swift
//  LifeStyles
//
//  Multi-select filter chip group
//  Created by Claude on 05.11.2025.
//

import SwiftUI

struct FilterChipGroup: View {
    @Binding var selectedType: JournalType?
    @Binding var showOnlyFavorites: Bool
    @Binding var showOnlyWithImages: Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // Favorites filter
                JournalFilterChipView(
                    icon: "heart.fill",
                    label: "Favoriler",
                    isSelected: showOnlyFavorites,
                    color: .red,
                    onTap: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showOnlyFavorites.toggle()
                        }
                        HapticFeedback.light()
                    }
                )

                // Images filter
                JournalFilterChipView(
                    icon: "photo.fill",
                    label: "Fotoğraflı",
                    isSelected: showOnlyWithImages,
                    color: .blue,
                    onTap: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showOnlyWithImages.toggle()
                        }
                        HapticFeedback.light()
                    }
                )

                // Type filters
                ForEach(JournalType.allCases, id: \.self) { type in
                    JournalFilterChipView(
                        icon: type.icon,
                        label: type.displayName,
                        isSelected: selectedType == type,
                        color: type.color,
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if selectedType == type {
                                    selectedType = nil
                                } else {
                                    selectedType = type
                                }
                            }
                            HapticFeedback.light()
                        }
                    )
                }

                // Clear all (if any filter active)
                if selectedType != nil || showOnlyFavorites || showOnlyWithImages {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedType = nil
                            showOnlyFavorites = false
                            showOnlyWithImages = false
                        }
                        HapticFeedback.medium()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .semibold))
                            Text(String(localized: "filter.clear", comment: ""))
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.1))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Journal Filter Chip

struct JournalFilterChipView: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let color: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))

                Text(label)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(
                        isSelected ?
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [color.opacity(0.15), color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        isSelected ? Color.clear : color.opacity(0.2),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isSelected ? color.opacity(0.3) : Color.clear,
                radius: 8,
                y: 4
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    @State var selectedType: JournalType? = nil
    @State var showOnlyFavorites = false
    @State var showOnlyWithImages = false

    return VStack {
        FilterChipGroup(
            selectedType: $selectedType,
            showOnlyFavorites: $showOnlyFavorites,
            showOnlyWithImages: $showOnlyWithImages
        )
    }
    .padding(.vertical)
    .background(Color(.systemGroupedBackground))
}

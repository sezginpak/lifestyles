//
//  JournalSearchBar.swift
//  LifeStyles
//
//  Smart search bar for journals
//  Created by Claude on 05.11.2025.
//

import SwiftUI

struct JournalSearchBar: View {
    @Binding var searchText: String
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Search icon
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isFocused ? .brandPrimary : .secondary)

            // Text field
            TextField("Journal ara...", text: $searchText)
                .font(.system(size: 16))
                .focused($isFocused)
                .submitLabel(.search)

            // Clear button
            if !searchText.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        searchText = ""
                    }
                    HapticFeedback.light()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            isFocused ? Color.brandPrimary.opacity(0.3) : Color.clear,
                            lineWidth: 2
                        )
                )
        )
        .shadow(color: isFocused ? Color.brandPrimary.opacity(0.1) : Color.clear, radius: 8)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
    }
}

// MARK: - Preview

#Preview {
    @State var searchText = ""
    @FocusState var isFocused: Bool

    return VStack {
        JournalSearchBar(searchText: $searchText, isFocused: $isFocused)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

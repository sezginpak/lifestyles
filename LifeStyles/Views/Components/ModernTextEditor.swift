//
//  ModernTextEditor.swift
//  LifeStyles
//
//  Modern, glassmorphism TextEditor wrapper
//  Floating counter, focus state, animations
//

import SwiftUI

// MARK: - Modern Text Editor

struct ModernTextEditor: View {
    @Binding var text: String
    let placeholder: String
    let minHeight: CGFloat
    let showCounter: Bool
    let maxCharacters: Int?

    @FocusState private var isFocused: Bool
    @State private var isAnimating = false

    init(
        text: Binding<String>,
        placeholder: String = "Bugün neler oldu?",
        minHeight: CGFloat = 200,
        showCounter: Bool = true,
        maxCharacters: Int? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.minHeight = minHeight
        self.showCounter = showCounter
        self.maxCharacters = maxCharacters
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: isFocused ? [
                                    Color.brandPrimary.opacity(0.6),
                                    Color.purple.opacity(0.4)
                                ] : [
                                    Color.gray.opacity(0.2),
                                    Color.gray.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isFocused ? 2 : 1
                        )
                )
                .shadow(
                    color: isFocused ? Color.brandPrimary.opacity(0.2) : .clear,
                    radius: 12,
                    y: 4
                )

            // Text Editor
            VStack(alignment: .leading, spacing: 0) {
                TextEditor(text: $text)
                    .focused($isFocused)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .scrollContentBackground(.hidden)
                    .background(.clear)
                    .frame(minHeight: minHeight)
                    .padding(12)
                    .onChange(of: text) { _, newValue in
                        // Max character limit
                        if let max = maxCharacters, newValue.count > max {
                            text = String(newValue.prefix(max))
                            HapticFeedback.warning()
                        }
                    }
                    .onChange(of: isFocused) { _, newValue in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isAnimating = newValue
                        }
                    }

                // Floating Counter
                if showCounter {
                    HStack {
                        Spacer()

                        FloatingCounter(
                            characterCount: text.count,
                            wordCount: wordCount,
                            maxCharacters: maxCharacters,
                            isVisible: isFocused || !text.isEmpty
                        )
                        .padding(.trailing, 12)
                        .padding(.bottom, 12)
                    }
                }
            }

            // Placeholder
            if text.isEmpty && !isFocused {
                Text(placeholder)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(24)
                    .allowsHitTesting(false)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isFocused)
    }

    private var wordCount: Int {
        text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }
}

// MARK: - Floating Counter

struct FloatingCounter: View {
    let characterCount: Int
    let wordCount: Int
    let maxCharacters: Int?
    let isVisible: Bool

    @State private var scale: CGFloat = 0.8

    var body: some View {
        HStack(spacing: 6) {
            // Word count
            counterPill(
                icon: "textformat",
                value: "\(wordCount)",
                color: .blue
            )

            // Character count
            if let max = maxCharacters {
                counterPill(
                    icon: "character",
                    value: "\(characterCount)/\(max)",
                    color: characterCount > Int(Double(max) * 0.9) ? .orange : .purple,
                    isWarning: characterCount >= max
                )
            } else {
                counterPill(
                    icon: "character",
                    value: "\(characterCount)",
                    color: .purple
                )
            }
        }
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isVisible)
    }

    private func counterPill(
        icon: String,
        value: String,
        color: Color,
        isWarning: Bool = false
    ) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)

            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .monospacedDigit()
        }
        .foregroundStyle(isWarning ? .white : color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(isWarning ? color : color.opacity(0.15))
        )
        .overlay(
            Capsule()
                .strokeBorder(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("Modern Text Editor - Empty") {
    VStack {
        ModernTextEditor(
            text: .constant(""),
            placeholder: "Bugün neler oldu?"
        )
        .padding()

        Spacer()
    }
}

#Preview("Modern Text Editor - With Content") {
    VStack {
        ModernTextEditor(
            text: .constant("Bugün harika bir gündü! Sabah erkenden kalktım ve koşuya gittim. Sonra sevdiğim kahvaltıyı hazırladım..."),
            placeholder: "Bugün neler oldu?",
            maxCharacters: 500
        )
        .padding()

        Spacer()
    }
}

#Preview("Modern Text Editor - Max Characters") {
    @Previewable @State var text = String(repeating: "test ", count: 95)

    VStack {
        ModernTextEditor(
            text: $text,
            placeholder: "Bugün neler oldu?",
            maxCharacters: 500
        )
        .padding()

        Spacer()
    }
}

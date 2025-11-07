//
//  MarkdownEditor.swift
//  LifeStyles
//
//  Created by Claude on 25.10.2025.
//  Rich text editor with markdown toolbar
//

import SwiftUI

struct MarkdownEditor: View {
    @Binding var text: String
    @Binding var hasMarkdown: Bool

    let placeholder: String
    let minHeight: CGFloat
    let showToolbar: Bool

    @State private var showPreview = false
    @FocusState private var isFocused: Bool

    init(
        text: Binding<String>,
        hasMarkdown: Binding<Bool>,
        placeholder: String = "Yazın...",
        minHeight: CGFloat = 200,
        showToolbar: Bool = true
    ) {
        self._text = text
        self._hasMarkdown = hasMarkdown
        self.placeholder = placeholder
        self.minHeight = minHeight
        self.showToolbar = showToolbar
    }

    var body: some View {
        VStack(spacing: 0) {
            // Mode Toggle
            if showToolbar {
                modeToggle
                    .padding(.horizontal, Spacing.large)
                    .padding(.vertical, Spacing.small)
            }

            // Editor / Preview
            if showPreview {
                previewView
            } else {
                editorView
            }

            // Markdown Toolbar
            if showToolbar && !showPreview {
                markdownToolbar
                    .padding(.horizontal, Spacing.large)
                    .padding(.vertical, Spacing.small)
            }
        }
        .onChange(of: text) { _, newValue in
            // Auto-detect markdown
            hasMarkdown = MarkdownRenderer.hasMarkdownSyntax(newValue)
        }
    }

    // MARK: - Mode Toggle

    private var modeToggle: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showPreview = false
                }
                isFocused = true
            } label: {
                Label(String(localized: "button.edit", comment: "Edit button"), systemImage: "pencil")
                    .font(.caption)
                    .fontWeight(showPreview ? .regular : .semibold)
                    .foregroundStyle(showPreview ? .secondary : .primary)
            }

            Spacer()

            if hasMarkdown {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showPreview.toggle()
                    }
                    isFocused = false
                } label: {
                    Label(String(localized: "button.preview", comment: "Preview button"), systemImage: "eye")
                        .font(.caption)
                        .fontWeight(showPreview ? .semibold : .regular)
                        .foregroundStyle(showPreview ? .primary : .secondary)
                }
            }
        }
    }

    // MARK: - Editor View

    private var editorView: some View {
        TextEditor(text: $text)
            .font(.body)
            .focused($isFocused)
            .frame(minHeight: minHeight)
            .scrollContentBackground(.hidden)
            .padding(Spacing.medium)
            .overlay(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.body)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, Spacing.medium + 5)
                        .padding(.vertical, Spacing.medium + 8)
                        .allowsHitTesting(false)
                }
            }
    }

    // MARK: - Preview View

    private var previewView: some View {
        ScrollView {
            Text(markdown: text)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.large)
        }
        .frame(minHeight: minHeight)
    }

    // MARK: - Markdown Toolbar

    private var markdownToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.small) {
                ForEach(MarkdownAction.allCases, id: \.self) { action in
                    Button {
                        applyMarkdown(action)
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: action.icon)
                                .font(.caption)
                            Text(action.title)
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                        .frame(width: 50, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.compact, style: .continuous)
                                .fill(Color.gray.opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Markdown Actions

    private func applyMarkdown(_ action: MarkdownAction) {
        HapticFeedback.light()

        // Simple append for now (advanced selection handling would require UITextView)
        text = action.apply(to: text, selection: nil)
        hasMarkdown = true
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var text = "# Başlık\n\nBu bir **markdown** örneği.\n\n- Liste 1\n- Liste 2"
        @State private var hasMarkdown = true

        var body: some View {
            VStack {
                MarkdownEditor(
                    text: $text,
                    hasMarkdown: $hasMarkdown,
                    placeholder: "Yazın..."
                )
                .glassmorphismCard()
                .padding()
            }
        }
    }

    return PreviewWrapper()
}

//
//  MarkdownRenderer.swift
//  LifeStyles
//
//  Created by Claude on 25.10.2025.
//  Markdown rendering service - Converts Markdown → AttributedString
//

import SwiftUI

/// Markdown rendering service
enum MarkdownRenderer {
    /// Convert markdown string to AttributedString
    static func render(_ markdown: String) -> AttributedString {
        do {
            return try AttributedString(markdown: markdown, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))
        } catch {
            print("⚠️ Markdown parsing error: \(error)")
            return AttributedString(markdown)
        }
    }

    /// Convert markdown to plain text (strip formatting)
    static func toPlainText(_ markdown: String) -> String {
        // Simple regex-based stripping
        var text = markdown

        // Remove headers (# ## ###)
        text = text.replacingOccurrences(of: #"^#{1,6}\s+"#, with: "", options: .regularExpression)

        // Remove bold (**text** or __text__)
        text = text.replacingOccurrences(of: #"\*\*(.+?)\*\*"#, with: "$1", options: .regularExpression)
        text = text.replacingOccurrences(of: #"__(.+?)__"#, with: "$1", options: .regularExpression)

        // Remove italic (*text* or _text_)
        text = text.replacingOccurrences(of: #"\*(.+?)\*"#, with: "$1", options: .regularExpression)
        text = text.replacingOccurrences(of: #"_(.+?)_"#, with: "$1", options: .regularExpression)

        // Remove links [text](url)
        text = text.replacingOccurrences(of: #"\[(.+?)\]\(.+?\)"#, with: "$1", options: .regularExpression)

        // Remove list markers (- or *)
        text = text.replacingOccurrences(of: #"^[\*\-]\s+"#, with: "", options: .regularExpression)

        return text
    }

    /// Check if string contains markdown syntax
    static func hasMarkdownSyntax(_ text: String) -> Bool {
        let patterns = [
            #"^#{1,6}\s+"#,           // Headers
            #"\*\*(.+?)\*\*"#,        // Bold
            #"__(.+?)__"#,            // Bold (alt)
            #"\*(.+?)\*"#,            // Italic
            #"_(.+?)_"#,              // Italic (alt)
            #"\[.+?\]\(.+?\)"#,       // Links
            #"^[\*\-]\s+"#            // Lists
        ]

        return patterns.contains { pattern in
            text.range(of: pattern, options: .regularExpression) != nil
        }
    }
}

/// Markdown toolbar actions
enum MarkdownAction: CaseIterable {
    case bold
    case italic
    case heading
    case list
    case link

    var icon: String {
        switch self {
        case .bold: return "bold"
        case .italic: return "italic"
        case .heading: return "textformat.size.larger"
        case .list: return "list.bullet"
        case .link: return "link"
        }
    }

    var title: String {
        switch self {
        case .bold: return "Kalın"
        case .italic: return "İtalik"
        case .heading: return "Başlık"
        case .list: return "Liste"
        case .link: return "Link"
        }
    }

    /// Apply markdown formatting to text
    func apply(to text: String, selection: Range<String.Index>?) -> String {
        guard let selection = selection else {
            // No selection - insert template
            return insertTemplate(in: text)
        }

        let selectedText = String(text[selection])

        switch self {
        case .bold:
            return text.replacingCharacters(in: selection, with: "**\(selectedText)**")

        case .italic:
            return text.replacingCharacters(in: selection, with: "*\(selectedText)*")

        case .heading:
            // Add ## before line
            let lineStart = text.lineRange(for: selection).lowerBound
            return text.replacingCharacters(in: lineStart..<lineStart, with: "## ")

        case .list:
            // Add - before line
            let lineStart = text.lineRange(for: selection).lowerBound
            return text.replacingCharacters(in: lineStart..<lineStart, with: "- ")

        case .link:
            return text.replacingCharacters(in: selection, with: "[\(selectedText)](url)")
        }
    }

    /// Insert markdown template when no text is selected
    private func insertTemplate(in text: String) -> String {
        let template: String
        switch self {
        case .bold: template = "**kalın metin**"
        case .italic: template = "*italik metin*"
        case .heading: template = "## Başlık"
        case .list: template = "- Liste öğesi"
        case .link: template = "[link metni](url)"
        }

        return text + (text.isEmpty ? "" : "\n") + template
    }
}

// MARK: - SwiftUI Text Extension for Markdown

extension Text {
    /// Create Text from markdown string
    init(markdown: String) {
        let attributed = MarkdownRenderer.render(markdown)
        self.init(attributed)
    }
}

//
//  DesignSystem.swift
//  LifeStyles
//
//  Created by Claude on 22.10.2025.
//  Merkezi design system: spacing, corner radius, colors, typography
//

import SwiftUI

// MARK: - Spacing System

enum Spacing {
    /// 4pt - Micro spacing (very tight)
    static let micro: CGFloat = 4

    /// 8pt - Small spacing (list items, inline elements)
    static let small: CGFloat = 8

    /// 12pt - Medium spacing (card internal, sections)
    static let medium: CGFloat = 12

    /// 16pt - Large spacing (standard padding, card padding)
    static let large: CGFloat = 16

    /// 20pt - XLarge spacing (major sections)
    static let xlarge: CGFloat = 20

    /// 24pt - XXLarge spacing (screen sections)
    static let xxlarge: CGFloat = 24
}

// MARK: - Corner Radius System

enum CornerRadius {
    /// 8pt - Tight radius (small buttons, pills)
    static let tight: CGFloat = 8

    /// 10pt - Compact radius (input fields, small cards)
    static let compact: CGFloat = 10

    /// 12pt - Normal radius (standard buttons, cards)
    static let normal: CGFloat = 12

    /// 14pt - Medium radius (larger inputs)
    static let medium: CGFloat = 14

    /// 16pt - Relaxed radius (major cards)
    static let relaxed: CGFloat = 16

    /// 20pt - Rounded (hero elements)
    static let rounded: CGFloat = 20
}

// MARK: - Typography Helpers

extension View {
    /// Applies standard card title styling
    func cardTitle() -> some View {
        self
            .font(.headline)
            .fontWeight(.semibold)
    }

    /// Applies secondary text styling
    func secondaryText() -> some View {
        self
            .font(.callout)
            .foregroundStyle(.secondary)
    }

    /// Applies caption/metadata styling
    func metadataText() -> some View {
        self
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    /// Applies small caption styling
    func smallMetadataText() -> some View {
        self
            .font(.caption2)
            .foregroundStyle(.tertiary)
    }
}

// MARK: - Glassmorphism Card Modifier

struct GlassmorphismCard: ViewModifier {
    let cornerRadius: CGFloat
    let borderColor: Color
    let borderWidth: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
            )
    }
}

extension View {
    /// Applies glassmorphism card style
    func glassmorphismCard(
        cornerRadius: CGFloat = CornerRadius.relaxed,
        borderColor: Color = Color.gray.opacity(0.2),
        borderWidth: CGFloat = 1
    ) -> some View {
        self.modifier(
            GlassmorphismCard(
                cornerRadius: cornerRadius,
                borderColor: borderColor,
                borderWidth: borderWidth
            )
        )
    }
}

// MARK: - Standard Shadow

extension View {
    /// Applies standard card shadow
    func cardShadow() -> some View {
        self.shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

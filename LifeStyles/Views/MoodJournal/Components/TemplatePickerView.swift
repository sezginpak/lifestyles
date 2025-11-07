//
//  TemplatePickerView.swift
//  LifeStyles
//
//  Created by Claude on 25.10.2025.
//  Template selection sheet
//

import SwiftUI
import SwiftData

struct TemplatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Binding var selectedTemplate: JournalTemplate?
    @Query(sort: \JournalTemplate.usageCount, order: .reverse) private var templates: [JournalTemplate]

    @State private var selectedCategory: TemplateCategory?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.large) {
                    // Header
                    headerSection

                    // Category Filter
                    categoryFilter

                    // Templates Grid
                    templatesGrid

                    // Skip button
                    skipButton
                }
                .padding(Spacing.large)
            }
            .navigationTitle(String(localized: "journal.nav.template.select", comment: "Select template"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
            .onAppear {
                ensureDefaultTemplates()
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: Spacing.small) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.brandPrimary, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(String(localized: "template.use.writing", comment: "Use writing template"))
                .font(.title3)
                .fontWeight(.bold)

            Text(String(localized: "template.guided.writing", comment: "Guided writing description"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, Spacing.medium)
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.small) {
                // All
                TemplateCategoryChip(
                    category: nil,
                    isSelected: selectedCategory == nil,
                    onTap: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = nil
                        }
                    }
                )

                // Categories
                ForEach(TemplateCategory.allCases, id: \.self) { category in
                    TemplateCategoryChip(
                        category: category,
                        isSelected: selectedCategory == category,
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedCategory = category
                            }
                        }
                    )
                }
            }
        }
    }

    // MARK: - Templates Grid

    private var templatesGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.medium) {
            ForEach(filteredTemplates, id: \.id) { template in
                TemplateCard(
                    template: template,
                    isSelected: selectedTemplate?.id == template.id,
                    onTap: {
                        HapticFeedback.medium()
                        selectedTemplate = template
                        template.incrementUsage()
                        try? modelContext.save()

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            dismiss()
                        }
                    }
                )
            }
        }
    }

    // MARK: - Skip Button

    private var skipButton: some View {
        Button {
            HapticFeedback.light()
            selectedTemplate = nil
            dismiss()
        } label: {
            Text(String(localized: "template.continue.without", comment: "Continue Without Template"))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                        .fill(Color.gray.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var filteredTemplates: [JournalTemplate] {
        if let category = selectedCategory {
            return templates.filter { $0.category == category }
        }
        return templates
    }

    private func ensureDefaultTemplates() {
        if !JournalTemplate.hasDefaultTemplates(context: modelContext) {
            JournalTemplate.createDefaultTemplates(context: modelContext)
        }
    }
}

// MARK: - Template Category Chip

struct TemplateCategoryChip: View {
    let category: TemplateCategory?
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.micro) {
                if let category = category {
                    Image(systemName: category.icon)
                        .font(.caption)
                    Text(category.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                } else {
                    Text(String(localized: "template.all", comment: "All"))
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small)
            .background(
                Capsule()
                    .fill(isSelected ? Color.brandPrimary : Color.gray.opacity(0.15))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Template Card

struct TemplateCard: View {
    let template: JournalTemplate
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [template.color, template.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: template.icon)
                        .font(.title3)
                        .foregroundStyle(.white)
                }

                // Name
                HStack(spacing: 4) {
                    Text(template.emoji)
                        .font(.caption)
                    Text(template.name)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }

                // Description
                Text(template.templateDescription)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Spacer()

                // Usage count
                if template.usageCount > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                        Text(String(localized: "template.usage.count", defaultValue: "\(template.usageCount)", comment: "Template usage"))
                            .font(.caption2)
                    }
                    .foregroundStyle(.tertiary)
                }
            }
            .padding(Spacing.medium)
            .frame(height: 160)
            .glassmorphismCard(
                cornerRadius: CornerRadius.medium,
                borderColor: isSelected ? template.color.opacity(0.5) : Color.gray.opacity(0.2),
                borderWidth: isSelected ? 2 : 1
            )
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(template.color)
                        .padding(Spacing.small)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

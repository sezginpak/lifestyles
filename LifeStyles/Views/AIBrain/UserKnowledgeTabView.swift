//
//  UserKnowledgeTabView.swift
//  LifeStyles
//
//  Created by AI Assistant on 04.11.2025.
//  User Knowledge Tab - Kullanıcı bilgileri (Ultra Compact Design)
//

import SwiftUI
import SwiftData

struct UserKnowledgeTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = AIBrainViewModel()
    @State private var showingSettings = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.filteredKnowledge.isEmpty {
                    emptyState
                } else {
                    contentView
                }
            }
            .navigationTitle(String(localized: "aibrain.tab.title", defaultValue: "AI Hafıza", comment: "AI Brain tab title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingSettings = true
                        } label: {
                            Label(String(localized: "label.ayarlar"), systemImage: "gearshape")
                        }

                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label(
                                String(localized: "privacy.knowledge.deleteAll", defaultValue: "Tümünü Sil", comment: "Delete all knowledge"),
                                systemImage: "trash"
                            )
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                AIBrainSettingsView()
            }
            .alert(
                "Tüm Bilgileri Sil?",
                isPresented: $showingDeleteConfirmation
            ) {
                Button(String(localized: "button.cancel", comment: "Cancel button"), role: .cancel) {}
                Button(String(localized: "button.delete", comment: "Delete button"), role: .destructive) {
                    viewModel.deleteAll(context: modelContext)
                }
            } message: {
                Text(String(localized: "ai.knowledge.delete.warning", comment: "Warning message for deleting all AI knowledge"))
            }
            .onAppear {
                viewModel.loadKnowledge(context: modelContext)
            }
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Statistics Cards - Compact
                statisticsSection

                // Category Filter - Compact
                categoryFilterSection

                // Search Bar - Compact
                searchSection

                // Knowledge List - Ultra Compact
                knowledgeListSection
            }
            .padding(.vertical, 8)
        }
        .refreshable {
            viewModel.refresh(context: modelContext)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 32) {
            Spacer()

            // Animated brain icon
            ZStack {
                // Outer circles
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.purple.opacity(0.3), .pink.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.1), .pink.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                // Brain icon
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Text content
            VStack(spacing: 12) {
                Text(String(localized: "aibrain.empty.title", defaultValue: "Henüz Öğrenilen Bilgi Yok", comment: "Empty state title"))
                    .font(.title2.bold())
                    .foregroundStyle(.primary)

                Text(String(localized: "aibrain.empty.subtitle", defaultValue: "AI ile sohbet et, seni tanımaya başlasın", comment: "Empty state subtitle"))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // Info cards
            VStack(spacing: 12) {
                EmptyStateInfoRow(
                    icon: "sparkles",
                    text: "AI sohbetlerinden otomatik öğrenir",
                    color: .purple
                )

                EmptyStateInfoRow(
                    icon: "shield.checkered",
                    text: "Bilgilerin güvenle saklanır",
                    color: .blue
                )

                EmptyStateInfoRow(
                    icon: "gearshape.2",
                    text: "Öğrenme kategorilerini kontrol et",
                    color: .green
                )
            }
            .padding(.horizontal, 24)

            // CTA Button
            Button {
                // Navigate to AI Chat
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 16, weight: .semibold))
                    Text(String(localized: "ai.chat.try", comment: "Try AI Chat button"))
                        .font(.body.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .purple.opacity(0.4), radius: 12, x: 0, y: 6)
                )
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Statistics Section (Compact Cards)

    private var statisticsSection: some View {
        VStack(spacing: 8) {
            // Hero Card - Total Facts (Featured - Compact)
            HeroStatCard(
                title: "Toplam Bilgi",
                value: "\(viewModel.stats.totalFacts)",
                subtitle: "\(viewModel.stats.categoryCount) kategoride",
                icon: "brain.head.profile",
                gradient: [.purple, .blue]
            )
            .transition(.asymmetric(
                insertion: .scale.combined(with: .opacity),
                removal: .opacity
            ))
            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.0), value: viewModel.stats.totalFacts)

            // Grid - 2 Secondary Stats (Compact)
            HStack(spacing: 8) {
                // Average Confidence
                SecondaryStatCard(
                    title: "Ortalama Güven",
                    value: "\(viewModel.stats.confidencePercentage)%",
                    icon: "star.fill",
                    color: .orange,
                    trend: viewModel.stats.confidencePercentage >= 70 ? "Yüksek" : "Orta"
                )
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .opacity
                ))
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: viewModel.stats.totalFacts)

                // Recent (7 days)
                SecondaryStatCard(
                    title: "Son 7 Gün",
                    value: "\(viewModel.stats.recentFactsCount)",
                    icon: "clock.badge.checkmark",
                    color: .green,
                    trend: viewModel.stats.recentFactsCount > 0 ? "Aktif" : "Durgun"
                )
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .opacity
                ))
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: viewModel.stats.totalFacts)
            }
        }
        .padding(.horizontal, 12)
    }

    // MARK: - Category Filter (Compact Cards)

    private var categoryFilterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section Header (Compact)
            HStack {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.purple)

                Text(String(localized: "ai.categories", comment: "Categories label"))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.primary)

                Spacer()

                // Active filter indicator
                if viewModel.selectedCategory != nil {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.selectedCategory = nil
                        }
                        HapticFeedback.light()
                    } label: {
                        HStack(spacing: 4) {
                            Text(String(localized: "ai.clear", comment: "Clear filter button"))
                                .font(.system(size: 11, weight: .medium))
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.red.gradient)
                        )
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 12)

            // Category Grid (Compact)
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    // All Categories Card
                    ModernCategoryCard(
                        category: nil,
                        isSelected: viewModel.selectedCategory == nil,
                        count: viewModel.knowledge.count,
                        confidence: viewModel.stats.confidencePercentage
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.selectedCategory = nil
                        }
                        HapticFeedback.light()
                    }

                    // Individual Categories
                    ForEach(KnowledgeCategory.allCases, id: \.self) { category in
                        let count = viewModel.count(for: category)
                        if count > 0 {
                            ModernCategoryCard(
                                category: category,
                                isSelected: viewModel.selectedCategory == category,
                                count: count,
                                confidence: viewModel.categoryConfidence(for: category)
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    if viewModel.selectedCategory == category {
                                        viewModel.selectedCategory = nil
                                    } else {
                                        viewModel.selectedCategory = category
                                    }
                                }
                                HapticFeedback.light()
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 3)
            }
        }
    }

    // MARK: - Search Section (Compact)

    private var searchSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

            TextField(String(localized: "knowledge.search.placeholder", comment: ""), text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .autocorrectionDisabled()

            if !viewModel.searchText.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.searchText = ""
                    }
                    HapticFeedback.light()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.tertiary)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.separator).opacity(0.2), lineWidth: 0.5)
        )
        .padding(.horizontal, 8)
    }

    // MARK: - Knowledge List (Ultra Compact)

    private var knowledgeListSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(String(localized: "text.bilgiler.viewmodelfilteredknowledgecount"))
                    .font(.system(size: 12, weight: .semibold))

                Spacer()

                // Sort menu
                Menu {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Button {
                            viewModel.sortOrder = order
                        } label: {
                            HStack {
                                if viewModel.sortOrder == order {
                                    Image(systemName: "checkmark")
                                }
                                Label(order.rawValue, systemImage: order.systemImage)
                            }
                        }
                    }
                } label: {
                    Label(String(localized: "knowledge.sort", comment: ""), systemImage: "arrow.up.arrow.down")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 8)

            // Grouped by category
            if viewModel.selectedCategory == nil {
                ForEach(Array(viewModel.groupedByCategory().keys.sorted(by: { $0.localizedName < $1.localizedName })), id: \.self) { category in
                    if let facts = viewModel.groupedByCategory()[category] {
                        Section {
                            ForEach(Array(facts.enumerated()), id: \.element.id) { index, fact in
                                UltraCompactKnowledgeCard(
                                    fact: fact,
                                    onDelete: {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            viewModel.delete(fact, context: modelContext)
                                        }
                                    },
                                    onConfirm: {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            viewModel.confirm(fact, context: modelContext)
                                        }
                                    }
                                )
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                                .animation(
                                    .spring(response: 0.4, dampingFraction: 0.7)
                                        .delay(Double(index) * 0.05),
                                    value: viewModel.filteredKnowledge.count
                                )
                            }
                        } header: {
                            HStack(spacing: 4) {
                                Image(systemName: category.icon)
                                    .font(.system(size: 8))
                                    .foregroundStyle(Color(hex: category.colorHex) ?? .gray)
                                Text(category.localizedName)
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.top, 6)
                            .padding(.bottom, 2)
                        }
                    }
                }
            } else {
                // Single category view
                ForEach(Array(viewModel.filteredKnowledge.enumerated()), id: \.element.id) { index, fact in
                    UltraCompactKnowledgeCard(
                        fact: fact,
                        onDelete: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                viewModel.delete(fact, context: modelContext)
                            }
                        },
                        onConfirm: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                viewModel.confirm(fact, context: modelContext)
                            }
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.7)
                            .delay(Double(index) * 0.05),
                        value: viewModel.filteredKnowledge.count
                    )
                }
            }
        }
    }
}

// MARK: - Compact Stat Card (80x70 - Ultra Small)

struct AIBrainCompactStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.2), color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)

                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(color)
            }

            Spacer()

            // Value
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            // Title
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(10)
        .frame(height: 85)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: color.opacity(0.15), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [color.opacity(0.3), color.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
    }
}

// MARK: - Mini Category Chip (Ultra Compact)

struct MiniCategoryChip: View {
    let category: KnowledgeCategory?
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    private var chipColor: Color {
        if let category = category {
            return Color(hex: category.colorHex) ?? .blue
        }
        return .purple
    }

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            HStack(spacing: 4) {
                if let category = category {
                    Image(systemName: category.icon)
                        .font(.system(size: 9, weight: .semibold))
                } else {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 9, weight: .semibold))
                }

                Text(category?.localizedName ?? "Tümü")
                    .font(.system(size: 10, weight: .semibold))

                Text(String(localized: "text.count"))
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(isSelected ? .white.opacity(0.3) : chipColor.opacity(0.2))
                    )
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Group {
                    if isSelected {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [chipColor, chipColor.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: chipColor.opacity(0.4), radius: 6, x: 0, y: 3)
                    } else {
                        Capsule()
                            .fill(Color(.tertiarySystemBackground))
                    }
                }
            )
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ?
                            Color.clear :
                            chipColor.opacity(0.3),
                        lineWidth: 0.5
                    )
            )
            .foregroundStyle(isSelected ? .white : chipColor)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Hero Stat Card (Compact Featured Card)

struct HeroStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let gradient: [Color]

    var body: some View {
        HStack(spacing: 12) {
            // Left: Icon (Compact)
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.25), Color.white.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }

            // Right: Content (Compact)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .textCase(.uppercase)
                    .tracking(0.3)

                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                HStack(spacing: 3) {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 9, weight: .semibold))
                    Text(subtitle)
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(.white.opacity(0.75))
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: gradient.first?.opacity(0.3) ?? .black.opacity(0.15), radius: 10, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.25), Color.white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        )
    }
}

// MARK: - Secondary Stat Card (Compact Cards)

struct SecondaryStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header: Icon (Compact)
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.18), color.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(color)
            }

            Spacer()

            // Value (Compact)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            // Title + Trend (Compact)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                // Trend badge (Mini)
                Text(trend)
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(color.opacity(0.12))
                    )
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    LinearGradient(
                        colors: [color.opacity(0.15), color.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        )
    }
}

// MARK: - Modern Category Card (Compact)

struct ModernCategoryCard: View {
    let category: KnowledgeCategory?
    let isSelected: Bool
    let count: Int
    let confidence: Int
    let action: () -> Void

    private var cardColor: Color {
        if let category = category {
            return Color(hex: category.colorHex) ?? .purple
        }
        return .purple
    }

    private var categoryName: String {
        category?.localizedName ?? "Tümü"
    }

    private var categoryIcon: String {
        category?.icon ?? "square.grid.2x2.fill"
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 5) {
                // Header: Icon + Badge (Compact)
                HStack(spacing: 6) {
                    // Icon (Smaller)
                    ZStack {
                        Circle()
                            .fill(
                                isSelected
                                    ? Color.white.opacity(0.18)
                                    : cardColor.opacity(0.12)
                            )
                            .frame(width: 28, height: 28)

                        Image(systemName: categoryIcon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(
                                isSelected
                                    ? Color.white
                                    : cardColor
                            )
                    }

                    Spacer()

                    // Count Badge (Smaller)
                    Text(String(localized: "text.count"))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            isSelected
                                ? Color.white
                                : cardColor
                        )
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(
                                    isSelected
                                        ? Color.white.opacity(0.18)
                                        : cardColor.opacity(0.1)
                                )
                        )
                }

                // Title (Compact)
                Text(categoryName)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(
                        isSelected
                            ? Color.white
                            : Color.primary
                    )
                    .lineLimit(1)

                // Confidence Bar (Compact)
                HStack(spacing: 4) {
                    HStack(spacing: 1.5) {
                        ForEach(0..<5) { index in
                            Circle()
                                .fill(
                                    index < Int(Double(confidence) / 20.0)
                                        ? (isSelected ? Color.white : cardColor)
                                        : (isSelected ? Color.white.opacity(0.25) : Color(.systemGray5))
                                )
                                .frame(width: 5, height: 5)
                        }
                    }

                    Text(String(localized: "text.confidence"))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(
                            isSelected
                                ? Color.white.opacity(0.85)
                                : Color.secondary
                        )
                }
            }
            .padding(10)
            .frame(width: 110, height: 85)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        isSelected
                            ? LinearGradient(
                                colors: [cardColor, cardColor.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color(.secondarySystemBackground), Color(.tertiarySystemBackground)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .shadow(
                        color: isSelected ? cardColor.opacity(0.25) : Color.black.opacity(0.04),
                        radius: isSelected ? 10 : 5,
                        x: 0,
                        y: isSelected ? 3 : 1.5
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected
                            ? Color.white.opacity(0.18)
                            : cardColor.opacity(0.15),
                        lineWidth: isSelected ? 1.2 : 0.4
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Ultra Compact Knowledge Card

struct UltraCompactKnowledgeCard: View {
    let fact: UserKnowledge
    let onDelete: () -> Void
    let onConfirm: () -> Void

    private var categoryColor: Color {
        Color(hex: fact.categoryEnum.colorHex) ?? .blue
    }

    var body: some View {
        HStack(spacing: 10) {
            // Left: Category Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [categoryColor.opacity(0.2), categoryColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)

                Image(systemName: fact.categoryEnum.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(categoryColor)
            }

            // Center: Content
            VStack(alignment: .leading, spacing: 4) {
                // Key + Confidence inline
                HStack(spacing: 6) {
                    Text(fact.key)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Spacer()

                    // Confidence mini badge
                    HStack(spacing: 2) {
                        Image(systemName: fact.confidence >= 0.8 ? "star.fill" : "star.leadinghalf.filled")
                            .font(.system(size: 8))
                        Text(String(localized: "text.factconfidencepercentage"))
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(
                                fact.confidence >= 0.8 ?
                                    Color.orange.gradient :
                                    Color.gray.gradient
                            )
                    )
                }

                // Value
                Text(fact.value)
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                // Footer: Time + Source
                HStack(spacing: 4) {
                    Text(fact.timeAgo)
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)

                    Text("•")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)

                    Text(fact.sourceText)
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
            }

            // Right: Action Buttons
            VStack(spacing: 6) {
                Button {
                    HapticFeedback.success()
                    onConfirm()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.green.gradient)
                }

                Button {
                    HapticFeedback.warning()
                    onDelete()
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.red.gradient)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(categoryColor.opacity(0.2), lineWidth: 0.5)
        )
        .shadow(color: categoryColor.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 8)
    }
}

// MARK: - Empty State Info Row

struct EmptyStateInfoRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground))
        )
    }
}

// MARK: - Settings View (Placeholder)

struct AIBrainSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var privacyManager = KnowledgePrivacyManager.shared

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(
                        "Öğrenmeyi Etkinleştir",
                        isOn: Binding(
                            get: { privacyManager.isLearningEnabled },
                            set: { privacyManager.isLearningEnabled = $0 }
                        )
                    )
                } header: {
                    Text(String(localized: "privacy.knowledge.title", defaultValue: "Bilgi Öğrenme", comment: "Knowledge privacy title"))
                } footer: {
                    Text(String(localized: "privacy.knowledge.subtitle", defaultValue: "AI'ın senin hakkında ne öğrendiğini kontrol et", comment: "Knowledge privacy subtitle"))
                }

                Section(String(localized: "privacy.knowledge.categories", defaultValue: "Öğrenme Kategorileri", comment: "Learning categories")) {
                    ForEach(KnowledgeCategory.allCases, id: \.self) { category in
                        Toggle(
                            isOn: Binding(
                                get: { privacyManager.isCategoryAllowed(category) },
                                set: { _ in privacyManager.toggleCategory(category) }
                            )
                        ) {
                            Label(category.localizedName, systemImage: category.icon)
                        }
                    }
                }

                Section(String(localized: "privacy.knowledge.autoCleanup", defaultValue: "Otomatik Temizlik", comment: "Auto cleanup")) {
                    Picker("Temizlik Süresi", selection: Binding(
                        get: { privacyManager.autoCleanupDays },
                        set: { privacyManager.autoCleanupDays = $0 }
                    )) {
                        Text(String(localized: "ai.retention.off", comment: "Retention off")).tag(0)
                        Text(String(localized: "ai.retention.30days", comment: "30 days retention")).tag(30)
                        Text(String(localized: "ai.retention.60days", comment: "60 days retention")).tag(60)
                        Text(String(localized: "ai.retention.90days", comment: "90 days retention")).tag(90)
                    }
                }
            }
            .navigationTitle(String(localized: "knowledge.ai.brain.settings", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "button.ok", comment: "OK button")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    UserKnowledgeTabView()
        .modelContainer(for: [UserKnowledge.self])
}

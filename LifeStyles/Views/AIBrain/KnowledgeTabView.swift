//
//  KnowledgeTabView.swift
//  LifeStyles
//
//  Created by AI Assistant on 06.11.2025.
//  Universal Knowledge Tab - User + Entity Knowledge
//

import SwiftUI
import SwiftData

struct KnowledgeTabView: View {
    @Environment(\.modelContext) private var modelContext

    // Fetch UserKnowledge
    @Query(sort: \UserKnowledge.createdAt, order: .reverse)
    private var userKnowledge: [UserKnowledge]

    // Fetch EntityKnowledge
    @Query(sort: \EntityKnowledge.createdAt, order: .reverse)
    private var entityKnowledge: [EntityKnowledge]

    @State private var selectedFilter: KnowledgeFilter = .all
    @State private var selectedEntityType: EntityType? = nil
    @State private var searchText = ""
    @State private var showingSettings = false

    private var filteredKnowledge: [Any] {
        var combined: [Any] = []

        switch selectedFilter {
        case .all:
            combined = userKnowledge + entityKnowledge
        case .user:
            combined = userKnowledge
        case .entity:
            combined = entityKnowledge
        }

        // Entity type filter
        if let entityType = selectedEntityType {
            combined = combined.filter { item in
                if let entityKnow = item as? EntityKnowledge {
                    return entityKnow.entityTypeEnum == entityType
                }
                return false
            }
        }

        // Search filter
        if !searchText.isEmpty {
            combined = combined.filter { item in
                if let userKnow = item as? UserKnowledge {
                    return userKnow.key.localizedCaseInsensitiveContains(searchText) ||
                           userKnow.value.localizedCaseInsensitiveContains(searchText)
                } else if let entityKnow = item as? EntityKnowledge {
                    return entityKnow.key.localizedCaseInsensitiveContains(searchText) ||
                           entityKnow.value.localizedCaseInsensitiveContains(searchText) ||
                           (entityKnow.entityName?.localizedCaseInsensitiveContains(searchText) ?? false)
                }
                return false
            }
        }

        return combined
    }

    var body: some View {
        ZStack {
            if filteredKnowledge.isEmpty {
                emptyState
            } else {
                contentView
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            AIBrainSettingsView()
        }
        .searchable(text: $searchText, prompt: "Bilgi ara...")
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Statistics
                statisticsSection

                // Filter Pills
                filterSection

                // Entity Type Filter (if entity filter active)
                if selectedFilter == .entity || selectedFilter == .all {
                    entityTypeSection
                }

                // Knowledge List
                knowledgeListSection
            }
            .padding(.vertical)
        }
    }

    // MARK: - Statistics

    private var statisticsSection: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text(String(localized: "ai.learned.info", comment: "Learned information header"))
                    .font(.headline.weight(.bold))

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)

                    Text(String(localized: "ai.active", comment: "Active status"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)

            // Stats Grid
            HStack(spacing: 12) {
                KnowledgeStatCard(
                    title: "Kullanıcı",
                    value: "\(userKnowledge.count)",
                    icon: "person.fill",
                    color: .purple
                )

                KnowledgeStatCard(
                    title: "Varlıklar",
                    value: "\(entityKnowledge.count)",
                    icon: "square.stack.3d.up.fill",
                    color: .blue
                )

                KnowledgeStatCard(
                    title: "Toplam",
                    value: "\(userKnowledge.count + entityKnowledge.count)",
                    icon: "brain.head.profile",
                    color: .pink
                )
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(KnowledgeFilter.allCases, id: \.self) { filter in
                    FilterPill(
                        title: filter.title,
                        icon: filter.icon,
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedFilter = filter
                            if filter == .user {
                                selectedEntityType = nil
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Entity Type Section

    private var entityTypeSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All button
                FilterPill(
                    title: "Tümü",
                    icon: "square.grid.2x2",
                    isSelected: selectedEntityType == nil
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedEntityType = nil
                    }
                }

                ForEach(EntityType.allCases.filter { $0 != .other }, id: \.self) { type in
                    let count = entityKnowledge.filter { $0.entityTypeEnum == type }.count
                    if count > 0 {
                        FilterPill(
                            title: type.localizedName,
                            icon: type.icon,
                            count: count,
                            isSelected: selectedEntityType == type
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if selectedEntityType == type {
                                    selectedEntityType = nil
                                } else {
                                    selectedEntityType = type
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Knowledge List

    private var knowledgeListSection: some View {
        LazyVStack(spacing: 8) {
            ForEach(Array(filteredKnowledge.enumerated()), id: \.offset) { index, item in
                if let userKnow = item as? UserKnowledge {
                    UserKnowledgeCard(knowledge: userKnow) {
                        // Delete action
                        modelContext.delete(userKnow)
                        try? modelContext.save()
                    }
                } else if let entityKnow = item as? EntityKnowledge {
                    EntityKnowledgeCard(knowledge: entityKnow) {
                        // Delete action
                        modelContext.delete(entityKnow)
                        try? modelContext.save()
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 32) {
            // Animated brain icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.1), .blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 12) {
                Text(String(localized: "ai.doesnt.know.you", comment: "AI doesn't know you yet"))
                    .font(.title2.bold())

                Text(String(localized: "ai.chat.to.learn", comment: "Chat with AI to learn about you"))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // Quick tips
            VStack(alignment: .leading, spacing: 12) {
                EmptyStateTip(icon: "bubble.left.and.bubble.right.fill", text: "Sohbetler sekmesinden AI ile konuş")
                EmptyStateTip(icon: "person.fill", text: "Arkadaşların hakkında bilgi paylaş")
                EmptyStateTip(icon: "heart.fill", text: "Tercihlerini ve hedeflerini anlat")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
            .padding(.horizontal)
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }
}

// MARK: - Empty State Tip Component

struct EmptyStateTip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.purple)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer()
        }
    }
}

// MARK: - Knowledge Filter

enum KnowledgeFilter: String, CaseIterable {
    case all = "Tümü"
    case user = "Kullanıcı"
    case entity = "Varlıklar"

    var title: String { rawValue }
    var icon: String {
        switch self {
        case .all: return "square.stack.3d.up"
        case .user: return "person.fill"
        case .entity: return "cube.fill"
        }
    }
}

// MARK: - Knowledge Stat Card

struct KnowledgeStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
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
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(color)
            }
            .scaleEffect(isAnimating ? 1.0 : 0.8)
            .opacity(isAnimating ? 1.0 : 0.0)

            Spacer()

            // Value
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .offset(y: isAnimating ? 0 : 20)
                .opacity(isAnimating ? 1.0 : 0.0)

            // Title
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .offset(y: isAnimating ? 0 : 10)
                .opacity(isAnimating ? 1.0 : 0.0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 140)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: color.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [color.opacity(0.3), color.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Filter Pill

private struct FilterPill: View {
    let title: String
    let icon: String
    var count: Int? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))

                Text(title)
                    .font(.system(size: 13, weight: .semibold))

                if let count = count {
                    Text(String(localized: "text.count"))
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? .white.opacity(0.3) : Color(.tertiarySystemBackground))
                        )
                }
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? AnyShapeStyle(Color.purple.gradient) : AnyShapeStyle(Color(.secondarySystemBackground)))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - User Knowledge Card

struct UserKnowledgeCard: View {
    let knowledge: UserKnowledge
    let onDelete: () -> Void

    private var categoryColor: Color {
        Color(hex: knowledge.categoryEnum.colorHex) ?? .purple
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Icon with better design
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [categoryColor.opacity(0.2), categoryColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)

                    Image(systemName: knowledge.categoryEnum.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(categoryColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(String(localized: "ai.user", comment: "User label"))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [.purple, .blue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )

                        Text(knowledge.categoryEnum.localizedName)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }

                    Text(knowledge.timeAgo)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                // Confidence badge
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(categoryColor)

                    Text(String(localized: "text.knowledgeconfidencepercentage"))
                        .font(.caption.bold())
                        .foregroundStyle(categoryColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(categoryColor.opacity(0.15))
                )

                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
            }

            Divider()

            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(knowledge.key)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(knowledge.value)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: categoryColor.opacity(0.08), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    LinearGradient(
                        colors: [categoryColor.opacity(0.3), categoryColor.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Entity Knowledge Card

struct EntityKnowledgeCard: View {
    let knowledge: EntityKnowledge
    let onDelete: () -> Void

    private var categoryColor: Color {
        Color(hex: knowledge.categoryEnum.colorHex) ?? .blue
    }

    private var entityColor: Color {
        Color(hex: knowledge.entityTypeEnum.colorHex) ?? .blue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Icon with better design
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [entityColor.opacity(0.2), entityColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)

                    Image(systemName: knowledge.entityTypeEnum.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(entityColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(knowledge.entityTypeEnum.localizedName)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [entityColor, entityColor.opacity(0.7)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )

                        if let entityName = knowledge.entityName {
                            Text(entityName)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.primary)
                        }
                    }

                    HStack(spacing: 4) {
                        Image(systemName: knowledge.categoryEnum.icon)
                            .font(.system(size: 10))
                            .foregroundStyle(categoryColor)

                        Text(knowledge.categoryEnum.localizedName)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)

                        Text("·")
                            .foregroundStyle(.tertiary)

                        Text(knowledge.timeAgo)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                // Confidence badge
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(categoryColor)

                    Text(String(localized: "text.knowledgeconfidencepercentage"))
                        .font(.caption.bold())
                        .foregroundStyle(categoryColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(categoryColor.opacity(0.15))
                )

                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
            }

            Divider()

            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(knowledge.key)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(knowledge.value)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: entityColor.opacity(0.08), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    LinearGradient(
                        colors: [entityColor.opacity(0.3), entityColor.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

#Preview {
    KnowledgeTabView()
        .modelContainer(for: [UserKnowledge.self, EntityKnowledge.self])
}

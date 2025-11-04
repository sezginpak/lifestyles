//
//  AIBrainView.swift
//  LifeStyles
//
//  Created by AI Assistant on 04.11.2025.
//  AI Brain - Main tab view
//

import SwiftUI
import SwiftData

struct AIBrainView: View {
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
                            Label("Ayarlar", systemImage: "gearshape")
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
                Button("İptal", role: .cancel) {}
                Button("Sil", role: .destructive) {
                    viewModel.deleteAll(context: modelContext)
                }
            } message: {
                Text("AI'ın öğrendiği tüm bilgiler silinecek. Bu işlem geri alınamaz.")
            }
            .onAppear {
                viewModel.loadKnowledge(context: modelContext)
            }
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Statistics Cards
                statisticsSection

                // Category Filter
                categoryFilterSection

                // Search Bar
                searchSection

                // Knowledge List
                knowledgeListSection
            }
            .padding(.vertical)
        }
        .refreshable {
            viewModel.refresh(context: modelContext)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 8) {
                Text(String(localized: "aibrain.empty.title", defaultValue: "Henüz Öğrenilen Bilgi Yok", comment: "Empty state title"))
                    .font(.title2.bold())

                Text(String(localized: "aibrain.empty.subtitle", defaultValue: "AI ile sohbet et, seni tanımaya başlasın", comment: "Empty state subtitle"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                // Navigate to AI Chat
            } label: {
                Label("AI Chat'e Git", systemImage: "brain.head.profile")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
    }

    // MARK: - Statistics Section

    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("İstatistikler")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Total Facts
                    KnowledgeStatCard(
                        title: "Toplam Bilgi",
                        value: "\(viewModel.stats.totalFacts)",
                        icon: "brain.head.profile",
                        color: .purple
                    )

                    // Average Confidence
                    KnowledgeStatCard(
                        title: "Ortalama Güven",
                        value: "\(viewModel.stats.confidencePercentage)%",
                        icon: "star.fill",
                        color: .orange
                    )

                    // Categories
                    KnowledgeStatCard(
                        title: "Kategoriler",
                        value: "\(viewModel.stats.categoryCount)",
                        icon: "folder.fill",
                        color: .blue
                    )

                    // Recent
                    KnowledgeStatCard(
                        title: "Son 7 Gün",
                        value: "\(viewModel.stats.recentFactsCount)",
                        icon: "clock.fill",
                        color: .green
                    )
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Category Filter

    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All
                KnowledgeCategoryChip(
                    category: nil,
                    isSelected: viewModel.selectedCategory == nil,
                    count: viewModel.knowledge.count
                ) {
                    viewModel.selectedCategory = nil
                }

                // Categories
                ForEach(KnowledgeCategory.allCases, id: \.self) { category in
                    let count = viewModel.count(for: category)
                    if count > 0 {
                        KnowledgeCategoryChip(
                            category: category,
                            isSelected: viewModel.selectedCategory == category,
                            count: count
                        ) {
                            viewModel.selectedCategory = (viewModel.selectedCategory == category) ? nil : category
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Search Section

    private var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Ara...", text: $viewModel.searchText)
                .textFieldStyle(.plain)

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    // MARK: - Knowledge List

    private var knowledgeListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Bilgiler (\(viewModel.filteredKnowledge.count))")
                    .font(.headline)

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
                    Label("Sırala", systemImage: "arrow.up.arrow.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)

            // Grouped by category
            if viewModel.selectedCategory == nil {
                ForEach(Array(viewModel.groupedByCategory().keys.sorted(by: { $0.localizedName < $1.localizedName })), id: \.self) { category in
                    if let facts = viewModel.groupedByCategory()[category] {
                        Section {
                            ForEach(facts) { fact in
                                KnowledgeCard(
                                    fact: fact,
                                    onDelete: {
                                        viewModel.delete(fact, context: modelContext)
                                    },
                                    onConfirm: {
                                        viewModel.confirm(fact, context: modelContext)
                                    }
                                )
                            }
                        } header: {
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.localizedName)
                            }
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                    }
                }
            } else {
                // Single category view
                ForEach(viewModel.filteredKnowledge) { fact in
                    KnowledgeCard(
                        fact: fact,
                        onDelete: {
                            viewModel.delete(fact, context: modelContext)
                        },
                        onConfirm: {
                            viewModel.confirm(fact, context: modelContext)
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct KnowledgeStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }

            Text(value)
                .font(.title2.bold())

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(width: 140)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct KnowledgeCategoryChip: View {
    let category: KnowledgeCategory?
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let category = category {
                    Image(systemName: category.icon)
                        .font(.caption)
                }

                Text(category?.localizedName ?? "Tümü")
                    .font(.caption.weight(.medium))

                Text("(\(count))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected ?
                    Color.accentColor :
                    Color(.systemGray6)
            )
            .foregroundStyle(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

struct KnowledgeCard: View {
    let fact: UserKnowledge
    let onDelete: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: fact.categoryEnum.icon)
                    .foregroundStyle(Color(hex: fact.categoryEnum.colorHex) ?? .gray)

                Text(fact.categoryEnum.localizedName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Text(fact.timeAgo)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // Key-Value
            VStack(alignment: .leading, spacing: 4) {
                Text(fact.key)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                Text(fact.value)
                    .font(.body)
            }

            // Footer
            HStack {
                // Confidence
                HStack(spacing: 4) {
                    Image(systemName: fact.confidence >= 0.8 ? "star.fill" : "star")
                        .font(.caption2)
                    Text("\(fact.confidencePercentage)%")
                        .font(.caption2)
                }
                .foregroundStyle(.orange)

                // Source
                Text(fact.sourceText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                // Actions
                HStack(spacing: 12) {
                    Button {
                        onConfirm()
                    } label: {
                        Image(systemName: "checkmark.circle")
                            .foregroundStyle(.green)
                    }

                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
        .padding(.horizontal)
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
                        Text("Kapalı").tag(0)
                        Text("30 Gün").tag(30)
                        Text("60 Gün").tag(60)
                        Text("90 Gün").tag(90)
                    }
                }
            }
            .navigationTitle("AI Brain Ayarları")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Tamam") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AIBrainView()
        .modelContainer(for: [UserKnowledge.self])
}

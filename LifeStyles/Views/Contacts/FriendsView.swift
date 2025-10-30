//
//  FriendsView.swift
//  LifeStyles
//
//  Created by Claude on 16.10.2025.
//

import SwiftUI
import SwiftData

struct FriendsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = FriendsViewModel()
    @State private var showingAddSheet = false
    @State private var showingPhoneBookPicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Compact Stats Banner
                    compactStatsBanner
                        .padding(.horizontal)
                        .padding(.top, 4)

                    // Sort Picker
                    sortPicker
                        .padding(.horizontal)

                    // Relationship Type Filter
                    relationshipTypeFilter
                        .padding(.horizontal)

                    // Compact Friends List
                    if !viewModel.filteredFriends.isEmpty {
                        VStack(spacing: 8) {
                            ForEach(viewModel.filteredFriends) { friend in
                                SwipeableFriendRow(friend: friend, viewModel: viewModel)
                                    .padding(.horizontal)
                            }
                        }
                    } else if viewModel.friends.isEmpty {
                        // Boş durum
                        emptyState
                            .padding(.top, 40)
                    } else {
                        // Arama sonucu boş
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)

                            Text(String(localized: "common.no.results", comment: "No results found"))
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 40)
                    }
                }
                .padding(.bottom, 8)
            }
            .navigationTitle(String(localized: "friends.title", comment: "Friends"))
            .searchable(text: $viewModel.searchText, prompt: String(localized: "friends.search.placeholder", comment: "Search Friends"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingPhoneBookPicker = true
                    } label: {
                        Label(String(localized: "friends.pick.from.contacts", comment: "Pick from Contacts"), systemImage: "person.crop.circle.badge.plus")
                            .font(.caption)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.body)
                    }
                }
            }
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
            .sheet(isPresented: $showingAddSheet) {
                AddFriendView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingPhoneBookPicker) {
                PhoneBookPickerView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Compact Stats Banner

    private var compactStatsBanner: some View {
        HStack(spacing: 10) {
            // Acil
            HStack(spacing: 3) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
                Text("\(viewModel.friendsNeedingAttention)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.red)
                Text(String(localized: "common.urgent", comment: "Urgent"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .frame(height: 16)

            // Yakında
            HStack(spacing: 3) {
                Image(systemName: "clock.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Text("\(viewModel.friendsSoonCount)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.orange)
                Text(String(localized: "friends.coming.soon", comment: "Coming Soon"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .frame(height: 16)

            // Toplam
            HStack(spacing: 3) {
                Image(systemName: "person.2.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
                Text("\(viewModel.friends.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.blue)
                Text(String(localized: "common.total", comment: "Total"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Sort Picker

    private var sortPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FriendSortOption.allCases, id: \.self) { option in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.sortOption = option
                            HapticFeedback.light()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: option.icon)
                                .font(.caption)
                            Text(option.rawValue)
                                .font(.caption.weight(.medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(viewModel.sortOption == option
                                      ? Color.accentColor
                                      : Color(.tertiarySystemGroupedBackground))
                        )
                        .foregroundStyle(viewModel.sortOption == option
                                       ? .white
                                       : .primary)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.crop.square.stack")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 8) {
                Text(String(localized: "friends.empty.title", comment: "No Friends Added Yet"))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(String(localized: "friends.empty.message", comment: "Add your important friends and start tracking"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            HStack(spacing: 12) {
                Button {
                    showingPhoneBookPicker = true
                } label: {
                    Label("Rehberden Ekle", systemImage: "person.crop.circle.badge.plus")
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.bordered)

                Button {
                    showingAddSheet = true
                } label: {
                    Label("Manuel Ekle", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - Relationship Type Filter

    private var relationshipTypeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Tümü butonu
                FriendFilterChip(
                    title: String(localized: "friends.filter.all", comment: "All"),
                    emoji: "👥",
                    isSelected: viewModel.selectedRelationshipType == nil,
                    count: viewModel.friends.count
                ) {
                    withAnimation {
                        viewModel.selectedRelationshipType = nil
                    }
                }

                // Her relationship type için chip
                ForEach(RelationshipType.allCases, id: \.self) { type in
                    let count = viewModel.friendsForType(type).count
                    if count > 0 {
                        FriendFilterChip(
                            title: type.displayName,
                            emoji: type.emoji,
                            isSelected: viewModel.selectedRelationshipType == type,
                            count: count
                        ) {
                            withAnimation {
                                viewModel.selectedRelationshipType = type
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}


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
                VStack(spacing: 20) {
                    // Relationship Type Segmented Control
                    relationshipTypeFilter
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // Partner özel kartı (eğer partner varsa ve filtre partner'da ise)
                    if let partner = viewModel.partner,
                       viewModel.selectedRelationshipType == .partner || viewModel.selectedRelationshipType == nil {
                        PartnerHeroCard(partner: partner)
                            .padding(.horizontal)
                    }

                    // İstatistik Kartı
                    FriendsStatsCard(
                        needsAttention: viewModel.friendsNeedingAttention,
                        totalFriends: viewModel.friends.count,
                        importantFriends: viewModel.importantFriends.count
                    )
                    .padding(.horizontal)

                    // İletişim Gerekenlerin Listesi
                    if !viewModel.filteredFriends.filter({ $0.needsContact }).isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(String(localized: "friend.needs.contact", comment: "Needs contact"))
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)

                            ForEach(viewModel.filteredFriends.filter { $0.needsContact }) { friend in
                                NavigationLink(destination: FriendDetailView(friend: friend)) {
                                    FriendCard(friend: friend, viewModel: viewModel)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Tüm Arkadaşlar
                    if !viewModel.filteredFriends.filter({ !$0.needsContact }).isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(String(localized: "friend.all.friends", comment: "All friends"))
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)

                            ForEach(viewModel.filteredFriends.filter { !$0.needsContact }) { friend in
                                NavigationLink(destination: FriendDetailView(friend: friend)) {
                                    FriendCard(friend: friend, viewModel: viewModel)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Boş durum
                    if viewModel.friends.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "person.2.slash")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)

                            Text(String(localized: "friend.empty.title", comment: "No friends added yet"))
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            Text(String(localized: "friend.empty.message", comment: "Add important friends and track regular communication."))
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 60)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(String(localized: "friends.title", comment: "Friends"))
            .searchable(text: $viewModel.searchText, prompt: "Arkadaş Ara")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingPhoneBookPicker = true
                    } label: {
                        Label("Rehberden Seç", systemImage: "person.crop.circle.badge.plus")
                            .font(.subheadline)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
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

    // MARK: - Relationship Type Filter

    private var relationshipTypeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Tümü butonu
                FriendFilterChip(
                    title: "Tümü",
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


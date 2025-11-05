//
//  FriendDetailHistoryTab.swift
//  LifeStyles
//
//  Extracted from FriendDetailTabs.swift - Phase 5
//  History tab content showing contact history with friend
//

import SwiftUI
import SwiftData

struct FriendDetailHistoryTab: View {
    @Bindable var friend: Friend
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 16) {
            // Mini Calendar View
            if !sortedHistory.isEmpty {
                MiniCalendarView(history: sortedHistory)
            }

            // History List
            if !sortedHistory.isEmpty {
                VStack(spacing: 8) {
                    ForEach(sortedHistory) { item in
                        CompactHistoryCard(historyItem: item)
                            .padding(.horizontal)
                            .contextMenu {
                                Button(role: .destructive) {
                                    deleteHistory(item)
                                } label: {
                                    Label("Sil", systemImage: "trash")
                                }
                            }
                    }
                }
            } else {
                EmptyHistoryView()
            }
        }
        .padding(.vertical)
    }

    // MARK: - Helper Properties

    private var sortedHistory: [ContactHistory] {
        (friend.contactHistory ?? []).sorted(by: { $0.date > $1.date })
    }

    // MARK: - Actions

    private func deleteHistory(_ item: ContactHistory) {
        modelContext.delete(item)
        try? modelContext.save()
    }
}

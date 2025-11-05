//
//  FriendDetailPartnerTab.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Extracted from FriendDetailTabs.swift - Partner Tab Content
//

import SwiftUI

/// Partner tab içeriği - İlişki özel detayları
struct FriendDetailPartnerTab: View {
    @Bindable var friend: Friend

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // İlişki Timeline Widget
                if let _ = friend.relationshipStartDate {
                    PartnerRelationshipDurationCard(friend: friend)
                        .padding(.horizontal)
                }

                // Özel Günler
                SpecialDatesSection(friend: friend)
                    .padding(.horizontal)

                // Love Language Detayları
                if let _ = friend.loveLanguage {
                    LoveLanguageDetailCard(friend: friend)
                        .padding(.horizontal)
                }

                // Date Ideas
                DateIdeasSection(friend: friend)
                    .padding(.horizontal)

                // Partner Notes
                PartnerNotesSection(friend: friend)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

#Preview {
    FriendDetailPartnerTab(friend: .preview)
        .modelContainer(for: Friend.self)
}

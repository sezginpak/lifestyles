//
//  QuickContactLogView.swift
//  LifeStyles
//
//  Created by Claude on 06.11.2025.
//  Hızlı iletişim kaydı - Dashboard'dan hızlı erişim
//

import SwiftUI
import SwiftData

struct QuickContactLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var friends: [Friend] = []
    @State private var selectedFriend: Friend?
    @State private var contactDate = Date()
    @State private var contactNotes = ""
    @State private var contactMood: ContactMood = .good
    @State private var searchText = ""

    var filteredFriends: [Friend] {
        if searchText.isEmpty {
            return friends
        }
        return friends.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if selectedFriend == nil {
                    // Friend selection
                    friendSelectionView
                } else {
                    // Contact log form
                    contactLogForm
                }
            }
            .navigationTitle(String(localized: "contact.log.navigation.title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "button.cancel", comment: "Cancel button")) {
                        dismiss()
                    }
                }

                if selectedFriend != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(String(localized: "button.save", comment: "Save button")) {
                            saveContact()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .onAppear {
                loadFriends()
            }
        }
    }

    // MARK: - Friend Selection

    private var friendSelectionView: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField(String(localized: "dashboard.contact.search.placeholder", comment: "Search friend placeholder"), text: $searchText)
                    .textFieldStyle(.plain)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding()

            // Friends list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredFriends) { friend in
                        FriendRowButton(friend: friend) {
                            selectedFriend = friend
                            HapticFeedback.medium()
                        }
                    }
                }
                .padding()
            }

            if filteredFriends.isEmpty {
                emptyState
            }
        }
    }

    // MARK: - Contact Log Form

    private var contactLogForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Selected friend
                if let friend = selectedFriend {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(friend.name)
                                .font(.title2.bold())

                            if let phone = friend.phoneNumber {
                                Text(phone)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        Button {
                            selectedFriend = nil
                        } label: {
                            Text(String(localized: "quick.contact.change", comment: "Change"))
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                // Date picker
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "quick.contact.date", comment: "Date"))
                        .font(.headline)

                    DatePicker("", selection: $contactDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                }

                // Mood selection
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "quick.contact.quality", comment: "How was the meeting?"))
                        .font(.headline)

                    HStack(spacing: 12) {
                        ForEach([ContactMood.great, .good, .okay, .notGreat], id: \.self) { mood in
                            MoodButton(
                                mood: mood,
                                isSelected: contactMood == mood
                            ) {
                                contactMood = mood
                                HapticFeedback.light()
                            }
                        }
                    }
                }

                // Notes
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "quick.contact.notes.optional", comment: "Notes (Optional)"))
                        .font(.headline)

                    TextEditor(text: $contactNotes)
                        .frame(height: 120)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(String(localized: "quick.contact.no.friend", comment: "No Friend Found"))
                .font(.headline)

            Text(String(localized: "quick.contact.add.instruction", comment: "Add friends first"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Actions

    private func loadFriends() {
        let descriptor = FetchDescriptor<Friend>(sortBy: [SortDescriptor(\.name)])
        friends = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func saveContact() {
        guard let friend = selectedFriend else { return }

        // Create contact history
        let history = ContactHistory(
            date: contactDate,
            notes: contactNotes.isEmpty ? nil : contactNotes,
            mood: contactMood
        )

        // Add to friend
        if friend.contactHistory == nil {
            friend.contactHistory = []
        }
        friend.contactHistory?.append(history)
        friend.lastContactDate = contactDate

        // Save context
        try? modelContext.save()

        HapticFeedback.success()
        dismiss()
    }
}

// MARK: - Friend Row Button

struct FriendRowButton: View {
    let friend: Friend
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    if let emoji = friend.avatarEmoji {
                        Text(emoji)
                            .font(.title2)
                    } else {
                        Image(systemName: "person.fill")
                            .foregroundStyle(.blue)
                    }
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(friend.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if let lastContact = friend.lastContactDate {
                        let daysSince = Calendar.current.dateComponents([.day], from: lastContact, to: Date()).day ?? 0
                        Text(String(format: NSLocalizedString("quick.contact.days.ago.format", comment: "Days ago"), daysSince))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(String(localized: "quick.contact.never", comment: "Never contacted"))
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mood Button

struct MoodButton: View {
    let mood: ContactMood
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(mood.emoji)
                    .font(.title)

                Text(mood.label)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? mood.color.opacity(0.2) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? mood.color : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Contact Mood Extension

extension ContactMood {
    var emoji: String {
        switch self {
        case .great: return "😊"
        case .good: return "🙂"
        case .okay: return "😐"
        case .notGreat: return "😔"
        }
    }

    var label: String {
        switch self {
        case .great: return "Harika"
        case .good: return "İyi"
        case .okay: return "Normal"
        case .notGreat: return "Zor"
        }
    }

    var color: Color {
        switch self {
        case .great: return .green
        case .good: return .blue
        case .okay: return .orange
        case .notGreat: return .red
        }
    }
}

#Preview {
    QuickContactLogView()
}

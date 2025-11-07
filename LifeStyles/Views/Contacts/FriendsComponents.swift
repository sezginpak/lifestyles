//
//  FriendsComponents.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Refactored from FriendsView.swift - Supporting components
//

import SwiftUI
import SwiftData

// MARK: - Arkadaş Ekleme View

struct AddFriendView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: FriendsViewModel

    @State private var name: String = ""
    @State private var phoneNumber: String = ""
    @State private var selectedFrequency: ContactFrequency = .weekly
    @State private var isImportant: Bool = false
    @State private var notes: String = ""
    @State private var avatarEmoji: String = ""
    @State private var relationshipType: RelationshipType = .friend

    // Partner için özel alanlar
    @State private var relationshipStartDate: Date = Date()
    @State private var anniversaryDate: Date = Date()
    @State private var selectedLoveLanguage: LoveLanguage? = nil
    @State private var favoriteThings: String = ""

    // Duplicate error
    @State private var showDuplicateError: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "friends.relationship.type", comment: "Relationship Type")) {
                    Picker(String(localized: "friends.type", comment: "Type"), selection: $relationshipType) {
                        ForEach(RelationshipType.allCases, id: \.self) { type in
                            HStack {
                                Text(type.emoji)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section(String(localized: "friends.person.info", comment: "Person Info")) {
                    TextField(String(localized: "friends.name", comment: "Name"), text: $name)

                    TextField(String(localized: "friends.phone.optional", comment: "Phone (Optional)"), text: $phoneNumber)
                        .keyboardType(.phonePad)

                    TextField(String(localized: "friends.avatar.emoji.optional", comment: "Avatar Emoji (Optional)"), text: $avatarEmoji)
                        .font(.title2)
                }

                // Partner için özel bölümler
                if relationshipType == .partner {
                    Section(String(localized: "friends.relationship.info", comment: "Relationship Info")) {
                        DatePicker(String(localized: "friends.relationship.start", comment: "Relationship Start"), selection: $relationshipStartDate, displayedComponents: .date)

                        DatePicker(String(localized: "friends.anniversary.date", comment: "Anniversary Date"), selection: $anniversaryDate, displayedComponents: .date)
                    }

                    Section(String(localized: "friends.love.language", comment: "Love Language")) {
                        Picker(String(localized: "friends.love.language", comment: "Love Language"), selection: $selectedLoveLanguage) {
                            Text(String(localized: "friends.not.selected", comment: "Not Selected")).tag(nil as LoveLanguage?)
                            ForEach(LoveLanguage.allCases, id: \.self) { language in
                                HStack {
                                    Text(language.emoji)
                                    VStack(alignment: .leading) {
                                        Text(language.displayName)
                                        Text(language.description)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .tag(language as LoveLanguage?)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    Section {
                        TextEditor(text: $favoriteThings)
                            .frame(height: 80)
                    } header: {
                        Text(String(localized: "friends.favorite.things", comment: "Favorite Things"))
                    } footer: {
                        Text(String(localized: "friends.favorite.things.description", comment: "Favorite food, movies, activities etc."))
                    }
                }

                Section(String(localized: "friends.contact.frequency", comment: "Contact Frequency")) {
                    Picker(String(localized: "friends.frequency", comment: "Frequency"), selection: $selectedFrequency) {
                        ForEach(ContactFrequency.orderedCases, id: \.self) { freq in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(freq.displayName)
                                    .font(.subheadline)
                                Text(freq.shortDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .tag(freq)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    
                    if !selectedFrequency.description.isEmpty {
                        Text(selectedFrequency.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Toggle(String(localized: "friends.important.friend", comment: "Important Friend"), isOn: $isImportant)
                } footer: {
                    Text(String(localized: "friends.important.description", comment: "Important friends are shown prioritized in widgets"))
                }

                Section(String(localized: "friends.notes.optional", comment: "Notes (Optional)")) {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                }
            }
            .navigationTitle(String(localized: "friends.add.new", comment: "Add New Friend"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "common.cancel", comment: "Cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "common.save", comment: "Save")) {
                        let success = viewModel.addFriend(
                            name: name,
                            phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
                            frequency: selectedFrequency,
                            isImportant: isImportant,
                            notes: notes.isEmpty ? nil : notes,
                            avatarEmoji: avatarEmoji.isEmpty ? nil : avatarEmoji,
                            relationshipType: relationshipType,
                            relationshipStartDate: relationshipType == .partner ? relationshipStartDate : nil,
                            anniversaryDate: relationshipType == .partner ? anniversaryDate : nil,
                            loveLanguage: relationshipType == .partner ? selectedLoveLanguage : nil,
                            favoriteThings: relationshipType == .partner && !favoriteThings.isEmpty ? favoriteThings : nil
                        )

                        if success {
                            dismiss()
                        } else {
                            showDuplicateError = true
                            HapticFeedback.error()
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
            .alert(String(localized: "friends.duplicate.title", comment: "Duplicate Friend"), isPresented: $showDuplicateError) {
                Button(String(localized: "common.ok", comment: "OK"), role: .cancel) { }
            } message: {
                Text(String(localized: "friends.already.exists", comment: "Friend already exists validation"))
            }
        }
    }
}

// MARK: - Friend Stat Item

struct FriendStatItem: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(String(localized: "component.value", defaultValue: "\(value)", comment: "Generic value"))
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(color)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    FriendsView()
}

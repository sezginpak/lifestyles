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

    var body: some View {
        NavigationStack {
            Form {
                Section("İlişki Tipi") {
                    Picker("Tip", selection: $relationshipType) {
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

                Section("Kişi Bilgileri") {
                    TextField("İsim", text: $name)

                    TextField("Telefon (Opsiyonel)", text: $phoneNumber)
                        .keyboardType(.phonePad)

                    TextField("Avatar Emoji (Opsiyonel)", text: $avatarEmoji)
                        .font(.title2)
                }

                // Partner için özel bölümler
                if relationshipType == .partner {
                    Section("İlişki Bilgileri") {
                        DatePicker("İlişki Başlangıcı", selection: $relationshipStartDate, displayedComponents: .date)

                        DatePicker("Yıldönümü Tarihi", selection: $anniversaryDate, displayedComponents: .date)
                    }

                    Section("Sevgi Dili") {
                        Picker("Sevgi Dili", selection: $selectedLoveLanguage) {
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

                Section("İletişim Sıklığı") {
                    Picker("Sıklık", selection: $selectedFrequency) {
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
                    Toggle("Önemli Arkadaş", isOn: $isImportant)
                } footer: {
                    Text(String(localized: "friends.important.description", comment: "Important friends are shown prioritized in widgets"))
                }

                Section("Notlar (Opsiyonel)") {
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
                        viewModel.addFriend(
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
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
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
            Text("\(value)")
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

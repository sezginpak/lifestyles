//
//  UserProfileEditView.swift
//  LifeStyles
//
//  User Profile Edit Screen
//  Created by Claude on 22.10.2025.
//

import SwiftUI
import SwiftData

struct UserProfileEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var profile: UserProfile?
    @State private var name: String = ""
    @State private var ageString: String = ""
    @State private var occupation: String = ""
    @State private var bio: String = ""
    @State private var hobbies: [String] = []
    @State private var interests: [String] = []
    @State private var workSchedule: String = ""
    @State private var livingArrangement: String = ""
    @State private var lifeGoals: String = ""
    @State private var coreValues: [String] = []

    @State private var showHobbyInput = false
    @State private var showInterestInput = false
    @State private var showValueInput = false
    @State private var showSaveAlert = false

    let workScheduleOptions = [
        String(localized: "profile.work.schedule.9to5", comment: "9-5"),
        String(localized: "profile.work.schedule.flexible", comment: "Flexible"),
        String(localized: "profile.work.schedule.night", comment: "Night Shift"),
        String(localized: "profile.work.schedule.remote", comment: "Remote"),
        String(localized: "profile.work.schedule.parttime", comment: "Part-time")
    ]
    let livingArrangementOptions = [
        String(localized: "profile.living.alone", comment: "Alone"),
        String(localized: "profile.living.family", comment: "With Family"),
        String(localized: "profile.living.roommates", comment: "With Roommates"),
        String(localized: "profile.living.partner", comment: "With Partner")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color.backgroundPrimary,
                        Color.backgroundSecondary
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppConstants.Spacing.large) {
                        // Header with avatar
                        VStack(spacing: AppConstants.Spacing.medium) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient.primaryGradient)
                                    .frame(width: 100, height: 100)

                                Image(systemName: "person.fill")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.white)
                            }

                            Text(String(localized: "profile.my.info", comment: "My Profile Information"))
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(String(localized: "profile.ai.description", comment: "AI uses this information to provide better suggestions"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top)

                        // Basic Info Section
                        VStack(alignment: .leading, spacing: AppConstants.Spacing.small) {
                            Text(String(localized: "profile.basic.info", comment: "Basic Information"))
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .padding(.horizontal, AppConstants.Spacing.large)

                            VStack(spacing: AppConstants.Spacing.medium) {
                                ProfileTextField(
                                    icon: "person.fill",
                                    title: String(localized: "profile.name", comment: "Name"),
                                    placeholder: String(localized: "profile.name.placeholder", comment: "Your Name"),
                                    text: $name
                                )

                                ProfileTextField(
                                    icon: "calendar",
                                    title: String(localized: "profile.age", comment: "Age"),
                                    placeholder: "25",
                                    text: $ageString,
                                    keyboardType: .numberPad
                                )

                                ProfileTextField(
                                    icon: "briefcase.fill",
                                    title: String(localized: "profile.occupation", comment: "Occupation"),
                                    placeholder: String(localized: "profile.occupation.placeholder", comment: "Software Developer"),
                                    text: $occupation
                                )
                            }
                            .padding(.horizontal, AppConstants.Spacing.large)
                        }

                        // Bio Section
                        VStack(alignment: .leading, spacing: AppConstants.Spacing.small) {
                            Text(String(localized: "profile.about", comment: "About Me"))
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .padding(.horizontal, AppConstants.Spacing.large)

                            VStack(spacing: 0) {
                                TextEditor(text: $bio)
                                    .frame(minHeight: 100)
                                    .padding(AppConstants.Spacing.medium)
                                    .background(Color.surfaceSecondary)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppConstants.CornerRadius.medium)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                    .cornerRadius(AppConstants.CornerRadius.medium)
                            }
                            .padding(.horizontal, AppConstants.Spacing.large)
                        }

                        // Hobbies Section
                        VStack(alignment: .leading, spacing: AppConstants.Spacing.small) {
                            HStack {
                                Text(String(localized: "profile.hobbies", comment: "My Hobbies"))
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Spacer()

                                Button {
                                    showHobbyInput = true
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(Color.brandPrimary)
                                }
                            }
                            .padding(.horizontal, AppConstants.Spacing.large)

                            if hobbies.isEmpty {
                                Text(String(localized: "profile.hobbies.empty", comment: "You have no hobbies. Tap + to add"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, AppConstants.Spacing.large)
                            } else {
                                TagCloudView(tags: $hobbies)
                                    .padding(.horizontal, AppConstants.Spacing.large)
                            }
                        }

                        // Interests Section
                        VStack(alignment: .leading, spacing: AppConstants.Spacing.small) {
                            HStack {
                                Text(String(localized: "profile.interests", comment: "My Interests"))
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Spacer()

                                Button {
                                    showInterestInput = true
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(Color.brandPrimary)
                                }
                            }
                            .padding(.horizontal, AppConstants.Spacing.large)

                            if interests.isEmpty {
                                Text(String(localized: "profile.interests.empty", comment: "You have no interests. Tap + to add"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, AppConstants.Spacing.large)
                            } else {
                                TagCloudView(tags: $interests)
                                    .padding(.horizontal, AppConstants.Spacing.large)
                            }
                        }

                        // Lifestyle Section
                        VStack(alignment: .leading, spacing: AppConstants.Spacing.small) {
                            Text(String(localized: "profile.lifestyle", comment: "Lifestyle"))
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .padding(.horizontal, AppConstants.Spacing.large)

                            VStack(spacing: AppConstants.Spacing.medium) {
                                ProfilePickerField(
                                    icon: "clock.fill",
                                    title: String(localized: "profile.work.schedule", comment: "Work Schedule"),
                                    selection: $workSchedule,
                                    options: workScheduleOptions
                                )

                                ProfilePickerField(
                                    icon: "house.fill",
                                    title: String(localized: "profile.living.arrangement", comment: "Living Situation"),
                                    selection: $livingArrangement,
                                    options: livingArrangementOptions
                                )
                            }
                            .padding(.horizontal, AppConstants.Spacing.large)
                        }

                        // Life Goals Section
                        VStack(alignment: .leading, spacing: AppConstants.Spacing.small) {
                            Text(String(localized: "profile.life.goals", comment: "My Life Goals"))
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .padding(.horizontal, AppConstants.Spacing.large)

                            VStack(spacing: 0) {
                                TextEditor(text: $lifeGoals)
                                    .frame(minHeight: 100)
                                    .padding(AppConstants.Spacing.medium)
                                    .background(Color.surfaceSecondary)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppConstants.CornerRadius.medium)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                    .cornerRadius(AppConstants.CornerRadius.medium)
                            }
                            .padding(.horizontal, AppConstants.Spacing.large)
                        }

                        // Core Values Section
                        VStack(alignment: .leading, spacing: AppConstants.Spacing.small) {
                            HStack {
                                Text(String(localized: "profile.core.values", comment: "My Core Values"))
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Spacer()

                                Button {
                                    showValueInput = true
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(Color.brandPrimary)
                                }
                            }
                            .padding(.horizontal, AppConstants.Spacing.large)

                            if coreValues.isEmpty {
                                Text(String(localized: "profile.values.empty", comment: "You have no core values. Tap + to add"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, AppConstants.Spacing.large)
                            } else {
                                TagCloudView(tags: $coreValues)
                                    .padding(.horizontal, AppConstants.Spacing.large)
                            }
                        }

                        // Save Button
                        Button {
                            HapticFeedback.medium()
                            saveProfile()
                        } label: {
                            Text(String(localized: "common.save", comment: "Save"))
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(LinearGradient.primaryGradient)
                                .cornerRadius(AppConstants.CornerRadius.medium)
                        }
                        .padding(.horizontal, AppConstants.Spacing.large)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle(String(localized: "profile.my.profile", comment: "My Profile"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "common.close", comment: "Close")) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadProfile()
            }
            .sheet(isPresented: $showHobbyInput) {
                TagInputSheet(title: String(localized: "profile.add.hobby", comment: "Add Hobby"), tags: $hobbies)
            }
            .sheet(isPresented: $showInterestInput) {
                TagInputSheet(title: String(localized: "profile.add.interest", comment: "Add Interest"), tags: $interests)
            }
            .sheet(isPresented: $showValueInput) {
                TagInputSheet(title: String(localized: "profile.add.value", comment: "Add Core Value"), tags: $coreValues)
            }
            .alert(String(localized: "profile.saved", comment: "Profile Saved"), isPresented: $showSaveAlert) {
                Button(String(localized: "common.ok", comment: "OK"), role: .cancel) {
                    dismiss()
                }
            } message: {
                Text(String(localized: "profile.saved.message", comment: "Your profile has been saved successfully. AI can now provide more personalized suggestions."))
            }
        }
    }

    // MARK: - Data Methods

    private func loadProfile() {
        let descriptor = FetchDescriptor<UserProfile>()

        if let profiles = try? modelContext.fetch(descriptor),
           let existingProfile = profiles.first {
            profile = existingProfile

            // Load data
            name = existingProfile.name ?? ""
            ageString = existingProfile.age != nil ? String(existingProfile.age!) : ""
            occupation = existingProfile.occupation ?? ""
            bio = existingProfile.bio ?? ""
            hobbies = existingProfile.hobbies
            interests = existingProfile.interests
            workSchedule = existingProfile.workSchedule ?? ""
            livingArrangement = existingProfile.livingArrangement ?? ""
            lifeGoals = existingProfile.lifeGoals ?? ""
            coreValues = existingProfile.coreValues
        }
    }

    private func saveProfile() {
        if let existingProfile = profile {
            // Update existing profile
            existingProfile.name = name.isEmpty ? nil : name
            existingProfile.age = Int(ageString)
            existingProfile.occupation = occupation.isEmpty ? nil : occupation
            existingProfile.bio = bio.isEmpty ? nil : bio
            existingProfile.hobbies = hobbies
            existingProfile.interests = interests
            existingProfile.workSchedule = workSchedule.isEmpty ? nil : workSchedule
            existingProfile.livingArrangement = livingArrangement.isEmpty ? nil : livingArrangement
            existingProfile.lifeGoals = lifeGoals.isEmpty ? nil : lifeGoals
            existingProfile.coreValues = coreValues
            existingProfile.updateTimestamp()
        } else {
            // Create new profile
            let newProfile = UserProfile(
                name: name.isEmpty ? nil : name,
                age: Int(ageString),
                occupation: occupation.isEmpty ? nil : occupation,
                bio: bio.isEmpty ? nil : bio,
                hobbies: hobbies,
                interests: interests,
                workSchedule: workSchedule.isEmpty ? nil : workSchedule,
                livingArrangement: livingArrangement.isEmpty ? nil : livingArrangement,
                lifeGoals: lifeGoals.isEmpty ? nil : lifeGoals,
                coreValues: coreValues
            )
            modelContext.insert(newProfile)
        }

        do {
            try modelContext.save()
            showSaveAlert = true
        } catch {
            print("❌ Profil kaydedilemedi: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct ProfileTextField: View {
    let icon: String
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .padding()
                .background(Color.surfaceSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: AppConstants.CornerRadius.medium)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .cornerRadius(AppConstants.CornerRadius.medium)
        }
    }
}

struct ProfilePickerField: View {
    let icon: String
    let title: String
    @Binding var selection: String
    let options: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) {
                        selection = option
                    }
                }
            } label: {
                HStack {
                    Text(selection.isEmpty ? String(localized: "profile.picker.placeholder", comment: "Select") : selection)
                        .foregroundStyle(selection.isEmpty ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.surfaceSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: AppConstants.CornerRadius.medium)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .cornerRadius(AppConstants.CornerRadius.medium)
            }
        }
    }
}

struct TagCloudView: View {
    @Binding var tags: [String]

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                HStack(spacing: 4) {
                    Text(tag)
                        .font(.caption)
                        .foregroundStyle(.primary)

                    Button {
                        HapticFeedback.light()
                        tags.removeAll { $0 == tag }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.brandPrimary.opacity(0.1))
                .cornerRadius(16)
            }
        }
    }
}

struct TagInputSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    @Binding var tags: [String]
    @State private var newTag = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: AppConstants.Spacing.large) {
                TextField(String(localized: "profile.add.new", comment: "Add new"), text: $newTag)
                    .padding()
                    .background(Color.surfaceSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppConstants.CornerRadius.medium)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .cornerRadius(AppConstants.CornerRadius.medium)
                    .padding()
                    .onSubmit {
                        addTag()
                    }

                Button {
                    HapticFeedback.medium()
                    addTag()
                } label: {
                    Text(String(localized: "common.add", comment: "Add"))
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            newTag.isEmpty ?
                                AnyShapeStyle(Color.gray) :
                                AnyShapeStyle(LinearGradient.primaryGradient)
                        )
                        .cornerRadius(AppConstants.CornerRadius.medium)
                }
                .disabled(newTag.isEmpty)
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "common.close", comment: "Close")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !tags.contains(trimmed) {
            tags.append(trimmed)
            newTag = ""
            dismiss()
        }
    }
}

#Preview {
    UserProfileEditView()
}

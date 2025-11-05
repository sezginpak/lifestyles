//
//  DataUsageInfoSheet.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//

import SwiftUI

struct DataUsageInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var privacySettings = AIPrivacySettings.shared

    var body: some View {
        NavigationStack {
            List {
                if let dataCount = privacySettings.lastRequestDataCount {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.shield.fill")
                                    .foregroundStyle(.green)
                                Text(String(localized: "ai.data.last.request", comment: "Last AI Request"))
                                    .font(.headline)
                            }

                            Text(String(localized: "ai.data.used.for.response", comment: "Data used for this response:"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            if dataCount.friendsCount > 0 {
                                HStack {
                                    Image(systemName: "person.2.fill")
                                        .foregroundStyle(.blue)
                                        .frame(width: 24)
                                    Text(String(format: NSLocalizedString("ai.data.friends.count.format", comment: "Friend information count"), dataCount.friendsCount))
                                        .font(.callout)
                                }
                            }

                            if dataCount.goalsCount > 0 {
                                HStack {
                                    Image(systemName: "target")
                                        .foregroundStyle(.green)
                                        .frame(width: 24)
                                    Text(String(format: NSLocalizedString("ai.data.goals.count.format", comment: "Goals information count"), dataCount.goalsCount))
                                        .font(.callout)
                                }
                            }

                            if dataCount.habitsCount > 0 {
                                HStack {
                                    Image(systemName: "checkmark.circle")
                                        .foregroundStyle(.purple)
                                        .frame(width: 24)
                                    Text(String(format: NSLocalizedString("ai.data.habits.count.format", comment: "Habits information count"), dataCount.habitsCount))
                                        .font(.callout)
                                }
                            }

                            if dataCount.hasMoodData {
                                HStack {
                                    Image(systemName: "face.smiling")
                                        .foregroundStyle(.orange)
                                        .frame(width: 24)
                                    Text(String(localized: "ai.data.mood", comment: "Mood data"))
                                        .font(.callout)
                                }
                            }

                            if dataCount.hasLocationData {
                                HStack {
                                    Image(systemName: "location.fill")
                                        .foregroundStyle(.purple)
                                        .frame(width: 24)
                                    Text(String(localized: "ai.data.location", comment: "Location data"))
                                        .font(.callout)
                                }
                            }

                            if dataCount.totalItems == 0 && !dataCount.hasMoodData && !dataCount.hasLocationData {
                                HStack {
                                    Image(systemName: "exclamationmark.circle")
                                        .foregroundStyle(.orange)
                                        .frame(width: 24)
                                    Text(String(localized: "ai.data.not.shared", comment: "No data shared"))
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Text(dataCount.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .padding(.top, 4)
                        }
                    }
                }

                Section {
                    NavigationLink {
                        AIPrivacySettingsView()
                    } label: {
                        HStack {
                            Image(systemName: "gearshape.fill")
                                .foregroundStyle(.purple)
                            Text(String(localized: "ai.privacy.manage.settings", comment: "Manage Privacy Settings"))
                        }
                    }
                } header: {
                    Text(String(localized: "common.settings", comment: "Settings"))
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                            Text(String(localized: "ai.privacy.note.1", comment: "Your data is only used to generate AI responses"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                            Text(String(localized: "ai.privacy.note.2", comment: "Anthropic does not use your data for training"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                            Text(String(localized: "ai.privacy.note.3", comment: "You can control each data type separately"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text(String(localized: "ai.privacy.notes", comment: "Privacy Notes"))
                }
            }
            .navigationTitle(String(localized: "ai.data.usage", comment: "Data Usage"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.ok", comment: "OK")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    DataUsageInfoSheet()
}

//
//  LocationSettingsView.swift
//  LifeStyles
//
//  Created by Claude on 25.10.2025.
//  Konum ayarları merkezi sayfası
//

import SwiftUI
import SwiftData

struct LocationSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        List {
            Section {
                SettingsToggleRow(
                    icon: "location.fill",
                    title: String(localized: "Konum Takibi", comment: "Location Tracking"),
                    color: Color.cardActivity,
                    isOn: Binding(
                        get: { viewModel.locationTrackingEnabled },
                        set: { viewModel.toggleLocationTracking($0, context: modelContext) }
                    )
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } header: {
                Text(String(localized: "settings.general.settings", comment: "General Settings"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.none)
            }

            Section {
                NavigationLink {
                    SavedPlacesListView()
                } label: {
                    SettingsRow(
                        icon: "mappin.circle.fill",
                        title: String(localized: "Kayıtlı Yerler", comment: "Saved Places"),
                        color: Color.brandPrimary
                    )
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } header: {
                Text(String(localized: "settings.location.management", comment: "Location Management"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.none)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        Text(String(localized: "settings.location.permission", comment: "Location Permission"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    Text(String(localized: "settings.location.permission.desc", comment: "Location permission description"))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if viewModel.locationPermissionStatus != .authorized {
                        Button {
                            viewModel.openAppSettings()
                        } label: {
                            Text(String(localized: "settings.location.open.settings", comment: "Open Settings"))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.brandPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                }
                .padding()
            } header: {
                Text(String(localized: "settings.info", comment: "Info"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.none)
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "settings.privacy", comment: "Privacy"))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(String(localized: "settings.location.privacy.info", comment: "Location privacy info"))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack {
                        Image(systemName: "battery.100.bolt")
                            .foregroundStyle(.yellow)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "settings.battery.optimization", comment: "Battery Optimization"))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(String(localized: "settings.location.significant.changes", comment: "Significant changes info"))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
            } header: {
                Text(String(localized: "settings.location.features", comment: "Features"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.none)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(String(localized: "Konum Ayarları", comment: "Location Settings"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.checkPermissions()
        }
    }
}

#Preview {
    NavigationStack {
        LocationSettingsView()
    }
}

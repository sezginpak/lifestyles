//
//  HomeLocationPickerView.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//

import SwiftUI
import MapKit

struct HomeLocationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    private let locationService = LocationService.shared

    @State private var position: MapCameraPosition = .automatic
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var showConfirmation = false
    @State private var homeRadiusMeters: Double = 100

    var body: some View {
        ZStack {
            // Harita
            Map(position: $position) {
                // Mevcut konum
                if let current = locationService.currentLocation {
                    Marker("Şu Anki Konum", systemImage: "location.fill", coordinate: current.coordinate)
                        .tint(.blue)
                }

                // Seçilen ev konumu
                if let home = selectedCoordinate {
                    Marker("Ev", systemImage: "house.fill", coordinate: home)
                        .tint(.green)

                    // Ev yarıçapı
                    MapCircle(center: home, radius: homeRadiusMeters)
                        .foregroundStyle(.green.opacity(0.2))
                        .stroke(.green, lineWidth: 2)
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .onTapGesture { screenCoordinate in
                // Haritaya tıklandığında koordinat al
                // Not: iOS 17+ için doğrudan MapReader kullanabiliriz
            }

            // Üst bilgi kartı
            VStack {
                VStack(spacing: AppConstants.Spacing.medium) {
                    HStack {
                        Image(systemName: "house.fill")
                            .foregroundStyle(Color.brandPrimary)
                        Text("Ev Konumunu Ayarla")
                            .font(.headline)
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                                .font(.title3)
                        }
                    }

                    Text(String(localized: "location.home.instruction", comment: "Select your home location on the map or use your current location"))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Yarıçap ayarı
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(String(localized: "location.home.radius", comment: "Home Radius"))
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("\(Int(homeRadiusMeters)) metre")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.brandPrimary)
                        }

                        Slider(value: $homeRadiusMeters, in: 50...500, step: 50)
                            .tint(Color.brandPrimary)
                    }

                    Divider()

                    // Aksiyon butonları
                    HStack(spacing: AppConstants.Spacing.medium) {
                        Button {
                            useCurrentLocation()
                        } label: {
                            Label("Mevcut Konum", systemImage: "location.fill")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.brandSecondary.opacity(0.1))
                                .foregroundStyle(Color.brandSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.medium))
                        }

                        Button {
                            if selectedCoordinate != nil {
                                showConfirmation = true
                            }
                        } label: {
                            Label("Kaydet", systemImage: "checkmark")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(selectedCoordinate != nil ? Color.brandPrimary : Color.gray.opacity(0.3))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.medium))
                        }
                        .disabled(selectedCoordinate == nil)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.large))
                .padding()

                Spacer()
            }

            // Alt bilgi kartı - Mevcut ev konumu
            if let home = locationService.homeLocation {
                VStack {
                    Spacer()
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Mevcut Ev Konumu")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Lat: \(String(format: "%.4f", home.latitude)), Lon: \(String(format: "%.4f", home.longitude))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            selectedCoordinate = home
                            position = .region(MKCoordinateRegion(
                                center: home,
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            ))
                        } label: {
                            Text(String(localized: "common.show", comment: "Show"))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.brandPrimary)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.medium))
                    .padding()
                }
            }
        }
        .onAppear {
            // Mevcut ev konumunu yükle
            locationService.loadHomeLocation()
            if let home = locationService.homeLocation {
                selectedCoordinate = home
                position = .region(MKCoordinateRegion(
                    center: home,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
            } else if let current = locationService.currentLocation {
                position = .region(MKCoordinateRegion(
                    center: current.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
            }
        }
        .alert("Ev Konumu Kaydet?", isPresented: $showConfirmation) {
            Button("İptal", role: .cancel) {}
            Button("Kaydet") {
                saveHomeLocation()
            }
        } message: {
            Text(String(localized: "location.home.save.confirmation", comment: "This location will be saved as your home location"))
        }
    }

    // MARK: - Helper Functions

    private func useCurrentLocation() {
        guard let current = locationService.currentLocation else {
            return
        }

        selectedCoordinate = current.coordinate
        position = .region(MKCoordinateRegion(
            center: current.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))

        HapticFeedback.medium()
    }

    private func saveHomeLocation() {
        guard let coordinate = selectedCoordinate else {
            return
        }

        locationService.setHomeLocation(coordinate)
        HapticFeedback.success()
        dismiss()
    }
}

#Preview {
    HomeLocationPickerView()
}

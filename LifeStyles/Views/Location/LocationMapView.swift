//
//  LocationMapView.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Refactored from LocationView.swift - Map view and location cards
//

import SwiftUI
import SwiftData
import MapKit

// MARK: - Stats Item Compact

struct StatsItemCompact: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.callout)
                    .foregroundStyle(color)
            }

            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(uiColor: .systemBackground).opacity(0.5))
        )
    }
}

// MARK: - Modern Location Card Compact

struct ModernLocationCard: View {
    let log: LocationLog

    var body: some View {
        HStack(spacing: 10) {
            // Timeline Indicator
            VStack {
                Circle()
                    .fill(locationColor)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(locationColor.opacity(0.3), lineWidth: 3)
                    )

                Rectangle()
                    .fill(locationColor.opacity(0.2))
                    .frame(width: 2)
            }

            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(locationColor.opacity(0.15))
                            .frame(width: 32, height: 32)

                        Image(systemName: locationIcon)
                            .font(.caption)
                            .foregroundStyle(locationColor)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(log.timeOfDay)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        HStack(spacing: 4) {
                            Text(locationTypeText)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(locationColor)

                            if log.accuracy > 0 {
                                Text("•")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)

                                Text(String(format: "±%.0fm", log.accuracy))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                if let address = log.address, !address.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text(address)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .padding(.leading, 38)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(locationColor.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: locationColor.opacity(0.06), radius: 6, x: 0, y: 3)
    }

    private var locationIcon: String {
        switch log.locationType {
        case .home: return "house.fill"
        case .work: return "briefcase.fill"
        case .other: return "mappin"
        }
    }

    private var locationColor: Color {
        switch log.locationType {
        case .home: return .blue
        case .work: return .orange
        case .other: return .green
        }
    }

    private var locationTypeText: String {
        switch log.locationType {
        case .home: return String(localized: "location.type.home", comment: "Home location type")
        case .work: return String(localized: "location.type.work", comment: "Work location type")
        case .other: return String(localized: "location.type.outside", comment: "Outside location type")
        }
    }
}

// MARK: - Harita Görünümü

struct LocationMapView: View {
    let locations: [LocationLog]
    @Binding var selectedLog: LocationLog?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784), // İstanbul default
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var showRoute = true

    var sortedLocations: [LocationLog] {
        locations.sorted { $0.timestamp < $1.timestamp }
    }

    var totalDistance: Double {
        var distance: Double = 0
        for i in 0..<(sortedLocations.count - 1) {
            let loc1 = CLLocation(latitude: sortedLocations[i].latitude, longitude: sortedLocations[i].longitude)
            let loc2 = CLLocation(latitude: sortedLocations[i + 1].latitude, longitude: sortedLocations[i + 1].longitude)
            distance += loc1.distance(from: loc2)
        }
        return distance
    }

    var body: some View {
        Map(position: .constant(.region(region)), selection: $selectedLog) {
            // Rota çizgisi (Polyline)
            if showRoute && sortedLocations.count > 1 {
                MapPolyline(coordinates: sortedLocations.map { $0.coordinate })
                    .stroke(Color.brandPrimary.gradient, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            }

            // Konum pinleri
            ForEach(Array(sortedLocations.enumerated()), id: \.element.id) { index, log in
                Annotation(log.timeOfDay, coordinate: log.coordinate) {
                    ZStack {
                        Circle()
                            .fill(locationColor(for: log).gradient)
                            .frame(width: index == 0 ? 40 : (index == sortedLocations.count - 1 ? 40 : 32), height: index == 0 ? 40 : (index == sortedLocations.count - 1 ? 40 : 32))
                            .shadow(radius: index == 0 || index == sortedLocations.count - 1 ? 5 : 3)
                            .overlay {
                                if index == 0 {
                                    // Başlangıç pini
                                    Circle()
                                        .stroke(Color.white, lineWidth: 3)
                                } else if index == sortedLocations.count - 1 {
                                    // Bitiş pini
                                    Circle()
                                        .stroke(Color.white, lineWidth: 3)
                                }
                            }

                        Image(systemName: pinIcon(for: log, index: index))
                            .font(.system(size: index == 0 || index == sortedLocations.count - 1 ? 18 : 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .tag(log)
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .overlay(alignment: .topTrailing) {
            // Rota Toggle
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showRoute.toggle()
                    HapticFeedback.light()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: showRoute ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .font(.system(size: 16))
                    Text(showRoute ? String(localized: "route.on", comment: "Route display is on") : String(localized: "route.off", comment: "Route display is off"))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(showRoute ? Color.brandPrimary : Color.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }
            .padding()
        }
        .overlay(alignment: .topLeading) {
            // İstatistik Kartı
            if sortedLocations.count > 1 {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                            .font(.caption)
                            .foregroundStyle(Color.brandPrimary)
                        Text(String(localized: "total.distance", comment: "Total distance label"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Text(formatDistance(totalDistance))
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(String(format: NSLocalizedString("map.points.format", comment: "Number of points on map format"), sortedLocations.count))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 5)
                .padding()
            }
        }
        .overlay(alignment: .bottom) {
            if let log = selectedLog {
                LocationDetailCard(log: log, indexInRoute: sortedLocations.firstIndex(where: { $0.id == log.id }))
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            if !locations.isEmpty {
                // Tüm konumları içine alan region hesapla
                let coordinates = sortedLocations.map { $0.coordinate }
                let region = calculateRegion(for: coordinates)
                self.region = region
            }
        }
    }

    private func pinIcon(for log: LocationLog, index: Int) -> String {
        if index == 0 {
            return "figure.walk.arrival"
        } else if index == sortedLocations.count - 1 {
            return "flag.checkered"
        } else {
            return locationIcon(for: log)
        }
    }

    private func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return String(format: "%.0f m", meters)
        } else {
            return String(format: "%.2f km", meters / 1000)
        }
    }

    private func calculateRegion(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard !coordinates.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }

        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.5, 0.01),
            longitudeDelta: max((maxLon - minLon) * 1.5, 0.01)
        )

        return MKCoordinateRegion(center: center, span: span)
    }

    private func locationIcon(for log: LocationLog) -> String {
        switch log.locationType {
        case .home: return "house.fill"
        case .work: return "briefcase.fill"
        case .other: return "mappin"
        }
    }

    private func locationColor(for log: LocationLog) -> Color {
        switch log.locationType {
        case .home: return .blue
        case .work: return .orange
        case .other: return .green
        }
    }
}


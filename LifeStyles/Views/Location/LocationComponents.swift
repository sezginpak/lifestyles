//
//  LocationComponents.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Refactored from LocationView.swift - Detail cards and log rows
//

import SwiftUI
import MapKit

// MARK: - Konum Detay Kartı

struct LocationDetailCard: View {
    let log: LocationLog
    var indexInRoute: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(locationColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: locationIcon)
                        .font(.system(size: 18))
                        .foregroundStyle(locationColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(log.timeOfDay)
                            .font(.headline)

                        if let index = indexInRoute {
                            Text(String(format: NSLocalizedString("location.number.format", comment: "Number format with hash"), index + 1))
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.brandPrimary)
                                .clipShape(Capsule())
                        }
                    }

                    Text(locationTypeText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if log.accuracy > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(localized: "accuracy", comment: "Location accuracy label"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(String(format: "±%.0fm", log.accuracy))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }

            if let address = log.address, !address.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(address)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            HStack {
                Label(String(format: "%.5f", log.latitude), systemImage: "location.north")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Spacer()

                Label(String(format: "%.5f", log.longitude), systemImage: "location")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 10)
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

// MARK: - Konum Log Satırı

struct LocationLogRow: View {
    let log: LocationLog

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(locationColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: locationIcon)
                    .font(.system(size: 16))
                    .foregroundStyle(locationColor)
            }

            // Bilgiler
            VStack(alignment: .leading, spacing: 4) {
                Text(log.timeOfDay)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if let address = log.address, !address.isEmpty {
                    Text(address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    HStack(spacing: 8) {
                        Label(locationTypeText, systemImage: "mappin.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if log.accuracy > 0 {
                            Label(String(format: "±%.0fm", log.accuracy), systemImage: "scope")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
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

#Preview {
    LocationView()
}

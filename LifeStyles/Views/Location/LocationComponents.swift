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
    var groupInfo: GroupedLocationInfo?

    struct GroupedLocationInfo {
        let timeRange: String
        let durationText: String
        let durationColor: Color
        let durationIcon: String
        let recordCount: Int
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Üst: İkon ve Temel Bilgiler
            HStack(spacing: 12) {
                // Sol: Konum İkonu
                ZStack {
                    Circle()
                        .fill(locationColor.opacity(0.15))
                        .frame(width: 52, height: 52)

                    Image(systemName: locationIcon)
                        .font(.system(size: 22))
                        .foregroundStyle(locationColor)
                }

                // Orta: Zaman ve Tip Bilgisi
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(log.timeOfDay)
                            .font(.system(size: 18, weight: .bold))

                        if let index = indexInRoute {
                            HStack(spacing: 3) {
                                Image(systemName: "number")
                                    .font(.system(size: 9))
                                Text(String(localized: "component.index", defaultValue: "\(index + 1)", comment: "Index"))
                                    .font(.caption2)
                                    .fontWeight(.bold)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.brandPrimary.gradient)
                            .clipShape(Capsule())
                        }
                    }

                    HStack(spacing: 6) {
                        Text(locationTypeText)
                            .font(.caption)
                            .foregroundStyle(locationColor)
                            .fontWeight(.medium)

                        if let groupInfo = groupInfo {
                            Text("•")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            Text(String(localized: "location.record.count", defaultValue: "\(groupInfo.recordCount) records", comment: "Record count"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                // Sağ: Doğruluk
                if log.accuracy > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Image(systemName: "scope")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(String(format: "±%.0fm", log.accuracy))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                    }
                }
            }

            // Süre Bilgisi (Grup varsa)
            if let groupInfo = groupInfo {
                HStack(spacing: 10) {
                    Image(systemName: groupInfo.durationIcon)
                        .font(.callout)
                        .foregroundStyle(groupInfo.durationColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "location.stay.duration", comment: "Stay Duration"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 6) {
                            Text(groupInfo.timeRange)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)

                            Text(groupInfo.durationText)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(groupInfo.durationColor.gradient)
                                )
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(groupInfo.durationColor.opacity(0.08))
                )
            }

            // Adres
            if let address = log.address, !address.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(address)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Koordinatlar
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "location.north.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(String(format: "%.5f", log.latitude))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }

                HStack(spacing: 4) {
                    Image(systemName: "location.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(String(format: "%.5f", log.longitude))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
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
        case .work: return .purple
        case .other: return .cyan
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

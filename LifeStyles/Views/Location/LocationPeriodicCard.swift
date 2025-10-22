//
//  LocationPeriodicCard.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Refactored from LocationView.swift - Periodic tracking card
//

import SwiftUI

// MARK: - Periyodik Takip Kartı

struct PeriodicTrackingCard: View {
    let isActive: Bool
    let lastRecorded: String
    let totalRecorded: Int
    let onToggle: () -> Void
    let onViewHistory: () -> Void

    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header - Kompakt
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isActive ?
                                    [Color.blue, Color.cyan] :
                                    [Color.gray.opacity(0.5), Color.gray.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .glowEffect(color: isActive ? .blue : .gray, radius: isActive ? 8 : 0)

                    Image(systemName: "clock.arrow.circlepath")
                        .font(.callout)
                        .foregroundStyle(.white)
                        .symbolEffect(.pulse, value: isActive)
                }
                .scaleEffect(isAnimating ? 1.0 : 0.9)

                VStack(alignment: .leading, spacing: 3) {
                    Text(String(localized: "location.history", comment: "Location history title"))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue, Color.cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text(String(localized: "every.15.minutes", comment: "Location tracking frequency"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Toggle button
                Toggle("", isOn: Binding(
                    get: { isActive },
                    set: { _ in
                        HapticFeedback.medium()
                        onToggle()
                    }
                ))
                .labelsHidden()
                .tint(Color.brandPrimary)
            }

            if isActive {
                // İstatistikler - Kompakt Grid
                HStack(spacing: 12) {
                    // Toplam Kayıt
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 36, height: 36)

                            Image(systemName: "doc.text.fill")
                                .font(.callout)
                                .foregroundStyle(.blue)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(totalRecorded)")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.blue, Color.cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            Text(String(localized: "total.records", comment: "Total location records count label"))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.blue.opacity(0.08))
                    )

                    Spacer()

                    // Son Kayıt
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(String(localized: "last.record", comment: "Last location record label"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text(lastRecorded)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.trailing)
                    }
                }

                // Geçmişi Görüntüle Butonu - Kompakt
                Button {
                    HapticFeedback.medium()
                    onViewHistory()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "map.fill")
                            .font(.subheadline)

                        Text(String(localized: "view.history", comment: "View location history button"))
                            .fontWeight(.semibold)
                            .font(.subheadline)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: Color.blue.opacity(0.25), radius: 8, x: 0, y: 4)
                }
            } else {
                // Info message - Kompakt
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .font(.callout)
                        .foregroundStyle(.blue)

                    Text(String(localized: "location.tracking.info", comment: "Location tracking information message"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.blue.opacity(0.08))
                )
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: isActive ?
                                    [Color.blue.opacity(0.3), Color.cyan.opacity(0.3)] :
                                    [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .shadow(color: isActive ? Color.blue.opacity(0.12) : Color.gray.opacity(0.05), radius: 12, x: 0, y: 6)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isAnimating = true
            }
        }
    }
}


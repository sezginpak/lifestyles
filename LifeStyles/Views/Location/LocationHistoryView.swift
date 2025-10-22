//
//  LocationHistoryView.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Refactored from LocationView.swift - Location history view
//

import SwiftUI
import SwiftData

// MARK: - Konum Geçmişi View

struct LocationHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: LocationViewModel
    @State private var selectedDate = Date()
    @State private var groupedLogs: [Date: [LocationLog]] = [:]
    @State private var showingMap = false
    @State private var selectedLog: LocationLog?
    @State private var isAnimating = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Modern gradient background
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color.blue.opacity(0.03),
                        Color.cyan.opacity(0.03)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Kompakt Header
                    VStack(spacing: 12) {
                        // İstatistik Özeti - Kompakt
                        HStack(spacing: 8) {
                            StatsItemCompact(
                                icon: "doc.text.fill",
                                value: "\(viewModel.locationHistory.count)",
                                label: String(localized: "stats.records", comment: "Records stats label"),
                                color: .blue
                            )

                            StatsItemCompact(
                                icon: "house.fill",
                                value: "\(viewModel.locationHistory.filter { $0.locationType == .home }.count)",
                                label: String(localized: "stats.at.home", comment: "At home stats label"),
                                color: .green
                            )

                            StatsItemCompact(
                                icon: "mappin",
                                value: "\(viewModel.locationHistory.filter { $0.locationType == .other }.count)",
                                label: String(localized: "stats.outside", comment: "Outside stats label"),
                                color: .orange
                            )
                        }
                        .padding(.horizontal)

                        // Tarih ve Toggle - Kompakt
                        HStack(spacing: 10) {
                            DatePicker(
                                "",
                                selection: $selectedDate,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .tint(Color.brandPrimary)
                            .onChange(of: selectedDate) { _, newDate in
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    loadLocationsForDate(newDate)
                                }
                            }

                            Spacer()

                            // Kompakt Toggle
                            HStack(spacing: 6) {
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        showingMap = false
                                        HapticFeedback.light()
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "list.bullet")
                                            .font(.caption2)
                                        Text(String(localized: "view.list", comment: "List view toggle"))
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundStyle(!showingMap ? .white : .secondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        !showingMap ?
                                            LinearGradient(colors: [Color.blue, Color.cyan], startPoint: .leading, endPoint: .trailing) :
                                            LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing)
                                    )
                                    .clipShape(Capsule())
                                }

                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        showingMap = true
                                        HapticFeedback.light()
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "map")
                                            .font(.caption2)
                                        Text(String(localized: "view.map", comment: "Map view toggle"))
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundStyle(showingMap ? .white : .secondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        showingMap ?
                                            LinearGradient(colors: [Color.blue, Color.cyan], startPoint: .leading, endPoint: .trailing) :
                                            LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing)
                                    )
                                    .clipShape(Capsule())
                                }
                            }
                            .padding(3)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Capsule())
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)

                    // Content
                    if viewModel.locationHistory.isEmpty {
                        // Modern Empty State
                        VStack(spacing: 24) {
                            Spacer()

                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue.opacity(0.1), Color.cyan.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 120, height: 120)

                                Image(systemName: "location.slash")
                                    .font(.system(size: 50))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.blue, Color.cyan],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }

                            VStack(spacing: 12) {
                                Text(String(localized: "no.records.for.date", comment: "No location records for selected date"))
                                    .font(.title2)
                                    .fontWeight(.bold)

                                Text(String(localized: "no.records.for.date.message", comment: "No location records message"))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()
                        }
                        .padding()
                    } else {
                        if showingMap {
                            // Harita Görünümü
                            LocationMapView(
                                locations: viewModel.locationHistory,
                                selectedLog: $selectedLog
                            )
                        } else {
                            // Modern Liste Görünümü
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(sortedDateKeys, id: \.self) { date in
                                        VStack(alignment: .leading, spacing: 12) {
                                            // Section Header - Modern
                                            HStack(spacing: 8) {
                                                Image(systemName: "clock.fill")
                                                    .font(.caption)
                                                    .foregroundStyle(Color.brandPrimary)

                                                Text(formatSectionDate(date))
                                                    .font(.subheadline)
                                                    .fontWeight(.bold)
                                                    .foregroundStyle(.primary)

                                                Rectangle()
                                                    .fill(Color.secondary.opacity(0.2))
                                                    .frame(height: 1)
                                            }
                                            .padding(.horizontal)
                                            .padding(.top, 8)

                                            // Konum Kartları
                                            ForEach(groupedLogs[date] ?? []) { log in
                                                ModernLocationCard(log: log)
                                                    .padding(.horizontal)
                                                    .onTapGesture {
                                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                                            selectedLog = log
                                                            showingMap = true
                                                            HapticFeedback.light()
                                                        }
                                                    }
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical)
                            }
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "location.history", comment: "Location history title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .onAppear {
                loadLocationsForDate(selectedDate)
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                    isAnimating = true
                }
            }
        }
    }

    private var sortedDateKeys: [Date] {
        groupedLogs.keys.sorted(by: >)
    }

    private func loadLocationsForDate(_ date: Date) {
        viewModel.fetchLocationHistory(for: date)
        groupLocationsByHour()
    }

    private func groupLocationsByHour() {
        groupedLogs = Dictionary(grouping: viewModel.locationHistory) { log in
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day, .hour], from: log.timestamp)
            return calendar.date(from: components) ?? log.timestamp
        }
    }

    private func formatSectionDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:00"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
}


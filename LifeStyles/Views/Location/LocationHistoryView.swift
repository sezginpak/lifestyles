//
//  LocationHistoryView.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Refactored from LocationView.swift - Location history view
//

import SwiftUI
import SwiftData
import CoreLocation
import MapKit

// MARK: - Gruplu Konum (Aynı yerde kalma süresi)

struct GroupedLocation: Identifiable {
    let id = UUID()
    let logs: [LocationLog]
    let startTime: Date
    let endTime: Date
    let coordinate: CLLocationCoordinate2D
    let address: String?
    let locationType: LocationType

    // Süre hesaplama - LocationLog.durationInMinutes toplamını kullan (Daha doğru)
    var durationMinutes: Int {
        logs.reduce(0) { $0 + $1.durationInMinutes }
    }

    var duration: TimeInterval {
        TimeInterval(durationMinutes * 60)
    }

    var timeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "tr_TR")
        let start = formatter.string(from: startTime)

        // Tek kayıt ise sadece saati göster
        if logs.count == 1 || durationMinutes < 1 {
            return start
        }

        let end = formatter.string(from: endTime)
        return "\(start) - \(end)"
    }

    var durationText: String {
        // Tek kayıt veya 1 dakikadan az
        if logs.count == 1 {
            return "Anlık"
        }

        if durationMinutes < 1 {
            return "< 1dk"
        }

        let hours = durationMinutes / 60
        let mins = durationMinutes % 60

        if hours > 0 {
            if mins > 0 {
                return "\(hours)s \(mins)dk"
            } else {
                return "\(hours)s"
            }
        } else {
            return "\(mins)dk"
        }
    }

    // Süre bazlı renk kategorisi
    enum DurationCategory {
        case instant      // Anlık (< 1dk)
        case short        // Kısa (1-30dk)
        case medium       // Orta (30dk-2s)
        case long         // Uzun (> 2s)
    }

    var durationCategory: DurationCategory {
        if logs.count == 1 || durationMinutes < 1 {
            return .instant
        } else if durationMinutes < 30 {
            return .short
        } else if durationMinutes < 120 {
            return .medium
        } else {
            return .long
        }
    }

    var durationColor: Color {
        switch durationCategory {
        case .instant: return .gray
        case .short: return .orange
        case .medium: return .blue
        case .long: return .green
        }
    }

    var durationIcon: String {
        switch durationCategory {
        case .instant: return "clock.badge"
        case .short: return "clock"
        case .medium: return "clock.arrow.circlepath"
        case .long: return "clock.fill"
        }
    }
}

// MARK: - Konum Geçmişi View

struct LocationHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let viewModel: LocationViewModel
    @State private var selectedDate = Date()
    @State private var groupedLocations: [GroupedLocation] = []
    @State private var showingMap = false
    @State private var selectedLog: LocationLog?
    @State private var isAnimating = false

    // iPad Detection
    private var isIPad: Bool {
        horizontalSizeClass == .regular
    }

    // Adaptive Layout Helpers
    private var horizontalPadding: CGFloat {
        isIPad ? 32 : 16
    }

    private var cardSpacing: CGFloat {
        isIPad ? 20 : 12
    }

    private var gridColumns: [GridItem] {
        isIPad ? [
            GridItem(.flexible(), spacing: 20),
            GridItem(.flexible(), spacing: 20)
        ] : [
            GridItem(.flexible())
        ]
    }

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
                        .padding(.horizontal, horizontalPadding)

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
                            // Harita Görünümü (Gruplu)
                            GroupedLocationMapView(
                                groupedLocations: groupedLocations,
                                selectedLog: $selectedLog
                            )
                        } else {
                            // Modern Liste Görünümü - iPad'de 2 sütun
                            ScrollView {
                                LazyVGrid(columns: gridColumns, spacing: cardSpacing) {
                                    ForEach(groupedLocations) { group in
                                        GroupedLocationCard(group: group)
                                            .onTapGesture {
                                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                                    selectedLog = group.logs.first
                                                    showingMap = true
                                                    HapticFeedback.light()
                                                }
                                            }
                                    }
                                }
                                .padding(.horizontal, horizontalPadding)
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

    private func loadLocationsForDate(_ date: Date) {
        viewModel.fetchLocationHistory(for: date)
        groupLocationsByProximity()
    }

    private func groupLocationsByProximity() {
        let logs = viewModel.locationHistory.sorted { $0.timestamp < $1.timestamp } // Eskiden yeniye sırala
        var groups: [GroupedLocation] = []

        guard !logs.isEmpty else {
            groupedLocations = []
            return
        }

        var currentGroup: [LocationLog] = [logs[0]]

        for i in 1..<logs.count {
            let currentLog = logs[i]

            // Defensive: currentGroup her zaman en az 1 eleman içerir ama yine de kontrol et
            guard let previousLog = currentGroup.last else {
                currentGroup = [currentLog]
                continue
            }

            let location1 = CLLocation(latitude: previousLog.latitude, longitude: previousLog.longitude)
            let location2 = CLLocation(latitude: currentLog.latitude, longitude: currentLog.longitude)
            let distance = location1.distance(from: location2)

            // Aynı yerde mi? (Config threshold kullan)
            if distance < LocationConfiguration.sameLocationThreshold {
                currentGroup.append(currentLog)
            } else {
                // Yeni grup oluştur
                if let firstLog = currentGroup.first, let lastLog = currentGroup.last {
                    let group = GroupedLocation(
                        logs: currentGroup,
                        startTime: firstLog.timestamp,
                        endTime: lastLog.timestamp,
                        coordinate: firstLog.coordinate,
                        address: firstLog.address,
                        locationType: firstLog.locationType
                    )
                    groups.append(group)
                }
                currentGroup = [currentLog]
            }
        }

        // Son grubu ekle
        if let firstLog = currentGroup.first, let lastLog = currentGroup.last {
            let group = GroupedLocation(
                logs: currentGroup,
                startTime: firstLog.timestamp,
                endTime: lastLog.timestamp,
                coordinate: firstLog.coordinate,
                address: firstLog.address,
                locationType: firstLog.locationType
            )
            groups.append(group)
        }

        // En yeniden eskiye sırala
        groupedLocations = groups.sorted { $0.startTime > $1.startTime }
    }
}

// MARK: - Grouped Location Card

struct GroupedLocationCard: View {
    let group: GroupedLocation

    var body: some View {
        HStack(spacing: 14) {
            // Sol: Konum tipi ikonu ve renk çizgisi
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(locationColor(for: group.locationType).opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: locationIcon(for: group.locationType))
                        .font(.system(size: 20))
                        .foregroundStyle(locationColor(for: group.locationType))
                }

                // Süre kategorisi indikatörü
                Capsule()
                    .fill(group.durationColor.gradient)
                    .frame(width: 4)
            }

            // Sağ: Bilgiler
            VStack(alignment: .leading, spacing: 10) {
                // Üst: Zaman aralığı - Daha belirgin
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: group.durationIcon)
                            .font(.caption)
                            .foregroundStyle(group.durationColor)

                        Text(group.timeRange)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)

                        Spacer()

                        // Süre badge'i - Renkli
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                                .font(.system(size: 10))

                            Text(group.durationText)
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(group.durationColor.gradient)
                        )
                    }

                    // Konum tipi ve kayıt sayısı
                    HStack(spacing: 6) {
                        Text(locationTypeText(for: group.locationType))
                            .font(.caption)
                            .foregroundStyle(locationColor(for: group.locationType))
                            .fontWeight(.medium)

                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text(String(format: NSLocalizedString("location.records.count", comment: "Location records count"), group.logs.count))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Orta: Adres (varsa)
                if let address = group.address, !address.isEmpty {
                    HStack(spacing: 6) {
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

                // Alt: Koordinat ve doğruluk
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "location.circle")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)

                        Text(String(format: "%.4f, %.4f", group.coordinate.latitude, group.coordinate.longitude))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .monospacedDigit()
                    }

                    if let firstLog = group.logs.first, firstLog.accuracy > 0 {
                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: "scope")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)

                            Text(String(format: "±%.0fm", firstLog.accuracy))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    group.durationColor.opacity(0.3),
                                    group.durationColor.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: group.durationColor.opacity(0.15), radius: 8, y: 4)
        )
    }

    private func locationIcon(for type: LocationType) -> String {
        switch type {
        case .home: return "house.fill"
        case .work: return "briefcase.fill"
        case .other: return "mappin.circle.fill"
        }
    }

    private func locationColor(for type: LocationType) -> Color {
        switch type {
        case .home: return .blue
        case .work: return .purple
        case .other: return .cyan
        }
    }

    private func locationTypeText(for type: LocationType) -> String {
        switch type {
        case .home: return String(localized: "location.type.home", comment: "Home location type")
        case .work: return String(localized: "location.type.work", comment: "Work location type")
        case .other: return String(localized: "location.type.outside", comment: "Outside location type")
        }
    }
}

// MARK: - Grouped Location Map View

struct GroupedLocationMapView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let groupedLocations: [GroupedLocation]
    @Binding var selectedLog: LocationLog?
    @State private var region: MKCoordinateRegion = MKCoordinateRegion()
    @State private var showRoute = true
    @State private var selectedGroup: GroupedLocation?

    // iPad Detection
    private var isIPad: Bool {
        horizontalSizeClass == .regular
    }

    // Adaptive padding for overlay cards
    private var overlayPadding: CGFloat {
        isIPad ? 24 : 12
    }

    // Adaptive card width
    private var statsCardWidth: CGFloat? {
        isIPad ? 250 : nil
    }

    var sortedGroups: [GroupedLocation] {
        groupedLocations.sorted { $0.startTime < $1.startTime }
    }

    var totalDistance: Double {
        var distance: Double = 0
        for i in 0..<(sortedGroups.count - 1) {
            let loc1 = CLLocation(latitude: sortedGroups[i].coordinate.latitude, longitude: sortedGroups[i].coordinate.longitude)
            let loc2 = CLLocation(latitude: sortedGroups[i + 1].coordinate.latitude, longitude: sortedGroups[i + 1].coordinate.longitude)
            distance += loc1.distance(from: loc2)
        }
        return distance
    }

    var body: some View {
        Map(position: .constant(.region(region))) {
            // Rota çizgisi (Gruplar arası)
            if showRoute && sortedGroups.count > 1 {
                MapPolyline(coordinates: sortedGroups.map { $0.coordinate })
                    .stroke(Color.brandPrimary.gradient, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            }

            // Grup marker'ları
            ForEach(Array(sortedGroups.enumerated()), id: \.element.id) { index, group in
                Annotation(group.timeRange, coordinate: group.coordinate) {
                    VStack(spacing: 6) {
                        // Konum ikonu - Daha modern ve renkli
                        ZStack {
                            // Glow efekti
                            Circle()
                                .fill(group.durationColor.opacity(0.3))
                                .frame(width: index == 0 ? 60 : (index == sortedGroups.count - 1 ? 60 : 50),
                                       height: index == 0 ? 60 : (index == sortedGroups.count - 1 ? 60 : 50))
                                .blur(radius: 8)

                            Circle()
                                .fill(group.durationColor.gradient)
                                .frame(width: index == 0 ? 52 : (index == sortedGroups.count - 1 ? 52 : 42),
                                       height: index == 0 ? 52 : (index == sortedGroups.count - 1 ? 52 : 42))
                                .shadow(color: .black.opacity(0.25), radius: index == 0 || index == sortedGroups.count - 1 ? 8 : 6, y: 3)
                                .overlay {
                                    if index == 0 || index == sortedGroups.count - 1 {
                                        Circle()
                                            .stroke(Color.white, lineWidth: 3.5)
                                    } else {
                                        Circle()
                                            .stroke(Color.white.opacity(0.4), lineWidth: 2)
                                    }
                                }

                            Image(systemName: index == 0 ? "figure.walk.arrival" : (index == sortedGroups.count - 1 ? "flag.checkered" : locationIcon(for: group.locationType)))
                                .font(.system(size: index == 0 || index == sortedGroups.count - 1 ? 24 : 18, weight: .bold))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.3), radius: 2)
                        }

                        // Süre bilgisi - Daha bilgilendirici
                        VStack(spacing: 2) {
                            Text(group.timeRange)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.5), radius: 2)

                            HStack(spacing: 3) {
                                Image(systemName: group.durationIcon)
                                    .font(.system(size: 9))

                                Text(group.durationText)
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(group.durationColor.gradient)
                                    .shadow(color: .black.opacity(0.2), radius: 3)
                            )
                        }
                    }
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedLog = group.logs.first
                            selectedGroup = group
                            HapticFeedback.light()
                        }
                    }
                }
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
                    Text(showRoute ? "Rota Açık" : "Rota Kapalı")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(showRoute ? Color.brandPrimary : Color.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }
            .padding(overlayPadding)
        }
        .overlay(alignment: .topLeading) {
            // İstatistik Kartı
            if sortedGroups.count > 1 {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                            .font(.caption)
                            .foregroundStyle(Color.brandPrimary)
                        Text(String(localized: "location.total.distance", comment: "Total Distance"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Text(formatDistance(totalDistance))
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(String(localized: "text.sortedgroupscount.konum"))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(isIPad ? 16 : 12)
                .frame(minWidth: statsCardWidth)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 5)
                .padding(overlayPadding)
            }
        }
        .overlay(alignment: .bottom) {
            // Seçilen konum detay kartı
            if let log = selectedLog, let group = selectedGroup {
                LocationDetailCard(
                    log: log,
                    indexInRoute: sortedGroups.firstIndex(where: { $0.id == group.id }),
                    groupInfo: LocationDetailCard.GroupedLocationInfo(
                        timeRange: group.timeRange,
                        durationText: group.durationText,
                        durationColor: group.durationColor,
                        durationIcon: group.durationIcon,
                        recordCount: group.logs.count
                    )
                )
                .padding(overlayPadding)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            setCameraToShowAllLocations()
        }
    }

    private func setCameraToShowAllLocations() {
        guard !groupedLocations.isEmpty else { return }

        let coordinates = groupedLocations.map { $0.coordinate }
        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }

        guard let minLat = latitudes.min(),
              let maxLat = latitudes.max(),
              let minLon = longitudes.min(),
              let maxLon = longitudes.max() else { return }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: max(maxLat - minLat, 0.01) * 1.5,
            longitudeDelta: max(maxLon - minLon, 0.01) * 1.5
        )

        region = MKCoordinateRegion(center: center, span: span)
    }

    private func formatDistance(_ distance: Double) -> String {
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.2f km", distance / 1000)
        }
    }

    private func locationColor(for type: LocationType) -> Color {
        switch type {
        case .home: return .green
        case .work: return .blue
        case .other: return .orange
        }
    }

    private func locationIcon(for type: LocationType) -> String {
        switch type {
        case .home: return "house.fill"
        case .work: return "briefcase.fill"
        case .other: return "mappin.circle.fill"
        }
    }
}


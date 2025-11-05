//
//  CallReminderWidgetLiveActivity.swift
//  CallReminderWidget
//
//  Modern Live Activity widget with glassmorphism design
//

import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents

struct CallReminderWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CallReminderAttributes.self) { context in
            // Lock Screen görünümü
            ModernLockScreenView(context: context)
                .activityBackgroundTint(Color.clear)
                .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            // Dynamic Island görünümü
            DynamicIsland {
                // MARK: - Expanded View

                DynamicIslandExpandedRegion(.leading) {
                    // Sol taraf: Profil ve durum
                    HStack(spacing: 12) {
                        // Profil görünümü
                        ProfileAvatarView(context: context)
                            .frame(width: 56, height: 56)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(context.state.friendName)
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            StatusBadgeView(status: context.state.status)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    // Sağ taraf: Kalan süre
                    VStack(spacing: 6) {
                        // Büyük timer
                        Text(timeRemaining(from: context.state.reminderTime))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(gradientForStatus(context.state.status))

                        // Küçük etiket
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 10, weight: .medium))
                            Text(context.state.status == .overdue ? "geçti" : "kaldı")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                    }
                }

                DynamicIslandExpandedRegion(.center) {
                    EmptyView()
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 14) {
                        // Modern Progress Ring
                        ModernProgressRing(
                            progress: progressValue(from: context.state.reminderTime),
                            status: context.state.status
                        )
                        .frame(height: 6)

                        // Aksiyon butonları
                        ModernActionButtons(context: context)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
                }

            } compactLeading: {
                // Compact Leading - Profil
                CompactProfileView(context: context)

            } compactTrailing: {
                // Compact Trailing - Timer
                CompactTimerView(context: context)

            } minimal: {
                // Minimal - Sadece durum ikonu
                Image(systemName: iconForStatus(context.state.status))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(gradientForStatus(context.state.status))
                    .symbolEffect(.pulse, options: .repeating, value: context.state.status == .overdue)
            }
            .widgetURL(URL(string: "lifestyles://call-reminder/\(context.attributes.friendId)"))
            .keylineTint(colorForStatus(context.state.status))
        }
    }

    // MARK: - Helper Functions

    func timeRemaining(from date: Date) -> String {
        let diff = Int(date.timeIntervalSinceNow)

        if diff < 0 {
            let elapsed = abs(diff)
            let minutes = elapsed / 60
            let seconds = elapsed % 60
            return String(format: "+%02d:%02d", minutes, seconds)
        }

        let minutes = diff / 60
        let seconds = diff % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func progressValue(from date: Date) -> Double {
        let totalDuration: Double = 900
        let remaining = date.timeIntervalSinceNow

        if remaining <= 0 {
            return 1.0
        }

        let elapsed = totalDuration - remaining
        return min(max(elapsed / totalDuration, 0.0), 1.0)
    }

    func gradientForStatus(_ status: CallReminderAttributes.ContentState.ReminderStatus) -> LinearGradient {
        switch status {
        case .waiting:
            return LinearGradient(
                colors: [Color(red: 0.2, green: 0.5, blue: 1.0), Color(red: 0.4, green: 0.3, blue: 0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .overdue:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.3, blue: 0.3), Color(red: 1.0, green: 0.6, blue: 0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .calling:
            return LinearGradient(
                colors: [Color(red: 0.2, green: 0.8, blue: 0.5), Color(red: 0.3, green: 0.9, blue: 0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    func colorForStatus(_ status: CallReminderAttributes.ContentState.ReminderStatus) -> Color {
        switch status {
        case .waiting: return Color(red: 0.3, green: 0.5, blue: 1.0)
        case .overdue: return Color(red: 1.0, green: 0.3, blue: 0.3)
        case .calling: return Color(red: 0.2, green: 0.8, blue: 0.5)
        }
    }

    func iconForStatus(_ status: CallReminderAttributes.ContentState.ReminderStatus) -> String {
        switch status {
        case .waiting: return "phone.circle.fill"
        case .overdue: return "exclamationmark.triangle.fill"
        case .calling: return "phone.arrow.up.right.fill"
        }
    }
}

// MARK: - Modern Action Buttons

struct ModernActionButtons: View {
    let context: ActivityViewContext<CallReminderAttributes>

    var body: some View {
        HStack(spacing: 8) {
            // Ara butonu - Link kullanarak direkt telefonu aç
            if let phoneNumber = context.state.phoneNumber,
               !phoneNumber.isEmpty,
               let telURL = URL(string: "tel:\(phoneNumber)") {
                Link(destination: telURL) {
                    HStack(spacing: 4) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Ara")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.2, green: 0.8, blue: 0.5),
                                        Color(red: 0.3, green: 0.9, blue: 0.7)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color(red: 0.2, green: 0.8, blue: 0.5).opacity(0.3), radius: 4, y: 2)
                    )
                }
            }

            // Mesaj butonu - Link kullanarak direkt mesaj uygulamasını aç
            if let phoneNumber = context.state.phoneNumber,
               !phoneNumber.isEmpty,
               let smsURL = URL(string: "sms:\(phoneNumber)") {
                Link(destination: smsURL) {
                    HStack(spacing: 4) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Mesaj")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.2, green: 0.5, blue: 1.0),
                                        Color(red: 0.4, green: 0.6, blue: 1.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color(red: 0.2, green: 0.5, blue: 1.0).opacity(0.3), radius: 4, y: 2)
                    )
                }
            }

            // Tamamla butonu - AppIntent kullanarak widget'ı kapat
            Button(intent: CompleteCallIntent(friendId: context.attributes.friendId)) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Tamam")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.5, blue: 0.2),
                                    Color(red: 1.0, green: 0.3, blue: 0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color(red: 1.0, green: 0.4, blue: 0.2).opacity(0.3), radius: 4, y: 2)
                )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Profile Avatar View

struct ProfileAvatarView: View {
    let context: ActivityViewContext<CallReminderAttributes>

    var body: some View {
        ZStack {
            // Profil fotoğrafı veya emoji
            if let imageBase64 = context.attributes.profileImageBase64,
               let imageData = Data(base64Encoded: imageBase64),
               let uiImage = UIImage(data: imageData) {
                // Gerçek fotoğraf
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        colorForStatus(context.state.status),
                                        colorForStatus(context.state.status).opacity(0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                    )
                    .shadow(color: colorForStatus(context.state.status).opacity(0.3), radius: 8)
            } else {
                // Emoji fallback
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    colorForStatus(context.state.status).opacity(0.2),
                                    colorForStatus(context.state.status).opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            colorForStatus(context.state.status),
                                            colorForStatus(context.state.status).opacity(0.5)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 3
                                )
                        )

                    Text(context.attributes.friendEmoji ?? "👤")
                        .font(.system(size: 32))
                }
            }

            // Durum badge (küçük)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: iconForStatus(context.state.status))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(colorForStatus(context.state.status))
                                .shadow(radius: 3)
                        )
                        .symbolEffect(.pulse, options: .repeating, value: context.state.status == .overdue)
                }
            }
        }
    }

    func colorForStatus(_ status: CallReminderAttributes.ContentState.ReminderStatus) -> Color {
        switch status {
        case .waiting: return Color(red: 0.3, green: 0.5, blue: 1.0)
        case .overdue: return Color(red: 1.0, green: 0.3, blue: 0.3)
        case .calling: return Color(red: 0.2, green: 0.8, blue: 0.5)
        }
    }

    func iconForStatus(_ status: CallReminderAttributes.ContentState.ReminderStatus) -> String {
        switch status {
        case .waiting: return "phone.circle.fill"
        case .overdue: return "exclamationmark.triangle.fill"
        case .calling: return "phone.arrow.up.right.fill"
        }
    }
}

// MARK: - Status Badge View

struct StatusBadgeView: View {
    let status: CallReminderAttributes.ContentState.ReminderStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconForStatus)
                .font(.system(size: 11, weight: .semibold))
            Text(statusText)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(gradientForStatus)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(colorForStatus.opacity(0.15))
        )
    }

    var statusText: String {
        switch status {
        case .waiting: return "Bekliyor"
        case .overdue: return "Gecikti"
        case .calling: return "Aranıyor"
        }
    }

    var iconForStatus: String {
        switch status {
        case .waiting: return "clock.fill"
        case .overdue: return "exclamationmark.circle.fill"
        case .calling: return "phone.fill"
        }
    }

    var gradientForStatus: LinearGradient {
        switch status {
        case .waiting:
            return LinearGradient(
                colors: [Color(red: 0.2, green: 0.5, blue: 1.0), Color(red: 0.4, green: 0.3, blue: 0.9)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .overdue:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.3, blue: 0.3), Color(red: 1.0, green: 0.6, blue: 0.2)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .calling:
            return LinearGradient(
                colors: [Color(red: 0.2, green: 0.8, blue: 0.5), Color(red: 0.3, green: 0.9, blue: 0.7)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    var colorForStatus: Color {
        switch status {
        case .waiting: return Color(red: 0.3, green: 0.5, blue: 1.0)
        case .overdue: return Color(red: 1.0, green: 0.3, blue: 0.3)
        case .calling: return Color(red: 0.2, green: 0.8, blue: 0.5)
        }
    }
}

// MARK: - Modern Progress Ring

struct ModernProgressRing: View {
    let progress: Double
    let status: CallReminderAttributes.ContentState.ReminderStatus

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Arka plan
                Capsule()
                    .fill(Color.secondary.opacity(0.15))
                    .frame(height: 6)

                // Dolum
                Capsule()
                    .fill(gradientForStatus)
                    .frame(width: geometry.size.width * progress, height: 6)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress)
                    .shadow(color: colorForStatus.opacity(0.4), radius: 4, y: 2)
            }
        }
        .frame(height: 6)
    }

    var gradientForStatus: LinearGradient {
        switch status {
        case .waiting:
            return LinearGradient(
                colors: [Color(red: 0.2, green: 0.5, blue: 1.0), Color(red: 0.4, green: 0.3, blue: 0.9)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .overdue:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.3, blue: 0.3), Color(red: 1.0, green: 0.6, blue: 0.2)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .calling:
            return LinearGradient(
                colors: [Color(red: 0.2, green: 0.8, blue: 0.5), Color(red: 0.3, green: 0.9, blue: 0.7)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    var colorForStatus: Color {
        switch status {
        case .waiting: return Color(red: 0.3, green: 0.5, blue: 1.0)
        case .overdue: return Color(red: 1.0, green: 0.3, blue: 0.3)
        case .calling: return Color(red: 0.2, green: 0.8, blue: 0.5)
        }
    }
}

// MARK: - Compact Profile View

struct CompactProfileView: View {
    let context: ActivityViewContext<CallReminderAttributes>

    var body: some View {
        ZStack {
            Circle()
                .fill(gradientForStatus)
                .frame(width: 24, height: 24)

            if let emoji = context.attributes.friendEmoji {
                Text(emoji)
                    .font(.system(size: 14))
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
    }

    var gradientForStatus: LinearGradient {
        let status = context.state.status
        switch status {
        case .waiting:
            return LinearGradient(
                colors: [Color(red: 0.2, green: 0.5, blue: 1.0), Color(red: 0.4, green: 0.3, blue: 0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .overdue:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.3, blue: 0.3), Color(red: 1.0, green: 0.6, blue: 0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .calling:
            return LinearGradient(
                colors: [Color(red: 0.2, green: 0.8, blue: 0.5), Color(red: 0.3, green: 0.9, blue: 0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Compact Timer View

struct CompactTimerView: View {
    let context: ActivityViewContext<CallReminderAttributes>

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock.fill")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(gradientForStatus)

            Text(timeRemainingShort)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(gradientForStatus)
        }
    }

    var timeRemainingShort: String {
        let diff = Int(context.state.reminderTime.timeIntervalSinceNow)

        if diff < 0 {
            return "GEÇTİ"
        }

        if diff < 60 {
            return "\(diff)s"
        }

        let minutes = diff / 60
        return "\(minutes)m"
    }

    var gradientForStatus: LinearGradient {
        let status = context.state.status
        switch status {
        case .waiting:
            return LinearGradient(
                colors: [Color(red: 0.2, green: 0.5, blue: 1.0), Color(red: 0.4, green: 0.3, blue: 0.9)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .overdue:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.3, blue: 0.3), Color(red: 1.0, green: 0.6, blue: 0.2)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .calling:
            return LinearGradient(
                colors: [Color(red: 0.2, green: 0.8, blue: 0.5), Color(red: 0.3, green: 0.9, blue: 0.7)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}

// MARK: - Modern Lock Screen View

struct ModernLockScreenView: View {
    let context: ActivityViewContext<CallReminderAttributes>

    var body: some View {
        HStack(spacing: 16) {
            // Sol: Profil
            ProfileAvatarView(context: context)
                .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 8) {
                // İsim ve durum
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.state.friendName)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    StatusBadgeView(status: context.state.status)
                }

                // Timer ve progress
                HStack(spacing: 12) {
                    // Timer
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 14, weight: .medium))
                        Text(timeRemaining)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .monospacedDigit()
                    }
                    .foregroundStyle(gradientForStatus)

                    Spacer()

                    // Progress percentage
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(gradientForStatus)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.secondary.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            colorForStatus.opacity(0.3),
                            colorForStatus.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    var timeRemaining: String {
        let diff = Int(context.state.reminderTime.timeIntervalSinceNow)

        if diff < 0 {
            let elapsed = abs(diff)
            let minutes = elapsed / 60
            let seconds = elapsed % 60
            return String(format: "+%02d:%02d", minutes, seconds)
        }

        let minutes = diff / 60
        let seconds = diff % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var progress: Double {
        let totalDuration: Double = 900
        let remaining = context.state.reminderTime.timeIntervalSinceNow

        if remaining <= 0 {
            return 1.0
        }

        let elapsed = totalDuration - remaining
        return min(max(elapsed / totalDuration, 0.0), 1.0)
    }

    var gradientForStatus: LinearGradient {
        switch context.state.status {
        case .waiting:
            return LinearGradient(
                colors: [Color(red: 0.2, green: 0.5, blue: 1.0), Color(red: 0.4, green: 0.3, blue: 0.9)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .overdue:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.3, blue: 0.3), Color(red: 1.0, green: 0.6, blue: 0.2)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .calling:
            return LinearGradient(
                colors: [Color(red: 0.2, green: 0.8, blue: 0.5), Color(red: 0.3, green: 0.9, blue: 0.7)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    var colorForStatus: Color {
        switch context.state.status {
        case .waiting: return Color(red: 0.3, green: 0.5, blue: 1.0)
        case .overdue: return Color(red: 1.0, green: 0.3, blue: 0.3)
        case .calling: return Color(red: 0.2, green: 0.8, blue: 0.5)
        }
    }
}

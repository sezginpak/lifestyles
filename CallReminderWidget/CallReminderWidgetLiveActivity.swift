//
//  CallReminderWidgetLiveActivity.swift
//  CallReminderWidget
//
//  Live Activity widget for call reminders
//

import ActivityKit
import WidgetKit
import SwiftUI

struct CallReminderWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CallReminderAttributes.self) { context in
            // Lock Screen görünümü
            CallReminderLockScreenView(context: context)
                .activityBackgroundTint(Color.clear)
                .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            // Dynamic Island görünümü
            DynamicIsland {
                // Expanded (genişletilmiş) görünüm
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 12) {
                        // Animasyonlu ikon
                        ZStack {
                            Circle()
                                .fill(gradientForStatus(context.state.status))
                                .frame(width: 50, height: 50)
                                .shadow(color: colorForStatus(context.state.status).opacity(0.4), radius: 8)

                            Image(systemName: iconForStatus(context.state.status))
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(.white)
                                .symbolEffect(.pulse, options: .repeating, value: context.state.status == .overdue)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(context.state.friendName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)

                            Text(statusText(context.state.status))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(gradientForStatus(context.state.status))
                        }
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(spacing: 8) {
                        // Profil fotoğrafı veya emoji
                        if let imageBase64 = context.attributes.profileImageBase64,
                           let imageData = Data(base64Encoded: imageBase64),
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(gradientForStatus(context.state.status), lineWidth: 2)
                                )
                                .shadow(color: colorForStatus(context.state.status).opacity(0.3), radius: 6)
                        } else {
                            // Fallback: Emoji avatar
                            Text(context.attributes.friendEmoji ?? "👤")
                                .font(.system(size: 36))
                                .shadow(radius: 4)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.center) {
                    EmptyView()
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 12) {
                        // Progress Bar
                        ProgressBarView(
                            progress: progressValue(from: context.state.reminderTime),
                            status: context.state.status
                        )

                        // Kalan süre
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 14))
                            Text(timeRemaining(from: context.state.reminderTime))
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .monospacedDigit()
                        }
                        .foregroundStyle(gradientForStatus(context.state.status))
                        .shadow(color: colorForStatus(context.state.status).opacity(0.3), radius: 4)

                        // Hızlı Aksiyon Butonları
                        HStack(spacing: 8) {
                            // Ara butonu
                            if let phoneNumber = context.state.phoneNumber, !phoneNumber.isEmpty {
                                Link(destination: URL(string: "tel:\(phoneNumber)")!) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "phone.fill")
                                            .font(.system(size: 12))
                                        Text("Ara")
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.green, Color.mint],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(10)
                                }
                            }

                            // Mesaj butonu
                            if let phoneNumber = context.state.phoneNumber, !phoneNumber.isEmpty {
                                Link(destination: URL(string: "sms:\(phoneNumber)")!) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "message.fill")
                                            .font(.system(size: 12))
                                        Text("Mesaj")
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.blue, Color.cyan],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(10)
                                }
                            }

                            // Tamamla butonu
                            Link(destination: URL(string: "lifestyles://complete-call/\(context.attributes.friendId)")!) {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                    Text("Tamam")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    LinearGradient(
                                        colors: [Color.orange, Color.red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .padding(.vertical, 12)
                }

            } compactLeading: {
                // Compact Leading - animasyonlu ikon
                ZStack {
                    Circle()
                        .fill(gradientForStatus(context.state.status))
                        .frame(width: 24, height: 24)

                    Image(systemName: iconForStatus(context.state.status))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .symbolEffect(.pulse, options: .repeating, value: context.state.status == .overdue)
                }
            } compactTrailing: {
                // Compact Trailing - mini progress
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(gradientForStatus(context.state.status))

                    Text(timeRemainingShort(from: context.state.reminderTime))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(gradientForStatus(context.state.status))
                }
            } minimal: {
                // Minimal - sadece durum ikonu
                Image(systemName: iconForStatus(context.state.status))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(gradientForStatus(context.state.status))
                    .symbolEffect(.pulse, options: .repeating, value: context.state.status == .overdue)
            }
            .widgetURL(URL(string: "lifestyles://call-reminder/\(context.attributes.friendId)"))
            .keylineTint(colorForStatus(context.state.status))
        }
    }

    // MARK: - Helper Functions

    // Kalan süreyi hesapla (uzun format: MM:SS)
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

    // Kalan süreyi hesapla (kısa format: Xm veya Xs)
    func timeRemainingShort(from date: Date) -> String {
        let diff = Int(date.timeIntervalSinceNow)

        if diff < 0 {
            return "GEÇTİ"
        }

        if diff < 60 {
            return "\(diff)s"
        }

        let minutes = diff / 60
        return "\(minutes)m"
    }

    // Durum için gradient renk
    func gradientForStatus(_ status: CallReminderAttributes.ContentState.ReminderStatus) -> LinearGradient {
        switch status {
        case .waiting:
            return LinearGradient(
                colors: [Color.blue, Color.purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .overdue:
            return LinearGradient(
                colors: [Color.orange, Color.red],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .calling:
            return LinearGradient(
                colors: [Color.green, Color.mint],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // Durum için ana renk
    func colorForStatus(_ status: CallReminderAttributes.ContentState.ReminderStatus) -> Color {
        switch status {
        case .waiting:
            return .blue
        case .overdue:
            return .red
        case .calling:
            return .green
        }
    }

    // Durum için SF Symbol ikonu
    func iconForStatus(_ status: CallReminderAttributes.ContentState.ReminderStatus) -> String {
        switch status {
        case .waiting:
            return "phone.circle.fill"
        case .overdue:
            return "exclamationmark.triangle.fill"
        case .calling:
            return "phone.arrow.up.right.fill"
        }
    }

    // Durum metni
    func statusText(_ status: CallReminderAttributes.ContentState.ReminderStatus) -> String {
        switch status {
        case .waiting:
            return "Arama Bekliyor"
        case .overdue:
            return "Vakit Geçti!"
        case .calling:
            return "Aranıyor..."
        }
    }

    // Progress değeri (0.0 - 1.0)
    func progressValue(from date: Date) -> Double {
        // 15 dakika (900 saniye) varsayılan süre
        let totalDuration: Double = 900
        let remaining = date.timeIntervalSinceNow

        if remaining <= 0 {
            return 1.0 // Süre doldu
        }

        let elapsed = totalDuration - remaining
        return min(max(elapsed / totalDuration, 0.0), 1.0)
    }
}

// MARK: - Progress Bar Component

struct ProgressBarView: View {
    let progress: Double
    let status: CallReminderAttributes.ContentState.ReminderStatus

    var body: some View {
        VStack(spacing: 8) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Arka plan
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 8)

                    // Dolum - animasyonlu
                    RoundedRectangle(cornerRadius: 8)
                        .fill(gradientForStatus(status))
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                        .shadow(color: colorForStatus(status).opacity(0.5), radius: 4)
                }
            }
            .frame(height: 8)

            // Progress yüzdesi
            HStack {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)

                Spacer()

                Text(progress >= 1.0 ? "Tamamlandı" : "İlerliyor")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 4)
    }

    func gradientForStatus(_ status: CallReminderAttributes.ContentState.ReminderStatus) -> LinearGradient {
        switch status {
        case .waiting:
            return LinearGradient(
                colors: [Color.blue, Color.purple],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .overdue:
            return LinearGradient(
                colors: [Color.orange, Color.red],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .calling:
            return LinearGradient(
                colors: [Color.green, Color.mint],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    func colorForStatus(_ status: CallReminderAttributes.ContentState.ReminderStatus) -> Color {
        switch status {
        case .waiting:
            return .blue
        case .overdue:
            return .red
        case .calling:
            return .green
        }
    }
}

// MARK: - Lock Screen View

struct CallReminderLockScreenView: View {
    let context: ActivityViewContext<CallReminderAttributes>

    var body: some View {
        ZStack {
            // Gradient arka plan
            RoundedRectangle(cornerRadius: 20)
                .fill(gradientForStatus(context.state.status))
                .opacity(0.15)

            VStack(spacing: 16) {
                // Üst kısım: İkon ve bilgi
                HStack(spacing: 16) {
                    // Profil fotoğrafı veya animasyonlu ikon
                    if let imageBase64 = context.attributes.profileImageBase64,
                       let imageData = Data(base64Encoded: imageBase64),
                       let uiImage = UIImage(data: imageData) {
                        // Gerçek profil fotoğrafı
                        ZStack {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(gradientForStatus(context.state.status), lineWidth: 3)
                                )
                                .shadow(color: colorForStatus(context.state.status).opacity(0.4), radius: 8)

                            // Durum ikonu overlay (küçük badge)
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Image(systemName: iconForStatus(context.state.status))
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(6)
                                        .background(Circle().fill(colorForStatus(context.state.status)))
                                        .shadow(radius: 3)
                                        .symbolEffect(.pulse, options: .repeating, value: context.state.status == .overdue)
                                }
                            }
                            .frame(width: 60, height: 60)
                        }
                    } else {
                        // Fallback: Animasyonlu ikon
                        ZStack {
                            Circle()
                                .fill(gradientForStatus(context.state.status))
                                .frame(width: 60, height: 60)
                                .shadow(color: colorForStatus(context.state.status).opacity(0.4), radius: 8)

                            Image(systemName: iconForStatus(context.state.status))
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(.white)
                                .symbolEffect(.pulse, options: .repeating, value: context.state.status == .overdue)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        // Emoji ve isim (emoji yalnızca fotoğraf yoksa gösterilir)
                        HStack(spacing: 8) {
                            if context.attributes.profileImageBase64 == nil {
                                Text(context.attributes.friendEmoji ?? "👤")
                                    .font(.system(size: 24))
                            }

                            Text(context.state.friendName)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)
                        }

                        // Durum
                        Text(statusText(context.state.status))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(gradientForStatus(context.state.status))
                    }

                    Spacer()

                    // Kalan süre - büyük
                    VStack(spacing: 4) {
                        Text(timeRemaining(from: context.state.reminderTime))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(gradientForStatus(context.state.status))

                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 10))
                            Text(context.state.status == .overdue ? "geçti" : "kaldı")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                    }
                }

                // Progress bar
                ProgressBarView(
                    progress: progressValue(from: context.state.reminderTime),
                    status: context.state.status
                )

                // Hızlı Aksiyon Butonları
                HStack(spacing: 10) {
                    // Ara butonu
                    if let phoneNumber = context.state.phoneNumber, !phoneNumber.isEmpty {
                        Link(destination: URL(string: "tel:\(phoneNumber)")!) {
                            HStack(spacing: 6) {
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Ara")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [Color.green, Color.mint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: Color.green.opacity(0.3), radius: 4)
                        }
                    }

                    // Mesaj butonu
                    if let phoneNumber = context.state.phoneNumber, !phoneNumber.isEmpty {
                        Link(destination: URL(string: "sms:\(phoneNumber)")!) {
                            HStack(spacing: 6) {
                                Image(systemName: "message.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Mesaj")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: Color.blue.opacity(0.3), radius: 4)
                        }
                    }

                    // Tamamla butonu
                    Link(destination: URL(string: "lifestyles://complete-call/\(context.attributes.friendId)")!) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Tamam")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color.orange, Color.red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: Color.orange.opacity(0.3), radius: 4)
                    }
                }
                .padding(.top, 8)
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity)
    }

    // Helper functions
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
                colors: [Color.blue, Color.purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .overdue:
            return LinearGradient(
                colors: [Color.orange, Color.red],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .calling:
            return LinearGradient(
                colors: [Color.green, Color.mint],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    func colorForStatus(_ status: CallReminderAttributes.ContentState.ReminderStatus) -> Color {
        switch status {
        case .waiting:
            return .blue
        case .overdue:
            return .red
        case .calling:
            return .green
        }
    }

    func iconForStatus(_ status: CallReminderAttributes.ContentState.ReminderStatus) -> String {
        switch status {
        case .waiting:
            return "phone.circle.fill"
        case .overdue:
            return "exclamationmark.triangle.fill"
        case .calling:
            return "phone.arrow.up.right.fill"
        }
    }

    func statusText(_ status: CallReminderAttributes.ContentState.ReminderStatus) -> String {
        switch status {
        case .waiting:
            return "Arama Bekliyor"
        case .overdue:
            return "Vakit Geçti!"
        case .calling:
            return "Aranıyor..."
        }
    }
}

// MARK: - Dynamic Theme Engine

extension CallReminderWidgetLiveActivity {

    /// İlişki tipine göre gradient tema
    func themeGradient(for attributes: CallReminderAttributes, status: CallReminderAttributes.ContentState.ReminderStatus) -> LinearGradient {
        // VIP ise altın tema
        if attributes.isVIP {
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 1.0, green: 0.65, blue: 0.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        // Gecikme durumuna göre öncelik
        if attributes.daysOverdue >= 7 {
            return LinearGradient(
                colors: [Color.red, Color.orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if attributes.daysOverdue >= 3 {
            return LinearGradient(
                colors: [Color.orange, Color.yellow],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        // İlişki tipine göre tema
        switch attributes.relationshipType {
        case "partner":
            return LinearGradient(
                colors: [Color.pink, Color.purple, Color.red],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "family":
            return LinearGradient(
                colors: [Color.green, Color.orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "colleague":
            return LinearGradient(
                colors: [Color.purple, Color.blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default: // friend
            return LinearGradient(
                colors: [Color.blue, Color.cyan],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    /// İlişki tipine göre ana renk
    func themeColor(for attributes: CallReminderAttributes) -> Color {
        if attributes.isVIP {
            return Color(red: 1.0, green: 0.84, blue: 0.0) // Gold
        }

        if attributes.daysOverdue >= 7 {
            return .red
        } else if attributes.daysOverdue >= 3 {
            return .orange
        }

        switch attributes.relationshipType {
        case "partner": return .pink
        case "family": return .green
        case "colleague": return .purple
        default: return .blue
        }
    }

    /// İlişki tipine göre emoji ikon
    func relationshipEmoji(for attributes: CallReminderAttributes) -> String {
        switch attributes.relationshipType {
        case "partner": return "💑"
        case "family": return "👨‍👩‍👧"
        case "colleague": return "💼"
        default: return "👥"
        }
    }

    /// Sevgi dili ipucu (partner için)
    func loveLanguageTip(for attributes: CallReminderAttributes) -> String? {
        guard attributes.relationshipType == "partner",
              let loveLanguage = attributes.loveLanguage else {
            return nil
        }

        switch loveLanguage {
        case "words":
            return "💬 İltifat etmeyi unutma"
        case "time":
            return "⏰ Birlikte zaman geçirin"
        case "gifts":
            return "🎁 Küçük sürpriz hazırla"
        case "service":
            return "🤝 Yardım teklif et"
        case "touch":
            return "🤗 Sarılmayı unutma"
        default:
            return nil
        }
    }

    /// Özel tarih banner mesajı
    func specialDateBanner(for attributes: CallReminderAttributes) -> String? {
        if attributes.hasUpcomingBirthday, let days = attributes.daysUntilBirthday {
            if days == 0 {
                return "🎂 BUGÜN DOĞUM GÜNÜ! 🎉"
            } else if days == 1 {
                return "🎂 Doğum günü yarın!"
            } else {
                return "🎂 Doğum günü \(days) gün sonra!"
            }
        }

        if attributes.hasUpcomingAnniversary, let days = attributes.daysUntilAnniversary {
            if days == 0 {
                return "💕 BUGÜN YILDÖNÜMÜ! 🎉"
            } else if days == 1 {
                return "💕 Yıldönümü yarın!"
            } else {
                return "💕 Yıldönümünüz \(days) gün sonra!"
            }
        }

        return nil
    }

    /// Borç/alacak badge mesajı
    func debtCreditBadge(for attributes: CallReminderAttributes) -> String? {
        guard let balance = attributes.balance else { return nil }

        if attributes.hasDebt {
            return "Borç: \(balance) 💸"
        } else if attributes.hasCredit {
            return "Alacak: \(balance) 💰"
        }

        return nil
    }

    /// Gecikme durumu mesajı
    func overdueMessage(for attributes: CallReminderAttributes) -> String? {
        let days = attributes.daysOverdue

        if days >= 7 {
            return "❗ \(days) GÜN GEÇTİ!"
        } else if days >= 3 {
            return "⚠️ \(days) gün gecikti"
        }

        return nil
    }
}

//
//  CompactFriendRow.swift
//  LifeStyles
//
//  Modern, compact friend row tasarımı
//  Swipe actions, status indicators, ve visual badges ile
//

import SwiftUI

// MARK: - Compact Friend Row

struct CompactFriendRow: View {
    let friend: Friend
    let viewModel: FriendsViewModel

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            FriendAvatarView(friend: friend, size: 44, showBadge: false)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                // İsim + Badges
                HStack(spacing: 6) {
                    Text(friend.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    // Important badge
                    if friend.isImportant {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.yellow)
                    }

                    // Relationship badge
                    if friend.relationshipType == .partner {
                        Text("❤️")
                            .font(.system(size: 10))
                    } else if friend.relationshipType == .family {
                        Text("👨‍👩‍👧")
                            .font(.system(size: 10))
                    } else if friend.relationshipType == .colleague {
                        Text("💼")
                            .font(.system(size: 10))
                    }

                    Spacer(minLength: 0)

                    // Status indicator
                    statusIndicator
                }

                // Frequency + Son iletişim
                HStack(spacing: 8) {
                    Text(friend.frequency.displayName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if let lastContact = friend.lastContactDate {
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)

                        Text(String(format: NSLocalizedString("friends.last.contact", comment: "Last contact with date"), formatRelativeDate(lastContact)))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(rowBackground)
        .contentShape(Rectangle())
    }

    // MARK: - Status Indicator

    private var statusIndicator: some View {
        HStack(spacing: 4) {
            if friend.needsContact {
                // Gecikmiş
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.red)

                Text(String(format: NSLocalizedString("friends.days.overdue", comment: "Days overdue"), friend.daysOverdue))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.red)
            } else if friend.daysRemaining <= 3 {
                // Yakında
                Image(systemName: "clock.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)

                Text(String(format: NSLocalizedString("friends.days.remaining", comment: "Days remaining"), friend.daysRemaining))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.orange)
            } else {
                // OK
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)

                Text(String(format: NSLocalizedString("friends.days.remaining", comment: "Days remaining"), friend.daysRemaining))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.green)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(statusBackgroundColor.opacity(0.15))
        )
    }

    private var statusBackgroundColor: Color {
        if friend.needsContact {
            return .red
        } else if friend.daysRemaining <= 3 {
            return .orange
        } else {
            return .green
        }
    }

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color(.secondarySystemGroupedBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(friend.needsContact ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
            )
    }

    // MARK: - Helper

    private func formatRelativeDate(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0

        if days == 0 {
            return "Bugün"
        } else if days == 1 {
            return "Dün"
        } else if days < 7 {
            return "\(days)g"
        } else if days < 30 {
            let weeks = days / 7
            return "\(weeks)h"
        } else {
            let months = days / 30
            return "\(months)a"
        }
    }
}

// MARK: - Swipe Actions Wrapper

struct SwipeableFriendRow: View {
    let friend: Friend
    let viewModel: FriendsViewModel

    var body: some View {
        NavigationLink(destination: FriendDetailView(friend: friend)) {
            CompactFriendRow(friend: friend, viewModel: viewModel)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            // İletişim tamamla
            Button {
                HapticFeedback.success()
                viewModel.markAsContacted(friend)
            } label: {
                Label("Tamamla", systemImage: "checkmark.circle.fill")
            }
            .tint(.green)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            // Mesaj
            Button {
                HapticFeedback.light()
                sendMessage(to: friend)
            } label: {
                Label("Mesaj", systemImage: "message.fill")
            }
            .tint(.blue)

            // Ara
            Button {
                HapticFeedback.light()
                callFriend(friend)
            } label: {
                Label("Ara", systemImage: "phone.fill")
            }
            .tint(.purple)
        }
    }

    private func callFriend(_ friend: Friend) {
        guard let phoneNumber = friend.phoneNumber else { return }
        if let url = URL(string: "tel://\(phoneNumber)") {
            UIApplication.shared.open(url)
        }
    }

    private func sendMessage(to friend: Friend) {
        guard let phoneNumber = friend.phoneNumber else { return }
        if let url = URL(string: "sms://\(phoneNumber)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Preview

#Preview("Compact Row - Normal") {
    List {
        // Preview için sample friend oluştur
        let friend = Friend(
            name: "Ahmet Yılmaz",
            phoneNumber: "+905551234567",
            frequency: .weekly,
            isImportant: true
        )

        SwipeableFriendRow(
            friend: friend,
            viewModel: FriendsViewModel()
        )
        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
        .listRowBackground(Color.clear)
    }
    .listStyle(.plain)
}

#Preview("Compact Row - Overdue") {
    let friend = Friend(
        name: "Zeynep Demir",
        phoneNumber: "+905559876543",
        frequency: .daily,
        lastContactDate: Calendar.current.date(byAdding: .day, value: -10, to: Date()),
        isImportant: true
    )

    return List {
        SwipeableFriendRow(
            friend: friend,
            viewModel: FriendsViewModel()
        )
        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
        .listRowBackground(Color.clear)
    }
    .listStyle(.plain)
}

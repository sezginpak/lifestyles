//
//  ToastView.swift
//  LifeStyles
//
//  Modern toast bildirim UI component
//  Glassmorphism tasarımı, swipe-to-dismiss, animasyonlar
//

import SwiftUI

// MARK: - Toast View

struct ToastView: View {
    let toast: Toast
    let onDismiss: () -> Void

    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1.0

    var body: some View {
        HStack(spacing: 12) {
            // Emoji veya Icon
            Group {
                if let emoji = toast.emoji {
                    Text(emoji)
                        .font(.system(size: 24))
                } else {
                    Image(systemName: toast.type.icon)
                        .font(.title3)
                        .foregroundStyle(toast.type.color)
                }
            }
            .frame(width: 32)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(toast.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if let message = toast.message {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)

            // Close button
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            ZStack {
                // Glassmorphism background
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)

                // Accent border
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(toast.type.color.opacity(0.3), lineWidth: 1)
            }
        )
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        .padding(.horizontal, 16)
        .offset(y: offset)
        .opacity(opacity)
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    // Yukarı kaydırmaya izin ver
                    if gesture.translation.height < 0 {
                        offset = gesture.translation.height
                    }
                }
                .onEnded { gesture in
                    if gesture.translation.height < -50 {
                        // Hızlıca yukarı kaydırıldıysa kapat
                        dismissWithAnimation()
                    } else {
                        // Geri dön
                        withAnimation(.spring(response: 0.3)) {
                            offset = 0
                        }
                    }
                }
        )
    }

    private func dismissWithAnimation() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            offset = -100
            opacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - Toast Container (Positioned Overlay)

/// ToastView'ı ekranın üst kısmında konumlandıran container
struct ToastContainer: View {
    @Bindable var toastManager: ToastManager

    var body: some View {
        ZStack {
            if let toast = toastManager.currentToast {
                VStack {
                    ToastView(toast: toast) {
                        toastManager.dismiss()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(999)

                    Spacer()
                }
                .padding(.top, 50) // Safe area + offset
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: toastManager.currentToast != nil)
    }
}

// MARK: - Preview

#Preview("Success Toast") {
    VStack {
        Spacer()
    }
    .overlay {
        ToastView(
            toast: Toast(
                title: "Hedef Kaydedildi",
                message: "Yeni hedef başarıyla eklendi",
                type: .success,
                emoji: "🎯"
            ),
            onDismiss: {}
        )
        .padding(.top, 50)
    }
}

#Preview("Error Toast") {
    VStack {
        Spacer()
    }
    .overlay {
        ToastView(
            toast: Toast(
                title: "Hata Oluştu",
                message: "Lütfen tekrar deneyin",
                type: .error,
                emoji: "❌"
            ),
            onDismiss: {}
        )
        .padding(.top, 50)
    }
}

#Preview("Warning Toast") {
    VStack {
        Spacer()
    }
    .overlay {
        ToastView(
            toast: Toast(
                title: "Uyarı",
                message: "İzin gerekli",
                type: .warning,
                emoji: "⚠️"
            ),
            onDismiss: {}
        )
        .padding(.top, 50)
    }
}

#Preview("Info Toast") {
    VStack {
        Spacer()
    }
    .overlay {
        ToastView(
            toast: Toast(
                title: "Bilgi",
                message: "Konum güncellendi",
                type: .info,
                emoji: "📍"
            ),
            onDismiss: {}
        )
        .padding(.top, 50)
    }
}

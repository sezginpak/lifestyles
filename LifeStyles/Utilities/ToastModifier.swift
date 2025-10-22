//
//  ToastModifier.swift
//  LifeStyles
//
//  SwiftUI modifier - Toast sistemini view'lara ekleme
//  Environment ile ToastManager erişimi
//

import SwiftUI

// MARK: - Toast Modifier

/// Toast gösterme modifier'ı
struct ToastModifier: ViewModifier {
    @Bindable var toastManager: ToastManager

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                ToastContainer(toastManager: toastManager)
            }
    }
}

// MARK: - View Extension

extension View {
    /// View'a toast sistemi ekle
    /// - Parameter toastManager: ToastManager instance (default: .shared)
    func withToast(manager: ToastManager = .shared) -> some View {
        modifier(ToastModifier(toastManager: manager))
    }
}

// MARK: - Environment Key

/// ToastManager için Environment Key
private struct ToastManagerKey: EnvironmentKey {
    static let defaultValue: ToastManager = .shared
}

extension EnvironmentValues {
    var toastManager: ToastManager {
        get { self[ToastManagerKey.self] }
        set { self[ToastManagerKey.self] = newValue }
    }
}

// MARK: - Preview

#Preview("Toast Modifier Demo") {
    struct ToastDemoView: View {
        @State private var toastManager = ToastManager.shared

        var body: some View {
            VStack(spacing: 20) {
                Text("Toast Modifier Demo")
                    .font(.title)
                    .fontWeight(.bold)

                Divider()

                // Success
                Button("Başarı Toast") {
                    toastManager.success(
                        title: "Başarılı!",
                        message: "İşlem tamamlandı",
                        emoji: "✅"
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(.success)

                // Error
                Button("Hata Toast") {
                    toastManager.error(
                        title: "Hata!",
                        message: "Bir şeyler yanlış gitti",
                        emoji: "❌"
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(.error)

                // Warning
                Button("Uyarı Toast") {
                    toastManager.warning(
                        title: "Dikkat!",
                        message: "İzin gerekli",
                        emoji: "⚠️"
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(.warning)

                // Info
                Button("Bilgi Toast") {
                    toastManager.info(
                        title: "Bilgilendirme",
                        message: "Güncelleme mevcut",
                        emoji: "ℹ️"
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(.info)

                // Custom
                Button("Custom Toast") {
                    toastManager.custom(
                        title: "Özel Bildirim",
                        message: "Custom renk ve icon",
                        icon: "star.fill",
                        color: .purple,
                        emoji: "🌟"
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)

                // Multiple toasts (queue demo)
                Button("Çoklu Toast (Kuyruk)") {
                    toastManager.success(title: "İlk Toast", emoji: "1️⃣")
                    toastManager.info(title: "İkinci Toast", emoji: "2️⃣")
                    toastManager.warning(title: "Üçüncü Toast", emoji: "3️⃣")
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding()
            .withToast(manager: toastManager)
        }
    }

    return ToastDemoView()
}

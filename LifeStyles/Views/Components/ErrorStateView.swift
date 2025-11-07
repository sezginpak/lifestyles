//
//  ErrorStateView.swift
//  LifeStyles
//
//  Created by Claude Code
//

import SwiftUI

/// Kritik hata durumlarında gösterilecek view
struct ErrorStateView: View {
    let errorType: ErrorType

    enum ErrorType {
        case emergencyMode
        case emptyContainer
        case storageFailure

        var title: String {
            switch self {
            case .emergencyMode:
                return "Acil Durum Modu"
            case .emptyContainer:
                return "Kritik Hata"
            case .storageFailure:
                return "Veri Hatası"
            }
        }

        var message: String {
            switch self {
            case .emergencyMode:
                return "Uygulama minimal özelliklerle çalışıyor. Verileriniz geçici olarak saklanacak."
            case .emptyContainer:
                return "Veri sistemi başlatılamadı. Lütfen uygulamayı yeniden başlatın."
            case .storageFailure:
                return "Veri depolama hatası oluştu. Lütfen uygulamayı güncelleyin."
            }
        }

        var icon: String {
            switch self {
            case .emergencyMode:
                return "exclamationmark.triangle.fill"
            case .emptyContainer:
                return "xmark.circle.fill"
            case .storageFailure:
                return "externaldrive.fill.badge.exclamationmark"
            }
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: errorType.icon)
                .font(.system(size: 60))
                .foregroundStyle(.red)

            Text(errorType.title)
                .font(.title.bold())
                .foregroundStyle(.primary)

            Text(errorType.message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            VStack(spacing: 12) {
                Button {
                    // Uygulamayı yeniden başlat
                    exit(0)
                } label: {
                    Label(String(localized: "error.restart.app", comment: ""), systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    // App Store'a yönlendir
                    if let url = URL(string: "https://apps.apple.com") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label(String(localized: "error.check.updates", comment: ""), systemImage: "arrow.down.circle")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)

            Spacer()

            Text(String(localized: "error.contact.support", comment: ""))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }
}

#Preview {
    ErrorStateView(errorType: .emergencyMode)
}

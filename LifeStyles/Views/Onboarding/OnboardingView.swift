//
//  OnboardingView.swift
//  LifeStyles
//
//  Created by Claude on 15.10.2025.
//

import SwiftUI

struct OnboardingView: View {
    @State private var viewModel = OnboardingViewModel()
    @Binding var isOnboardingComplete: Bool

    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                colors: [
                    Color.backgroundPrimary,
                    Color.backgroundSecondary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip Button
                HStack {
                    Spacer()

                    if !viewModel.isLastPage {
                        Button {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                viewModel.completeOnboarding()
                                isOnboardingComplete = true
                            }
                        } label: {
                            Text("Atla")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    }
                }

                Spacer()

                // Page Content
                TabView(selection: $viewModel.currentPage) {
                    ForEach(Array(viewModel.pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 500)

                // Custom Page Indicator
                HStack(spacing: 8) {
                    ForEach(0..<viewModel.pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == viewModel.currentPage ? Color.brandPrimary : Color.textTertiary.opacity(0.3))
                            .frame(width: index == viewModel.currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.currentPage)
                    }
                }
                .padding(.vertical, 20)

                Spacer()

                // Action Buttons
                VStack(spacing: 12) {
                    if let permissionType = viewModel.pages[viewModel.currentPage].permissionType {
                        // Konum için özel uyarı
                        if permissionType == .location {
                            VStack(spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundStyle(Color.brandPrimary)
                                    Text("Lütfen \"Her Zaman\" seçeneğini işaretleyin")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.brandPrimary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }

                        // İzin İste Butonu
                        Button {
                            Task {
                                HapticFeedback.medium()
                                let granted = await viewModel.requestPermissionForCurrentPage()

                                if granted {
                                    HapticFeedback.success()

                                    // Konum izninde "Her Zaman" kontrolü
                                    if permissionType == .location {
                                        if !PermissionManager.shared.hasAlwaysLocationPermission() {
                                            // "Kullanım sırasında" izni verilmiş, ayarlara yönlendir
                                            await MainActor.run {
                                                viewModel.showLocationSettingsAlert = true
                                            }
                                            return
                                        }
                                    }

                                    // Son sayfada değilse devam et
                                    if !viewModel.isLastPage {
                                        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 saniye
                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                            viewModel.nextPage()
                                        }
                                    } else {
                                        // Son sayfadaysa tamamla
                                        viewModel.completeOnboarding()
                                        isOnboardingComplete = true
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                if viewModel.isRequestingPermission {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(permissionButtonText(for: permissionType))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(viewModel.isRequestingPermission)

                        // Daha Sonra Butonu
                        if !viewModel.isLastPage {
                            Button {
                                HapticFeedback.light()
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    viewModel.nextPage()
                                }
                            } label: {
                                Text("Daha Sonra")
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                    } else {
                        // İlk sayfa - Başla butonu
                        Button {
                            HapticFeedback.medium()
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                viewModel.nextPage()
                            }
                        } label: {
                            HStack {
                                Text("Başlayalım")
                                Image(systemName: "arrow.right")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
                .padding(.horizontal, AppConstants.Spacing.large)
                .padding(.bottom, 40)
            }
        }
        .alert("Arka Plan Konum İzni", isPresented: $viewModel.showLocationSettingsAlert) {
            Button("Ayarlara Git") {
                PermissionManager.shared.openAppSettings()
                // Onboarding'i tamamla veya devam et
                if viewModel.isLastPage {
                    viewModel.completeOnboarding()
                    isOnboardingComplete = true
                } else {
                    viewModel.nextPage()
                }
            }
            Button("Daha Sonra", role: .cancel) {
                if viewModel.isLastPage {
                    viewModel.completeOnboarding()
                    isOnboardingComplete = true
                } else {
                    viewModel.nextPage()
                }
            }
        } message: {
            Text("LifeStyles, hayat kalitenizi artırmak için konumunuzu 15 dakikada bir kaydeder. Bunun arka planda da çalışabilmesi için:\n\nAyarlar → LifeStyles → Konum → \"Her Zaman\" seçeneğini işaretleyin")
        }
    }

    private func permissionButtonText(for type: OnboardingPage.PermissionType) -> String {
        switch type {
        case .contacts:
            return "Rehbere Erişime İzin Ver"
        case .location:
            return "Konuma Erişime İzin Ver"
        case .notifications:
            return "Bildirimlere İzin Ver"
        }
    }
}

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            // Icon with Gradient
            ZStack {
                Circle()
                    .fill(page.gradient)
                    .frame(width: 140, height: 140)
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)

                Image(systemName: page.icon)
                    .font(.system(size: 60, weight: .medium))
                    .foregroundStyle(.white)
            }
            .bounce()

            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 24)
            }
        }
        .padding()
    }
}

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
}

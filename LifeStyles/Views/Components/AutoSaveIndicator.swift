//
//  AutoSaveIndicator.swift
//  LifeStyles
//
//  Cloud sync indicator with animations
//  States: idle, saving, saved, error
//

import SwiftUI

// MARK: - Auto Save State

enum AutoSaveState {
    case idle
    case saving
    case saved
    case error

    var icon: String {
        switch self {
        case .idle: return "cloud"
        case .saving: return "cloud.fill"
        case .saved: return "checkmark.icloud.fill"
        case .error: return "exclamationmark.icloud.fill"
        }
    }

    var color: Color {
        switch self {
        case .idle: return .secondary
        case .saving: return .blue
        case .saved: return .success
        case .error: return .error
        }
    }

    var message: String {
        switch self {
        case .idle: return "Değişiklikler kaydedilecek"
        case .saving: return "Kaydediliyor..."
        case .saved: return "Kaydedildi"
        case .error: return "Kayıt hatası"
        }
    }
}

// MARK: - Auto Save Indicator

struct AutoSaveIndicator: View {
    let state: AutoSaveState
    let showMessage: Bool

    @State private var isAnimating = false
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0

    init(
        state: AutoSaveState,
        showMessage: Bool = true
    ) {
        self.state = state
        self.showMessage = showMessage
    }

    var body: some View {
        HStack(spacing: 6) {
            // Icon with animation
            ZStack {
                Image(systemName: state.icon)
                    .font(.caption)
                    .foregroundStyle(state.color)
                    .scaleEffect(scale)
                    .opacity(opacity)

                // Rotating ring for saving state
                if state == .saving {
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(state.color.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 16, height: 16)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                }
            }
            .frame(width: 20, height: 20)

            // Message
            if showMessage {
                Text(state.message)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(state.color)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(state.color.opacity(0.1))
        )
        .overlay(
            Capsule()
                .strokeBorder(state.color.opacity(0.3), lineWidth: 1)
        )
        .onChange(of: state) { _, newState in
            handleStateChange(newState)
        }
        .onAppear {
            if state == .saving {
                startSavingAnimation()
            }
        }
    }

    private func handleStateChange(_ newState: AutoSaveState) {
        switch newState {
        case .saving:
            startSavingAnimation()

        case .saved:
            stopSavingAnimation()
            celebrateSave()

        case .error:
            stopSavingAnimation()
            shakeAnimation()

        case .idle:
            stopSavingAnimation()
        }
    }

    private func startSavingAnimation() {
        withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
            isAnimating = true
        }

        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            opacity = 0.6
        }
    }

    private func stopSavingAnimation() {
        withAnimation {
            isAnimating = false
            opacity = 1.0
        }
    }

    private func celebrateSave() {
        // Scale up and down
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            scale = 1.3
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.0
            }
        }

        HapticFeedback.success()
    }

    private func shakeAnimation() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.3)) {
            scale = 1.1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.3)) {
                scale = 0.9
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.0
            }
        }

        HapticFeedback.error()
    }
}

// MARK: - Floating Auto Save

struct FloatingAutoSave: View {
    let state: AutoSaveState

    var body: some View {
        AutoSaveIndicator(state: state, showMessage: true)
            .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
    }
}

// MARK: - Auto Save Manager

@Observable
class AutoSaveManager {
    var state: AutoSaveState = .idle
    private var saveTask: Task<Void, Never>?

    /// Trigger auto save with debounce
    func triggerSave(after delay: TimeInterval = 1.0, action: @escaping () async -> Bool) {
        // Cancel previous save task
        saveTask?.cancel()

        // Set saving state after delay
        saveTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

            guard !Task.isCancelled else { return }

            await MainActor.run {
                state = .saving
            }

            // Execute save action
            let success = await action()

            guard !Task.isCancelled else { return }

            await MainActor.run {
                if success {
                    state = .saved

                    // Reset to idle after 2 seconds
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        await MainActor.run {
                            if state == .saved {
                                state = .idle
                            }
                        }
                    }
                } else {
                    state = .error

                    // Reset to idle after 3 seconds
                    Task {
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                        await MainActor.run {
                            if state == .error {
                                state = .idle
                            }
                        }
                    }
                }
            }
        }
    }

    /// Manual save (immediate)
    func save(action: @escaping () async -> Bool) async {
        state = .saving

        let success = await action()

        if success {
            state = .saved

            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if state == .saved {
                state = .idle
            }
        } else {
            state = .error

            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if state == .error {
                state = .idle
            }
        }
    }
}

// MARK: - Preview

#Preview("All States") {
    VStack(spacing: 24) {
        Text("Auto Save Indicator States")
            .font(.title2)
            .fontWeight(.bold)

        Divider()

        VStack(alignment: .leading, spacing: 16) {
            AutoSaveIndicator(state: .idle, showMessage: true)
            AutoSaveIndicator(state: .saving, showMessage: true)
            AutoSaveIndicator(state: .saved, showMessage: true)
            AutoSaveIndicator(state: .error, showMessage: true)
        }

        Divider()

        VStack(alignment: .leading, spacing: 16) {
            Text("Without Message")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                AutoSaveIndicator(state: .idle, showMessage: false)
                AutoSaveIndicator(state: .saving, showMessage: false)
                AutoSaveIndicator(state: .saved, showMessage: false)
                AutoSaveIndicator(state: .error, showMessage: false)
            }
        }
    }
    .padding()
}

#Preview("Saving Animation") {
    FloatingAutoSave(state: .saving)
        .padding()
}

#Preview("Auto Save Demo") {
    struct DemoView: View {
        @State private var autoSave = AutoSaveManager()
        @State private var text = ""

        var body: some View {
            VStack(spacing: 20) {
                // Auto save indicator
                FloatingAutoSave(state: autoSave.state)

                TextField("Type something...", text: $text)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: text) { _, _ in
                        // Trigger auto save on text change
                        autoSave.triggerSave {
                            // Simulate save
                            try? await Task.sleep(nanoseconds: 1_000_000_000)
                            return true
                        }
                    }

                HStack {
                    Button("Save (Success)") {
                        Task {
                            await autoSave.save {
                                try? await Task.sleep(nanoseconds: 1_000_000_000)
                                return true
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Save (Error)") {
                        Task {
                            await autoSave.save {
                                try? await Task.sleep(nanoseconds: 1_000_000_000)
                                return false
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
    }

    return DemoView()
}

//
//  StreamingTextView.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//

import SwiftUI

/// Streaming AI response görünümü - Typewriter effect
@available(iOS 26.0, *)
struct StreamingTextView: View {
    let stream: AsyncThrowingStream<String, Error>
    @State private var displayedText: String = ""
    @State private var isComplete: Bool = false
    @State private var error: Error?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !displayedText.isEmpty {
                Text(displayedText)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
            }

            if !isComplete && displayedText.isEmpty {
                // Loading state
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)

                    Text("AI düşünüyor...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let error = error {
                // Error state
                Label(error.localizedDescription, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if isComplete && !displayedText.isEmpty {
                // Completion indicator
                HStack {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .opacity(0.6)
                }
            }
        }
        .task {
            await consumeStream()
        }
    }

    private func consumeStream() async {
        do {
            for try await chunk in stream {
                withAnimation(.easeOut(duration: 0.1)) {
                    displayedText += chunk
                }

                // Simulate typewriter delay
                try? await Task.sleep(for: .milliseconds(10))
            }

            withAnimation {
                isComplete = true
            }
        } catch {
            withAnimation {
                self.error = error
            }
        }
    }
}

/// AI response kartı - Streaming veya static content
@available(iOS 26.0, *)
struct AIResponseCard: View {
    let title: String
    let icon: String
    let accentColor: Color
    var staticContent: String?
    var stream: AsyncThrowingStream<String, Error>?

    @State private var isExpanded = true

    var body: some View {
        AIInsightCard(
            title: title,
            icon: icon,
            accentColor: accentColor,
            isExpanded: $isExpanded
        ) {
            VStack(alignment: .leading, spacing: 12) {
                if let staticContent = staticContent {
                    Text(staticContent)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if let stream = stream {
                    StreamingTextView(stream: stream)
                }
            }
        }
    }
}

/// Markdown destekli AI yanıt view'ı
struct AIMarkdownView: View {
    let content: String
    @State private var animateIn = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(parsedLines, id: \.self) { line in
                lineView(for: line)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 10)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateIn = true
            }
        }
    }

    private var parsedLines: [String] {
        content.components(separatedBy: "\n").filter { !$0.isEmpty }
    }

    @ViewBuilder
    private func lineView(for line: String) -> some View {
        if line.hasPrefix("• ") || line.hasPrefix("- ") {
            // Bullet point
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .foregroundStyle(.secondary)
                Text(String(line.dropFirst(2)))
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
        } else if line.hasPrefix("# ") {
            // Header
            Text(String(line.dropFirst(2)))
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)
        } else if line.hasPrefix("## ") {
            // Subheader
            Text(String(line.dropFirst(3)))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        } else {
            // Regular text
            Text(line)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

/// Typing indicator (AI düşünüyor animasyonu)
struct AITypingIndicator: View {
    @State private var animationPhase = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.secondary.opacity(0.6))
                    .frame(width: 8, height: 8)
                    .scaleEffect(animationPhase == index ? 1.2 : 0.8)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: animationPhase
                    )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.secondary.opacity(0.1))
        )
        .onAppear {
            withAnimation {
                animationPhase = 1
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
@available(iOS 26.0, *)
#Preview("Streaming Text") {
    VStack(spacing: 20) {
        // Mock stream for preview
        StreamingTextView(stream: mockStream())
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)

        AITypingIndicator()

        AIMarkdownView(content: """
        # Günlük Özet

        Bugün harika bir gün!

        ## Başarılar:
        • 3 hedefte ilerleme kaydettiniz
        • 2 alışkanlık tamamlandı
        • 1 arkadaşla iletişim kuruldu

        Devam et, sen harikasın! 💪
        """)
        .padding()
    }
    .padding()
}

@available(iOS 26.0, *)
private func mockStream() -> AsyncThrowingStream<String, Error> {
    AsyncThrowingStream { continuation in
        Task {
            let text = "Bugün harika bir gün! Hedeflerinize doğru adım adım ilerliyorsunuz. Devam edin!"
            for char in text {
                continuation.yield(String(char))
                try? await Task.sleep(for: .milliseconds(50))
            }
            continuation.finish()
        }
    }
}
#endif

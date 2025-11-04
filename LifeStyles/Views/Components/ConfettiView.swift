//
//  ConfettiView.swift
//  LifeStyles
//
//  Confetti particles animation
//  Created by Claude on 31.10.2025.
//

import SwiftUI

struct ConfettiView: View {
    let count: Int
    let colors: [Color]

    init(count: Int = 20, colors: [Color] = [.green, .blue, .purple, .pink, .yellow, .orange]) {
        self.count = count
        self.colors = colors
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<count, id: \.self) { index in
                    ConfettiParticle(
                        color: colors[index % colors.count],
                        size: CGSize(
                            width: geometry.size.width,
                            height: geometry.size.height
                        )
                    )
                    .animation(
                        .linear(duration: Double.random(in: 1.0...2.0))
                            .delay(Double(index) * 0.05),
                        value: UUID()
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct ConfettiParticle: View {
    let color: Color
    let size: CGSize

    @State private var isAnimating = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: CGFloat.random(in: 4...8), height: CGFloat.random(in: 4...8))
            .position(
                x: isAnimating ? CGFloat.random(in: 0...size.width) : size.width / 2,
                y: isAnimating ? size.height + 20 : -20
            )
            .rotationEffect(.degrees(isAnimating ? Double.random(in: 0...360) : 0))
            .opacity(isAnimating ? 0 : 1)
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - View Extension

extension View {
    func confetti(isPresented: Binding<Bool>, count: Int = 20) -> some View {
        ZStack {
            self

            if isPresented.wrappedValue {
                ConfettiView(count: count)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            isPresented.wrappedValue = false
                        }
                    }
            }
        }
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground)

        ConfettiView(count: 30)
    }
}

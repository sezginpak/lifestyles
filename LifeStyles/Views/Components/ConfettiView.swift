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

// MARK: - Achievement Tier Helper

extension ConfettiView {
    /// Achievement tier'ına göre confetti oluştur
    /// - Parameter requirement: Achievement requirement değeri
    /// - Returns: Tier'a uygun confetti
    init(achievementRequirement requirement: Int) {
        let tier = AchievementConfettiTier(requirement: requirement)
        self.count = tier.particleCount
        self.colors = tier.colors
    }
}

/// Achievement tier'ına göre confetti özellikleri
enum AchievementConfettiTier {
    case bronze   // 1-5 requirement
    case silver   // 6-15
    case gold     // 16-50
    case platinum // 51+

    init(requirement: Int) {
        switch requirement {
        case 1...5:
            self = .bronze
        case 6...15:
            self = .silver
        case 16...50:
            self = .gold
        default:
            self = .platinum
        }
    }

    var particleCount: Int {
        switch self {
        case .bronze: return 20
        case .silver: return 35
        case .gold: return 50
        case .platinum: return 70
        }
    }

    var colors: [Color] {
        switch self {
        case .bronze:
            return [.orange, .brown, .yellow, Color(hex: "CD7F32")]
        case .silver:
            return [.gray, .white, .blue, Color(hex: "C0C0C0")]
        case .gold:
            return [.yellow, .orange, Color(hex: "FFD700"), Color(hex: "FFA500")]
        case .platinum:
            return [.cyan, .purple, .pink, .white, Color(hex: "E5E4E2")]
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

    /// Achievement tier-based confetti
    /// - Parameters:
    ///   - isPresented: Binding to control confetti visibility
    ///   - requirement: Achievement requirement değeri
    func achievementConfetti(isPresented: Binding<Bool>, requirement: Int) -> some View {
        ZStack {
            self

            if isPresented.wrappedValue {
                ConfettiView(achievementRequirement: requirement)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
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

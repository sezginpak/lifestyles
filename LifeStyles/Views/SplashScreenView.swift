//
//  SplashScreenView.swift
//  LifeStyles
//
//  Modern, premium splash screen animasyonu
//  Gradient background + particle effects + smooth transitions
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var particlesActive = false
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        ZStack {
            // MARK: - Animated Background Gradient
            AnimatedGradientBackground()

            // MARK: - Particle Effects
            if particlesActive {
                ParticleEffectView()
            }

            // MARK: - Logo/Branding
            VStack(spacing: 24) {
                // Logo Circle with Icon
                ZStack {
                    // Outer glow ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.brandPrimary.opacity(0.6),
                                    Color.brandSecondary.opacity(0.4),
                                    Color.accentSecondary.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 160, height: 160)
                        .blur(radius: 8)
                        .opacity(isAnimating ? 1 : 0)

                    // Main logo circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: Color.gradientPrimary,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .overlay(
                            // Shimmer effect
                            GeometryReader { geometry in
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0),
                                                Color.white.opacity(0.4),
                                                Color.white.opacity(0)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .rotationEffect(.degrees(45))
                                    .offset(x: shimmerOffset)
                            }
                            .clipShape(Circle())
                        )
                        .shadow(color: Color.brandPrimary.opacity(0.4), radius: 30, x: 0, y: 15)

                    // Icon
                    Image(systemName: "sparkles")
                        .font(.system(size: 60, weight: .medium))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                // App Name
                VStack(spacing: 8) {
                    Text("LifeStyles")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: Color.gradientPrimary,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(logoOpacity)

                    Text(String(localized: "splash.tagline", comment: "With You at Every Moment of Life"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .opacity(logoOpacity * 0.8)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startAnimationSequence()
        }
    }

    // MARK: - Animation Sequence
    private func startAnimationSequence() {
        // 1. Logo scale + fade in (0.0 - 0.6s)
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }

        // 2. Start rotation (0.2s delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 2.0)) {
                isAnimating = true
            }
        }

        // 3. Shimmer effect (0.4s delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeInOut(duration: 1.2)) {
                shimmerOffset = 400
            }
        }

        // 4. Particle effects (0.6s delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            particlesActive = true
        }
    }
}

// MARK: - Animated Gradient Background

struct AnimatedGradientBackground: View {
    @State private var animateGradient = false

    var body: some View {
        LinearGradient(
            colors: [
                Color(hex: "6366F1"), // Indigo
                Color(hex: "8B5CF6"), // Purple
                Color(hex: "EC4899"), // Pink
                Color(hex: "F59E0B")  // Amber
            ],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
    }
}

// MARK: - Particle Effect View

struct ParticleEffectView: View {
    @State private var particles: [Particle] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ParticleDot(particle: particle)
                }
            }
            .onAppear {
                generateParticles(in: geometry.size)
            }
        }
    }

    private func generateParticles(in size: CGSize) {
        particles = (0..<30).map { _ in
            Particle(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                size: CGFloat.random(in: 3...8),
                duration: Double.random(in: 2...4),
                delay: Double.random(in: 0...1)
            )
        }
    }
}

// MARK: - Particle Model

struct Particle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let duration: Double
    let delay: Double
}

// MARK: - Particle Dot View

struct ParticleDot: View {
    let particle: Particle
    @State private var opacity: Double = 0

    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: particle.size, height: particle.size)
            .position(x: particle.x, y: particle.y)
            .opacity(opacity)
            .blur(radius: 1)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: particle.duration)
                    .repeatForever(autoreverses: true)
                    .delay(particle.delay)
                ) {
                    opacity = Double.random(in: 0.3...0.7)
                }
            }
    }
}

// MARK: - Bounce Animation Extension

extension View {
    func bounce() -> some View {
        modifier(BounceEffect())
    }
}

struct BounceEffect: ViewModifier {
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? 1.05 : 1.0)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Preview

#Preview {
    SplashScreenView()
}

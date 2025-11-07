//
//  SplashScreenView.swift
//  LifeStyles
//
//  Premium splash screen tasarımları - 4 alternatif
//  Her alternatif için açıklama ve kullanım notları aşağıda
//

import SwiftUI

// MARK: - Ana Splash View
// Kullanım: Aşağıdaki alternatifleri değiştirerek test edin
// Örnek: body içinde "SplashAlternative1()" yerine "SplashAlternative2()" yazın

struct SplashScreenView: View {
    var body: some View {
        // 🎯 BURADAN ALTERNATİFİ SEÇİN (1-4)
        SplashAlternative1()

        // Diğer alternatifler:
        // SplashAlternative2()
        // SplashAlternative3()
        // SplashAlternative4()
    }
}

// MARK: - 🌟 ALTERNATİF 1: MINIMAL LUXURY
/*
 TASARIM KONSEPT:
 - Apple tarzı minimalist yaklaşım
 - Özel "Lifestyle" icon: Birden fazla hayat unsurunun birleşimi
 - Smooth spring animasyonlar
 - Gradient kullanımı minimal
 - Dark mode uyumlu

 ANİMASYON TİMELİNE:
 0.0-0.3s: Background fade in
 0.1-0.7s: Icon scale up + fade in (spring bounce)
 0.5-1.0s: App name slide up + fade in
 0.7-1.2s: Tagline fade in
 0.8-1.3s: Subtle icon pulse (1 kere)

 ICON TASARIM:
 - Merkez: figure.walk (kişisel gelişim)
 - Üst: star.fill (hedefler)
 - Sağ: message.fill (iletişim)
 - Sol: heart.fill (yaşam kalitesi)
 - Tümü birleşik kompozisyon
*/

struct SplashAlternative1: View {
    @State private var backgroundOpacity: Double = 0
    @State private var iconScale: CGFloat = 0.3
    @State private var iconOpacity: Double = 0
    @State private var nameOffset: CGFloat = 30
    @State private var nameOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var iconPulse: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Background
            Color.black
                .overlay(
                    LinearGradient(
                        colors: [
                            Color(hex: "6366F1").opacity(0.15),
                            Color.black,
                            Color(hex: "EC4899").opacity(0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .ignoresSafeArea()
                .opacity(backgroundOpacity)

            VStack(spacing: 32) {
                // Custom LifeStyle Icon - Design 1 (Multi-Icon)
                ZStack {
                    // Background gradient circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "6366F1"), // Indigo
                                    Color(hex: "8B5CF6"), // Purple
                                    Color(hex: "EC4899")  // Pink
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .shadow(color: Color(hex: "8B5CF6").opacity(0.4), radius: 20, y: 10)

                    // Outer ring - life cycle
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.9),
                                    .white.opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 8
                        )
                        .frame(width: 98, height: 98)

                    // Icon composition (4 elements + center)
                    LifeStyleIconComposition()
                        .foregroundStyle(.white)

                    // Center white circle
                    Circle()
                        .fill(.white)
                        .frame(width: 49, height: 49)

                    // Center "L" letter
                    Text("L")
                        .font(.system(size: 35, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(hex: "6366F1"),
                                    Color(hex: "EC4899")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .scaleEffect(iconScale * iconPulse)
                .opacity(iconOpacity)

                // App name
                VStack(spacing: 12) {
                    Text(String(localized: "app.name", defaultValue: "LifeStyles", comment: "App name"))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(hex: "E0E7FF")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .offset(y: nameOffset)
                        .opacity(nameOpacity)

                    Text(String(localized: "splash.tagline", comment: "With You Every Moment of Life"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .opacity(taglineOpacity)
                }
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        // Background fade
        withAnimation(.easeOut(duration: 0.3)) {
            backgroundOpacity = 1.0
        }

        // Icon scale + fade (spring bounce)
        withAnimation(.spring(response: 0.6, dampingFraction: 0.65).delay(0.1)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }

        // App name slide up
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.5)) {
            nameOffset = 0
            nameOpacity = 1.0
        }

        // Tagline fade
        withAnimation(.easeOut(duration: 0.5).delay(0.7)) {
            taglineOpacity = 1.0
        }

        // Subtle pulse (1 kere)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.5)) {
                iconPulse = 1.08
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    iconPulse = 1.0
                }
            }
        }
    }
}

// Custom Icon Composition - Design 1 (Multi-Icon)
// 4 hayat unsuru: Hedefler, Sağlık, Gelişim, Anlar
struct LifeStyleIconComposition: View {
    var body: some View {
        ZStack {
            // Top: Star (Hedefler)
            Image(systemName: "star.fill")
                .font(.system(size: 17, weight: .bold))
                .offset(y: -35)

            // Right: Heart (Sağlık/Wellness)
            Image(systemName: "heart.fill")
                .font(.system(size: 17, weight: .bold))
                .offset(x: 35)

            // Bottom: Figure Walking (Kişisel Gelişim)
            Image(systemName: "figure.walk")
                .font(.system(size: 17, weight: .bold))
                .offset(y: 35)

            // Left: Sparkles (Hayatın Anları)
            Image(systemName: "sparkles")
                .font(.system(size: 17, weight: .bold))
                .offset(x: -35)
        }
    }
}

// MARK: - 🎯 ALTERNATİF 2: GEOMETRIC FLOW
/*
 TASARIM KONSEPT:
 - Modern geometrik şekiller (daireler, rounded rectangles)
 - Smooth morphing animasyonlar
 - Layered depth effect
 - Minimal renk kullanımı

 ANİMASYON TİMELİNE:
 0.0-0.4s: Background fade in
 0.2-0.8s: Geometric shapes morph in (staggered)
 0.5-1.0s: App name scale + fade
 0.7-1.2s: Tagline fade
 0.8-1.5s: Shapes subtle rotation

 ICON TASARIM:
 - 3 katmanlı geometrik şekil
 - Her katman farklı boyut ve opacity
 - Merkez: Rounded square
 - Orta: Circle
 - Dış: Larger circle
*/

struct SplashAlternative2: View {
    @State private var backgroundOpacity: Double = 0
    @State private var shape1Scale: CGFloat = 0.5
    @State private var shape2Scale: CGFloat = 0.5
    @State private var shape3Scale: CGFloat = 0.5
    @State private var shapesOpacity: Double = 0
    @State private var nameScale: CGFloat = 0.8
    @State private var nameOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // Background
            Color(hex: "0F172A") // Dark slate
                .ignoresSafeArea()
                .opacity(backgroundOpacity)

            VStack(spacing: 40) {
                // Geometric icon
                ZStack {
                    // Outer circle
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color(hex: "8B5CF6").opacity(0.4),
                                    Color(hex: "EC4899").opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 140, height: 140)
                        .scaleEffect(shape1Scale)
                        .opacity(shapesOpacity * 0.6)
                        .rotationEffect(.degrees(rotation))

                    // Middle circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "6366F1").opacity(0.3),
                                    Color(hex: "8B5CF6").opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .scaleEffect(shape2Scale)
                        .opacity(shapesOpacity * 0.8)
                        .rotationEffect(.degrees(-rotation * 0.5))

                    // Inner rounded square
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "6366F1"),
                                    Color(hex: "8B5CF6")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .scaleEffect(shape3Scale)
                        .opacity(shapesOpacity)

                    // Center icon
                    Image(systemName: "infinity")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.white)
                        .opacity(shapesOpacity)
                }

                // App name
                VStack(spacing: 12) {
                    Text(String(localized: "app.name", defaultValue: "LifeStyles", comment: "App name"))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .scaleEffect(nameScale)
                        .opacity(nameOpacity)

                    Text(String(localized: "splash.tagline", comment: "With You Every Moment of Life"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .opacity(taglineOpacity)
                }
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        // Background
        withAnimation(.easeOut(duration: 0.4)) {
            backgroundOpacity = 1.0
        }

        // Shapes (staggered)
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
            shape1Scale = 1.0
            shapesOpacity = 1.0
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.35)) {
            shape2Scale = 1.0
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5)) {
            shape3Scale = 1.0
        }

        // App name
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.5)) {
            nameScale = 1.0
            nameOpacity = 1.0
        }

        // Tagline
        withAnimation(.easeOut(duration: 0.5).delay(0.7)) {
            taglineOpacity = 1.0
        }

        // Subtle rotation
        withAnimation(.easeInOut(duration: 3.0).delay(0.8)) {
            rotation = 180
        }
    }
}

// MARK: - ✨ ALTERNATİF 3: GLASSMORPHIC BLOOM
/*
 TASARIM KONSEPT:
 - Glassmorphism effect (blur + transparency)
 - Katmanlı depth hissi
 - Soft shadows ve glow
 - Premium glass surface görünümü

 ANİMASYON TİMELİNE:
 0.0-0.4s: Background fade in
 0.2-0.8s: Glass layers scale + blur (staggered)
 0.5-1.0s: Icon fade in
 0.6-1.1s: App name fade + slide up
 0.8-1.3s: Tagline fade

 ICON TASARIM:
 - Merkez glass panel
 - Blur background effect
 - Layered glass circles
 - Gradient border
*/

struct SplashAlternative3: View {
    @State private var backgroundOpacity: Double = 0
    @State private var glassScale: CGFloat = 0.5
    @State private var glassOpacity: Double = 0
    @State private var iconOpacity: Double = 0
    @State private var nameOffset: CGFloat = 20
    @State private var nameOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var glowPulse: Double = 0.6

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "1E1B4B"), // Deep indigo
                    Color(hex: "312E81"),
                    Color(hex: "4C1D95")  // Purple
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .opacity(backgroundOpacity)

            VStack(spacing: 36) {
                // Glass morphic icon
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: "8B5CF6").opacity(glowPulse),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .blur(radius: 20)
                        .opacity(glassOpacity)

                    // Glass circle layers
                    ForEach(0..<3) { index in
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.05))
                                    .blur(radius: 1)
                            )
                            .frame(width: CGFloat(120 - index * 15), height: CGFloat(120 - index * 15))
                            .scaleEffect(glassScale)
                            .opacity(glassOpacity)
                    }

                    // Center icon
                    Image(systemName: "sparkles")
                        .font(.system(size: 45, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(hex: "E0E7FF")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .opacity(iconOpacity)
                        .shadow(color: .white.opacity(0.3), radius: 10)
                }

                // App name
                VStack(spacing: 12) {
                    Text(String(localized: "app.name", defaultValue: "LifeStyles", comment: "App name"))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(hex: "E0E7FF")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .offset(y: nameOffset)
                        .opacity(nameOpacity)

                    Text(String(localized: "splash.tagline", comment: "With You Every Moment of Life"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .opacity(taglineOpacity)
                }
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        // Background
        withAnimation(.easeOut(duration: 0.4)) {
            backgroundOpacity = 1.0
        }

        // Glass layers
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
            glassScale = 1.0
            glassOpacity = 1.0
        }

        // Icon
        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
            iconOpacity = 1.0
        }

        // App name
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.6)) {
            nameOffset = 0
            nameOpacity = 1.0
        }

        // Tagline
        withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
            taglineOpacity = 1.0
        }

        // Glow pulse
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowPulse = 0.9
        }
    }
}

// MARK: - 💫 ALTERNATİF 4: RADIAL PULSE
/*
 TASARIM KONSEPT:
 - Radial gradient animasyonlar
 - Merkez odaklı enerji dalgaları
 - Pulse effect (kalp atışı gibi)
 - Dynamic gradient background

 ANİMASYON TİMELİNE:
 0.0-0.4s: Background fade in
 0.2-0.7s: Central pulse appears
 0.3-0.8s: Radial rings expand
 0.5-1.0s: Icon scale + fade
 0.7-1.2s: App name appear
 0.9-1.4s: Tagline appear
 1.0+: Continuous subtle pulse

 ICON TASARIM:
 - Merkez radial gradient
 - Expanding pulse rings
 - Energy waves effect
 - SF Symbol: bolt.heart.fill (enerji + yaşam)
*/

struct SplashAlternative4: View {
    @State private var backgroundOpacity: Double = 0
    @State private var pulseScale1: CGFloat = 0.8
    @State private var pulseScale2: CGFloat = 0.6
    @State private var pulseScale3: CGFloat = 0.4
    @State private var pulseOpacity: Double = 0
    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0
    @State private var nameOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var continuousPulse: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Dynamic gradient background
            RadialGradient(
                colors: [
                    Color(hex: "4C1D95"),
                    Color(hex: "1E1B4B"),
                    Color.black
                ],
                center: .center,
                startRadius: 100,
                endRadius: 500
            )
            .ignoresSafeArea()
            .opacity(backgroundOpacity)

            VStack(spacing: 40) {
                // Radial pulse icon
                ZStack {
                    // Pulse rings
                    ForEach([
                        (scale: pulseScale3, opacity: 0.15),
                        (scale: pulseScale2, opacity: 0.25),
                        (scale: pulseScale1, opacity: 0.35)
                    ], id: \.scale) { ring in
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "8B5CF6"),
                                        Color(hex: "EC4899")
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 120, height: 120)
                            .scaleEffect(ring.scale)
                            .opacity(pulseOpacity * ring.opacity)
                    }

                    // Center radial gradient
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: "8B5CF6"),
                                    Color(hex: "6366F1"),
                                    Color(hex: "4C1D95")
                                ],
                                center: .center,
                                startRadius: 5,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(iconScale)
                        .opacity(iconOpacity)

                    // Icon
                    Image(systemName: "bolt.heart.fill")
                        .font(.system(size: 50, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(hex: "FDE68A")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .scaleEffect(continuousPulse)
                        .opacity(iconOpacity)
                }

                // App name
                VStack(spacing: 12) {
                    Text(String(localized: "app.name", defaultValue: "LifeStyles", comment: "App name"))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(hex: "E0E7FF")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .opacity(nameOpacity)

                    Text(String(localized: "splash.tagline", comment: "With You Every Moment of Life"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .opacity(taglineOpacity)
                }
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        // Background
        withAnimation(.easeOut(duration: 0.4)) {
            backgroundOpacity = 1.0
        }

        // Central pulse
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2)) {
            pulseOpacity = 1.0
        }

        // Radial rings (staggered expansion)
        withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
            pulseScale1 = 1.3
        }
        withAnimation(.easeOut(duration: 0.7).delay(0.4)) {
            pulseScale2 = 1.6
        }
        withAnimation(.easeOut(duration: 0.8).delay(0.5)) {
            pulseScale3 = 1.9
        }

        // Icon
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }

        // App name
        withAnimation(.easeOut(duration: 0.5).delay(0.7)) {
            nameOpacity = 1.0
        }

        // Tagline
        withAnimation(.easeOut(duration: 0.5).delay(0.9)) {
            taglineOpacity = 1.0
        }

        // Continuous pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                continuousPulse = 1.1
            }
        }
    }
}

// MARK: - Preview

#Preview("Alternative 1 - Minimal Luxury") {
    SplashAlternative1()
}

#Preview("Alternative 2 - Geometric Flow") {
    SplashAlternative2()
}

#Preview("Alternative 3 - Glassmorphic Bloom") {
    SplashAlternative3()
}

#Preview("Alternative 4 - Radial Pulse") {
    SplashAlternative4()
}

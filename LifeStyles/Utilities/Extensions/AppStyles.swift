//
//  AppStyles.swift
//  LifeStyles
//
//  Custom ViewModifier'lar ve stil bileşenleri
//  Modern, glassmorphism ve animasyonlu stiller
//  iOS 26 Liquid Glass desteği ile güncellenmiş
//

import SwiftUI

// MARK: - Liquid Glass Support

/// Liquid Glass material modifier - Modern glass effect with backward compatibility
struct LiquidGlassMaterialModifier: ViewModifier {
    var tintColor: Color = .white
    var opacity: Double = 0.2
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        if #available(iOS 26.0, macOS 15.0, *) {
            // Use the new native Liquid Glass effect for iOS 26+
            content
                .glassEffect(.regular.tint(tintColor.opacity(opacity)), in: .rect(cornerRadius: cornerRadius))
        } else {
            // Fallback to traditional glass effect for older versions
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(tintColor.opacity(opacity))
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(tintColor.opacity(0.1), lineWidth: 0.5)
                )
        }
    }
}

/// Enhanced animation modifier with smooth transitions
struct EnhancedAnimationModifier: ViewModifier {
    @State private var isAnimating = false
    var duration: Double = 1.0
    var delay: Double = 0

    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? 1.0 : 0.95)
            .opacity(isAnimating ? 1.0 : 0.0)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .delay(delay)
                ) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Card Styles

/// Modern card modifier - soft shadow ve rounded corners
struct CardModifier: ViewModifier {
    var backgroundColor: Color = .backgroundSecondary
    var cornerRadius: CGFloat = 16
    var shadowRadius: CGFloat = 8
    var shadowOpacity: Double = 0.08

    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(shadowOpacity), radius: shadowRadius, x: 0, y: 4)
    }
}

/// Glassmorphism card modifier - yarı saydam, blur efekti
struct GlassCardModifier: ViewModifier {
    var tintColor: Color = .white
    var opacity: Double = 0.2
    var blurRadius: CGFloat = 10
    var cornerRadius: CGFloat = 20
    var borderColor: Color?
    var borderWidth: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(tintColor.opacity(opacity))
                    .background(.ultraThinMaterial)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor ?? tintColor.opacity(0.2), lineWidth: borderWidth)
            )
    }
}

/// Gradient card modifier - arka planda gradient
struct GradientCardModifier: ViewModifier {
    var gradient: LinearGradient = .primaryGradient
    var cornerRadius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Button Styles

/// Primary button style - gradient background
struct PrimaryButtonStyle: ButtonStyle {
    var gradient: LinearGradient = .primaryGradient
    var foregroundColor: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
}

/// Secondary button style - outline border
struct SecondaryButtonStyle: ButtonStyle {
    var color: Color = .brandPrimary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(color, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Icon button style - küçük, circular
struct IconButtonStyle: ButtonStyle {
    var backgroundColor: Color = .backgroundTertiary
    var foregroundColor: Color = .brandPrimary
    var size: CGFloat = 44

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3)
            .foregroundStyle(foregroundColor)
            .frame(width: size, height: size)
            .background(backgroundColor)
            .clipShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Text Styles

/// Başlık text modifier
struct TitleTextModifier: ViewModifier {
    var color: Color = .textPrimary

    func body(content: Content) -> some View {
        content
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .foregroundStyle(color)
    }
}

/// Alt başlık text modifier
struct SubtitleTextModifier: ViewModifier {
    var color: Color = .textSecondary

    func body(content: Content) -> some View {
        content
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundStyle(color)
    }
}

/// Vurgu text modifier - gradient text
struct GradientTextModifier: ViewModifier {
    var gradient: LinearGradient = .primaryGradient

    func body(content: Content) -> some View {
        content
            .foregroundStyle(gradient)
    }
}

// MARK: - Input Styles

/// Text field modifier
struct TextFieldModifier: ViewModifier {
    var backgroundColor: Color = .backgroundSecondary
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .padding()
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.textTertiary.opacity(0.2), lineWidth: 1)
            )
    }
}

// MARK: - Animation Modifiers

/// Shimmer loading effect
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    var duration: Double = 1.5

    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.3),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(30))
                    .offset(x: phase)
            )
            .onAppear {
                withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                    phase = 500
                }
            }
    }
}

/// Pulse animation
struct PulseModifier: ViewModifier {
    @State private var isAnimating = false
    var duration: Double = 1.0
    var minScale: CGFloat = 0.95

    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? 1.0 : minScale)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
}

/// Bounce animation
struct BounceModifier: ViewModifier {
    @State private var isAnimating = false
    var delay: Double = 0

    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? 1.0 : 0.8)
            .opacity(isAnimating ? 1.0 : 0.0)
            .onAppear {
                withAnimation(
                    .spring(response: 0.6, dampingFraction: 0.7)
                    .delay(delay)
                ) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - View Extensions

extension View {
    // Card Styles
    func cardStyle(
        backgroundColor: Color = .backgroundSecondary,
        cornerRadius: CGFloat = 16,
        shadowRadius: CGFloat = 8,
        shadowOpacity: Double = 0.08
    ) -> some View {
        modifier(CardModifier(
            backgroundColor: backgroundColor,
            cornerRadius: cornerRadius,
            shadowRadius: shadowRadius,
            shadowOpacity: shadowOpacity
        ))
    }

    func glassCard(
        tintColor: Color = .white,
        opacity: Double = 0.2,
        blurRadius: CGFloat = 10,
        cornerRadius: CGFloat = 20,
        borderColor: Color? = nil,
        borderWidth: CGFloat = 1
    ) -> some View {
        modifier(GlassCardModifier(
            tintColor: tintColor,
            opacity: opacity,
            blurRadius: blurRadius,
            cornerRadius: cornerRadius,
            borderColor: borderColor,
            borderWidth: borderWidth
        ))
    }

    func gradientCard(
        gradient: LinearGradient = .primaryGradient,
        cornerRadius: CGFloat = 16
    ) -> some View {
        modifier(GradientCardModifier(
            gradient: gradient,
            cornerRadius: cornerRadius
        ))
    }

    // Text Styles
    func titleText(color: Color = .textPrimary) -> some View {
        modifier(TitleTextModifier(color: color))
    }

    func subtitleText(color: Color = .textSecondary) -> some View {
        modifier(SubtitleTextModifier(color: color))
    }

    func gradientText(gradient: LinearGradient = .primaryGradient) -> some View {
        modifier(GradientTextModifier(gradient: gradient))
    }

    func metadataText() -> some View {
        self
            .font(.caption2)
            .foregroundStyle(.secondary)
    }

    func cardTitle() -> some View {
        self
            .font(.headline)
            .fontWeight(.bold)
            .foregroundStyle(.primary)
    }

    func secondaryText() -> some View {
        self
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    func cardShadow(radius: CGFloat = 8, y: CGFloat = 4) -> some View {
        self
            .shadow(color: .black.opacity(0.1), radius: radius, x: 0, y: y)
    }

    // Input Styles
    func textFieldStyle(
        backgroundColor: Color = .backgroundSecondary,
        cornerRadius: CGFloat = 12
    ) -> some View {
        modifier(TextFieldModifier(
            backgroundColor: backgroundColor,
            cornerRadius: cornerRadius
        ))
    }

    // Animation Styles
    func shimmer(duration: Double = 1.5) -> some View {
        modifier(ShimmerModifier(duration: duration))
    }

    func pulse(duration: Double = 1.0, minScale: CGFloat = 0.95) -> some View {
        modifier(PulseModifier(duration: duration, minScale: minScale))
    }

    func bounce(delay: Double = 0) -> some View {
        modifier(BounceModifier(delay: delay))
    }

    // iOS 26 Liquid Glass
    /// Liquid Glass efekti - Modern glass material
    func liquidGlass(
        tintColor: Color = .white,
        opacity: Double = 0.2,
        cornerRadius: CGFloat = 20
    ) -> some View {
        modifier(LiquidGlassMaterialModifier(
            tintColor: tintColor,
            opacity: opacity,
            cornerRadius: cornerRadius
        ))
    }

    /// Glassmorphism card efekti - Alias for glassCard
    func glassmorphismCard(
        tintColor: Color = .white,
        opacity: Double = 0.2,
        blurRadius: CGFloat = 10,
        cornerRadius: CGFloat = 20,
        borderColor: Color? = nil,
        borderWidth: CGFloat = 1
    ) -> some View {
        glassCard(
            tintColor: tintColor,
            opacity: opacity,
            blurRadius: blurRadius,
            cornerRadius: cornerRadius,
            borderColor: borderColor,
            borderWidth: borderWidth
        )
    }

    /// Gelişmiş smooth animasyon
    func enhancedAnimation(duration: Double = 1.0, delay: Double = 0) -> some View {
        modifier(EnhancedAnimationModifier(duration: duration, delay: delay))
    }
}



//
//  AppConstants.swift
//  LifeStyles
//
//  Created by Claude on 15.10.2025.
//

import SwiftUI

/// App genelindeki sabitler
struct AppConstants {
    
    // MARK: - Spacing
    struct Spacing {
        static let micro: CGFloat = 2
        static let tiny: CGFloat = 4
        static let extraSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xlarge: CGFloat = 32 // Alias for extraLarge
        static let extraLarge: CGFloat = 32
        static let xxlarge: CGFloat = 48 // Alias for huge
        static let huge: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let tight: CGFloat = 6
        static let compact: CGFloat = 8
        static let small: CGFloat = 8
        static let normal: CGFloat = 12 // Alias for medium
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let rounded: CGFloat = 16
        static let relaxed: CGFloat = 18
        static let card: CGFloat = 20
        static let button: CGFloat = 24
    }
    
    // MARK: - Animation
    struct Animation {
        static let fast = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let normal = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.8)
    }
    
    // MARK: - Opacity
    struct Opacity {
        static let disabled: Double = 0.6
        static let secondary: Double = 0.8
        static let overlay: Double = 0.1
    }
}

// MARK: - Global Typealiases (for backward compatibility)
typealias Spacing = AppConstants.Spacing
typealias CornerRadius = AppConstants.CornerRadius
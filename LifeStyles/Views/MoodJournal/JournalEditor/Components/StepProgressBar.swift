//
//  StepProgressBar.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Modern step progress indicator for journal editor
//

import SwiftUI

struct StepProgressBar: View {
    let currentStep: JournalStep

    var body: some View {
        VStack(spacing: Spacing.small) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(JournalStep.allCases, id: \.self) { step in
                    Circle()
                        .fill(step.rawValue <= currentStep.rawValue ? Color.brandPrimary : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(step == currentStep ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentStep)
                }
            }

            // Current step title
            Text(currentStep.title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .animation(.none, value: currentStep)
        }
        .padding(.vertical, Spacing.medium)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    VStack(spacing: 20) {
        ForEach(JournalStep.allCases, id: \.self) { step in
            StepProgressBar(currentStep: step)
        }
    }
    .padding()
}

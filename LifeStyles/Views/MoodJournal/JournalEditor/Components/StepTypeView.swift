//
//  StepTypeView.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Journal editor - Type selection step
//

import SwiftUI

struct StepTypeView: View {
    @Bindable var state: JournalEditorState

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.large) {
                // Header
                VStack(spacing: Spacing.small) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.brandPrimary, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text(String(localized: "journal.type.question", comment: "What type of journal do you want to write?"))
                        .font(.title3)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text(String(localized: "journal.type.instruction", comment: "Start by selecting journal type"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Spacing.xlarge)

                // Journal Type Cards (Compact)
                VStack(spacing: Spacing.medium) {
                    ForEach(JournalType.allCases, id: \.self) { type in
                        TypeCard(
                            type: type,
                            isSelected: state.selectedType == type,
                            onSelect: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    state.selectedType = type
                                }
                                HapticFeedback.light()
                            }
                        )
                    }
                }
            }
            .padding(Spacing.large)
        }
    }
}

#Preview {
    StepTypeView(state: JournalEditorState())
}

//
//  StepContentView.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Journal editor - Content textarea step
//

import SwiftUI

struct StepContentView: View {
    @Bindable var state: JournalEditorState

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: Spacing.medium) {
                    // Compact Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "journal.write.content", comment: "Write your content"))
                                .font(.headline)
                                .fontWeight(.bold)

                            Text(state.selectedType.aiPrompt)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(state.selectedType.emoji)
                            .font(.title2)
                    }
                    .padding(.horizontal, Spacing.large)
                    .padding(.top, Spacing.small)

                    // Modern Text Editor - Dynamic height
                    ModernTextEditor(
                        text: $state.content,
                        placeholder: state.selectedType.aiPrompt,
                        minHeight: max(200, geometry.size.height * 0.5),
                        showCounter: true,
                        maxCharacters: 5000
                    )
                    .frame(height: max(250, geometry.size.height * 0.65))
                    .padding(.horizontal, Spacing.large)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
}

#Preview {
    StepContentView(state: JournalEditorState())
}

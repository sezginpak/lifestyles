//
//  StepTitleView.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Journal editor - Title input step
//

import SwiftUI

struct StepTitleView: View {
    @Bindable var state: JournalEditorState

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xlarge) {
                // Compact Header
                VStack(spacing: Spacing.small) {
                    Image(systemName: "text.cursor")
                        .font(.system(size: 40))
                        .foregroundStyle(state.selectedType.color)

                    Text(String(localized: "journal.add.title", comment: "Add title"))
                        .font(.title3)
                        .fontWeight(.bold)

                    Text(String(localized: "journal.title.optional", comment: "Optional - you can skip"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, Spacing.large)

                // Title Input
                TextField("Başlık (opsiyonel)", text: $state.title)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .fontWeight(.medium)
                    .padding(Spacing.large)
                    .glassmorphismCard(
                        cornerRadius: CornerRadius.medium
                    )

                // Bottom padding for keyboard
                Color.clear.frame(height: 80)
            }
            .padding(Spacing.large)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

#Preview {
    StepTitleView(state: JournalEditorState())
}

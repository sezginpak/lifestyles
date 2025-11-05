//
//  EditorState.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Shared state object for journal editor
//

import SwiftUI

@Observable
final class JournalEditorState {
    // MARK: - Properties
    var currentStep: JournalStep = .type
    var selectedType: JournalType = .general
    var title: String = ""
    var content: String = ""
    var selectedTags: [String] = []
    var linkToMood: Bool = false
    var isSaving: Bool = false

    // MARK: - Validation
    var canProceed: Bool {
        switch currentStep {
        case .type:
            return true
        case .title:
            return true // Optional field
        case .content:
            return !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .tags:
            return true // Optional field
        case .review:
            return !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    // MARK: - Methods
    func reset() {
        currentStep = .type
        selectedType = .general
        title = ""
        content = ""
        selectedTags = []
        linkToMood = false
        isSaving = false
    }

    func populate(from entry: JournalEntry) {
        selectedType = entry.journalType
        title = entry.title ?? ""
        content = entry.content
        selectedTags = entry.tags
    }

    func nextStep() {
        guard let next = JournalStep(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = next
    }

    func previousStep() {
        guard let prev = JournalStep(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = prev
    }
}

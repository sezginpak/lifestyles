//
//  JournalStep.swift
//  LifeStyles
//
//  Created by Claude on 05.11.2025.
//  Journal editor step enum
//

import Foundation

enum JournalStep: Int, CaseIterable {
    case type = 0
    case title = 1
    case content = 2
    case tags = 3
    case review = 4

    var title: String {
        switch self {
        case .type: return String(localized: "journal.step.type", defaultValue: "Journal Tipi", comment: "Step: Journal Type")
        case .title: return String(localized: "journal.step.title", defaultValue: "Başlık", comment: "Step: Title")
        case .content: return String(localized: "journal.step.content", defaultValue: "İçerik", comment: "Step: Content")
        case .tags: return String(localized: "journal.step.tags", defaultValue: "Etiketler", comment: "Step: Tags")
        case .review: return String(localized: "journal.step.review", defaultValue: "Önizleme", comment: "Step: Review")
        }
    }

    var icon: String {
        switch self {
        case .type: return "doc.text"
        case .title: return "text.cursor"
        case .content: return "pencil.line"
        case .tags: return "tag"
        case .review: return "checkmark.circle"
        }
    }

    var canSkip: Bool {
        switch self {
        case .title, .tags: return true
        default: return false
        }
    }
}

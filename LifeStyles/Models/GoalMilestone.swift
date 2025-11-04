//
//  GoalMilestone.swift
//  LifeStyles
//
//  Created by Claude on 21.10.2025.
//  Hedeflere ara adımlar/milestone eklemek için
//

import Foundation
import SwiftData

@Model
final class GoalMilestone {
    var id: UUID = UUID()
    var title: String = ""
    var isCompleted: Bool = false
    var completedAt: Date?
    var order: Int = 0 // Sıralama (0, 1, 2...)
    var createdAt: Date = Date()

    @Relationship(deleteRule: .nullify, inverse: \Goal.milestones)
    var goal: Goal?

    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        order: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.order = order
        self.createdAt = createdAt
    }

    /// Milestone'u tamamla
    func complete() {
        isCompleted = true
        completedAt = Date()
    }

    /// Milestone tamamlamayı geri al
    func uncomplete() {
        isCompleted = false
        completedAt = nil
    }
}

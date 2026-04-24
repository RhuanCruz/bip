import Foundation
import SwiftData

@Model
final class Task {
    @Attribute(.unique) var id: UUID
    var title: String
    var isCompleted: Bool
    var scheduledAt: Date?
    var durationMinutes: Int?
    var rawInput: String
    var createdAt: Date
    var updatedAt: Date

    var category: Category?

    @Relationship(deleteRule: .cascade, inverse: \Recurrence.task)
    var recurrence: Recurrence?

    @Relationship(deleteRule: .cascade, inverse: \Reminder.task)
    var reminder: Reminder?

    var parentTask: Task?

    @Relationship(deleteRule: .cascade, inverse: \Task.parentTask)
    var subtasks: [Task]

    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        scheduledAt: Date? = nil,
        durationMinutes: Int? = 60,
        rawInput: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        category: Category? = nil,
        recurrence: Recurrence? = nil,
        reminder: Reminder? = nil,
        parentTask: Task? = nil,
        subtasks: [Task] = []
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.scheduledAt = scheduledAt
        self.durationMinutes = durationMinutes
        self.rawInput = rawInput
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.category = category
        self.recurrence = recurrence
        self.reminder = reminder
        self.parentTask = parentTask
        self.subtasks = subtasks
    }

    var resolvedDurationMinutes: Int {
        max(15, durationMinutes ?? 60)
    }
}

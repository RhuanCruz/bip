import Foundation

enum TaskOccurrencePolicy {
    static func occurs(_ task: Task, on date: Date, calendar: Calendar = .current) -> Bool {
        guard let scheduledAt = task.scheduledAt else {
            return calendar.isDateInToday(date)
        }

        guard calendar.startOfDay(for: date) >= calendar.startOfDay(for: scheduledAt) else {
            return false
        }

        guard let recurrence = task.recurrence, recurrence.type != .none else {
            return calendar.isDate(scheduledAt, inSameDayAs: date)
        }

        switch recurrence.type {
        case .none:
            return calendar.isDate(scheduledAt, inSameDayAs: date)
        case .daily:
            return true
        case .weekly:
            return calendar.component(.weekday, from: scheduledAt) == calendar.component(.weekday, from: date)
        case .custom:
            return recurrence.daysOfWeek.contains(calendar.component(.weekday, from: date))
        }
    }
}

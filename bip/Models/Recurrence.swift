import Foundation
import SwiftData

enum RecurrenceType: String, Codable, CaseIterable, Identifiable {
    case none
    case daily
    case weekly
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none:
            "None"
        case .daily:
            "Daily"
        case .weekly:
            "Weekly"
        case .custom:
            "Custom"
        }
    }
}

@Model
final class Recurrence {
    var id: UUID = UUID()
    var type: RecurrenceType = RecurrenceType.none
    var daysOfWeek: [Int] = []
    var task: Task?

    init(
        id: UUID = UUID(),
        type: RecurrenceType = .none,
        daysOfWeek: [Int] = []
    ) {
        self.id = id
        self.type = type
        self.daysOfWeek = daysOfWeek
    }
}

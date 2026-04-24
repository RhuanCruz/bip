import Foundation

enum MainViewMode: String, CaseIterable, Identifiable {
    case tasks = "Tasks"
    case calendar = "Calendar"

    var id: String { rawValue }

    mutating func toggle() {
        self = self == .tasks ? .calendar : .tasks
    }
}

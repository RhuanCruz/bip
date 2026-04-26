import Foundation

enum MainViewMode: String, CaseIterable, Identifiable {
    case tasks = "Tasks"
    case calendar = "Calendar"
    case bip = "BIP"

    var id: String { rawValue }

    mutating func toggle() {
        switch self {
        case .tasks:
            self = .calendar
        case .calendar:
            self = .bip
        case .bip:
            self = .tasks
        }
    }
}

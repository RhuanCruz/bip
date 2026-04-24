import Foundation

enum SheetDestination: Identifiable {
    case datePicker
    case taskDetail(Task)
    case moreMenu
    case categories

    var id: String {
        switch self {
        case .datePicker:
            "datePicker"
        case .taskDetail(let task):
            "taskDetail-\(task.id.uuidString)"
        case .moreMenu:
            "moreMenu"
        case .categories:
            "categories"
        }
    }
}

import Foundation

enum SheetDestination: Identifiable {
    case datePicker
    case taskDetail(Task)
    case taskEditor(Task)
    case moreMenu
    case categories
    case geminiSettings
    case postComposer

    var id: String {
        switch self {
        case .datePicker:
            "datePicker"
        case .taskDetail(let task):
            "taskDetail-\(task.id.uuidString)"
        case .taskEditor(let task):
            "taskEditor-\(task.id.uuidString)"
        case .moreMenu:
            "moreMenu"
        case .categories:
            "categories"
        case .geminiSettings:
            "geminiSettings"
        case .postComposer:
            "postComposer"
        }
    }
}

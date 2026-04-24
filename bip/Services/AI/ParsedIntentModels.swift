import Foundation

struct ParsedIntentPlan: Decodable {
    var transcript: String?
    var items: [ParsedIntentItem]
    var needsConfirmation: Bool
    var question: String?
}

struct ParsedIntentItem: Decodable {
    var kind: ParsedIntentKind
    var title: String
    var rawInput: String?
    var scheduledAt: String?
    var durationMinutes: Int?
    var categoryName: String?
    var categorySymbolName: String?
    var recurrence: ParsedRecurrence?
    var reminder: ParsedReminder?
    var subtasks: [String]

    private enum CodingKeys: String, CodingKey {
        case kind
        case title
        case rawInput
        case scheduledAt
        case durationMinutes
        case categoryName
        case categorySymbolName
        case recurrence
        case reminder
        case subtasks
    }
}

enum ParsedIntentKind: String, Decodable {
    case task
    case event
}

struct ParsedRecurrence: Decodable {
    var type: RecurrenceType
    var daysOfWeek: [Int]
}

struct ParsedReminder: Decodable {
    var enabled: Bool
    var offsetMinutes: Int
}

enum ParsedIntentInput {
    case text(String)
    case audio(fileURL: URL, mimeType: String)
}

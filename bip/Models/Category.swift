import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID = UUID()
    var name: String = ""
    var colorHex: String = "#A0A0A0"
    var symbolName: String = "tag"

    @Relationship(deleteRule: .nullify, inverse: \Task.category)
    var tasks: [Task]?

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String,
        symbolName: String
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.symbolName = symbolName
        self.tasks = []
    }

    var taskCount: Int {
        tasks?.count ?? 0
    }
}

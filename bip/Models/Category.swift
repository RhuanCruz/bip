import Foundation
import SwiftData

@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHex: String
    var symbolName: String

    @Relationship(deleteRule: .nullify, inverse: \Task.category)
    var tasks: [Task]

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
}

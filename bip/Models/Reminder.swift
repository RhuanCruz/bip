import Foundation
import SwiftData

@Model
final class Reminder {
    @Attribute(.unique) var id: UUID
    var enabled: Bool
    var offsetMinutes: Int
    var task: Task?

    init(
        id: UUID = UUID(),
        enabled: Bool = false,
        offsetMinutes: Int = 0
    ) {
        self.id = id
        self.enabled = enabled
        self.offsetMinutes = offsetMinutes
    }
}

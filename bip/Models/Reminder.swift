import Foundation
import SwiftData

@Model
final class Reminder {
    var id: UUID = UUID()
    var enabled: Bool = false
    var offsetMinutes: Int = 0
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

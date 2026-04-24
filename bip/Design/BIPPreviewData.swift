import Foundation
import SwiftData

@MainActor
enum BIPPreviewData {
    static func container() -> ModelContainer {
        let schema = Schema([
            Task.self,
            Recurrence.self,
            Reminder.self,
            Category.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        seed(into: container.mainContext)
        return container
    }

    static func seed(into context: ModelContext) {
        let home = Category(name: "Home", colorHex: "#8F8F8F", symbolName: "house")
        let fitness = Category(name: "Fitness", colorHex: "#A0A0A0", symbolName: "figure.strengthtraining.traditional")
        context.insert(home)
        context.insert(fitness)

        let morning = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
        let lunch = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()
        let evening = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date()

        context.insert(Task(title: "Sair com os cachorros", isCompleted: true, scheduledAt: morning, rawInput: "Sair com os cachorros", category: home, recurrence: Recurrence(type: .daily)))
        context.insert(Task(title: "Lavar a louça", scheduledAt: lunch, rawInput: "Lavar a louça", category: home))
        context.insert(Task(title: "Academia", scheduledAt: evening, rawInput: "Academia", category: fitness, recurrence: Recurrence(type: .weekly, daysOfWeek: [2, 3, 4])))
    }
}

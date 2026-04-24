import Foundation
import SwiftData

@MainActor
struct NaturalLanguageTaskService {
    func createItems(
        from input: ParsedIntentInput,
        selectedDate: Date,
        parentTask: Task?,
        categories: [Category],
        existingTasks: [Task],
        modelContext: ModelContext
    ) async throws {
        let parser = try GeminiIntentParser.live()
        let plan = try await parser.parse(
            input: input,
            context: parsingContext(selectedDate: selectedDate, parentTask: parentTask, existingTasks: existingTasks)
        )

        insert(plan: plan, fallbackInput: fallbackText(for: input), selectedDate: selectedDate, parentTask: parentTask, categories: categories, modelContext: modelContext)
    }

    private func insert(
        plan: ParsedIntentPlan,
        fallbackInput: String,
        selectedDate: Date,
        parentTask: Task?,
        categories: [Category],
        modelContext: ModelContext
    ) {
        guard !plan.items.isEmpty else {
            return
        }

        var knownCategories = categories

        if let parentTask, let item = plan.items.first {
            update(parentTask, with: item, plan: plan, fallbackInput: fallbackInput, selectedDate: selectedDate, categories: &knownCategories, modelContext: modelContext)
            return
        }

        for item in plan.items {
            insert(item: item, plan: plan, fallbackInput: fallbackInput, selectedDate: selectedDate, parentTask: nil, categories: &knownCategories, modelContext: modelContext)
        }
    }

    private func insert(
        item: ParsedIntentItem,
        plan: ParsedIntentPlan,
        fallbackInput: String,
        selectedDate: Date,
        parentTask: Task?,
        categories: inout [Category],
        modelContext: ModelContext
    ) {
        let category = category(named: item.categoryName, symbolName: item.categorySymbolName, in: &categories, modelContext: modelContext)
        let scheduledAt = date(from: item.scheduledAt) ?? selectedDate
        let task = Task(
            title: item.title,
            scheduledAt: scheduledAt,
            durationMinutes: max(15, item.durationMinutes ?? defaultDuration(for: item.kind)),
            rawInput: item.rawInput ?? plan.transcript ?? fallbackInput,
            category: category,
            parentTask: parentTask
        )

        applyRecurrence(item.recurrence, to: task, modelContext: modelContext)
        applyReminder(item.reminder, to: task, modelContext: modelContext)

        let subtasks = subtaskModels(from: item.subtasks, scheduledAt: scheduledAt, category: category, parentTask: task)
        task.subtasks = subtasks
        modelContext.insert(task)
        subtasks.forEach { modelContext.insert($0) }
    }

    private func update(
        _ task: Task,
        with item: ParsedIntentItem,
        plan: ParsedIntentPlan,
        fallbackInput: String,
        selectedDate: Date,
        categories: inout [Category],
        modelContext: ModelContext
    ) {
        let category = category(named: item.categoryName ?? task.category?.name, symbolName: item.categorySymbolName ?? task.category?.symbolName, in: &categories, modelContext: modelContext)
        let scheduledAt = date(from: item.scheduledAt) ?? task.scheduledAt ?? selectedDate

        let trimmedTitle = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTitle.isEmpty, trimmedTitle.localizedCaseInsensitiveCompare(task.title) != .orderedSame {
            task.title = trimmedTitle
        }
        task.scheduledAt = scheduledAt
        task.durationMinutes = max(15, item.durationMinutes ?? task.resolvedDurationMinutes)
        task.rawInput = item.rawInput ?? plan.transcript ?? fallbackInput
        task.category = category
        task.updatedAt = Date()

        applyRecurrence(item.recurrence, to: task, modelContext: modelContext)
        applyReminder(item.reminder, to: task, modelContext: modelContext)
        mergeSubtasks(item.subtasks, into: task, scheduledAt: scheduledAt, category: category, modelContext: modelContext)
    }

    private func parsingContext(selectedDate: Date, parentTask: Task?, existingTasks: [Task]) -> IntentParsingContext {
        IntentParsingContext(
            now: Date(),
            selectedDate: selectedDate,
            timeZone: .current,
            existingItems: existingTasks.compactMap { task in
                guard let scheduledAt = task.scheduledAt else { return nil }
                return ExistingScheduleItem(
                    title: task.title,
                    scheduledAt: Self.isoFormatter.string(from: scheduledAt),
                    durationMinutes: task.resolvedDurationMinutes
                )
            },
            contextTask: contextTaskItem(from: parentTask)
        )
    }

    private func contextTaskItem(from task: Task?) -> ContextTaskItem? {
        guard let task else { return nil }

        return ContextTaskItem(
            title: task.title,
            scheduledAt: task.scheduledAt.map { Self.isoFormatter.string(from: $0) },
            durationMinutes: task.resolvedDurationMinutes,
            categoryName: task.category?.name,
            subtasks: task.childTasks.map(\.title)
        )
    }

    private func category(named name: String?, symbolName: String?, in categories: inout [Category], modelContext: ModelContext) -> Category {
        let categoryName = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedName = categoryName?.isEmpty == false ? categoryName! : "Personal"

        if let category = categories.first(where: { $0.name.localizedCaseInsensitiveCompare(resolvedName) == .orderedSame }) {
            return category
        }

        let category = createCategory(
            name: resolvedName,
            symbolName: symbolName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? symbolName! : "tag",
            modelContext: modelContext
        )
        categories.append(category)
        return category
    }

    private func createCategory(name: String, symbolName: String, modelContext: ModelContext) -> Category {
        let category = Category(name: name, colorHex: "#A0A0A0", symbolName: symbolName)
        modelContext.insert(category)
        return category
    }

    private func defaultDuration(for kind: ParsedIntentKind) -> Int {
        kind == .event ? 60 : 30
    }

    private func applyRecurrence(_ recurrence: ParsedRecurrence?, to task: Task, modelContext: ModelContext) {
        guard let recurrence, recurrence.type != .none else { return }

        let model = task.recurrence ?? Recurrence()
        model.type = recurrence.type
        model.daysOfWeek = recurrence.daysOfWeek
        model.task = task
        task.recurrence = model
        modelContext.insert(model)
    }

    private func applyReminder(_ reminder: ParsedReminder?, to task: Task, modelContext: ModelContext) {
        guard let reminder, reminder.enabled else { return }

        let model = task.reminder ?? Reminder()
        model.enabled = true
        model.offsetMinutes = reminder.offsetMinutes
        model.task = task
        task.reminder = model
        modelContext.insert(model)
    }

    private func subtaskModels(from titles: [String], scheduledAt: Date, category: Category, parentTask: Task) -> [Task] {
        titles
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { title in
                Task(
                    title: title,
                    scheduledAt: scheduledAt,
                    rawInput: title,
                    category: category,
                    parentTask: parentTask
                )
            }
    }

    private func mergeSubtasks(_ titles: [String], into task: Task, scheduledAt: Date, category: Category, modelContext: ModelContext) {
        let newTitles = titles
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !newTitles.isEmpty else { return }

        var subtasks = task.subtasks ?? []
        let existingTitles = Set(subtasks.map { $0.title.lowercased() })

        for title in newTitles where !existingTitles.contains(title.lowercased()) {
            let subtask = Task(title: title, scheduledAt: scheduledAt, rawInput: title, category: category, parentTask: task)
            subtasks.append(subtask)
            modelContext.insert(subtask)
        }

        task.subtasks = subtasks
    }

    private func fallbackText(for input: ParsedIntentInput) -> String {
        switch input {
        case .text(let text):
            text
        case .audio:
            "Voice input"
        }
    }

    private func date(from text: String?) -> Date? {
        guard let text, !text.isEmpty else { return nil }
        return Self.isoFormatter.date(from: text) ?? Self.fractionalISOFormatter.date(from: text)
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let fractionalISOFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

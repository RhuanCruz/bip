import SwiftData
import SwiftUI

struct TaskRowView: View {
    @Bindable var task: Task
    let onOpen: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: BIPSpacing.medium) {
            VStack(alignment: .leading, spacing: 2) {
                Text(categoryPrefix)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(BIPTheme.muted)
                    .lineLimit(1)
                    .frame(width: 20, alignment: .leading)

                CategoryIconView(category: task.category, size: 22)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(BIPTheme.textPrimary)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(BIPTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: BIPSpacing.medium)

            CompletionToggle(isCompleted: $task.isCompleted)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
        .padding(.vertical, 4)
    }

    private var categoryPrefix: String {
        guard let name = task.category?.name, !name.isEmpty else { return "..." }
        return String(name.lowercased().prefix(1)) + "..."
    }

    private var subtitle: String {
        let recurrence = recurrenceText
        let time = task.scheduledAt.map { Self.timeFormatter.string(from: $0) }

        switch (recurrence, time) {
        case let (recurrence?, time?):
            return "\(recurrence) às \(time)"
        case let (nil, time?):
            return "às \(time)"
        case let (recurrence?, nil):
            return recurrence
        default:
            return "No schedule"
        }
    }

    private var recurrenceText: String? {
        guard let recurrence = task.recurrence else { return nil }
        switch recurrence.type {
        case .none:
            return nil
        case .daily:
            return "Todo dia"
        case .weekly:
            return recurrence.daysOfWeek.isEmpty ? "Weekly" : weekdayText(for: recurrence.daysOfWeek)
        case .custom:
            return recurrence.daysOfWeek.isEmpty ? "Custom" : weekdayText(for: recurrence.daysOfWeek)
        }
    }

    private func weekdayText(for days: [Int]) -> String {
        let symbols = Foundation.Calendar.current.shortWeekdaySymbols
        return days.sorted().compactMap { day in
            guard symbols.indices.contains(day - 1) else { return nil }
            return symbols[day - 1].capitalized
        }.joined(separator: ", ")
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

#Preview {
    let category = Category(name: "Home", colorHex: "#A0A0A0", symbolName: "house")
    let task = Task(title: "Sair com os cachorros", isCompleted: true, scheduledAt: Date(), category: category, recurrence: Recurrence(type: .daily))
    TaskRowView(task: task) {}
        .padding()
        .background(BIPTheme.background)
}

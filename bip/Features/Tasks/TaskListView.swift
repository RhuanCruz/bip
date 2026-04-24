import SwiftData
import SwiftUI

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Task.createdAt) private var tasks: [Task]

    let selectedDate: Date
    let onOpenTask: (Task) -> Void
    let onSetContext: (Task) -> Void

    private var filteredTasks: [Task] {
        tasks
            .filter { $0.parentTask == nil }
            .filter { task in
                guard let scheduledAt = task.scheduledAt else {
                    return Foundation.Calendar.current.isDateInToday(selectedDate)
                }
                return Foundation.Calendar.current.isDate(scheduledAt, inSameDayAs: selectedDate)
            }
            .sorted { lhs, rhs in
                switch (lhs.scheduledAt, rhs.scheduledAt) {
                case let (left?, right?):
                    return left < right
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                default:
                    return lhs.createdAt < rhs.createdAt
                }
            }
    }

    var body: some View {
        List {
            ForEach(filteredTasks) { task in
                TaskRowView(task: task) {
                    onOpenTask(task)
                }
                .listRowBackground(BIPTheme.background)
                .listRowInsets(EdgeInsets(top: 2, leading: BIPSpacing.large, bottom: 2, trailing: BIPSpacing.large))
                .listRowSeparator(.hidden)
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        onSetContext(task)
                    } label: {
                        Label("Context", systemImage: "arrow.uturn.down")
                    }
                    .tint(.gray)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        modelContext.delete(task)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.top, BIPSpacing.extraLarge, for: .scrollContent)
        .background(BIPTheme.background)
        .overlay {
            if filteredTasks.isEmpty {
                ContentUnavailableView(
                    "No tasks",
                    systemImage: "checklist",
                    description: Text("Add tasks in plain english")
                )
                .foregroundStyle(BIPTheme.textSecondary)
            }
        }
    }
}

#Preview {
    TaskListView(selectedDate: Date()) { _ in } onSetContext: { _ in }
        .modelContainer(BIPPreviewData.container())
}

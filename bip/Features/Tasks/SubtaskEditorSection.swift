import SwiftData
import SwiftUI

struct SubtaskEditorSection: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var task: Task
    @State private var newSubtaskTitle = ""

    var body: some View {
        VStack(alignment: .leading, spacing: BIPSpacing.medium) {
            Text("Subtasks")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(BIPTheme.textSecondary)

            VStack(spacing: 1) {
                ForEach(task.subtasks) { subtask in
                    SubtaskRow(subtask: subtask) {
                        modelContext.delete(subtask)
                    }
                }

                HStack(spacing: BIPSpacing.small) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(BIPTheme.textSecondary)

                    TextField("Add subtask", text: $newSubtaskTitle)
                        .textFieldStyle(.plain)
                        .foregroundStyle(BIPTheme.textPrimary)
                        .tint(BIPTheme.textPrimary)
                        .submitLabel(.done)
                        .onSubmit(addSubtask)

                    Button("Add", action: addSubtask)
                        .font(.system(size: 13, weight: .semibold))
                        .disabled(newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, BIPSpacing.medium)
                .padding(.vertical, BIPSpacing.medium)
                .background(BIPTheme.sheetField)
                .overlay(Divider().background(BIPTheme.sheetStroke), alignment: .top)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(BIPTheme.sheetStroke, lineWidth: 1)
            )
        }
    }

    private func addSubtask() {
        let trimmedTitle = newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let subtask = Task(
            title: trimmedTitle,
            scheduledAt: task.scheduledAt,
            rawInput: trimmedTitle,
            category: task.category,
            parentTask: task
        )
        task.subtasks.append(subtask)
        task.updatedAt = Date()
        modelContext.insert(subtask)
        newSubtaskTitle = ""
    }
}

private struct SubtaskRow: View {
    @Bindable var subtask: Task
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: BIPSpacing.small) {
            CompletionToggle(isCompleted: $subtask.isCompleted)
                .colorScheme(.dark)

            Text(subtask.title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(subtask.isCompleted ? BIPTheme.textSecondary : BIPTheme.textPrimary)
                .strikethrough(subtask.isCompleted)

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.red.opacity(0.72))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete subtask")
        }
        .padding(.horizontal, BIPSpacing.medium)
        .padding(.vertical, BIPSpacing.medium)
        .background(BIPTheme.sheetField)
    }
}

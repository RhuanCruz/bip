import SwiftData
import SwiftUI

struct TaskOverviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.name) private var categories: [Category]
    @Query(sort: \Task.scheduledAt) private var tasks: [Task]

    @Bindable var task: Task
    let onEdit: () -> Void

    @State private var agentText = ""
    @State private var isVoiceModeActive = false
    @State private var isProcessingAgentInput = false
    @State private var didCompleteAgentInput = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: BIPSpacing.extraLarge) {
                        headerSection
                        metadataSection
                        subtasksSection
                    }
                    .padding(BIPSpacing.large)
                    .padding(.bottom, 96)
                }
                .background(BIPTheme.sheetBackground)

                BIPBottomComposer(
                    text: $agentText,
                    isVoiceModeActive: $isVoiceModeActive,
                    didCompleteProcessing: didCompleteAgentInput,
                    isProcessing: isProcessingAgentInput,
                    placeholder: "Add subtasks or update this task...",
                    contextTask: task,
                    showsContextBar: false,
                    onSubmit: submitAgentText,
                    onVoiceSubmit: { submitAgentAudio(fileURL: $0) },
                    onClearContext: {}
                )
                .background(bottomFade)
            }
            .navigationTitle("Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(BIPTheme.sheetBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                        onEdit()
                    } label: {
                        Text("Edit")
                    }
                        .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: BIPSpacing.medium) {
            HStack(alignment: .top, spacing: BIPSpacing.medium) {
                CategoryIconView(category: task.category, size: 30)

                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(BIPTheme.textPrimary)

                    Text(subtitle)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(BIPTheme.textSecondary)
                }

                Spacer()

                CompletionToggle(isCompleted: $task.isCompleted)
                    .padding(.top, 4)
            }
        }
    }

    private var metadataSection: some View {
        VStack(spacing: 1) {
            metadataRow("Category", value: task.category?.name ?? "None", systemImage: task.category?.symbolName ?? "tag")

            if let scheduledAt = task.scheduledAt {
                metadataRow("Scheduled", value: Self.fullDateFormatter.string(from: scheduledAt), systemImage: "calendar")
                metadataRow("Duration", value: durationText, systemImage: "clock")
            }

            if let recurrence = task.recurrence, recurrence.type != .none {
                metadataRow("Repeat", value: recurrence.type.title, systemImage: "repeat")
            }
        }
        .background(BIPTheme.sheetField)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(BIPTheme.sheetStroke, lineWidth: 1)
        )
    }

    private var subtasksSection: some View {
        VStack(alignment: .leading, spacing: BIPSpacing.medium) {
            Text("Subtasks")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(BIPTheme.textSecondary)

            if task.childTasks.isEmpty {
                Text("No subtasks yet")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(BIPTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(BIPSpacing.large)
                    .background(BIPTheme.sheetField)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                VStack(spacing: 1) {
                    ForEach(task.childTasks.sorted { $0.createdAt < $1.createdAt }) { subtask in
                        HStack(spacing: BIPSpacing.medium) {
                            CompletionToggle(isCompleted: binding(for: subtask))
                                .colorScheme(.dark)

                            Text(subtask.title)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(subtask.isCompleted ? BIPTheme.textSecondary : BIPTheme.textPrimary)
                                .strikethrough(subtask.isCompleted)

                            Spacer()
                        }
                        .padding(.horizontal, BIPSpacing.medium)
                        .padding(.vertical, BIPSpacing.medium)
                        .background(BIPTheme.sheetField)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(BIPTheme.sheetStroke, lineWidth: 1)
                )
            }
        }
    }

    private func metadataRow(_ title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: BIPSpacing.medium) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(BIPTheme.textSecondary)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(BIPTheme.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(BIPTheme.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, BIPSpacing.medium)
        .padding(.vertical, BIPSpacing.medium)
    }

    private func submitAgentText() {
        guard !isProcessingAgentInput else { return }

        let trimmedText = agentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        agentText = ""
        processAgentInput(.text(trimmedText))
    }

    private func submitAgentAudio(fileURL: URL) {
        guard !isProcessingAgentInput else {
            try? FileManager.default.removeItem(at: fileURL)
            return
        }

        isVoiceModeActive = false
        processAgentInput(.audio(fileURL: fileURL, mimeType: "audio/aac"))
    }

    private func processAgentInput(_ input: ParsedIntentInput) {
        didCompleteAgentInput = false
        isProcessingAgentInput = true

        let selectedDate = task.scheduledAt ?? Date()
        let taskSnapshot = task
        let categoriesSnapshot = categories
        let tasksSnapshot = tasks
        let modelContextSnapshot = modelContext

        _Concurrency.Task {
            defer {
                isProcessingAgentInput = false
            }

            do {
                try await NaturalLanguageTaskService().createItems(
                    from: input,
                    selectedDate: selectedDate,
                    parentTask: taskSnapshot,
                    categories: categoriesSnapshot,
                    existingTasks: tasksSnapshot,
                    modelContext: modelContextSnapshot
                )
                showProcessingSuccess()
            } catch {
                print("Task overview agent processing failed: \(error)")
            }

            if case .audio(let fileURL, _) = input {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
    }

    private func showProcessingSuccess() {
        didCompleteAgentInput = true
        _Concurrency.Task {
            try? await _Concurrency.Task.sleep(for: .seconds(1.1))
            didCompleteAgentInput = false
        }
    }

    private func binding(for subtask: Task) -> Binding<Bool> {
        Binding(
            get: { subtask.isCompleted },
            set: { subtask.isCompleted = $0 }
        )
    }

    private var bottomFade: some View {
        LinearGradient(
            colors: [BIPTheme.sheetBackground.opacity(0), BIPTheme.sheetBackground],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var subtitle: String {
        if let scheduledAt = task.scheduledAt {
            return Self.fullDateFormatter.string(from: scheduledAt)
        }

        return "No schedule"
    }

    private var durationText: String {
        let duration = task.resolvedDurationMinutes
        if duration < 60 {
            return "\(duration)m"
        }

        let hours = duration / 60
        let minutes = duration % 60
        return minutes == 0 ? "\(hours)h" : "\(hours)h \(minutes)m"
    }

    private static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy 'at' HH:mm"
        return formatter
    }()
}

#Preview {
    let category = Category(name: "Home", colorHex: "#A0A0A0", symbolName: "house")
    let task = Task(title: "Plan weekend", scheduledAt: Date(), category: category)
    TaskOverviewSheet(task: task, onEdit: {})
        .modelContainer(BIPPreviewData.container())
}

import SwiftData
import SwiftUI

struct TaskDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.name) private var categories: [Category]

    @Bindable var task: Task
    @State private var title: String
    @State private var selectedCategoryID: UUID?
    @State private var assignToDay: Bool
    @State private var scheduledAt: Date
    @State private var durationMinutes: Int
    @State private var isRepeating: Bool
    @State private var recurrenceType: RecurrenceType
    @State private var daysOfWeek: Set<Int>
    @State private var reminderEnabled: Bool
    @State private var reminderOffsetMinutes: Int

    init(task: Task) {
        self.task = task
        _title = State(initialValue: task.title)
        _selectedCategoryID = State(initialValue: task.category?.id)
        _assignToDay = State(initialValue: task.scheduledAt != nil)
        _scheduledAt = State(initialValue: task.scheduledAt ?? Date())
        _durationMinutes = State(initialValue: task.resolvedDurationMinutes)
        _isRepeating = State(initialValue: task.recurrence?.type != nil && task.recurrence?.type != .none)
        _recurrenceType = State(initialValue: task.recurrence?.type ?? .none)
        _daysOfWeek = State(initialValue: Set(task.recurrence?.daysOfWeek ?? []))
        _reminderEnabled = State(initialValue: task.reminder?.enabled ?? false)
        _reminderOffsetMinutes = State(initialValue: task.reminder?.offsetMinutes ?? 0)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BIPSpacing.extraLarge) {
                    titleSection
                    categorySection
                    scheduleSection
                    recurrenceSection
                    reminderSection
                    SubtaskEditorSection(task: task)
                }
                .padding(BIPSpacing.large)
            }
            .background(BIPTheme.sheetBackground)
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(BIPTheme.sheetBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .destructive) {
                        modelContext.delete(task)
                        dismiss()
                    } label: {
                        Image(systemName: "trash")
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: BIPSpacing.small) {
            sectionTitle("Title")
            TextField("Title", text: $title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(BIPTheme.textPrimary)
                .tint(BIPTheme.textPrimary)
                .padding(BIPSpacing.medium)
                .background(BIPTheme.sheetField)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(sheetStroke)
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: BIPSpacing.small) {
            sectionTitle("Category")
            Picker("Category", selection: $selectedCategoryID) {
                Text("None").tag(Optional<UUID>.none)
                ForEach(categories) { category in
                    Label(category.name, systemImage: category.symbolName)
                        .tag(Optional(category.id))
                }
            }
            .pickerStyle(.menu)
            .foregroundStyle(BIPTheme.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(BIPSpacing.medium)
            .background(BIPTheme.sheetField)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(sheetStroke)
        }
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: BIPSpacing.small) {
            sectionTitle("Schedule")

            VStack(spacing: 1) {
                Toggle("Assign to day", isOn: $assignToDay)

                if assignToDay {
                    DatePicker("Date", selection: $scheduledAt, displayedComponents: .date)
                    DatePicker("Time", selection: $scheduledAt, displayedComponents: .hourAndMinute)
                    Stepper(value: $durationMinutes, in: 15...480, step: 15) {
                        Text("Duration \(durationText)")
                    }
                }
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(BIPTheme.textPrimary)
            .padding(BIPSpacing.medium)
            .background(BIPTheme.sheetField)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(sheetStroke)
            .tint(BIPTheme.warmAccent)
        }
    }

    private var recurrenceSection: some View {
        VStack(alignment: .leading, spacing: BIPSpacing.small) {
            sectionTitle("Repeat")

            VStack(alignment: .leading, spacing: BIPSpacing.medium) {
                Toggle("Repeat", isOn: $isRepeating)
                    .onChange(of: isRepeating) { _, newValue in
                        if newValue, recurrenceType == .none {
                            recurrenceType = .daily
                        }
                    }

                if isRepeating {
                    Divider()
                        .background(BIPTheme.sheetStroke)

                    Picker("Frequency", selection: $recurrenceType) {
                        Text("Daily").tag(RecurrenceType.daily)
                        Text("Weekly").tag(RecurrenceType.weekly)
                        Text("Custom").tag(RecurrenceType.custom)
                    }
                    .foregroundStyle(BIPTheme.textPrimary)
                    .onChange(of: recurrenceType) { _, newValue in
                        if newValue != .custom {
                            daysOfWeek.removeAll()
                        }
                    }

                    if recurrenceType == .custom {
                        HStack(spacing: BIPSpacing.small) {
                            ForEach(1...7, id: \.self) { weekday in
                                Button {
                                    toggleWeekday(weekday)
                                } label: {
                                    Text(weekdayLabel(for: weekday))
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(daysOfWeek.contains(weekday) ? Color.white : BIPTheme.textSecondary)
                                        .frame(width: 32, height: 32)
                                        .background(daysOfWeek.contains(weekday) ? BIPTheme.warmAccent : BIPTheme.elevatedLight)
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(BIPSpacing.medium)
            .background(BIPTheme.sheetField)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(sheetStroke)
            .tint(BIPTheme.warmAccent)
        }
    }

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: BIPSpacing.small) {
            sectionTitle("Reminder")

            VStack(spacing: 1) {
                Toggle("Remind me", isOn: $reminderEnabled)

                if reminderEnabled {
                    Stepper(value: $reminderOffsetMinutes, in: 0...240, step: 5) {
                        Text(reminderOffsetMinutes == 0 ? "At task time" : "\(reminderOffsetMinutes) minutes before")
                    }
                }
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(BIPTheme.textPrimary)
            .padding(BIPSpacing.medium)
            .background(BIPTheme.sheetField)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(sheetStroke)
            .tint(BIPTheme.warmAccent)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(BIPTheme.textSecondary)
    }

    private var sheetStroke: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(BIPTheme.sheetStroke, lineWidth: 1)
    }

    private func toggleWeekday(_ weekday: Int) {
        if daysOfWeek.contains(weekday) {
            daysOfWeek.remove(weekday)
        } else {
            daysOfWeek.insert(weekday)
        }
    }

    private func weekdayLabel(for weekday: Int) -> String {
        let symbols = Foundation.Calendar.current.veryShortWeekdaySymbols
        guard symbols.indices.contains(weekday - 1) else { return "?" }
        return symbols[weekday - 1]
    }

    private func save() {
        task.title = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? task.title : title.trimmingCharacters(in: .whitespacesAndNewlines)
        task.category = categories.first { $0.id == selectedCategoryID }
        task.scheduledAt = assignToDay ? scheduledAt : nil
        task.durationMinutes = durationMinutes
        task.updatedAt = Date()

        if !isRepeating {
            if let recurrence = task.recurrence {
                modelContext.delete(recurrence)
            }
            task.recurrence = nil
        } else {
            let recurrence = task.recurrence ?? Recurrence()
            recurrence.type = recurrenceType == .none ? .daily : recurrenceType
            recurrence.daysOfWeek = recurrenceType == .custom ? Array(daysOfWeek).sorted() : []
            recurrence.task = task
            task.recurrence = recurrence
            modelContext.insert(recurrence)
        }

        let reminder = task.reminder ?? Reminder()
        reminder.enabled = reminderEnabled
        reminder.offsetMinutes = reminderOffsetMinutes
        reminder.task = task
        task.reminder = reminder
        modelContext.insert(reminder)
    }

    private var durationText: String {
        if durationMinutes < 60 {
            return "\(durationMinutes)m"
        }

        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        return minutes == 0 ? "\(hours)h" : "\(hours)h \(minutes)m"
    }
}

#Preview {
    let category = Category(name: "Studies", colorHex: "#B07A2A", symbolName: "books.vertical")
    let task = Task(title: "Do econ homework", scheduledAt: Date(), category: category)
    TaskDetailSheet(task: task)
        .modelContainer(BIPPreviewData.container())
}

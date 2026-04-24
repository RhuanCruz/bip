import EventKit
import SwiftData
import SwiftUI

struct MoreMenuSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Task.createdAt) private var tasks: [Task]
    @Query(sort: \Category.name) private var categories: [Category]

    let onOpenCategories: () -> Void

    @State private var importState: ReminderImportState = .idle

    private let rows: [MoreMenuSection] = [
        MoreMenuSection(title: "Lists", rows: [
            MoreMenuRow(title: "Completed Tasks", systemImage: "checkmark.circle"),
            MoreMenuRow(title: "All Tasks", systemImage: "tray.full"),
        ]),
        MoreMenuSection(title: "Organization", rows: [
            MoreMenuRow(title: "Categories", systemImage: "square.grid.2x2", action: .categories),
        ]),
        MoreMenuSection(title: "Integrations", rows: [
            MoreMenuRow(title: "Apple Reminders", systemImage: "checklist", action: .appleReminders),
        ]),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BIPSpacing.extraLarge) {
                    ForEach(rows) { section in
                        MoreSectionView(section: section) { row in
                            handle(row)
                        }
                    }

                    if let statusText = importState.statusText {
                        Text(statusText)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(BIPTheme.textSecondary)
                            .padding(.horizontal, BIPSpacing.small)
                    }
                }
                .padding(.horizontal, BIPSpacing.extraLarge)
                .padding(.top, BIPSpacing.large)
                .padding(.bottom, BIPSpacing.extraLarge)
            }
            .background(BIPTheme.sheetBackground)
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(BIPTheme.sheetBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    private func handle(_ row: MoreMenuRow) {
        switch row.action {
        case .categories:
            onOpenCategories()
        case .appleReminders:
            _Concurrency.Task<Void, Never> {
                await importAppleReminders()
            }
        case .none:
            break
        }
    }

    private func importAppleReminders() async {
        importState = .importing

        do {
            let importedCount = try await AppleRemindersImporter.importIncompleteReminders(
                into: modelContext,
                existingTasks: tasks,
                categories: categories
            )
            importState = .imported(importedCount)
        } catch {
            importState = .failed(error.localizedDescription)
        }
    }
}

private struct MoreSectionView: View {
    let section: MoreMenuSection
    let onSelect: (MoreMenuRow) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: BIPSpacing.small) {
            Text(section.title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(BIPTheme.textSecondary)

            VStack(spacing: 0) {
                ForEach(Array(section.rows.enumerated()), id: \.element.id) { index, row in
                    Button {
                        onSelect(row)
                    } label: {
                        HStack(spacing: BIPSpacing.large) {
                            Image(systemName: row.systemImage)
                                .font(.system(size: 20, weight: .medium))
                                .frame(width: 26)

                            Text(row.title)
                                .font(.system(size: 17, weight: .medium))

                            Spacer()

                            if row.action == .categories {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(BIPTheme.textSecondary)
                            }
                        }
                        .foregroundStyle(BIPTheme.textPrimary)
                        .padding(.horizontal, BIPSpacing.large)
                        .frame(height: 54)
                    }
                    .buttonStyle(.plain)

                    if index < section.rows.count - 1 {
                        Divider()
                            .background(BIPTheme.sheetStroke)
                            .padding(.leading, 58)
                    }
                }
            }
            .background(BIPTheme.sheetField)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(BIPTheme.sheetStroke, lineWidth: 1)
            )
        }
    }
}

private struct MoreMenuSection: Identifiable {
    let id = UUID()
    let title: String
    let rows: [MoreMenuRow]
}

private struct MoreMenuRow: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    var action: MoreMenuAction = .none
}

private enum MoreMenuAction: Equatable {
    case none
    case categories
    case appleReminders
}

private enum ReminderImportState: Equatable {
    case idle
    case importing
    case imported(Int)
    case failed(String)

    var statusText: String? {
        switch self {
        case .idle:
            nil
        case .importing:
            "Importing Apple Reminders..."
        case .imported(let count):
            count == 1 ? "Imported 1 reminder." : "Imported \(count) reminders."
        case .failed(let message):
            "Apple Reminders failed: \(message)"
        }
    }
}

private enum AppleRemindersImporter {
    static func importIncompleteReminders(
        into modelContext: ModelContext,
        existingTasks: [Task],
        categories: [Category]
    ) async throws -> Int {
        let eventStore = EKEventStore()
        try await requestReminderAccess(eventStore)

        let predicate = eventStore.predicateForIncompleteReminders(
            withDueDateStarting: nil,
            ending: nil,
            calendars: nil
        )

        let reminders = try await fetchReminders(matching: predicate, in: eventStore)
        let reminderCategory = categories.first { $0.name == "Apple Reminders" } ?? {
            let category = Category(name: "Apple Reminders", colorHex: "#A0A0A0", symbolName: "checklist")
            modelContext.insert(category)
            return category
        }()
        let existingRawInputs = Set(existingTasks.map(\.rawInput))
        var importedCount = 0

        for reminder in reminders where !existingRawInputs.contains(rawInput(for: reminder)) {
            let task = Task(
                title: reminder.title,
                scheduledAt: scheduledAt(for: reminder),
                rawInput: rawInput(for: reminder),
                category: reminderCategory
            )
            modelContext.insert(task)
            importedCount += 1
        }

        return importedCount
    }

    private static func requestReminderAccess(_ eventStore: EKEventStore) async throws {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        if status == .fullAccess {
            return
        }

        let granted = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            eventStore.requestFullAccessToReminders { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
        if !granted {
            throw ReminderImportError.accessDenied
        }
    }

    private static func fetchReminders(
        matching predicate: NSPredicate,
        in eventStore: EKEventStore
    ) async throws -> [EKReminder] {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[EKReminder], Error>) in
            eventStore.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
    }

    private static func rawInput(for reminder: EKReminder) -> String {
        "apple-reminders:\(reminder.calendarItemIdentifier)"
    }

    private static func scheduledAt(for reminder: EKReminder) -> Date? {
        guard let dueDateComponents = reminder.dueDateComponents else { return nil }
        let calendar = dueDateComponents.calendar ?? Calendar.current
        return calendar.date(from: dueDateComponents)
    }
}

private enum ReminderImportError: LocalizedError {
    case accessDenied

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            "Access to Reminders was denied."
        }
    }
}

#Preview {
    MoreMenuSheet(onOpenCategories: {})
}

import SwiftUI

struct CalendarDaySection: View {
    let tasks: [Task]
    let onOpenTask: (Task) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(hourRange, id: \.self) { hour in
                HStack(alignment: .top, spacing: BIPSpacing.medium) {
                    Text(String(format: "%02d:00", hour))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(BIPTheme.textSecondary)
                        .frame(width: 48, alignment: .leading)

                    VStack(alignment: .leading, spacing: BIPSpacing.small) {
                        Divider()
                            .background(Color.white.opacity(0.12))

                        ForEach(tasksForHour(hour)) { task in
                            Button {
                                onOpenTask(task)
                            } label: {
                                eventCard(for: task)
                                .padding(BIPSpacing.small)
                                .frame(minHeight: eventHeight(for: task), alignment: .topLeading)
                                .background(BIPTheme.elevated)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(minHeight: hourHeight, alignment: .top)
            }
        }
        .padding(.horizontal, BIPSpacing.large)
    }

    private var hourRange: ClosedRange<Int> {
        7...22
    }

    private var hourHeight: CGFloat {
        72
    }

    private func tasksForHour(_ hour: Int) -> [Task] {
        tasks.filter { task in
            guard let scheduledAt = task.scheduledAt else { return false }
            return Foundation.Calendar.current.component(.hour, from: scheduledAt) == hour
        }
    }

    private func eventHeight(for task: Task) -> CGFloat {
        max(44, CGFloat(task.resolvedDurationMinutes) / 60 * hourHeight - BIPSpacing.small)
    }

    @ViewBuilder
    private func eventCard(for task: Task) -> some View {
        let visibleSubtasks = subtasksToShow(for: task)
        let remainingSubtasks = max(0, task.childTasks.count - visibleSubtasks.count)

        HStack(alignment: .top, spacing: BIPSpacing.small) {
            CategoryIconView(category: task.category, size: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(BIPTheme.textPrimary)
                    .lineLimit(1)

                Text(durationText(for: task))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(BIPTheme.textSecondary)
                    .lineLimit(1)

                if !visibleSubtasks.isEmpty {
                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(visibleSubtasks) { subtask in
                            HStack(spacing: 5) {
                                Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(subtask.isCompleted ? BIPTheme.success : BIPTheme.textSecondary)

                                Text(subtask.title)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(BIPTheme.textSecondary)
                                    .lineLimit(1)
                            }
                        }

                        if remainingSubtasks > 0 {
                            Text("+\(remainingSubtasks) more")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(BIPTheme.textSecondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)
        }
    }

    private func subtasksToShow(for task: Task) -> [Task] {
        let availableRows = max(0, Int((eventHeight(for: task) - 52) / 17))
        let limit = min(3, availableRows)

        guard limit > 0 else { return [] }

        return Array(
            task.childTasks
                .sorted { $0.createdAt < $1.createdAt }
                .prefix(limit)
        )
    }

    private func durationText(for task: Task) -> String {
        let durationMinutes = task.resolvedDurationMinutes

        if durationMinutes < 60 {
            return "\(durationMinutes)m"
        }

        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        return minutes == 0 ? "\(hours)h" : "\(hours)h \(minutes)m"
    }
}

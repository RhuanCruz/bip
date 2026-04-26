import SwiftUI

struct CalendarDaySection: View {
    let selectedDate: Date
    let tasks: [Task]
    let onOpenTask: (Task) -> Void

    var body: some View {
        GeometryReader { proxy in
            let contentWidth = max(0, proxy.size.width - timeColumnWidth - BIPSpacing.medium)
            let layouts = eventLayouts(contentWidth: contentWidth)

            ZStack(alignment: .topLeading) {
                hourGrid(contentWidth: contentWidth)

                ForEach(layouts) { layout in
                    Button {
                        onOpenTask(layout.task)
                    } label: {
                        eventCard(for: layout.task)
                            .padding(BIPSpacing.small)
                            .frame(width: layout.width, height: layout.height, alignment: .topLeading)
                            .background(eventTint(for: layout.task))
                            .overlay(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2, style: .continuous)
                                    .fill(eventAccent(for: layout.task))
                                    .frame(width: 4)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .offset(x: timeColumnWidth + BIPSpacing.medium + layout.x, y: layout.y)
                }

                if let marker = currentTimeMarkerY {
                    currentTimeMarker(contentWidth: contentWidth)
                        .offset(y: marker)
                }
            }
        }
        .frame(height: timelineHeight)
        .padding(.horizontal, BIPSpacing.large)
    }

    private var hourRange: ClosedRange<Int> {
        7...22
    }

    private var startHour: Int {
        hourRange.lowerBound
    }

    private var endHour: Int {
        hourRange.upperBound
    }

    private var hourHeight: CGFloat {
        72
    }

    private var timeColumnWidth: CGFloat {
        44
    }

    private var timelineHeight: CGFloat {
        CGFloat(hourRange.count) * hourHeight
    }

    private var currentTimeMarkerY: CGFloat? {
        let calendar = Foundation.Calendar.current
        let now = Date()

        guard calendar.isDate(now, inSameDayAs: selectedDate) else { return nil }

        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let minuteOfDay = hour * 60 + minute
        let startMinute = startHour * 60
        let endMinute = (endHour + 1) * 60

        guard minuteOfDay >= startMinute, minuteOfDay <= endMinute else { return nil }

        return CGFloat(minuteOfDay - startMinute) / 60 * hourHeight
    }

    private func hourGrid(contentWidth: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(hourRange.enumerated()), id: \.element) { index, hour in
                HStack(alignment: .top, spacing: BIPSpacing.medium) {
                    Text(String(format: "%02d:00", hour))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(BIPTheme.textSecondary)
                        .frame(width: timeColumnWidth, alignment: .leading)

                    Rectangle()
                        .fill(Color.white.opacity(0.10))
                        .frame(width: contentWidth, height: 1)
                        .padding(.top, 8)
                }
                .offset(y: CGFloat(index) * hourHeight)
            }
        }
    }

    private func eventHeight(for task: Task) -> CGFloat {
        max(44, CGFloat(task.resolvedDurationMinutes) / 60 * hourHeight - 4)
    }

    private func eventLayouts(contentWidth: CGFloat) -> [CalendarEventLayout] {
        let seeds = tasks
            .compactMap { task -> CalendarEventSeed? in
                guard let scheduledAt = task.scheduledAt else { return nil }
                return CalendarEventSeed(task: task, startMinute: minuteOfDay(for: scheduledAt))
            }
            .filter { seed in
                let start = startHour * 60
                let end = (endHour + 1) * 60
                return seed.endMinute > start && seed.startMinute < end
            }
            .sorted {
                if $0.startMinute == $1.startMinute {
                    return $0.endMinute > $1.endMinute
                }
                return $0.startMinute < $1.startMinute
            }

        let groups = overlappingGroups(from: seeds)
        let columnSpacing: CGFloat = 6

        return groups.flatMap { group -> [CalendarEventLayout] in
            let assignments = columnAssignments(for: group)
            let columnCount = max(1, assignments.map(\.column).max().map { $0 + 1 } ?? 1)
            let cardWidth = max(72, (contentWidth - CGFloat(columnCount - 1) * columnSpacing) / CGFloat(columnCount))

            return assignments.map { assignment in
                let visibleStart = max(assignment.seed.startMinute, startHour * 60)
                let visibleEnd = min(assignment.seed.endMinute, (endHour + 1) * 60)
                let y = CGFloat(visibleStart - startHour * 60) / 60 * hourHeight
                let height = max(44, CGFloat(visibleEnd - visibleStart) / 60 * hourHeight - 4)
                let x = CGFloat(assignment.column) * (cardWidth + columnSpacing)

                return CalendarEventLayout(
                    task: assignment.seed.task,
                    x: x,
                    y: y,
                    width: cardWidth,
                    height: height
                )
            }
        }
    }

    private func overlappingGroups(from seeds: [CalendarEventSeed]) -> [[CalendarEventSeed]] {
        var groups: [[CalendarEventSeed]] = []
        var currentGroup: [CalendarEventSeed] = []
        var currentEnd = 0

        for seed in seeds {
            if currentGroup.isEmpty || seed.startMinute < currentEnd {
                currentGroup.append(seed)
                currentEnd = max(currentEnd, seed.endMinute)
            } else {
                groups.append(currentGroup)
                currentGroup = [seed]
                currentEnd = seed.endMinute
            }
        }

        if !currentGroup.isEmpty {
            groups.append(currentGroup)
        }

        return groups
    }

    private func columnAssignments(for group: [CalendarEventSeed]) -> [CalendarEventColumnAssignment] {
        var columnEndMinutes: [Int] = []
        var assignments: [CalendarEventColumnAssignment] = []

        for seed in group {
            if let availableColumn = columnEndMinutes.firstIndex(where: { $0 <= seed.startMinute }) {
                columnEndMinutes[availableColumn] = seed.endMinute
                assignments.append(CalendarEventColumnAssignment(seed: seed, column: availableColumn))
            } else {
                columnEndMinutes.append(seed.endMinute)
                assignments.append(CalendarEventColumnAssignment(seed: seed, column: columnEndMinutes.count - 1))
            }
        }

        return assignments
    }

    private func minuteOfDay(for date: Date) -> Int {
        let calendar = Foundation.Calendar.current
        return calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
    }

    private func currentTimeMarker(contentWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            Text(Self.currentTimeFormatter.string(from: Date()))
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.black)
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(Color.white, in: Capsule())
                .frame(width: timeColumnWidth, alignment: .leading)

            Rectangle()
                .fill(Color.white.opacity(0.88))
                .frame(width: contentWidth + BIPSpacing.medium, height: 2)
        }
    }

    private func eventTint(for task: Task) -> some ShapeStyle {
        LinearGradient(
            colors: [eventAccent(for: task).opacity(0.25), BIPTheme.elevated.opacity(0.92)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private func eventAccent(for task: Task) -> Color {
        guard let category = task.category else { return BIPTheme.warmAccent }
        return Color(hex: category.colorHex)
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

    private static let currentTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

private struct CalendarEventSeed {
    let task: Task
    let startMinute: Int

    var endMinute: Int {
        startMinute + task.resolvedDurationMinutes
    }
}

private struct CalendarEventColumnAssignment {
    let seed: CalendarEventSeed
    let column: Int
}

private struct CalendarEventLayout: Identifiable {
    let task: Task
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat

    var id: UUID {
        task.id
    }
}

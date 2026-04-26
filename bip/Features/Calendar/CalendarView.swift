import SwiftData
import SwiftUI

struct CalendarView: View {
    @Query(sort: \Task.scheduledAt) private var tasks: [Task]

    @Binding var selectedDate: Date
    let onOpenDatePicker: () -> Void
    let onOpenTask: (Task) -> Void

    private var visibleDates: [Date] {
        let calendar = Foundation.Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? calendar.startOfDay(for: selectedDate)

        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            weekStrip

            ScrollView {
                CalendarDaySection(
                    selectedDate: selectedDate,
                    tasks: tasksForSelectedDate,
                    onOpenTask: onOpenTask
                )
                .padding(.top, BIPSpacing.extraLarge)
                .padding(.bottom, 96)
            }
        }
        .background(BIPTheme.background)
    }

    private var weekStrip: some View {
        VStack(alignment: .leading, spacing: BIPSpacing.medium) {
            HStack {
                Button(action: onOpenDatePicker) {
                    HStack(spacing: BIPSpacing.small) {
                        Text(Self.headerFormatter.string(from: selectedDate))
                            .font(.system(size: 24, weight: .bold))

                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(BIPTheme.textSecondary)
                    }
                    .foregroundStyle(BIPTheme.textPrimary)
                }
                .buttonStyle(.plain)

                Spacer()
            }

            LazyVGrid(columns: weekColumns, spacing: BIPSpacing.small) {
                ForEach(visibleDates, id: \.self) { date in
                    Button {
                        withAnimation(.snappy(duration: 0.18)) {
                            selectedDate = date
                        }
                    } label: {
                        VStack(spacing: 3) {
                            Text(Self.weekdayFormatter.string(from: date))
                                .font(.system(size: 10, weight: .semibold))
                            Text(Self.dayFormatter.string(from: date))
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundStyle(isSelected(date) ? Color.white : BIPTheme.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(isSelected(date) ? BIPTheme.sheetFieldLight : BIPTheme.elevated.opacity(0.72))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(isSelected(date) ? Color.white.opacity(0.14) : Color.white.opacity(0.06), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        guard abs(value.translation.width) > abs(value.translation.height),
                              abs(value.translation.width) > 36
                        else { return }

                        withAnimation(.snappy(duration: 0.22)) {
                            moveWeek(by: value.translation.width < 0 ? 1 : -1)
                        }
                    }
            )
        }
        .padding(.horizontal, BIPSpacing.large)
        .padding(.top, BIPSpacing.large)
        .padding(.bottom, BIPSpacing.medium)
    }

    private var weekColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(minimum: 36), spacing: BIPSpacing.small), count: 7)
    }

    private var tasksForSelectedDate: [Task] {
        tasks
            .filter { $0.parentTask == nil }
            .filter { TaskOccurrencePolicy.occurs($0, on: selectedDate) }
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

    private func isSelected(_ date: Date) -> Bool {
        Foundation.Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }

    private func moveWeek(by value: Int) {
        if let date = Foundation.Calendar.current.date(byAdding: .day, value: value * 7, to: selectedDate) {
            selectedDate = date
        }
    }

    private static let headerFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        return formatter
    }()

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
}

#Preview {
    @Previewable @State var selectedDate = Date()
    CalendarView(selectedDate: $selectedDate, onOpenDatePicker: {}) { _ in }
        .modelContainer(BIPPreviewData.container())
}

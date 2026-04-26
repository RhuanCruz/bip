import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.name) private var categories: [Category]
    @Query(sort: \Task.scheduledAt) private var tasks: [Task]

    @State private var activeView: MainViewMode = .tasks
    @State private var selectedDate: Date = .now
    @State private var activeSheet: SheetDestination?
    @State private var swipeContext: Task?
    @State private var composerText: String = ""
    @State private var isVoiceModeActive: Bool = false
    @State private var isProcessingNaturalLanguage: Bool = false
    @State private var didCompleteNaturalLanguageProcessing: Bool = false

    var body: some View {
        ZStack {
            BIPTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                BIPTopBar(
                    activeView: activeView,
                    onDateTap: { activeSheet = .datePicker },
                    onTitleTap: { activeView.toggle() },
                    onMoreTap: { activeSheet = .moreMenu }
                )

                Group {
                    switch activeView {
                    case .tasks:
                        TaskListView(
                            selectedDate: selectedDate,
                            onOpenTask: { activeSheet = .taskDetail($0) },
                            onSetContext: { swipeContext = $0 }
                        )
                    case .calendar:
                        CalendarView(
                            selectedDate: $selectedDate,
                            onOpenDatePicker: { activeSheet = .datePicker },
                            onOpenTask: { activeSheet = .taskDetail($0) }
                        )
                    case .bip:
                        BIPFeedView(
                            onAddPost: { activeSheet = .postComposer }
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if activeView == .bip {
                    BIPPostBar(onAddPost: { activeSheet = .postComposer })
                } else {
                    BIPBottomComposer(
                        text: $composerText,
                        isVoiceModeActive: $isVoiceModeActive,
                        didCompleteProcessing: didCompleteNaturalLanguageProcessing,
                        isProcessing: isProcessingNaturalLanguage,
                        placeholder: activeView == .calendar ? "Add event in plain english..." : "Add tasks in plain english",
                        contextTask: swipeContext,
                        showsContextBar: true,
                        onSubmit: submitComposer,
                        onVoiceSubmit: { submitVoiceComposer(fileURL: $0) },
                        onClearContext: { swipeContext = nil }
                    )
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            seedDefaultCategories()
        }
        .sheet(item: $activeSheet) { destination in
            switch destination {
            case .datePicker:
                DatePickerSheet(selectedDate: $selectedDate)
                    .presentationDetents([.height(620), .large])
                    .presentationDragIndicator(.visible)
            case .taskDetail(let task):
                TaskOverviewSheet(
                    task: task,
                    onEdit: { activeSheet = .taskEditor(task) }
                )
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            case .taskEditor(let task):
                TaskDetailSheet(task: task)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            case .moreMenu:
                MoreMenuSheet(
                    onOpenCategories: { activeSheet = .categories },
                    onOpenGeminiSettings: { activeSheet = .geminiSettings }
                )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            case .categories:
                CategoriesSheet()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            case .geminiSettings:
                GeminiSettingsSheet()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            case .postComposer:
                BIPPostComposerSheet()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private func submitComposer() {
        guard !isProcessingNaturalLanguage else { return }

        let trimmedText = composerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        composerText = ""
        processNaturalLanguageInput(.text(trimmedText))
    }

    private func submitVoiceComposer(fileURL: URL) {
        guard !isProcessingNaturalLanguage else {
            try? FileManager.default.removeItem(at: fileURL)
            return
        }

        isVoiceModeActive = false
        processNaturalLanguageInput(.audio(fileURL: fileURL, mimeType: "audio/aac"))
    }

    private func processNaturalLanguageInput(_ input: ParsedIntentInput) {
        didCompleteNaturalLanguageProcessing = false
        isProcessingNaturalLanguage = true

        let selectedDateSnapshot = selectedDate
        let parentTaskSnapshot = swipeContext
        let categoriesSnapshot = categories
        let tasksSnapshot = tasks
        let modelContextSnapshot = modelContext

        _Concurrency.Task {
            defer {
                isProcessingNaturalLanguage = false
            }

            do {
                try await NaturalLanguageTaskService().createItems(
                    from: input,
                    selectedDate: selectedDateSnapshot,
                    parentTask: parentTaskSnapshot,
                    categories: categoriesSnapshot,
                    existingTasks: tasksSnapshot,
                    modelContext: modelContextSnapshot
                )
                if parentTaskSnapshot != nil {
                    swipeContext = nil
                }
                showProcessingSuccess()
            } catch {
                print("Natural language processing failed: \(error)")
            }

            if case .audio(let fileURL, _) = input {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
    }

    private func showProcessingSuccess() {
        didCompleteNaturalLanguageProcessing = true
        _Concurrency.Task {
            try? await _Concurrency.Task.sleep(for: .seconds(1.1))
            didCompleteNaturalLanguageProcessing = false
        }
    }

    private func seedDefaultCategories() {
        guard categories.isEmpty else { return }
        modelContext.insert(Category(name: "Home", colorHex: "#A0A0A0", symbolName: "house"))
        modelContext.insert(Category(name: "Fitness", colorHex: "#A0A0A0", symbolName: "figure.strengthtraining.traditional"))
        modelContext.insert(Category(name: "Studies", colorHex: "#B07A2A", symbolName: "books.vertical"))
    }

}

private struct DatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date

    @State private var visibleMonth: Date

    init(selectedDate: Binding<Date>) {
        _selectedDate = selectedDate
        _visibleMonth = State(initialValue: Calendar.current.dateInterval(of: .month, for: selectedDate.wrappedValue)?.start ?? selectedDate.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BIPSpacing.extraLarge) {
                    Text("Select Date")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(BIPTheme.textPrimary)
                        .padding(.top, BIPSpacing.medium)

                    monthHeader
                    weekdayHeader
                    dayGrid
                }
                .padding(.horizontal, BIPSpacing.large)
                .padding(.bottom, BIPSpacing.extraLarge)
            }
            .background(BIPTheme.sheetBackground)
            .toolbarBackground(BIPTheme.sheetBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var monthHeader: some View {
        HStack {
            Text(Self.monthFormatter.string(from: visibleMonth))
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(BIPTheme.textPrimary)

            Spacer()

            Button {
                moveMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            Button {
                moveMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .bold))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(BIPTheme.textPrimary)
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: gridColumns, spacing: BIPSpacing.small) {
            ForEach(Self.weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(BIPTheme.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var dayGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: BIPSpacing.medium) {
            ForEach(monthDays, id: \.id) { item in
                if let date = item.date {
                    Button {
                        selectedDate = date
                    } label: {
                        ZStack {
                            if isSelected(date) {
                                Circle()
                                    .fill(BIPTheme.textPrimary)
                                    .frame(width: 36, height: 36)
                            }

                            Text(Self.dayFormatter.string(from: date))
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(isSelected(date) ? BIPTheme.background : BIPTheme.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.65)
                                .frame(width: 40, height: 40)
                        }
                        .frame(maxWidth: .infinity, minHeight: 42)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear
                        .frame(maxWidth: .infinity, minHeight: 42)
                }
            }
        }
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(minimum: 32), spacing: BIPSpacing.tiny), count: 7)
    }

    private var monthDays: [CalendarDayItem] {
        let calendar = Calendar.current
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: visibleMonth),
            let dayRange = calendar.range(of: .day, in: .month, for: visibleMonth)
        else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        let leadingEmptyDays = firstWeekday - calendar.firstWeekday
        let normalizedLeadingDays = leadingEmptyDays >= 0 ? leadingEmptyDays : leadingEmptyDays + 7
        var items = (0..<normalizedLeadingDays).map { CalendarDayItem(id: "empty-\($0)", date: nil) }

        items += dayRange.compactMap { day -> CalendarDayItem? in
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: monthInterval.start) else { return nil }
            return CalendarDayItem(id: "day-\(day)", date: date)
        }

        let trailingCount = (7 - items.count % 7) % 7
        items += (0..<trailingCount).map { CalendarDayItem(id: "trailing-\($0)", date: nil) }
        return items
    }

    private func moveMonth(by value: Int) {
        if let month = Calendar.current.date(byAdding: .month, value: value, to: visibleMonth) {
            visibleMonth = month
        }
    }

    private func isSelected(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }

    private static let weekdaySymbols = Calendar.current.shortStandaloneWeekdaySymbols.map { $0.uppercased() }

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
}

private struct CalendarDayItem: Identifiable {
    let id: String
    let date: Date?
}

#Preview {
    RootView()
        .modelContainer(BIPPreviewData.container())
}

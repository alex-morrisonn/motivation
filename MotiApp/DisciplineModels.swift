import Foundation

// MARK: - Discipline Categories

enum DisciplineCategory: String, CaseIterable, Codable, Hashable, Identifiable {
    case mind = "Mind"
    case body = "Body"
    case focus = "Focus"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .mind:
            return "brain.head.profile"
        case .body:
            return "figure.walk"
        case .focus:
            return "target"
        }
    }

    var subtitle: String {
        switch self {
        case .mind:
            return "Build clarity and calm."
        case .body:
            return "Move your body every day."
        case .focus:
            return "Finish one meaningful action."
        }
    }

    var displayOrder: Int {
        switch self {
        case .mind:
            return 0
        case .body:
            return 1
        case .focus:
            return 2
        }
    }
}

// MARK: - Task Options

struct DisciplineTaskOption: Identifiable, Hashable {
    let id: String
    let category: DisciplineCategory
    let title: String
    let detail: String
}

enum DisciplineTaskLibrary {
    private static let allOptions: [DisciplineTaskOption] = [
        DisciplineTaskOption(
            id: "mind_read",
            category: .mind,
            title: "Read 10 pages",
            detail: "Read something useful or inspiring for at least 10 pages."
        ),
        DisciplineTaskOption(
            id: "mind_journal",
            category: .mind,
            title: "Journal for 5 minutes",
            detail: "Write down what matters today or reflect on your progress."
        ),
        DisciplineTaskOption(
            id: "mind_meditate",
            category: .mind,
            title: "Meditate for 10 minutes",
            detail: "Take 10 quiet minutes to reset and focus."
        ),
        DisciplineTaskOption(
            id: "body_walk",
            category: .body,
            title: "Walk for 20 minutes",
            detail: "Get outside or on the treadmill for a short walk."
        ),
        DisciplineTaskOption(
            id: "body_stretch",
            category: .body,
            title: "Stretch for 10 minutes",
            detail: "Do a simple mobility or recovery session."
        ),
        DisciplineTaskOption(
            id: "body_workout",
            category: .body,
            title: "Do a 15 minute workout",
            detail: "Finish a quick bodyweight, gym, or cardio session."
        ),
        DisciplineTaskOption(
            id: "focus_deep_work",
            category: .focus,
            title: "Do 25 minutes of deep work",
            detail: "Focus on one important task without distractions."
        ),
        DisciplineTaskOption(
            id: "focus_priority",
            category: .focus,
            title: "Finish one priority task",
            detail: "Pick one thing that moves your day forward and complete it."
        ),
        DisciplineTaskOption(
            id: "focus_tidy",
            category: .focus,
            title: "Tidy your space for 10 minutes",
            detail: "Reset your desk, room, or workspace so it supports action."
        )
    ]

    static func options(for category: DisciplineCategory) -> [DisciplineTaskOption] {
        allOptions.filter { $0.category == category }
    }

    static func option(id: String, category: DisciplineCategory) -> DisciplineTaskOption? {
        options(for: category).first { $0.id == id }
    }

    static func defaultOption(for category: DisciplineCategory) -> DisciplineTaskOption {
        options(for: category).first!
    }
}

// MARK: - Daily Discipline Task Model

struct DisciplineTask: Identifiable, Codable, Hashable {
    let id: UUID
    let category: DisciplineCategory
    var optionID: String
    var title: String
    var detail: String
    var isCompleted: Bool
    var completedAt: Date?
    var orderIndex: Int

    init(
        id: UUID = UUID(),
        category: DisciplineCategory,
        optionID: String,
        title: String,
        detail: String,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        orderIndex: Int
    ) {
        self.id = id
        self.category = category
        self.optionID = optionID
        self.title = title
        self.detail = detail
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.orderIndex = orderIndex
    }

    mutating func toggleCompletion() {
        isCompleted.toggle()
        completedAt = isCompleted ? Date() : nil
    }
}

// MARK: - Daily Discipline Day Model

struct DisciplineDay: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var tasks: [DisciplineTask]

    var minimumTasksForConsistency: Int {
        guard !tasks.isEmpty else { return 0 }
        return min(tasks.count, max(1, tasks.count - 1))
    }

    var isConsistencyDay: Bool {
        completedTaskCount >= minimumTasksForConsistency
    }

    var isFullyCompleted: Bool {
        tasks.count == DisciplineCategory.allCases.count && tasks.allSatisfy(\.isCompleted)
    }

    var completedTaskCount: Int {
        tasks.filter(\.isCompleted).count
    }

    var completionPercentage: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(completedTaskCount) / Double(tasks.count)
    }

    var formattedDate: String {
        DateFormatter.mediumDate.string(from: date)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    init(id: UUID = UUID(), date: Date, tasks: [DisciplineTask]) {
        self.id = id
        self.date = date
        self.tasks = tasks.sorted { $0.orderIndex < $1.orderIndex }
    }

    static func createForDate(_ date: Date, selections: [DisciplineCategory: String] = [:]) -> DisciplineDay {
        let tasks = DisciplineCategory.allCases.sorted { $0.displayOrder < $1.displayOrder }.map { category in
            let selectedOption = selections[category]
                .flatMap { DisciplineTaskLibrary.option(id: $0, category: category) }
                ?? DisciplineTaskLibrary.defaultOption(for: category)

            return DisciplineTask(
                category: category,
                optionID: selectedOption.id,
                title: selectedOption.title,
                detail: selectedOption.detail,
                orderIndex: category.displayOrder
            )
        }

        return DisciplineDay(date: date, tasks: tasks)
    }

    mutating func toggleTask(at index: Int) {
        guard tasks.indices.contains(index) else { return }
        tasks[index].toggleCompletion()
    }

    mutating func updateSelections(_ selections: [DisciplineCategory: String]) {
        let previousTasks = Dictionary(uniqueKeysWithValues: tasks.map { ($0.category, $0) })

        tasks = DisciplineCategory.allCases.sorted { $0.displayOrder < $1.displayOrder }.map { category in
            let selectedOption = selections[category]
                .flatMap { DisciplineTaskLibrary.option(id: $0, category: category) }
                ?? DisciplineTaskLibrary.defaultOption(for: category)

            if let existingTask = previousTasks[category], existingTask.optionID == selectedOption.id {
                return existingTask
            }

            return DisciplineTask(
                category: category,
                optionID: selectedOption.id,
                title: selectedOption.title,
                detail: selectedOption.detail,
                orderIndex: category.displayOrder
            )
        }
    }

    func selectedOptionID(for category: DisciplineCategory) -> String {
        tasks.first(where: { $0.category == category })?.optionID
            ?? DisciplineTaskLibrary.defaultOption(for: category).id
    }
}

// MARK: - Discipline System State

final class DisciplineSystemState: ObservableObject {
    static let shared = DisciplineSystemState()

    @Published private(set) var days: [String: DisciplineDay] = [:]

    private let daysKey = "discipline_days"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .shared) {
        self.defaults = defaults
        loadData()
    }

    var totalCompletedDays: Int {
        days.values.filter(\.isFullyCompleted).count
    }

    func getTaskOptions(for category: DisciplineCategory) -> [DisciplineTaskOption] {
        DisciplineTaskLibrary.options(for: category)
    }

    func getOrCreateDay(for date: Date) -> DisciplineDay {
        let key = dateToKey(date)
        if let existingDay = days[key] {
            return existingDay
        }

        let newDay = DisciplineDay.createForDate(date)
        days[key] = newDay
        saveData()
        return newDay
    }

    func getTodayDay() -> DisciplineDay {
        day(for: Date())
    }

    struct ToggleResult {
        let reachedConsistency: Bool
        let justCompletedAllTasks: Bool
        let xpResult: XPAwardResult?
    }

    @discardableResult
    func toggleTodayTask(at index: Int) -> ToggleResult {
        var today = getTodayDay()
        let previousDay = today
        let wasFullyCompleted = today.isFullyCompleted
        let wasConsistencyDay = today.isConsistencyDay
        let taskWasCompleted = today.tasks.indices.contains(index) ? !today.tasks[index].isCompleted : false
        today.toggleTask(at: index)
        updateDay(today, previousDay: previousDay)

        // Award or reverse XP
        let xpResult: XPAwardResult?
        if taskWasCompleted {
            xpResult = GamificationManager.shared.awardTaskXP(
                completedCount: today.completedTaskCount,
                totalCount: today.tasks.count,
                wasCompleted: true
            )
        } else {
            GamificationManager.shared.reverseTaskXP(wasFullyCompletedBefore: wasFullyCompleted)
            xpResult = nil
        }

        return ToggleResult(
            reachedConsistency: !wasConsistencyDay && today.isConsistencyDay,
            justCompletedAllTasks: !wasFullyCompleted && today.isFullyCompleted,
            xpResult: xpResult
        )
    }

    func updateTodaySelections(_ selections: [DisciplineCategory: String]) {
        var today = getTodayDay()
        let previousDay = today
        today.updateSelections(selections)
        updateDay(today, previousDay: previousDay)
    }

    func updateTodayTask(for category: DisciplineCategory, optionID: String) {
        var selections = Dictionary(uniqueKeysWithValues: getTodayDay().tasks.map { ($0.category, $0.optionID) })
        selections[category] = optionID
        updateTodaySelections(selections)
    }

    func syncTaskCompletion(
        on date: Date,
        category: DisciplineCategory,
        title: String,
        isCompleted: Bool
    ) {
        var day = getOrCreateDay(for: date)
        let previousDay = day

        guard let index = day.tasks.firstIndex(where: { task in
            task.category == category && task.title == title
        }) else {
            return
        }

        if day.tasks[index].isCompleted != isCompleted {
            day.tasks[index].toggleCompletion()
            updateDay(day, previousDay: previousDay)
        }
    }

    func getCompletionHistory(days numberOfDays: Int = 30) -> [DisciplineDay] {
        let calendar = Calendar.current
        let today = Date()

        return (0..<numberOfDays).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: today).map(day(for:))
        }
        .sorted { $0.date > $1.date }
    }

    func completionRate(in lastDays: Int = 30) -> Double {
        let history = getCompletionHistory(days: lastDays)
        guard !history.isEmpty else { return 0 }
        let completedDays = history.filter(\.isFullyCompleted).count
        return Double(completedDays) / Double(history.count)
    }

    func resetAllData() {
        days.removeAll()
        defaults.removeObject(forKey: daysKey)
        StreakManager.shared.resetStreakData()
        GamificationManager.shared.resetAllData()
    }

    private func loadData() {
        guard
            let data = defaults.data(forKey: daysKey),
            let decodedDays = try? JSONDecoder().decode([String: DisciplineDay].self, from: data)
        else {
            days = [:]
            return
        }

        days = decodedDays.reduce(into: [:]) { partialResult, entry in
            var day = entry.value
            let selections = Dictionary(uniqueKeysWithValues: day.tasks.map { ($0.category, $0.optionID) })
            day.updateSelections(selections)
            partialResult[entry.key] = day
        }
    }

    private func saveData() {
        if let encodedDays = try? JSONEncoder().encode(days) {
            defaults.set(encodedDays, forKey: daysKey)
        }
    }

    private func updateDay(_ day: DisciplineDay, previousDay: DisciplineDay?) {
        days[dateToKey(day.date)] = day

        let wasConsistencyDay = previousDay?.isConsistencyDay ?? false

        if day.isConsistencyDay && !wasConsistencyDay {
            StreakManager.shared.recordCompletedDay(day.date)
        } else if !day.isConsistencyDay && wasConsistencyDay {
            StreakManager.shared.removeCompletedDay(day.date)
        } else {
            StreakManager.shared.checkInToday()
        }

        GamificationManager.shared.updateWeeklyQuestProgress(
            tasksCompletedThisWeek: completionCountForCurrentWeek(),
            perfectDaysThisWeek: perfectDayCountForCurrentWeek()
        )
        saveData()
    }

    private func day(for date: Date) -> DisciplineDay {
        days[dateToKey(date)] ?? DisciplineDay.createForDate(date)
    }

    private func dateToKey(_ date: Date) -> String {
        DateFormatter.dayStorageKey.string(from: date)
    }

    private func completionCountForCurrentWeek() -> Int {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: Date()) else {
            return 0
        }

        return days.values
            .filter { interval.contains($0.date) }
            .reduce(0) { $0 + $1.completedTaskCount }
    }

    private func perfectDayCountForCurrentWeek() -> Int {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: Date()) else {
            return 0
        }

        return days.values
            .filter { interval.contains($0.date) && $0.isFullyCompleted }
            .count
    }
}

import Foundation
import SwiftUI

#if os(iOS)
import WidgetKit
#endif

// Event service to manage events with app-widget data sharing
final class EventService: ObservableObject {
    // Singleton instance for shared access
    static let shared = EventService()

    // Published property with all events
    @Published var events: [Event] = []

    // UserDefaults key for storage
    private let eventsKey = "savedEvents"
    private let backupEventsKey = "savedEvents_backup"

    // Initialize with events from storage
    init() {
        loadEvents()
    }

    // MARK: - Event CRUD Operations

    func addEvent(_ event: Event) {
        events.append(event)
        sortEvents()
        saveEvents()
    }

    func updateEvent(_ event: Event) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
            sortEvents()
            saveEvents()
        } else {
            print("Warning: Attempted to update non-existent event: \(event.id)")
        }
    }

    func deleteEvent(_ event: Event) {
        events.removeAll(where: { $0.id == event.id })
        saveEvents()
    }

    func toggleCompletionStatus(_ event: Event) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index].isCompleted.toggle()
            syncDisciplineCompletionIfNeeded(for: events[index])
            sortEvents()
            saveEvents()
        } else {
            print("Warning: Attempted to toggle completion for non-existent event: \(event.id)")
        }
    }

    // MARK: - Event Queries

    func getEvents(for date: Date) -> [Event] {
        let calendar = Calendar.current
        return events
            .filter { event in
                calendar.isDate(event.date, inSameDayAs: date)
            }
            .sorted { lhs, rhs in
                sortPredicate(lhs, rhs)
            }
    }

    func getEvents(in interval: DateInterval) -> [Event] {
        events
            .filter { interval.contains($0.date) }
            .sorted { lhs, rhs in
                sortPredicate(lhs, rhs)
            }
    }

    func getEvents(forWeekContaining date: Date) -> [Event] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: date) else {
            return []
        }
        return getEvents(in: interval)
    }

    func getEvents(forMonthContaining date: Date) -> [Event] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: date) else {
            return []
        }
        return getEvents(in: interval)
    }

    func eventCount(on date: Date) -> Int {
        getEvents(for: date).count
    }

    func hasEvent(on date: Date) -> Bool {
        eventCount(on: date) > 0
    }

    func hasDisciplineEvent(for task: DisciplineTask, on date: Date = Date()) -> Bool {
        let calendar = Calendar.current
        return events.contains { event in
            matchesDisciplineEvent(event, task: task, on: date, calendar: calendar)
        }
    }

    @discardableResult
    func scheduleDisciplineTask(_ task: DisciplineTask, on date: Date = Date()) -> Event {
        let calendar = Calendar.current

        if let existingEvent = events.first(where: { event in
            matchesDisciplineEvent(event, task: task, on: date, calendar: calendar)
        }) {
            return existingEvent
        }

        let event = Event(
            title: task.title,
            date: suggestedDate(for: task.category, on: date),
            notes: "Discipline • \(task.category.rawValue)\n\(task.detail)",
            isCompleted: task.isCompleted,
            iconName: iconName(for: task.category),
            tintHex: tintHex(for: task.category),
            isAllDay: false
        )

        addEvent(event)
        return event
    }

    func syncDisciplineTaskCompletion(for task: DisciplineTask, on date: Date = Date(), isCompleted: Bool) {
        let calendar = Calendar.current

        guard let index = events.firstIndex(where: { event in
            matchesDisciplineEvent(event, task: task, on: date, calendar: calendar)
        }) else {
            return
        }

        events[index].isCompleted = isCompleted
        saveEvents()
    }

    func nextIncompleteEvent(from date: Date = Date()) -> Event? {
        events
            .filter { !$0.isCompleted && $0.date >= date }
            .sorted { lhs, rhs in
                sortPredicate(lhs, rhs)
            }
            .first
    }

    /// Get upcoming events for the next N days
    func getUpcomingEvents(days: Int = 14) -> [Event] {
        let today = Date()
        let calendar = Calendar.current
        guard let endDate = calendar.date(byAdding: .day, value: days, to: today) else {
            return []
        }

        return events
            .filter { event in
                event.date >= today && event.date <= endDate
            }
            .sorted { lhs, rhs in
                sortPredicate(lhs, rhs)
            }
    }

    func getCompletedEvents(limit: Int = 10) -> [Event] {
        Array(
            events
                .filter(\.isCompleted)
                .sorted { lhs, rhs in
                    lhs.date > rhs.date
                }
                .prefix(limit)
        )
    }

    func getEventsForCurrentMonth() -> [Event] {
        getEvents(forMonthContaining: Date())
    }

    func getEventDaysForCurrentMonth() -> [Int: Bool] {
        let events = getEventsForCurrentMonth()
        let calendar = Calendar.current

        var eventDays = [Int: Bool]()

        for event in events {
            let day = calendar.component(.day, from: event.date)
            eventDays[day] = true
        }

        return eventDays
    }

    // MARK: - Data Persistence

    private func saveEvents() {
        do {
            if events.contains(where: { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || $0.date == Date.distantPast }) {
                print("Warning: Attempting to save invalid event data")
            }

            createBackup()
            let encoded = try JSONEncoder().encode(events)
            UserDefaults.shared.set(encoded, forKey: eventsKey)

            #if os(iOS)
            WidgetCenter.shared.reloadAllTimelines()
            #endif

            print("Events saved successfully: \(events.count) events")
        } catch {
            print("Error saving events: \(error.localizedDescription)")
            attemptPartialSave()
        }
    }

    private func loadEvents() {
        do {
            if isDataCorrupted() && hasBackup() {
                print("Attempting to restore events from backup")
                restoreFromBackup()
                return
            }

            if let savedEvents = UserDefaults.shared.data(forKey: eventsKey) {
                let decodedEvents = try JSONDecoder().decode([Event].self, from: savedEvents)
                events = decodedEvents
                sortEvents()
                print("Successfully loaded \(events.count) events")
            } else {
                events = []
                print("No saved events found")
            }
        } catch let decodingError as DecodingError {
            print("Decoding error: \(decodingError)")
            events = []
            attemptRecovery()
        } catch {
            print("Error loading events: \(error.localizedDescription)")
            events = []
            attemptRecovery()
        }
    }

    // MARK: - Error Recovery

    private func isDataCorrupted() -> Bool {
        guard let savedEvents = UserDefaults.shared.data(forKey: eventsKey) else {
            return false
        }

        do {
            let decoded = try JSONDecoder().decode([Event].self, from: savedEvents)

            let hasSuspiciousEvents = decoded.contains { event in
                let calendar = Calendar.current
                let hundredYearsFromNow = calendar.date(byAdding: .year, value: 100, to: Date()) ?? Date.distantFuture

                return event.date > hundredYearsFromNow ||
                    event.date < Date(timeIntervalSince1970: 0) ||
                    event.title.count > 1000
            }

            return hasSuspiciousEvents
        } catch {
            return true
        }
    }

    private func hasBackup() -> Bool {
        UserDefaults.shared.data(forKey: backupEventsKey) != nil
    }

    private func createBackup() {
        do {
            if !events.isEmpty {
                let encoded = try JSONEncoder().encode(events)
                UserDefaults.shared.set(encoded, forKey: backupEventsKey)
                UserDefaults.shared.set(Date(), forKey: "events_backup_timestamp")
                print("Events backup created")
            }
        } catch {
            print("Error creating events backup: \(error.localizedDescription)")
        }
    }

    private func restoreFromBackup() {
        if let backupData = UserDefaults.shared.data(forKey: backupEventsKey) {
            do {
                let recoveredEvents = try JSONDecoder().decode([Event].self, from: backupData)
                if !recoveredEvents.isEmpty {
                    events = recoveredEvents
                    sortEvents()
                    print("Recovered \(recoveredEvents.count) events from backup")
                    saveEvents()
                } else {
                    events = []
                    print("Backup was empty, reset to empty events array")
                }
            } catch {
                print("Backup restoration failed: \(error.localizedDescription)")
                events = []
            }
        } else {
            print("No backup found, reset to empty events array")
            events = []
        }
    }

    private func attemptPartialSave() {
        let validEvents = events.filter {
            !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.date != Date.distantPast
        }

        if validEvents.count < events.count {
            print("Attempting to save \(validEvents.count) valid events out of \(events.count) total")
            events = validEvents
            sortEvents()
        }

        do {
            let encoded = try JSONEncoder().encode(events)
            UserDefaults.shared.set(encoded, forKey: eventsKey)
            print("Partial save successful")
        } catch {
            print("Partial save also failed: \(error.localizedDescription)")
        }
    }

    private func attemptRecovery() {
        print("Attempting to recover events data...")

        if hasBackup() {
            restoreFromBackup()
        } else {
            events = []
            saveEvents()
            print("No recovery source available, reset to empty events array")
        }
    }

    private func sortEvents() {
        events.sort { lhs, rhs in
            sortPredicate(lhs, rhs)
        }
    }

    private func syncDisciplineCompletionIfNeeded(for event: Event) {
        guard
            let category = disciplineCategory(for: event),
            event.notes.contains("Discipline •")
        else {
            return
        }

        DisciplineSystemState.shared.syncTaskCompletion(
            on: event.date,
            category: category,
            title: event.title,
            isCompleted: event.isCompleted
        )
    }

    private func disciplineCategory(for event: Event) -> DisciplineCategory? {
        DisciplineCategory.allCases.first { category in
            event.notes.contains(disciplineMarker(for: category))
        }
    }

    private func matchesDisciplineEvent(
        _ event: Event,
        task: DisciplineTask,
        on date: Date,
        calendar: Calendar
    ) -> Bool {
        calendar.isDate(event.date, inSameDayAs: date) &&
            event.title == task.title &&
            event.notes.contains(disciplineMarker(for: task.category))
    }

    private func disciplineMarker(for category: DisciplineCategory) -> String {
        "Discipline • \(category.rawValue)"
    }

    private func suggestedDate(for category: DisciplineCategory, on date: Date) -> Date {
        let calendar = Calendar.current

        switch category {
        case .mind:
            return calendar.date(bySettingHour: 7, minute: 30, second: 0, of: date) ?? date
        case .body:
            return calendar.date(bySettingHour: 18, minute: 0, second: 0, of: date) ?? date
        case .focus:
            return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
        }
    }

    private func iconName(for category: DisciplineCategory) -> String {
        switch category {
        case .mind:
            return "brain.head.profile"
        case .body:
            return "figure.run"
        case .focus:
            return "target"
        }
    }

    private func tintHex(for category: DisciplineCategory) -> String {
        switch category {
        case .mind:
            return EventTintPalette.options[4].hex
        case .body:
            return EventTintPalette.options[1].hex
        case .focus:
            return EventTintPalette.options[0].hex
        }
    }

    private func sortPredicate(_ lhs: Event, _ rhs: Event) -> Bool {
        if lhs.date == rhs.date {
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
        return lhs.date < rhs.date
    }
}

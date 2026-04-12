import Foundation
import UserNotifications

final class StreakManager: ObservableObject {
    static let shared = StreakManager()

    @Published private(set) var currentStreak: Int = 0
    @Published private(set) var longestStreak: Int = 0

    private let currentStreakKey = "streak_currentStreak"
    private let longestStreakKey = "streak_longestStreak"
    private let streakDaysKey = "streak_daysRecord"
    private let lastCompletionDateKey = "streak_lastCompletionDate"
    private let defaults: UserDefaults

    private var streakDays: [TimeInterval] = []

    private init(defaults: UserDefaults = .shared) {
        self.defaults = defaults
        loadStreakData()
        recomputeMetrics(notifyObservers: false)
    }

    func checkInToday() {
        recomputeMetrics(notifyObservers: true)
    }

    func recordCompletedDay(_ date: Date) {
        let timestamp = normalizedDay(for: date).timeIntervalSince1970
        guard !streakDays.contains(timestamp) else {
            recomputeMetrics(notifyObservers: true)
            return
        }

        streakDays.append(timestamp)
        streakDays.sort()

        if streakDays.count > 366 {
            streakDays = Array(streakDays.suffix(366))
        }

        let previousCurrentStreak = currentStreak
        recomputeMetrics(notifyObservers: true)

        if currentStreak > previousCurrentStreak {
            checkForStreakMilestone()
        }
    }

    func removeCompletedDay(_ date: Date) {
        let timestamp = normalizedDay(for: date).timeIntervalSince1970
        streakDays.removeAll { $0 == timestamp }
        recomputeMetrics(notifyObservers: true)
    }

    func getStreakDays() -> [Date] {
        streakDays
            .map { Date(timeIntervalSince1970: $0) }
            .sorted()
    }

    func isDateInStreak(_ date: Date) -> Bool {
        let timestamp = normalizedDay(for: date).timeIntervalSince1970
        return streakDays.contains(timestamp)
    }

    func resetStreakData() {
        streakDays.removeAll()
        currentStreak = 0
        longestStreak = 0

        defaults.removeObject(forKey: streakDaysKey)
        defaults.set(0, forKey: currentStreakKey)
        defaults.set(0, forKey: longestStreakKey)
        defaults.removeObject(forKey: lastCompletionDateKey)

        NotificationCenter.default.post(name: .streakUpdated, object: nil)
    }

    func getStreakStartDate() -> Date? {
        let days = sortedUniqueDays()
        guard let lastDay = days.last else { return nil }

        let today = normalizedDay(for: Date())
        let dayGap = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
        guard dayGap <= 1 else { return nil }

        var startDate = lastDay
        var previousDay = lastDay

        for day in days.dropLast().reversed() {
            let daysBetween = Calendar.current.dateComponents([.day], from: day, to: previousDay).day ?? 0
            if daysBetween == 1 {
                startDate = day
                previousDay = day
            } else {
                break
            }
        }

        return startDate
    }

    private func loadStreakData() {
        if let savedDays = defaults.array(forKey: streakDaysKey) as? [TimeInterval] {
            streakDays = savedDays
        } else {
            let legacyCurrentStreak = defaults.integer(forKey: currentStreakKey)
            let legacyLastCompletion = defaults.object(forKey: lastCompletionDateKey) as? Date

            if legacyCurrentStreak > 0, let lastCompletion = legacyLastCompletion {
                let lastDay = normalizedDay(for: lastCompletion)
                streakDays = (0..<legacyCurrentStreak).compactMap { offset in
                    Calendar.current.date(byAdding: .day, value: -offset, to: lastDay)?.timeIntervalSince1970
                }.sorted()
            }
        }
    }

    private func saveStreakData(lastCompletionDate: Date?) {
        defaults.set(streakDays, forKey: streakDaysKey)
        defaults.set(currentStreak, forKey: currentStreakKey)
        defaults.set(longestStreak, forKey: longestStreakKey)
        defaults.set(lastCompletionDate, forKey: lastCompletionDateKey)
    }

    private func recomputeMetrics(notifyObservers: Bool) {
        let previousCurrentStreak = currentStreak
        let previousLongestStreak = longestStreak

        let days = sortedUniqueDays()
        currentStreak = calculateCurrentStreak(from: days)
        longestStreak = calculateLongestStreak(from: days)

        saveStreakData(lastCompletionDate: days.last)

        if notifyObservers && (previousCurrentStreak != currentStreak || previousLongestStreak != longestStreak) {
            NotificationCenter.default.post(name: .streakUpdated, object: nil)
        }
    }

    private func sortedUniqueDays() -> [Date] {
        Array(Set(streakDays))
            .map { Date(timeIntervalSince1970: $0) }
            .sorted()
    }

    private func calculateCurrentStreak(from days: [Date]) -> Int {
        guard let lastDay = days.last else { return 0 }

        let today = normalizedDay(for: Date())
        let dayGap = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
        guard dayGap <= 1 else { return 0 }

        var streak = 1
        var previousDay = lastDay

        for day in days.dropLast().reversed() {
            let daysBetween = Calendar.current.dateComponents([.day], from: day, to: previousDay).day ?? 0
            if daysBetween == 1 {
                streak += 1
                previousDay = day
            } else {
                break
            }
        }

        return streak
    }

    private func calculateLongestStreak(from days: [Date]) -> Int {
        guard let firstDay = days.first else { return 0 }

        var longest = 1
        var current = 1
        var previousDay = firstDay

        for day in days.dropFirst() {
            let daysBetween = Calendar.current.dateComponents([.day], from: previousDay, to: day).day ?? 0
            if daysBetween == 1 {
                current += 1
            } else {
                current = 1
            }

            longest = max(longest, current)
            previousDay = day
        }

        return longest
    }

    private func normalizedDay(for date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    private func checkForStreakMilestone() {
        let milestones = [3, 7, 14, 21, 30, 50, 100, 365]
        guard milestones.contains(currentStreak) else { return }

        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }

            let content = UNMutableNotificationContent()
            content.title = "Streak Milestone Reached! 🔥"
            content.body = "You’ve completed your discipline plan for \(self.currentStreak) days in a row."
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "com.moti.streakMilestone.\(self.currentStreak)",
                content: content,
                trigger: nil
            )

            notificationCenter.add(request)
        }
    }
}

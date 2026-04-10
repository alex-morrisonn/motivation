import Foundation
import SwiftUI

// MARK: - Daily Discipline Task Model

/// Represents a single discipline task within a day
struct DisciplineTask: Identifiable, Codable, Hashable {
    /// Unique identifier for the task
    let id: UUID
    
    /// The task description/name
    var title: String
    
    /// Whether this task is completed
    var isCompleted: Bool
    
    /// Optional notes or details about the task
    var notes: String?
    
    /// Time the task was completed (if applicable)
    var completedAt: Date?
    
    /// Order index for the task (0, 1, or 2 for the three daily tasks)
    var orderIndex: Int
    
    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, notes: String? = nil, completedAt: Date? = nil, orderIndex: Int) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.notes = notes
        self.completedAt = completedAt
        self.orderIndex = orderIndex
    }
    
    /// Toggle the completion state
    mutating func toggleCompletion() {
        isCompleted.toggle()
        completedAt = isCompleted ? Date() : nil
    }
}

// MARK: - Daily Discipline Day Model

/// Represents a single day in the discipline system
struct DisciplineDay: Identifiable, Codable, Hashable {
    /// Unique identifier for the day
    let id: UUID
    
    /// The date this day represents
    var date: Date
    
    /// The three discipline tasks for this day
    var tasks: [DisciplineTask]
    
    /// Whether all tasks for the day are completed
    var isFullyCompleted: Bool {
        tasks.count == 3 && tasks.allSatisfy { $0.isCompleted }
    }
    
    /// Number of completed tasks
    var completedTaskCount: Int {
        tasks.filter { $0.isCompleted }.count
    }
    
    /// Completion percentage (0.0 to 1.0)
    var completionPercentage: Double {
        guard tasks.count > 0 else { return 0.0 }
        return Double(completedTaskCount) / Double(tasks.count)
    }
    
    /// Formatted date string for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    /// Check if this day is today
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    /// Check if this day is in the past
    var isPast: Bool {
        !Calendar.current.isDateInToday(date) && date < Date()
    }
    
    init(id: UUID = UUID(), date: Date, tasks: [DisciplineTask]) {
        self.id = id
        self.date = date
        self.tasks = tasks.sorted { $0.orderIndex < $1.orderIndex }
    }
    
    /// Create a new day with empty tasks
    static func createForDate(_ date: Date, taskTemplates: [String] = ["Task 1", "Task 2", "Task 3"]) -> DisciplineDay {
        let tasks = taskTemplates.enumerated().map { index, title in
            DisciplineTask(title: title, orderIndex: index)
        }
        return DisciplineDay(date: date, tasks: tasks)
    }
    
    /// Toggle a task's completion state by index
    mutating func toggleTask(at index: Int) {
        guard tasks.indices.contains(index) else { return }
        tasks[index].toggleCompletion()
    }
    
    /// Toggle a task's completion state by ID
    mutating func toggleTask(id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].toggleCompletion()
    }
}

// MARK: - Discipline Streak Model

/// Represents the streak information for the discipline system
struct DisciplineStreak: Codable {
    /// Current consecutive days with all tasks completed
    var currentStreak: Int
    
    /// Longest streak ever achieved
    var longestStreak: Int
    
    /// Last date a full day was completed
    var lastCompletionDate: Date?
    
    /// Total number of days with all tasks completed
    var totalCompletedDays: Int
    
    /// Date the user started using the discipline system
    var startDate: Date
    
    init(currentStreak: Int = 0, longestStreak: Int = 0, lastCompletionDate: Date? = nil, totalCompletedDays: Int = 0, startDate: Date = Date()) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastCompletionDate = lastCompletionDate
        self.totalCompletedDays = totalCompletedDays
        self.startDate = startDate
    }
    
    /// Update the streak based on a newly completed day
    mutating func updateForCompletion(on date: Date) {
        let calendar = Calendar.current
        
        // Check if this is a new completion or updating today's completion
        if let lastDate = lastCompletionDate {
            let daysBetween = calendar.dateComponents([.day], from: lastDate, to: date).day ?? 0
            
            if calendar.isDate(date, inSameDayAs: lastDate) {
                // Same day, no streak change
                return
            } else if daysBetween == 1 {
                // Consecutive day - increment streak
                currentStreak += 1
            } else if daysBetween > 1 {
                // Streak broken - reset to 1
                currentStreak = 1
            }
        } else {
            // First completion ever
            currentStreak = 1
        }
        
        // Update longest streak if necessary
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
        
        // Update last completion date
        lastCompletionDate = date
        
        // Increment total completed days
        totalCompletedDays += 1
    }
    
    /// Check if the streak should be broken based on current date
    mutating func validateStreak(currentDate: Date = Date()) {
        guard let lastDate = lastCompletionDate else {
            currentStreak = 0
            return
        }
        
        let calendar = Calendar.current
        let daysSinceLastCompletion = calendar.dateComponents([.day], from: lastDate, to: currentDate).day ?? 0
        
        // If more than one day has passed without a completion, reset streak
        if daysSinceLastCompletion > 1 {
            currentStreak = 0
        }
    }
}

// MARK: - Discipline System State

/// Main state container for the entire discipline system
class DisciplineSystemState: ObservableObject {
    /// All discipline days, keyed by date string (yyyy-MM-dd)
    @Published var days: [String: DisciplineDay] = [:]
    
    /// Current streak information
    @Published var streak: DisciplineStreak = DisciplineStreak()
    
    /// User's custom task templates
    @Published var taskTemplates: [String] = ["Task 1", "Task 2", "Task 3"]
    
    /// Storage keys
    private let daysKey = "discipline_days"
    private let streakKey = "discipline_streak"
    private let templatesKey = "discipline_task_templates"
    
    /// UserDefaults instance
    private let defaults: UserDefaults
    
    /// App group identifier
    private let appGroupIdentifier = "group.com.alexmorrison.moti.shared"
    
    init() {
        // Initialize with shared UserDefaults for widget support
        if let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) {
            self.defaults = sharedDefaults
            print("DisciplineSystemState: Connected to shared app group")
        } else {
            print("DisciplineSystemState: Warning - using standard UserDefaults")
            self.defaults = UserDefaults.standard
        }
        
        loadData()
    }
    
    // MARK: - Data Persistence
    
    /// Load all data from UserDefaults
    func loadData() {
        // Load days
        if let daysData = defaults.data(forKey: daysKey),
           let decodedDays = try? JSONDecoder().decode([String: DisciplineDay].self, from: daysData) {
            self.days = decodedDays
        }
        
        // Load streak
        if let streakData = defaults.data(forKey: streakKey),
           let decodedStreak = try? JSONDecoder().decode(DisciplineStreak.self, from: streakData) {
            self.streak = decodedStreak
        }
        
        // Load templates
        if let templates = defaults.stringArray(forKey: templatesKey), templates.count == 3 {
            self.taskTemplates = templates
        }
        
        // Validate streak on load
        streak.validateStreak()
        saveData()
    }
    
    /// Save all data to UserDefaults
    func saveData() {
        // Save days
        if let encodedDays = try? JSONEncoder().encode(days) {
            defaults.set(encodedDays, forKey: daysKey)
        }
        
        // Save streak
        if let encodedStreak = try? JSONEncoder().encode(streak) {
            defaults.set(encodedStreak, forKey: streakKey)
        }
        
        // Save templates
        defaults.set(taskTemplates, forKey: templatesKey)
    }
    
    // MARK: - Day Management
    
    /// Get or create a discipline day for a specific date
    func getOrCreateDay(for date: Date) -> DisciplineDay {
        let dateKey = dateToKey(date)
        
        if let existingDay = days[dateKey] {
            return existingDay
        } else {
            let newDay = DisciplineDay.createForDate(date, taskTemplates: taskTemplates)
            days[dateKey] = newDay
            saveData()
            return newDay
        }
    }
    
    /// Get today's discipline day
    func getTodayDay() -> DisciplineDay {
        return getOrCreateDay(for: Date())
    }
    
    /// Update a specific day
    func updateDay(_ day: DisciplineDay) {
        let dateKey = dateToKey(day.date)
        days[dateKey] = day
        
        // If the day is fully completed, update streak
        if day.isFullyCompleted {
            streak.updateForCompletion(on: day.date)
        }
        
        saveData()
    }
    
    /// Toggle a task in today's day
    func toggleTodayTask(at index: Int) {
        var today = getTodayDay()
        today.toggleTask(at: index)
        updateDay(today)
    }
    
    /// Toggle a task by ID in a specific day
    func toggleTask(id: UUID, in day: DisciplineDay) {
        var updatedDay = day
        updatedDay.toggleTask(id: id)
        updateDay(updatedDay)
    }
    
    /// Update task templates
    func updateTemplates(_ templates: [String]) {
        guard templates.count == 3 else { return }
        self.taskTemplates = templates
        saveData()
    }
    
    // MARK: - Statistics
    
    /// Get completion history for a date range
    func getCompletionHistory(days: Int = 30) -> [DisciplineDay] {
        let calendar = Calendar.current
        let today = Date()
        
        var history: [DisciplineDay] = []
        
        for dayOffset in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                let day = getOrCreateDay(for: date)
                history.append(day)
            }
        }
        
        return history.sorted { $0.date > $1.date }
    }
    
    /// Get the number of completed days in the last N days
    func completedDaysCount(in lastDays: Int = 30) -> Int {
        let history = getCompletionHistory(days: lastDays)
        return history.filter { $0.isFullyCompleted }.count
    }
    
    /// Get completion rate for the last N days (0.0 to 1.0)
    func completionRate(in lastDays: Int = 30) -> Double {
        let history = getCompletionHistory(days: lastDays)
        guard !history.isEmpty else { return 0.0 }
        
        let completedCount = history.filter { $0.isFullyCompleted }.count
        return Double(completedCount) / Double(history.count)
    }
    
    // MARK: - Helper Methods
    
    /// Convert a date to a storage key string (yyyy-MM-dd)
    private func dateToKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    /// Reset all data (useful for testing or user preference)
    func resetAllData() {
        days.removeAll()
        streak = DisciplineStreak()
        taskTemplates = ["Task 1", "Task 2", "Task 3"]
        saveData()
    }
}

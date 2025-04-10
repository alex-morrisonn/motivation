import Foundation
import SwiftUI

/// Service responsible for managing to-do items
class TodoService: ObservableObject {
    // Singleton instance for app-wide access
    static let shared = TodoService()
    
    // MARK: - Published Properties
    
    /// Collection of all todo items
    @Published var todos: [TodoItem] = []
    
    // MARK: - Private Properties
    
    /// UserDefaults keys
    private let todosKey = "savedTodos"
    private let backupTodosKey = "savedTodos_backup"
    
    // MARK: - Streak Management Properties
    
    private let momentumStreakKey = "todo_momentumStreak"
    private let lastStreakDateKey = "todo_lastStreakDate"
    private let streakCountKey = "todo_streakCount"
    
    // MARK: - Error Types
    
    /// Error type for TodoService operations
    enum TodoServiceError: Error, LocalizedError {
        case failedToLoadTodos
        case failedToSaveTodos
        case invalidTodo
        case todoNotFound
        
        var errorDescription: String? {
            switch self {
            case .failedToLoadTodos: return "Failed to load todos"
            case .failedToSaveTodos: return "Failed to save todos"
            case .invalidTodo: return "Invalid todo data"
            case .todoNotFound: return "Todo not found"
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        // Load saved todos
        loadTodos()
    }
    
    // MARK: - Public Methods - CRUD
    
    /// Add a new todo item
    /// - Parameter todo: The todo item to add
    func addTodo(_ todo: TodoItem) {
        todos.append(todo)
        saveTodos()
    }
    
    /// Update an existing todo item
    /// - Parameter todo: The todo with updated properties
    func updateTodo(_ todo: TodoItem) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index] = todo
            saveTodos()
        } else {
            print("Warning: Attempted to update non-existent todo: \(todo.id)")
        }
    }
    
    /// Delete a todo item
    /// - Parameter todo: The todo to delete
    func deleteTodo(_ todo: TodoItem) {
        todos.removeAll(where: { $0.id == todo.id })
        saveTodos()
    }
    
    /// Toggle completion status for a todo
    /// - Parameter todo: The todo to toggle
    func toggleCompletionStatus(_ todo: TodoItem) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            let wasCompleted = todos[index].isCompleted
            todos[index].isCompleted.toggle()
            
            // Check if we just completed a task (not uncompleted)
            if !wasCompleted && todos[index].isCompleted {
                // Update streak only when completing a task (not uncompleting)
                checkStreakAfterCompletion()
            }
            
            saveTodos()
        } else {
            print("Warning: Attempted to toggle completion for non-existent todo: \(todo.id)")
        }
    }
    
    // MARK: - Public Methods - Queries
    
    /// Get incomplete todos sorted by priority
    /// - Returns: Array of incomplete todos
    func getIncompleteTodos() -> [TodoItem] {
        return todos
            .filter { !$0.isCompleted }
            .sorted(by: { $0.priority.rawValue > $1.priority.rawValue })
    }
    
    /// Get completed todos
    /// - Returns: Array of completed todos
    func getCompletedTodos() -> [TodoItem] {
        return todos
            .filter { $0.isCompleted }
            .sorted(by: { $0.createdDate > $1.createdDate })
    }
    
    /// Get overdue todos
    /// - Returns: Array of overdue todos
    func getOverdueTodos() -> [TodoItem] {
        return todos.filter { $0.isOverdue }
    }
    
    // MARK: - Streak Management Methods
    
    /// Check if user has momentum streak (completed 3+ tasks today)
    var hasMomentumToday: Bool {
        return getCompletedTodosForToday().count >= 3
    }
    
    /// Get current streak count
    var currentStreakDays: Int {
        return UserDefaults.standard.integer(forKey: streakCountKey)
    }
    
    /// Get completed todos for today only
    func getCompletedTodosForToday() -> [TodoItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return todos.filter {
            $0.isCompleted &&
            calendar.isDate(calendar.startOfDay(for: $0.createdDate), inSameDayAs: today)
        }
    }
    
    /// Calculate progress for today's tasks
    func calculateDailyProgress() -> Double {
        let todayTodos = todos.filter {
            let calendar = Calendar.current
            return calendar.isDateInToday($0.createdDate)
        }
        
        guard !todayTodos.isEmpty else { return 0.0 }
        
        let completedCount = todayTodos.filter { $0.isCompleted }.count
        return Double(completedCount) / Double(todayTodos.count)
    }
    
    /// Update streak when completing a task
    func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let defaults = UserDefaults.standard
        
        // Get last streak date if exists
        if let lastStreakDateData = defaults.object(forKey: lastStreakDateKey) as? Date {
            let lastDate = calendar.startOfDay(for: lastStreakDateData)
            
            if calendar.isDate(today, inSameDayAs: lastDate) {
                // Same day, check if we just hit 3 tasks
                if getCompletedTodosForToday().count == 3 {
                    // Just reached momentum today
                    defaults.set(true, forKey: momentumStreakKey)
                }
            } else if let daysBetween = calendar.dateComponents([.day], from: lastDate, to: today).day {
                if daysBetween == 1 {
                    // Consecutive day
                    if hasMomentumToday {
                        // Continue streak
                        let currentStreak = defaults.integer(forKey: streakCountKey)
                        defaults.set(currentStreak + 1, forKey: streakCountKey)
                        defaults.set(true, forKey: momentumStreakKey)
                    }
                } else {
                    // Streak broken
                    if hasMomentumToday {
                        // Start new streak
                        defaults.set(1, forKey: streakCountKey)
                        defaults.set(true, forKey: momentumStreakKey)
                    } else {
                        // No streak
                        defaults.set(0, forKey: streakCountKey)
                        defaults.set(false, forKey: momentumStreakKey)
                    }
                }
            }
        } else if hasMomentumToday {
            // First time ever reaching momentum
            defaults.set(1, forKey: streakCountKey)
            defaults.set(true, forKey: momentumStreakKey)
        }
        
        // Always update the last streak date
        defaults.set(today, forKey: lastStreakDateKey)
    }
    
    /// Call this when a task is completed
    func checkStreakAfterCompletion() {
        updateStreak()
    }
    
    // MARK: - Private Methods
    
    /// Save todos to UserDefaults with error handling
    private func saveTodos() {
        do {
            // Create backup before saving
            createBackup()
            
            let encoded = try JSONEncoder().encode(todos)
            UserDefaults.standard.set(encoded, forKey: todosKey)
            
            print("Successfully saved \(todos.count) todos")
        } catch {
            print("Error saving todos: \(error.localizedDescription)")
            // Try to recover by saving valid todos
            attemptPartialSave()
        }
    }
    
    /// Load todos from UserDefaults with error handling
    private func loadTodos() {
        if let savedTodos = UserDefaults.standard.data(forKey: todosKey) {
            do {
                let decodedTodos = try JSONDecoder().decode([TodoItem].self, from: savedTodos)
                todos = decodedTodos
                print("Successfully loaded \(todos.count) todos")
            } catch {
                print("Error decoding todos: \(error.localizedDescription)")
                // Attempt to recover from backup
                if !restoreFromBackup() {
                    // If recovery fails, start with empty array
                    todos = []
                }
            }
        } else {
            todos = [] // Default to empty array if no todos found
            print("No saved todos found")
        }
    }
    
    /// Create a backup of todos data
    private func createBackup() {
        // Only backup if we have valid data
        if !todos.isEmpty {
            if let encoded = try? JSONEncoder().encode(todos) {
                UserDefaults.standard.set(encoded, forKey: backupTodosKey)
                print("Todos backup created")
            }
        }
    }
    
    /// Restore from backup if available
    /// - Returns: Boolean indicating if restore was successful
    private func restoreFromBackup() -> Bool {
        if let backupData = UserDefaults.standard.data(forKey: backupTodosKey) {
            do {
                let recoveredTodos = try JSONDecoder().decode([TodoItem].self, from: backupData)
                if !recoveredTodos.isEmpty {
                    print("Recovered \(recoveredTodos.count) todos from backup")
                    todos = recoveredTodos
                    return true
                }
            } catch {
                print("Backup restoration failed: \(error.localizedDescription)")
            }
        }
        return false
    }
    
    /// Attempt to save only valid todos
    private func attemptPartialSave() {
        let validTodos = todos.filter { !$0.title.isEmpty }
        
        if validTodos.count < todos.count {
            print("Attempting to save \(validTodos.count) valid todos out of \(todos.count) total")
            todos = validTodos
        }
        
        do {
            let encoded = try JSONEncoder().encode(todos)
            UserDefaults.standard.set(encoded, forKey: todosKey)
            print("Partial save successful")
        } catch {
            print("Partial save also failed: \(error.localizedDescription)")
        }
    }
}

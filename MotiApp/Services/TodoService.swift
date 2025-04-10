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
    
    // MARK: - Public Methods
    
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
            todos[index].isCompleted.toggle()
            saveTodos()
        } else {
            print("Warning: Attempted to toggle completion for non-existent todo: \(todo.id)")
        }
    }
    
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

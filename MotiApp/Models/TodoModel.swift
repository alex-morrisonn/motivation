import Foundation

/// Todo item model for task management
struct TodoItem: Identifiable, Codable, Equatable {
    // Unique identifier for the todo item
    var id = UUID()
    
    // Todo properties
    var title: String
    var notes: String
    var isCompleted: Bool = false
    var createdDate: Date
    var dueDate: Date?
    var priority: Priority = .normal
    var whyThisMatters: String = "" // New field for emotional context
    
    // Priority levels for todos
    enum Priority: Int, Codable, CaseIterable {
        case low = 0
        case normal = 1
        case high = 2
        
        var name: String {
            switch self {
            case .low: return "Low"
            case .normal: return "Normal"
            case .high: return "High"
            }
        }
        
        var color: String {
            switch self {
            case .low: return "green"
            case .normal: return "blue"
            case .high: return "red"
            }
        }
    }
    
    // Equatable implementation
    static func == (lhs: TodoItem, rhs: TodoItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Convenience Methods
    
    /// Returns whether the todo item is overdue
    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return !isCompleted && dueDate < Date()
    }
    
    /// Returns a formatted due date string if available
    var formattedDueDate: String? {
        guard let dueDate = dueDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: dueDate)
    }
    
    // MARK: - Factory Methods
    
    /// Create a new todo item with default values
    static func createNew(title: String, notes: String = "", whyThisMatters: String = "") -> TodoItem {
        return TodoItem(
            title: title,
            notes: notes,
            createdDate: Date(),
            whyThisMatters: whyThisMatters
        )
    }
    
    /// Create a sample todo for UI previews
    static var sample: TodoItem {
        TodoItem(
            id: UUID(),
            title: "Sample Todo",
            notes: "This is a sample todo item",
            isCompleted: false,
            createdDate: Date(),
            dueDate: Date().addingTimeInterval(86400),
            priority: .normal,
            whyThisMatters: "It's an important example"
        )
    }
    
    /// Create multiple samples for UI previews
    static var samples: [TodoItem] {
        [
            TodoItem(
                id: UUID(),
                title: "Meditate for 10 minutes",
                notes: "Focus on mindful breathing",
                isCompleted: false,
                createdDate: Date(),
                dueDate: Date().addingTimeInterval(3600),
                priority: .high,
                whyThisMatters: "Helps keep me centered all day"
            ),
            TodoItem(
                id: UUID(),
                title: "Read motivational book",
                notes: "Chapter 3 of Atomic Habits",
                isCompleted: true,
                createdDate: Date().addingTimeInterval(-86400),
                dueDate: Date().addingTimeInterval(-3600),
                priority: .normal,
                whyThisMatters: "Building my knowledge foundation"
            ),
            TodoItem(
                id: UUID(),
                title: "Write in gratitude journal",
                notes: "List 3 things I'm grateful for today",
                isCompleted: false,
                createdDate: Date().addingTimeInterval(-172800),
                dueDate: Date().addingTimeInterval(86400),
                priority: .low,
                whyThisMatters: "So I don't panic Sunday night"
            )
        ]
    }
}

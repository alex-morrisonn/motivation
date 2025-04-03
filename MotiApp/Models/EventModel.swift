import Foundation

// Event model for calendar entries
struct Event: Identifiable, Codable, Equatable {
    // Unique identifier for the event
    var id = UUID()
    
    // Event properties
    var title: String
    var date: Date
    var notes: String
    var isCompleted: Bool = false
    
    // Equatable implementation
    static func == (lhs: Event, rhs: Event) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Convenience Methods
    
    /// Check if event is scheduled for today
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    /// Check if event is in the past
    var isPast: Bool {
        date < Date()
    }
    
    /// Check if event is in the future
    var isFuture: Bool {
        date > Date()
    }
    
    /// Returns a formatted time string
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    /// Returns a formatted date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // MARK: - Factory Methods
    
    /// Create a new event scheduled for today
    static func createForToday(title: String, notes: String = "") -> Event {
        let today = Date()
        return Event(title: title, date: today, notes: notes)
    }
    
    /// Create a new event scheduled for tomorrow
    static func createForTomorrow(title: String, notes: String = "") -> Event {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return Event(title: title, date: tomorrow, notes: notes)
    }
    
    /// Create a sample event for UI previews
    static var sample: Event {
        Event(
            id: UUID(),
            title: "Sample Event",
            date: Date(),
            notes: "This is a sample event for testing",
            isCompleted: false
        )
    }
}

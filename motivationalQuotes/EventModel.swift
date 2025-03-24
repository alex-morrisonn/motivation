import Foundation

// Event model for calendar entries
struct Event: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var date: Date
    var notes: String
    var isCompleted: Bool = false
    
    static func == (lhs: Event, rhs: Event) -> Bool {
        return lhs.id == rhs.id
    }
}

// Event service to manage events
class EventService: ObservableObject {
    static let shared = EventService()
    
    @Published var events: [Event] = []
    
    init() {
        loadEvents()
    }
    
    // Save events to UserDefaults
    private func saveEvents() {
        if let encoded = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(encoded, forKey: "savedEvents")
        }
    }
    
    // Load events from UserDefaults
    private func loadEvents() {
        if let savedEvents = UserDefaults.standard.data(forKey: "savedEvents") {
            if let decodedEvents = try? JSONDecoder().decode([Event].self, from: savedEvents) {
                events = decodedEvents
                return
            }
        }
        events = [] // Default to empty array if no events found
    }
    
    // Add a new event
    func addEvent(_ event: Event) {
        events.append(event)
        saveEvents()
    }
    
    // Update an existing event
    func updateEvent(_ event: Event) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
            saveEvents()
        }
    }
    
    // Delete an event
    func deleteEvent(_ event: Event) {
        events.removeAll(where: { $0.id == event.id })
        saveEvents()
    }
    
    // Toggle completion status
    func toggleCompletionStatus(_ event: Event) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index].isCompleted.toggle()
            saveEvents()
        }
    }
    
    // Get events for a specific date
    func getEvents(for date: Date) -> [Event] {
        let calendar = Calendar.current
        return events.filter { event in
            calendar.isDate(event.date, inSameDayAs: date)
        }
    }
    
    // Get upcoming events (next 7 days)
    func getUpcomingEvents() -> [Event] {
        let today = Date()
        let calendar = Calendar.current
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: today)!
        
        return events.filter { event in
            let eventDate = event.date
            return (eventDate >= today && eventDate <= nextWeek)
        }.sorted { $0.date < $1.date }
    }
}

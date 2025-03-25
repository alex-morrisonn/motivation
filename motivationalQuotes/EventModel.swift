import Foundation
import SwiftUI

#if os(iOS)
import WidgetKit
#endif

// Shared App Group identifier - use this same string in both app and widget extension
let appGroupIdentifier = "group.com.motivationalQuotes.shared"

// Access shared UserDefaults
extension UserDefaults {
    static var shared: UserDefaults {
        return UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }
}

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
    
    // Save events to Shared UserDefaults
    private func saveEvents() {
        if let encoded = try? JSONEncoder().encode(events) {
            UserDefaults.shared.set(encoded, forKey: "savedEvents")
            
            // Update WidgetCenter to refresh widgets
            #if os(iOS)
            WidgetCenter.shared.reloadAllTimelines()
            #endif
        }
    }
    
    // Load events from Shared UserDefaults
    private func loadEvents() {
        if let savedEvents = UserDefaults.shared.data(forKey: "savedEvents") {
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
    
    // Get events for the current month
    func getEventsForCurrentMonth() -> [Event] {
        let calendar = Calendar.current
        let currentDate = Date()
        let currentMonth = calendar.component(.month, from: currentDate)
        let currentYear = calendar.component(.year, from: currentDate)
        
        return events.filter { event in
            let eventMonth = calendar.component(.month, from: event.date)
            let eventYear = calendar.component(.year, from: event.date)
            return eventMonth == currentMonth && eventYear == currentYear
        }
    }
    
    // Get days in current month that have events
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
}

// NOTE: Instead of adding this extension here, add the following to your ContentView:
/*
.onOpenURL { url in
    if url.scheme == "moti" {
        if url.host == "calendar" {
            // Navigate to calendar or home tab
            self.selectedTab = 0 // Adjust based on your app's structure
        } else if url.host == "quotes" {
            // Navigate to quotes tab
            self.selectedTab = 1 // Adjust based on your app's structure
        }
    }
}
*/

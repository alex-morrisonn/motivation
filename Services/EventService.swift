import Foundation
import SwiftUI

#if os(iOS)
import WidgetKit
#endif

// Event service to manage events with app-widget data sharing
class EventService: ObservableObject {
    // Singleton instance for shared access
    static let shared = EventService()
    
    // Error types for better error handling
    enum EventServiceError: Error {
        case saveFailed
        case loadFailed
        case updateFailed
        case eventNotFound
        case appGroupAccessDenied
        case invalidEventData
        
        var description: String {
            switch self {
            case .saveFailed: return "Failed to save events"
            case .loadFailed: return "Failed to load events"
            case .updateFailed: return "Failed to update event"
            case .eventNotFound: return "Event not found"
            case .appGroupAccessDenied: return "Failed to access app group"
            case .invalidEventData: return "Invalid event data"
            }
        }
    }
    
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
    
    /// Add a new event
    /// - Parameter event: The event to add
    func addEvent(_ event: Event) {
        events.append(event)
        saveEvents()
    }
    
    /// Update an existing event
    /// - Parameter event: The event with updated properties
    func updateEvent(_ event: Event) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
            saveEvents()
        } else {
            print("Warning: Attempted to update non-existent event: \(event.id)")
        }
    }
    
    /// Delete an event
    /// - Parameter event: The event to delete
    func deleteEvent(_ event: Event) {
        events.removeAll(where: { $0.id == event.id })
        saveEvents()
    }
    
    /// Toggle completion status for an event
    /// - Parameter event: The event to toggle
    func toggleCompletionStatus(_ event: Event) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index].isCompleted.toggle()
            saveEvents()
        } else {
            print("Warning: Attempted to toggle completion for non-existent event: \(event.id)")
        }
    }
    
    // MARK: - Event Queries
    
    /// Get events for a specific date
    /// - Parameter date: The date to get events for
    /// - Returns: Array of events for the specified date
    func getEvents(for date: Date) -> [Event] {
        let calendar = Calendar.current
        return events.filter { event in
            calendar.isDate(event.date, inSameDayAs: date)
        }
    }
    
    /// Get upcoming events for the next 7 days
    /// - Returns: Array of events for the next week, sorted by date
    func getUpcomingEvents() -> [Event] {
        let today = Date()
        let calendar = Calendar.current
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: today)!
        
        return events.filter { event in
            let eventDate = event.date
            return (eventDate >= today && eventDate <= nextWeek)
        }.sorted { $0.date < $1.date }
    }
    
    /// Get events for the current month
    /// - Returns: Array of events in the current month
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
    
    /// Get days in current month that have events
    /// - Returns: Dictionary with days as keys and boolean values
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
    
    /// Save events to shared UserDefaults for app and widget access
    private func saveEvents() {
        do {
            // Validate events before saving
            guard !events.contains(where: {
                $0.title.isEmpty || $0.date == Date.distantPast
            }) else {
                print("Warning: Attempting to save invalid event data")
                // Continue saving anyway to avoid data loss
            }
            
            // Create backup before saving new data
            createBackup()
            
            // Encode events
            let encoded = try JSONEncoder().encode(events)
            
            // Save to shared UserDefaults for widget access
            UserDefaults.shared.set(encoded, forKey: eventsKey)
            
            // Refresh widgets if available
            #if os(iOS)
            WidgetCenter.shared.reloadAllTimelines()
            #endif
            
            print("Events saved successfully: \(events.count) events")
        } catch {
            print("Error saving events: \(error.localizedDescription)")
            // Try to recover by saving valid events
            attemptPartialSave()
        }
    }
    
    /// Load events from shared UserDefaults
    private func loadEvents() {
        do {
            // Check if data is corrupted and restore from backup if needed
            if isDataCorrupted() && hasBackup() {
                print("Attempting to restore events from backup")
                restoreFromBackup()
                return
            }
            
            // Normal loading
            if let savedEvents = UserDefaults.shared.data(forKey: eventsKey) {
                let decodedEvents = try JSONDecoder().decode([Event].self, from: savedEvents)
                events = decodedEvents
                print("Successfully loaded \(events.count) events")
            } else {
                events = [] // Default to empty array if no events found
                print("No saved events found")
            }
        } catch let decodingError as DecodingError {
            // Handle specific decoding errors
            print("Decoding error: \(decodingError)")
            events = [] // Reset to empty array
            attemptRecovery()
        } catch {
            print("Error loading events: \(error.localizedDescription)")
            events = [] // Reset to empty array
            attemptRecovery()
        }
    }
    
    // MARK: - Error Recovery
    
    /// Check if event data appears to be corrupted
    private func isDataCorrupted() -> Bool {
        guard let savedEvents = UserDefaults.shared.data(forKey: eventsKey) else {
            return false // No data, so not corrupted
        }
        
        do {
            // Try decoding and check for basic validity
            let decoded = try JSONDecoder().decode([Event].self, from: savedEvents)
            
            // Check for obviously corrupted events (future dates, empty titles, etc.)
            let hasSuspiciousEvents = decoded.contains { event in
                let calendar = Calendar.current
                let hundredYearsFromNow = calendar.date(byAdding: .year, value: 100, to: Date())!
                
                return event.date > hundredYearsFromNow ||
                       event.date < Date(timeIntervalSince1970: 0) ||
                       event.title.count > 1000
            }
            
            return hasSuspiciousEvents
        } catch {
            return true // Decoding failed, so data is corrupted
        }
    }
    
    /// Check if backup is available
    private func hasBackup() -> Bool {
        return UserDefaults.shared.data(forKey: backupEventsKey) != nil
    }
    
    /// Create backup of events data
    private func createBackup() {
        do {
            // Only backup if we have valid data
            if !events.isEmpty {
                let encoded = try JSONEncoder().encode(events)
                UserDefaults.shared.set(encoded, forKey: backupEventsKey)
                
                // Add timestamp of backup
                UserDefaults.shared.set(Date(), forKey: "events_backup_timestamp")
                
                print("Events backup created")
            }
        } catch {
            print("Error creating events backup: \(error.localizedDescription)")
        }
    }
    
    /// Restore from backup
    private func restoreFromBackup() {
        if let backupData = UserDefaults.shared.data(forKey: backupEventsKey) {
            do {
                let recoveredEvents = try JSONDecoder().decode([Event].self, from: backupData)
                if !recoveredEvents.isEmpty {
                    print("Recovered \(recoveredEvents.count) events from backup")
                    events = recoveredEvents
                    
                    // Save to main storage
                    saveEvents()
                } else {
                    events = []
                    print("Backup was empty, reset to empty events array")
                }
            } catch {
                print("Backup restoration failed: \(error.localizedDescription)")
                events = [] // Reset to empty if backup is also corrupted
            }
        } else {
            print("No backup found, reset to empty events array")
            events = []
        }
    }
    
    /// Attempt to save only valid events
    private func attemptPartialSave() {
        let validEvents = events.filter { !$0.title.isEmpty && $0.date != Date.distantPast }
        
        if validEvents.count < events.count {
            print("Attempting to save \(validEvents.count) valid events out of \(events.count) total")
            events = validEvents
        }
        
        do {
            let encoded = try JSONEncoder().encode(events)
            UserDefaults.shared.set(encoded, forKey: eventsKey)
            print("Partial save successful")
        } catch {
            print("Partial save also failed: \(error.localizedDescription)")
        }
    }
    
    /// Attempt to recover corrupted data
    private func attemptRecovery() {
        print("Attempting to recover events data...")
        
        // First try to restore from backup
        if hasBackup() {
            restoreFromBackup()
        } else {
            // If no backup, start with empty events
            events = []
            saveEvents()
            print("No recovery source available, reset to empty events array")
        }
    }
}

// Extension of UserDefaults to provide shared access for widgets
extension UserDefaults {
    static var shared: UserDefaults {
        return UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }
}

// Shared App Group identifier for app-widget communication
let appGroupIdentifier = "group.com.alexmorrison.moti.shared"
